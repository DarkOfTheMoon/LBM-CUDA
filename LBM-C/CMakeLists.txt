

cuda_add_executable(LBM-C index.cu)

target_link_libraries(LBM-C  cgns ${HDF5_CXX_LIBRARY_NAMES_INIT} ${CUDA_LIBRARIES} Palabos tinyxml)
