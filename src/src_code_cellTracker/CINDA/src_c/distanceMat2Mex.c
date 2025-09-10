#include <stdio.h>
#include <mex.h>
#include "matrix.h"
#define MAX(x, y) (((x) > (y)) ? x : y)
#define ABS(x) ((x) >= 0) ? (x) : -(x)
/*given two vector, get the m-by-n matrix, each element indicating the absolute
 difference between correponding elements in these two vectors*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 2)
        mexErrMsgTxt("Incorrect number of input arguments");
    if (nlhs != 1)
        mexErrMsgTxt("Incorrect number of output arguments");
    double *v_m = (double *)mxGetPr(prhs[0]);
    size_t l_m = MAX(mxGetN(prhs[0]), mxGetM(prhs[0]));
    
    double *v_n = (double *)mxGetPr(prhs[1]);
    size_t l_n = MAX(mxGetN(prhs[1]), mxGetM(prhs[1]));
//
    plhs[0] = mxCreateDoubleMatrix((mwSize)l_m, (mwSize)l_n, mxREAL);
    double *tracks = (double *)mxGetPr(plhs[0]);
    for(size_t i=0; i< l_m; i++){
        for(size_t j=0; j< l_n; j++){
            tracks[i + j * l_m] = ABS((v_m[i]-v_n[j]));
        }
    }
    return;
}