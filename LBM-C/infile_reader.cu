#include "data_types.cuh"

//#include <stdio.h>
#include <fstream>
#include <iostream>
#include <string>
#include <sstream>
#include <libraryInterfaces/TINYXML_xmlIO.h>
#include <libraryInterfaces/TINYXML_xmlIO.hh>
#include <libraryInterfaces/TINYXML_xmlIO.cpp>
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

    void parse_file ( plb::XMLreader const& document )
    {
		std::string tmp;
        document["ProjName"].read (project->name );

		std::cout<<project->name<<std::endl;
		exit(0);

        document["DomainFile"].read ( project->domain_fname );
        document["OutputFile"].read ( project->output_fname );
        document["TauMRT"]["TauMRT0"].read ( domain_constants->tau_mrt[0] );
        document["TauMRT"]["TauMRT1"].read ( domain_constants->tau_mrt[1] );
        document["TauMRT"]["TauMRT2"].read ( domain_constants->tau_mrt[2] );
        document["TauMRT"]["TauMRT3"].read ( domain_constants->tau_mrt[3] );
        document["TauMRT"]["TauMRT4"].read ( domain_constants->tau_mrt[4] );
        document["TauMRT"]["TauMRT5"].read ( domain_constants->tau_mrt[5] );
        document["TauMRT"]["TauMRT6"].read ( domain_constants->tau_mrt[6] );
        document["TauMRT"]["TauMRT7"].read ( domain_constants->tau_mrt[7] );
        document["TauMRT"]["TauMRT8"].read ( domain_constants->tau_mrt[8] );
#if DIM>2
        document["TauMRT"]["TauMRT9"].read ( domain_constants->tau_mrt[9] );
        document["TauMRT"]["TauMRT10"].read ( domain_constants->tau_mrt[10] );
        document["TauMRT"]["TauMRT11"].read ( domain_constants->tau_mrt[11] );
        document["TauMRT"]["TauMRT12"].read ( domain_constants->tau_mrt[12] );
        document["TauMRT"]["TauMRT13"].read ( domain_constants->tau_mrt[13] );
        document["TauMRT"]["TauMRT14"].read ( domain_constants->tau_mrt[14] );
#endif
        document["Tau"].read ( domain_constants->tau );

        document["Geometry"]["DeltaX"].read ( domain_constants->h );
        document["Geometry"]["x"].read ( domain_constants->length[0] );
        document["Geometry"]["y"].read ( domain_constants->length[1] );
#if DIM >2
        document["Geometry"]["z"].read ( domain_constants->length[2] );
#endif
        document["DeltaT"].read ( domain_constants->dt );
        document["C_smag"].read ( domain_constants->c_smag );
        //TODO enum{BGK,NTPOR,MRT,MRTPOR}
        document["ColType"].read ( domain_constants->collision_type );

        document["Force"].read ( domain_constants->forcing );
        document["MicroBC"].read ( domain_constants->micro_bc );
        document["MacroBC"].read ( domain_constants->macro_bc );
        document["Tolerance"].read ( domain_constants->tolerance );
        document["Init"].read ( domain_constants->init_type );
        document["MaxT"].read ( timer->max );
        document["FileOut"].read ( timer->plot );
        document["ScreenMes"].read ( timer->screen );

        document["SteadyCheck"].read ( timer->steady_check );

        document["OutputVars"]["u"].read ( output_controller->u[0] );
        document["OutputVars"]["v"].read ( output_controller->u[1] );
#if DIM >2
        document["OutputVars"]["w"].read ( output_controller->u[2] );
#endif
        document["OutputVars"]["rho"].read ( output_controller->rho );
        document["OutputVars"]["pressure"].read ( output_controller->pressure );

        document["ScreenNode"]["x"].read ( output_controller->screen_node[0] );
        document["ScreenNode"]["y"].read ( output_controller->screen_node[1] );
#if DIM >2
        document["ScreenNode"]["z"].read ( output_controller->screen_node[2] );
#endif
        document["Interactive"].read ( output_controller->interactive );

    }

public:
    InfileReader ( plb::XMLreader const& document, ProjectStrings*, DomainConstant *,Timing *,OutputController * );
};

InfileReader::InfileReader ( plb::XMLreader const& document, ProjectStrings *project_in, DomainConstant *domain_constants_in, Timing *timer_in, OutputController *output_controller_in )
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






