// value has to be power of 2
uniform int ilog2(uniform int value) {
    return count_trailing_zeros(value);
}

float reverse(float value) {
    int8 perm;
    foreach(i = 0...programCount) {
        uint pid = programCount - 1 - i;
        perm = pid;
    }

    return shuffle(value, perm);
}

void compare(float &a, float &b) {
    float min_val = min(a, b);
    float max_val = max(a, b);
    a = min_val;
    b = max_val;
}

int8 exchange_perm(int w) {
    int8 perm;
    foreach(i = 0...programCount) {
        int t = (i >> (w - 1)) & 1;
        perm = i + t * (programCount - w);
    }

    return perm;
}

void exchange(float &a, float &b, int w) {
    foreach(i = 0...programCount) {
        int8 const perm1 = exchange_perm(w);
        int8 const perm2 = perm1 + w;

        float x = shuffle(a, b, perm1);
        float y = shuffle(a, b, perm2);

        a = x;
        b = y;
    }
}

int8 final_perm() {
    int8 perm;
    foreach(i = 0...programCount) {
        perm = (i & 1) * programCount + i / 2;
    }

    return perm;
}

void final_shuffle(float &a, float &b) {
    int8 const perm1 = final_perm();
    int8 const perm2 = perm1 + 2;

    float x = shuffle(a, b, perm1);
    float y = shuffle(a, b, perm2);

    a = x;
    b = y;
}


int8 interleave_lft() {
    int8 perm;
    foreach(i = 0...programCount) {
        perm = (i & 1) * programCount + i / 2;
    }

    return perm;
}

int8 interleave_rgt() {
    return interleave_lft() + programCount / 2;
}

void bitonic_merge_kernel(float &a, float &b) {
    uniform int const m = programCount;
    uniform int const log_m = ilog2(m);

    foreach (i = 0...m) {
        b = reverse(b);

        for (uniform int j = 0; j < log_m; j++) {
            int w = 1 + log_m - (1 << j);

            compare(a, b);
            exchange(a, b, w);
        }

        compare(a, b);
        final_shuffle(a, b);
    }
}

void merge_lists(uniform float list0[], uniform float list1[],
                 uniform float output[], uniform size_t n) {
    uniform int const m = programCount;

    float a;
    float b;
    foreach(l = 0...m) {
        a = list0[l];
        b = list1[l];
    }

    uniform int i = 0;
    uniform int j = 0;

    for (uniform int k = 0; k < n * 2 - m; k += m) {
        foreach(l = 0...m) {
            bitonic_merge_kernel(a, b);     // get sorted sequence of 2m
            output[l + k] = a;              // store the lowest m
        }

        uniform float x = FLT_MAX;
        uniform float y = FLT_MAX;
        if (i + m < n) {
            x = list0[i + m];
        }

        if (j + m < n) {
            y = list1[j + m];
        }

        if (x < y) {
            i += m;
            foreach(l = 0...m) {
                a = list0[l + i];
            }
        } else {
            j += m;
            foreach(l = 0...m) {
                a = list1[l + j];
            }
        }
    }

    foreach(l = (n * 2 - m)...(n * 2)) {
        output[l] = b;
    }
}

void merge(uniform float input[], uniform float output[], uniform size_t n) {
    uniform int const m = programCount;
    uniform int const iterations = ilog2(n / m);

    for (uniform uint32 i = 1; i < iterations + 1; i++) {
        uniform int const half_len = m / 4 * (1 << (i + 1));
        uniform int const seq_len = 2 * half_len;

        for (uniform size_t j = 0; j < n / seq_len; j++) {
            merge_lists(&input[j * seq_len],
                        &input[j * seq_len + half_len],
                        &output[j * seq_len],
                        half_len);
        }

        // local swap of input and output arrays
        uniform float *uniform temp = input;
        input = output;
        output = temp;
    }

    // can we get rid of this?
    if (iterations % 2 == 0) {
        memcpy(output, input, n * sizeof(float));
    }
}

void transpose_matrix(uniform float data[]) {
    uniform int const m = programCount;
    uniform int const log_m = ilog2(m);

    int8 const inter_lft = interleave_lft();
    int8 const inter_rgt = interleave_rgt();

    foreach(i = 0...m) {
        for (uniform int j = 0; j < log_m; j++) {
            int w = m / (1 << (j + 1));
                for (uniform int k = 0; k < m / 2; k++) {
                    int x;
                    if (j == 0) {
                        x = k;
                    }
                    else if (j == 1) {
                        if (k > 2) {
                            x = 5;
                        }
                        else if (k > 1) {
                            x = k * 2;
                        } else {
                            x = k;
                        }
                    }
                    else if (j == 2) {
                        x = k * 2;
                    }

                    int y = x + w;

                    int ix = i + m * x;
                    int iy = i + m * y;

                    // desired results
                    // k: 0 1 2 3

                    // w: 4
                    // x: 0 8 16 24   k * m
                    // y: 32 40 48 56 x + m * w

                    // w: 2
                    // 0 8 32 40      k * m
                    // 16 24 48 56    x + m * w

                    // w: 1
                    // 0 16 32 48     k * m * 2
                    // 8 24 40 56     x * m + w

                    float a = shuffle(data[ix], data[iy], inter_lft);
                    float b = shuffle(data[ix], data[iy], inter_rgt);

                    data[ix] = a;
                    data[iy] = b;
            }
        }
    }
}

void bitonic_sort(uniform float data[]) {
    uniform int const m = programCount;
    uniform int const n = m * m;
    uniform int const num_rounds = m - 1 + (m * ilog2(m) * (ilog2(m) - 1))/4;

    for (uniform int r = 0; r < num_rounds; r++) {
        foreach (i = 0...(n - m)) {
            float a = data[i];
            float b = data[i + m];

            compare(a, b);

            data[i] = a;
            data[i + m] = b;
        }
    }
}

export void sort(uniform float input[], uniform float output[], uniform size_t n) {
    uniform int const m = programCount;

    // process in m * m chunks
    for (uniform int i = 0; i < n; i += m * m) {
        bitonic_sort(&input[i]);

        transpose_matrix(&input[i]);
    }

    // if you want to check the transposed output
    /*foreach (i = 0...n) {
        output[i] = input[i];
    }*/

    merge(input, output, n);
}
