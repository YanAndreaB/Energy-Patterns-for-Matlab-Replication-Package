// Compile with: mex readMsrByIdMex_noErrorHandling

#include <stdio.h> // needed for perror()
#include <stdlib.h> // needed for exit()
#include <stdint.h> // needed for uint64_t
#include <fcntl.h> // needed for open()
#include <unistd.h> // needed for pread()
#include "mex.h"
#include "matrix.h"

static long long read_msr_by_id(int registerId, int cpuId) {

	int fileId;
    uint64_t data;
    char msrFileName[BUFSIZ];

    sprintf(msrFileName,"/dev/cpu/%d/msr",cpuId);
	fileId = open(msrFileName, O_RDONLY); // open MSR file

    // read MSR file
	pread(fileId, &data, sizeof data, registerId);

    close(fileId);
	return (long long) data;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray *prhs[]) {
    long long data;

    data = read_msr_by_id(mxGetScalar(prhs[0]),mxGetScalar(prhs[1])); // get data from MSR
    plhs[0] = mxCreateDoubleScalar(data); // return value
}
