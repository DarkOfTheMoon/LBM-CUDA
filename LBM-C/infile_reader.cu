#include "data_types.cuh"

//#include <stdio.h>
#include <fstream>
#include <iostream>
#include <string>
#include <sstream>
#include "TINYXML_xmlIO.h"
#include "TINYXML_xmlIO.hh"
using namespace std;

class InfileReader
{

    DomainConstant *domain_constants;
    Timing *timer;
    OutputController *output_controller;
    ProjectStrings *project;

    void initialise()
    {
        domain_constants->c_smag = 0;
    }

    void parse_file ( XMLreader const& document )
    {
        document["Project"]["ProjName"].read ( project->name );
        document["Project"]["DomainFile"].read ( project->domain_fname );
        document["Project"]["OutputFile"].read ( project->output_fname );
        document["Project"]["DomainConst"]["TauMRT"]["TauMRT0"].read ( domain_constants->tau_mrt[0] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT1"].read ( domain_constants->tau_mrt[1] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT2"].read ( domain_constants->tau_mrt[2] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT3"].read ( domain_constants->tau_mrt[3] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT4"].read ( domain_constants->tau_mrt[4] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT5"].read ( domain_constants->tau_mrt[5] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT6"].read ( domain_constants->tau_mrt[6] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT7"].read ( domain_constants->tau_mrt[7] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT8"].read ( domain_constants->tau_mrt[8] );
#if DIM>2
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT9"].read ( domain_constants->tau_mrt[9] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT10"].read ( domain_constants->tau_mrt[10] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT11"].read ( domain_constants->tau_mrt[11] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT12"].read ( domain_constants->tau_mrt[12] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT13"].read ( domain_constants->tau_mrt[13] );
		document["Project"]["DomainConst"]["TauMRT"]["TauMRT14"].read ( domain_constants->tau_mrt[14] );
#endif
		document["Project"]["DomainConst"]["Tau"].read ( domain_constants->tau );

		document["Project"]["DomainConst"]["Geometry"]["DeltaX"].read ( domain_constants->h );
		document["Project"]["DomainConst"]["Geometry"]["x"].read ( domain_constants->length[0] );
		document["Project"]["DomainConst"]["Geometry"]["y"].read ( domain_constants->length[1] );
#if DIM >2
		document["Project"]["DomainConst"]["Geometry"]["z"].read ( domain_constants->length[2] );
#endif
		document["Project"]["DomainConst"]["DeltaT"].read ( domain_constants->dt );
		document["Project"]["DomainConst"]["C_smag"].read ( domain_constants->c_smag );
        //TODO enum{BGK,NTPOR,MRT,MRTPOR}
		document["Project"]["DomainConst"]["ColType"].read ( domain_constants->collision_type );

		document["Project"]["DomainConst"]["Force"].read ( domain_constants->forcing );
		document["Project"]["DomainConst"]["MicroBC"].read ( domain_constants->micro_bc );
		document["Project"]["DomainConst"]["MacroBC"].read ( domain_constants->macro_bc );
		document["Project"]["DomainConst"]["Tolerance"].read ( domain_constants->tolerance );
		document["Project"]["DomainConst"]["Init"].read ( domain_constants->init_type );

        document["Project"]["Timer"]["MaxT"].read ( timer->max );
		document["Project"]["Timer"]["FileOut"].read ( timer->plot );
		document["Project"]["Timer"]["ScreenMes"].read ( timer->screen );
		document["Project"]["Timer"]["SteadyCheck"].read ( timer->steady_check );

        document["Project"]["OutPutController"]["OutputVars"]["u"].read ( output_controller->u[0] );
		document["Project"]["OutPutController"]["OutputVars"]["v"].read ( output_controller->u[1] );
#if DIM >2
		document["Project"]["OutPutController"]["OutputVars"]["w"].read ( output_controller->u[2] );
#endif
		document["Project"]["OutPutController"]["OutputVars"]["rho"].read ( output_controller->rho );
		document["Project"]["OutPutController"]["OutputVars"]["pressure"].read ( output_controller->pressure );

		document["Project"]["OutPutController"]["ScreenNode"]["x"].read ( output_controller->screen_node[0] );
		document["Project"]["OutPutController"]["ScreenNode"]["y"].read ( output_controller->screen_node[1] );
#if DIM >2
		document["Project"]["OutPutController"]["ScreenNode"]["z"].read ( output_controller->screen_node[2] );
#endif
		document["Project"]["OutPutController"]["Interactive"].read ( output_controller->interactive );
    }

public:
    InfileReader ( XMLreader const& document, ProjectStrings*, DomainConstant *,Timing *,OutputController * );
};

InfileReader::InfileReader ( XMLreader const& document, ProjectStrings *project_in, DomainConstant *domain_constants_in, Timing *timer_in, OutputController *output_controller_in )
{
    project = project_in;
    domain_constants = domain_constants_in;
    timer = timer_in;
    output_controller = output_controller_in;

    cout << endl << "Reading configuration data: " << endl << endl;

    initialise();
    parse_file ( document );

    cout << endl << "Finished reading configuration data." << endl;
}







