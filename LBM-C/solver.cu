#ifndef SOLVER
#define SOLVER

#define LOAD_x_ORDER(a) {a[0]=3;a[1]=6;a[2]=7;a[3]=2;a[4]=4;a[5]=1;a[6]=8;a[7]=5;}

#include "macros.cu"
#include "solver.cuh"
#include "data_types.cuh"
#include "d2q9_boundary.cu"
#include "cuda.h"
#include "cuda_runtime.h"
#include "device_launch_parameters.h"


// PREFORMS ONE ITERATION OF THE LBM ON BULK NODES(NODES WHICH ARE NOT ON A DOMAIN BOUNDARY)
__global__ void iterate_bulk_kernel (Lattice *lattice_1, Lattice *lattice_2, Domain *domain)
{
	// Declare variables
	float f_eq,omega[Q],cu,u_sq, collision_bgk, collision_s, B;
	int i2d, ex[Q], ey[Q], opp[Q];
	int2 length;
	Node current_node;
	

	// Initialise variables
	LOAD_EX(ex);
	LOAD_EY(ey);
	LOAD_OMEGA(omega);
	LOAD_OPP(opp);
	current_node.rho = 0; current_node.ux = 0; current_node.uy = 0;
	
	// Compute coordinates
	int x     = threadIdx.x+1;
    int y     = blockIdx.x+1;

	// Load domain configuration
	length.x = domain->length.x;
	length.y = domain->length.y;
	int domain_size = length.x*length.y;
	float tau = domain->tau;

	// Check and account for boundary type, take note, this refers to internal boundaries
	// bounceback, halfway bounceback etc
	// B = 0 - BOUNCEBACK
	// 1 <= B < 2 - PARTIAL BOUNCEBACK
	int i2d_prime = x + y*length.x;
	float boundary_type = floor(domain->boundary_type[i2d_prime]);
	if (boundary_type >= 1.f) 
	{
		B = domain->boundary_type[i2d_prime]-boundary_type;
	} else if (boundary_type < 1.f) 
	{
		B = 1.f;
	} 

	// STREAMING - Stream f's and calculate macroscopic values. Streaming occurs here as streaming represents
	// an uncoalesced memory access, uncoalesced reads are less time consuming than uncoalesced
	// writes.
	int target_x, target_y;
	for(int i = 0; i<Q; i++)
	{
		target_x = x+ex[i]; target_y = y+ey[i];

		i2d = (target_x + target_y*length.x)+opp[i]*(domain_size);
		
		// UNCOALESCED READ
		current_node.f[opp[i]] = lattice_1->f[i2d];

		current_node.rho += current_node.f[opp[i]];
		current_node.ux += ex[opp[i]]*current_node.f[opp[i]];
		current_node.uy += ey[opp[i]]*current_node.f[opp[i]];
	}
	
	current_node.ux = current_node.ux/current_node.rho;
	current_node.uy = current_node.uy/current_node.rho;	

	// COLLISION - COALESCED WRITE
	u_sq = 1.5f*(current_node.ux*current_node.ux + current_node.uy*current_node.uy);
	for(int i=0;i<Q;i++)
	{
		i2d = (x + y*length.x)+i*(domain_size);

		cu = 3*(ex[i]*current_node.ux+ey[i]*current_node.uy);
		f_eq = current_node.rho*omega[i]*(1.f+cu+(0.5f*cu*cu)-u_sq);

		collision_bgk = (1.f/tau) * (current_node.f[i]-f_eq);
		collision_s = current_node.f[opp[i]]-current_node.f[i];

		lattice_2->f[i2d] = current_node.f[i] - (1-B)*collision_bgk + B*collision_s;
	}
}

