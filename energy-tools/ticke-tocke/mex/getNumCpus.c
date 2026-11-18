// Compile with: mex getNumCpus

#include <stdio.h> 
#include <dirent.h> 

#include "mex.h"
#include "matrix.h"

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray *prhs[]) {
    struct dirent *de;  // Pointer for directory entry 
    int counter = 0;
  
    // opendir() returns a pointer of DIR type.  
    DIR *dr = opendir("/dev/cpu");
  
    if (dr == NULL)  // opendir returns NULL if couldn't open directory 
    { 
        printf("Could not open current directory" ); 
    } 
  
    // Refer http://pubs.opengroup.org/onlinepubs/7990989775/xsh/readdir.html 
    // for readdir() 
    while ((de = readdir(dr)) != NULL) {
        // TODO: count only directories whos directory name is an integer number
        counter++;
    }
    closedir(dr);

    // substract 2 from counter for directories . and ..
    plhs[0] = mxCreateDoubleScalar(counter - 2); // return value
}    
