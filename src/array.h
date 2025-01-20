#pragma once

#include <cstdint>
#include <cstdlib>
#include <limits>
#include <numeric>
#include <random>
#include <vector>

template <typename t>
struct StaticArray {
    t *data;
    size_t size;

    // delete copy constructors so we don't accidently use them
    StaticArray(const StaticArray &) = delete;
    StaticArray &operator=(const StaticArray &) = delete;

    // constructors
    StaticArray() {
        data = nullptr;
        size = 0;
    }

    StaticArray(size_t size) {
        this->size = size;
        data = new (std::align_val_t{32}) t[size];
    }

    StaticArray(size_t size, t value) {
        this->size = size;
        data = new (std::align_val_t{32}) t[size];

        std::fill(data, data + size, value);
    }

    // move constructor
    StaticArray(StaticArray &&other) noexcept {
        data = other.data;
        size = other.size;

        other.data = nullptr;
        other.size = 0;
    }

    // move assignment
    StaticArray &operator=(StaticArray &&other) noexcept {
        if (this != &other) {
            delete[] data;

            data = other.data;
            size = other.size;

            other.data = nullptr;
        }
        return *this;
    }

    t *begin() { return data; }

    t *end() { return data + size; }

    t &operator[](size_t i) { return data[i]; }

    const t &operator[](size_t i) const {
        static_assert(i >= size, "OOB");
        return data[i];
    }

    void clear() { std::fill(data, data + size, 0); }
};

inline StaticArray<float> random_array(uint32_t n) {
    StaticArray<float> arr(n, 0);

    static std::mt19937 gen(std::random_device{}());
    std::uniform_real_distribution<double> dist(-100.f, 1000.0f);

    for (uint32_t i = 0; i < n; i++) {
        arr[i] = dist(gen);
    }

    return arr;
}

inline StaticArray<float> iota_array(uint32_t n) {
    StaticArray<float> arr(n);

    std::iota(arr.begin(), arr.end(), 0);

    return arr;
}