// PREFORMS ONE ITERATION OF THE LBM ON BOUNDARY NODES
__global__ void iterate_boundary_kernel (Lattice *lattice_1, Lattice *lattice_2, Domain *domain, int offset)
{
	// Declare Variables
	float f_eq, omega[Q], cu, u_sq, collision_bgk, collision_s, B;
	int i2d, ex[Q], ey[Q], opp[Q];
	int2 length;
	Node current_node;

	// Initialise variables
	LOAD_EX(ex);
	LOAD_EY(ey);
	LOAD_OMEGA(omega);
	LOAD_OPP(opp);
	current_node.rho = 0; current_node.ux = 0; current_node.uy = 0;
	
	// Compute coordinates
	int idx=blockIdx.x*BLOCK_SIZE+threadIdx.x+offset;
	int2 coords = compute_boundary_coords(idx, domain);
	int x = coords.x;
	int y = coords.y;

	// Load domain configuration
	length.x = domain->length.x;
	length.y = domain->length.y;
	int domain_size = length.x*length.y;
	float tau = domain->tau;
	int i2d_prime = x + y*length.x;

	// Check and account for boundary type, take note, this refers to internal boundaries
	// bounceback, halfway bounceback etc
	// B = 0 - BOUNCEBACK
	// 1 <= B < 2 - PARTIAL BOUNCEBACK
	float boundary_type = floor(domain->boundary_type[i2d_prime]);
	float boundary_value = domain->boundary_value[i2d_prime];
	if (boundary_type >= 1) 
	{
		B = domain->boundary_type[i2d_prime]-boundary_type;
	} else if (boundary_type < 1) 
	{
		B = 1.f;
	} 
	//B = 0.f;

	// STREAMING - UNCOALESCED READ
	int target_x, target_y;
	for(int i = 0; i<Q; i++)
	{
		target_x = x+ex[i]; target_y = y+ey[i];
		//PERIODIC BOUNDARY
		if(target_x>(length.x-1)) target_x = 0; if(target_x<0) target_x = length.x-1;
		if(target_y>(length.y-1)) target_y = 0; if(target_y<0) target_y = length.y-1;

		i2d = (target_x + target_y*length.x)+opp[i]*(domain_size);
		
		// UNCOALESCED READ
		current_node.f[opp[i]] = lattice_1->f[i2d];

		current_node.rho += current_node.f[opp[i]];
		current_node.ux += ex[opp[i]]*current_node.f[opp[i]];
		current_node.uy += ey[opp[i]]*current_node.f[opp[i]];
	}

	current_node.ux = current_node.ux/current_node.rho;
	current_node.uy = current_node.uy/current_node.rho;

	// APPLY BOUNDARY CONDITION
	// 2	-	Zhou/He Pressure, X- edge, uy = 0
	// 3	-	Zhou/He Pressure, X+ edge, uy = 0
	if(boundary_type == 2) current_node = zh_pressure_x(current_node, boundary_value);
	if(boundary_type == 3) current_node = zh_pressure_X(current_node, boundary_value);

	// COLLISION - COALESCED WRITE
	u_sq = 1.5f*(current_node.ux*current_node.ux + current_node.uy*current_node.uy);
	for(int i=0;i<Q;i++)
	{
		i2d = (x + y*length.x)+i*(domain_size);

		cu = 3*(ex[i]*current_node.ux+ey[i]*current_node.uy);
		f_eq = current_node.rho*omega[i]*(1.f+cu+(0.5f*cu*cu)-u_sq);

		collision_bgk = (1.f/tau) * (current_node.f[i]-f_eq);
		collision_s = current_node.f[opp[i]]-current_node.f[i];

		lattice_2->f[i2d] = current_node.f[i] - (1-B)*collision_bgk + B*collision_s;
	}
}

