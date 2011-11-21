#ifndef MACROS
#define MACROS

#define Q 9
#define BLOCK_SIZE 64

#if Q == 9						
	#define LOAD_EX(ex) {ex[0]=0;ex[1]=1;ex[2]=0;ex[3]=-1;ex[4]=0;ex[5]=1;ex[6]=-1;ex[7]=-1;ex[8]=1;}
	#define LOAD_EY(ey) {ey[0]=0;ey[1]=0;ey[2]=1;ey[3]=0;ey[4]=-1;ey[5]=1;ey[6]=1;ey[7]=-1;ey[8]=-1;}
	#define LOAD_OMEGA(omega) {omega[0]=4.f/9.f;omega[1]=1.f/9.f;omega[2]=1.f/9.f;omega[3]=1.f/9.f;omega[4]=1.f/9.f;omega[5]=1.f/36.f;omega[6]=1.f/36.f;omega[7]=1.f/36.f;omega[8]=1.f/36.f;}
	#define LOAD_OPP(opp) {opp[0]=0;opp[1]=3;opp[2]=4;opp[3]=1;opp[4]=2;opp[5]=7;opp[6]=8;opp[7]=5;opp[8]=6;}
#endif

#endif