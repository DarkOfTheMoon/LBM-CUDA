cmake_minimum_required(VERSION 2.8)

project(lbm-cuda)

find_package(CUDA REQUIRED)
if(CMAKE_COMPILER_IS_GNUCXX)
    add_definitions(-std=gnu++0x)
endif()

set(CMAKE_CXX_LINK_FLAGS "-Wl,-Bsymbolic-functions -Wl,-z,relro ${CMAKE_CXX_LINK_FLAGS}")
if(CUDA_FOUND)
	include_directories(${CUDA_INCLUDE_DIRS})
	set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} --gpu-architecture sm_20)
else(CUDA_FOUND)
	message(FATAL_ERROR "CUDA NOT FOUND")
endif(CUDA_FOUND)

find_package(HDF5 REQUIRED)

if(HDF5_FOUND)
	include_directories(${HDF5_INCLUDE_DIRS})
else(HDF5_FOUND)
	message(FATAL_ERROR "HDF5 NOT FOUND")
endif(HDF5_FOUND)
# set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};-gencode arch=compute_20,code=sm_20)

include_directories(/usr/include/Palabos-1.4)

add_definitions(-DD2Q9)
add_subdirectory(LBM-C)
