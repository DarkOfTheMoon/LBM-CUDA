

cuda_add_executable(LBM-C index.cu TINYXML_xmlIO.cpp)

target_link_libraries(LBM-C  cgns ${HDF5_LIBRARIES} ${CUDA_LIBRARIES} tinyxml)
