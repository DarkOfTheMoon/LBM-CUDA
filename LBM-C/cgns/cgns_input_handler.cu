#ifndef CGNS_INPUT_HANDLER
#define CGNS_INPUT_HANDLER

#include <stdio.h>
#include <string>
#include <iostream>
#include <sstream>
#include <vector>
using namespace std;
/* cgnslib.h file must be located in directory specified by -I during compile: */
#include <cgnslib.h>

class CGNSInputHandler
{

    string fname;

    // CGNS variables
    int index_file;
    int length[DIM];

    void open_file()
    {
        cgns_error_check ( cg_open ( fname.c_str(),CG_MODE_READ,&index_file ) );
    }

    void close_file()
    {
        cgns_error_check ( cg_close ( index_file ) );
    }

    void cgns_error_check ( int error_code )
    {
        if ( error_code!=0 )
        {
            const char *error_message = cg_get_error();
            cout << error_message << endl;
            getchar();
            cg_error_exit();
        }
    }

public:
    CGNSInputHandler ( const string &input_filename, int [DIM] );

    CGNSInputHandler ();

    template<class T>
    void read_field ( T *data, char *label )
    {
#warning fix function
        int num_arrays;

        //unused pointers;
        CG_DataType_t d_type;

        bool field_found = false;
        int i;
        char array_name[30];

        cgsize_t min[DIM], max[DIM];

        for ( int i=0; i!=DIM; i++ )
        {
            min[i]=1;
            max[i]=length[i];
        }

        open_file();

        cgns_error_check ( cg_nfields ( index_file, 1, 1, 1, &num_arrays ) );
        for ( i = 1; i<num_arrays+1; i++ )
        {
            cgns_error_check ( cg_field_info ( index_file, 1, 1, 1, i, &d_type, array_name ) );
            if ( strcmp ( array_name, label ) == 0 )
            {
                field_found = true;
                cgns_error_check ( cg_field_info ( index_file, 1, 1, 1, i, &d_type, array_name ) );
                break;
            }
        }
        if ( field_found==true )
        {
            cgns_error_check ( cg_field_read ( index_file, 1, 1, 1, label, d_type, min, max,data ) );
            cout << endl << "Input Handler: " << label << " loaded" << endl;
        }
        else
        {
            cout << endl << "Input Handler: " << label << " not found in file \"" << fname << "\"" << endl;
            exit ( -1 );
        }

        close_file();

    }

};

CGNSInputHandler::CGNSInputHandler ( const string &input_filename, int length_in[DIM] )
{
    fname = input_filename;

    for ( int i=0; i!=DIM; ++i )
        length[i]=length_in[i];

    open_file();

}

CGNSInputHandler::CGNSInputHandler () {}

#endif
