#include "array.h"
#include "sort.h"

#include <cstdlib>
#include <algorithm>

#include <sys/time.h>

// has to be multiple of 16(m*m) for now
int const N = pow(2, 16);
int const NUM_RUNS = 1000;

int get_elapsed(struct timeval &start, struct timeval &end) {
    int elapsed = (end.tv_sec * 1000000 + end.tv_usec) -
                  (start.tv_sec * 1000000 + start.tv_usec);

    return elapsed / NUM_RUNS;
}

double get_throughput(int elapsed) {
    double total_data =  N * sizeof(float);                   // bytes
    double elapsed_seconds = elapsed * 10e-6;                 // microseconds to seconds
    double bytes_per_sec = total_data / elapsed_seconds;      // B/s
    double throughput = bytes_per_sec / (1024 * 1024);        // MiB/s

    return throughput;
}

void print_out(float *array, size_t n) {
    for (size_t i = 0; i < n; i++) {
        printf("%f ", array[i]);

        if (i > 0 && (i + 1) % 4 == 0)
            printf("\n");
    }
    printf("\n\n");
}

inline int cmp(void const *a, void const *b) {
    return *(float *)a > *(float *)b;
}

int validate(float *reference, float *test, size_t n) {
    for (size_t i = 0; i < n; i++) {
        const float tolerance = 0.01;
        float abs_rel_diff = fabsf((reference[i] - test[i]) / reference[i]);
        if (abs_rel_diff > tolerance) {
            fprintf(stderr,
                    "ISPC, results differ at index %zu with tolerance = %f: "
                    "(expected, actual) = (%f, %f).\n",
                    i, tolerance, reference[i], test[i]);

            return 1;
        }
    }

    return 0;
}

int main() {
    StaticArray<float> input = random_array(N);

    StaticArray<float> cpp_output(N, 0);
    StaticArray<float> ispc_output(N, 0);
    StaticArray<float> c_output(N, 0);

    struct timeval start, end;
    struct timeval copy_start, copy_end;
    int elapsed;
    double throughput;

    // CPP
    {
        std::copy(input.begin(), input.end(), cpp_output.begin());

        // start timing
        gettimeofday(&start, NULL);

        for (int i = 0; i < NUM_RUNS; i++) {
            std::sort(cpp_output.begin(), cpp_output.end());
        }

        // end timing
        gettimeofday(&end, NULL);

        elapsed = get_elapsed(start, end);
        throughput = get_throughput(elapsed);

        printf("CPP, sequential:               %8d microseconds\n", elapsed);
        printf("Throughput:                    %8.4f MiB/s\n\n", throughput);
    }

    // ispc
    {
        // start timing
        gettimeofday(&start, NULL);

        for (int i = 0; i < NUM_RUNS; i++) {
            ispc::sort(input.begin(), ispc_output.begin(), N);
        }

        // end timing
        gettimeofday(&end, NULL);

        elapsed = get_elapsed(start, end);
        throughput = get_throughput(elapsed);

        printf("ISPC, sequential:              %8d microseconds\n", elapsed);
        printf("Throughput:                    %8.4f MiB/s\n\n", throughput);
    }

    // C
    {
        std::copy(input.begin(), input.end(), c_output.begin());

        // start timing
        gettimeofday(&start, NULL);

        for (int i = 0; i < NUM_RUNS; i++) {
            qsort(c_output.begin(), N, sizeof(float), cmp);
        }

        // end timing
        gettimeofday(&end, NULL);

        elapsed = get_elapsed(start, end);
        throughput = get_throughput(elapsed);

        printf("C, sequential:                 %8d microseconds\n", elapsed);
        printf("Throughput:                    %8.4f MiB/s\n\n", throughput);
    }

    // print_out(cpp_output.begin(), N);
    // print_out(ispc_output.begin(), N);
    // print_out(c_output.begin(), N);

    validate(cpp_output.begin(), ispc_output.begin(), N);

    printf("finished test\n");

    return 0;
}
