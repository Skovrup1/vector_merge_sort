CXX = clang++
ISPC = ispc

CXXFLAGS = -O3 -Wall -Wextra -std=c++20
ISPCFLAGS = -O3 --arch=x86-64 --target=avx2-i32x4

SRC_DIR = src
BUILD_DIR = build

CPP_SRC = $(SRC_DIR)/main.cpp
ISPC_SRC = $(SRC_DIR)/sort.ispc

CPP_OBJ = $(BUILD_DIR)/main.o
ISPC_OBJ = $(BUILD_DIR)/sort.o
ISPC_HEADER = $(SRC_DIR)/sort.h

TARGET = $(BUILD_DIR)/main

all: $(TARGET)

$(TARGET): $(CPP_OBJ) $(ISPC_OBJ)
	$(CXX) $(CXXFLAGS) $(TBB_LIB) -o $@ $^

$(CPP_OBJ): $(CPP_SRC) $(ISPC_HEADER)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(TBB_INCLUDE) -c -o $@ $<

$(ISPC_OBJ) $(ISPC_HEADER): $(ISPC_SRC)
	@mkdir -p $(BUILD_DIR)
	$(ISPC) $(ISPCFLAGS) -o $(ISPC_OBJ) -h $(ISPC_HEADER) $<

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(ISPC_HEADER)

.PHONY: all clean
