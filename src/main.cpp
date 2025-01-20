#include <algorithm>
#include <cstdio>
#include <cstdlib>

#include "array.h"
#include "sort.h"
#include "timing.h"

int const programCount = 8;
int const N = programCount * programCount;

int main() {
    StaticArray<float> input = random_array(N);
    StaticArray<float> cpp_output(N, 0);
    StaticArray<float> ispc_output(N, 0);

    input[0] = 16;
    input[1] = 22;
    input[2] = 10;
    input[3] = 3;
    input[4] = 6;
    input[5] = 5;
    input[6] = 8;
    input[7] = 13;
    input[8] = 1;
    input[9] = 7;
    input[10] = 15;
    input[11] = 23;
    input[12] = 9;
    input[13] = 2;
    input[14] = 11;
    input[15] = 14;

    for(int i = N; i >= 0; i--) {
        input[i] = i;
    }

    for (int i = 0; i < N; i++) {
        printf("%f, ", input[i]);

        if ((i + 1) % programCount == 0 && i != 0) {
            printf("\n");
        }
    }
    printf("\n\n");

    // runtime for timing
    int runtime;

    std::copy(input.begin(), input.end(), cpp_output.begin());
    TIMEIT(runtime) {
        std::sort(cpp_output.begin(),
                  cpp_output.end());
    }
    printf("CPP, sequential:               %8d microseconds\n", runtime);


    ispc::sort(input.begin(), ispc_output.begin(), N); 
    printf("ISPC, sequential:              %8d microseconds\n", runtime);

    for (int i = 0; i < N; i++) {
        printf("%f, ", ispc_output[i]);

        if ((i + 1) % programCount == 0 && i != 0) {
            printf("\n");
        }
    }
    printf("\n");

    printf("finished test\n");

    return 0;
}