__device__ inline int2 compute_boundary_coords(int idx, Domain *domain)
{
	// All boundary nodes are indexed by a single index, thresholds define
	// the length of boundary edges and the way in which the x and y 
	// coords are calculated from the index

	int2 coord, length;
	int id;

	length.x = domain->length.x;
	length.y = domain->length.y;

	if(idx>=0 && idx<domain->b_o[0]) // X-
	{
		id = idx;
		coord.y = id+1;
		coord.x = 0;
	} else if (idx>=domain->b_o[0] && idx<domain->b_o[1]) // X+
	{
		id = idx-domain->b_o[0];
		coord.y = id+1;
		coord.x = length.x-1;
	} else if (idx>=domain->b_o[1] && idx<domain->b_o[2]) // Y-
	{
		id = idx-domain->b_o[1];
		coord.x = id+1;
		coord.y = 0;
	} else if (idx>=domain->b_o[2] && idx<domain->b_o[3]) // Y+
	{
		id = idx-domain->b_o[2];
		coord.x = id+1;
		coord.y = length.y-1;
	} else if (idx>=domain->b_o[3]) //CORNERS
	{
		id = idx-domain->b_o[3];
		if(id == 0)
		{
			coord.x = 0;
			coord.y = 0;
		} else if(id==1)
		{
			coord.x = 0;
			coord.y = length.y-1;
		} else if(id==2)
		{
			coord.x = length.x-1;
			coord.y = length.y-1;
		} else if(id==3)
		{
			coord.x = length.x-1;
			coord.y = 0;
		}
	}

	return coord;
}
/*
__global__ void iterate_all_kernel (Lattice *lattice_1, Lattice *lattice_2, Domain *domain, int offset, int type)
{
	int x,y,z;
	if(type==1)
	{
		x     = threadIdx.x+1;
		y     = blockIdx.x+1;
		z     = blockIdx.y+1;
	} else
	{
		int idx=blockIdx.x*BLOCK_SIZE+threadIdx.x+offset;
		int3 coords = compute_boundary_coords(idx, domain);
		x = coords.x;
		y = coords.y;
		z = coords.z;
	}

	float f_eq, f_eqb[Q],omega[Q],cu,u_sq, collision_bgk, collision_s, B;
	int i2d, ex[Q], ey[Q], ez[Q], opp[Q];
	int3 length;
	Node current_node;
	current_node.rho = 0; current_node.ux = 0; current_node.uy = 0; current_node.uz = 0;

	LOAD_EX(ex);
	LOAD_EY(ey);
	LOAD_EZ(ez);
	LOAD_OMEGA(omega);
	LOAD_OPP(opp);
	
	length.x = domain->length.x;
	length.y = domain->length.y;
	length.z = domain->length.z;
	int domain_size = length.x*length.y*length.z;

	float tau = domain->tau;

	int target_x, target_y, target_z;

	int i2d_prime = x + y*length.x + z*length.y*length.x;
	float boundary_type = floor(domain->boundary_type[i2d_prime]);
	float boundary_value = domain->boundary_value[i2d_prime];
	if (boundary_type >= 1) 
	{
		B = domain->boundary_type[i2d_prime]-boundary_type;
	} else if (boundary_type < 1) 
	{
		B = 1.f;
	} 
	//B = 0.f;


	for(int i = 0; i<Q; i++)
	{
		target_x = x+ex[i]; target_y = y+ey[i]; target_z = z+ez[i];
		//PERIODIC BOUNDARY
		if(target_x>(length.x-1)) target_x = 0; if(target_x<0) target_x = length.x-1;
		if(target_y>(length.y-1)) target_y = 0; if(target_y<0) target_y = length.y-1;
		if(target_z>(length.z-1)) target_z = 0; if(target_z<0) target_z = length.z-1;

		i2d = (target_x + target_y*length.x + target_z*length.y*length.x)+opp[i]*(domain_size);
		
		// UNCOALESCED READ
		current_node.f[opp[i]] = lattice_1->f[i2d];

		current_node.rho += current_node.f[opp[i]];
		current_node.ux += ex[opp[i]]*current_node.f[opp[i]];
		current_node.uy += ey[opp[i]]*current_node.f[opp[i]];
		current_node.uz += ez[opp[i]]*current_node.f[opp[i]];
	}
	
	current_node.ux = current_node.ux/current_node.rho;
	current_node.uy = current_node.uy/current_node.rho;
	current_node.uz = current_node.uz/current_node.rho;

	// APPLY BOUNDARY CONDITION
	if(type!=1)
	{
		if(boundary_type == 2) current_node = zh_pressure_ZY_x(current_node, boundary_value);
		if(boundary_type == 3) current_node = zh_pressure_ZY_X(current_node, boundary_value);
	}

	u_sq = 1.5f*(current_node.ux*current_node.ux + current_node.uy*current_node.uy + current_node.uz*current_node.uz);
	

	// COALESCED WRITE
	for(int i=0;i<Q;i++)
	{
		i2d = (x + y*length.x + z*length.y*length.x)+i*(domain_size);

		cu = 3*(ex[i]*current_node.ux+ey[i]*current_node.uy+ez[i]*current_node.uz);
		f_eq = current_node.rho*omega[i]*(1.f+cu+(0.5f*cu*cu)-u_sq);

		collision_bgk = (1.f/tau) * (current_node.f[i]-f_eq);
		collision_s = current_node.f[opp[i]]-current_node.f[i];

		lattice_2->f[i2d] = current_node.f[i] - (1-B)*collision_bgk + B*collision_s;
	}
}*/


#endif