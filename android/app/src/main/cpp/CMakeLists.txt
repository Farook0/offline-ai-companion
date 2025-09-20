# CMake configuration for MLC-LLM Android integration
# Replaces the llama.cpp build system with TVM runtime

cmake_minimum_required(VERSION 3.18.1)
project(mlc_llm_android)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Android-specific settings
set(CMAKE_ANDROID_STL_TYPE c++_shared)

# Build configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions(-DDEBUG=1)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0 -g")
else()
    add_definitions(-DNDEBUG=1)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
endif()

# Android NDK settings
if(ANDROID)
    # Target ARM64 for optimal performance
    set(ANDROID_ABI arm64-v8a)
    
    # Enable GPU support
    add_definitions(-DMLC_GPU_SUPPORT=1)
    add_definitions(-DTVM_ANDROID=1)
    
    # Disable problematic features
    add_definitions(-DNO_POSIX_MADVISE=1)
    
    # Android logging
    add_definitions(-DMLC_LOG_ANDROID=1)
    
    message(STATUS "Building for Android ${ANDROID_ABI}")
endif()

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# Find required libraries
find_library(log-lib log)
find_library(android-lib android)

# MLC-LLM Runtime Library Configuration
# This links to actual MLC-LLM and TVM runtime libraries

set(MLC_RUNTIME_SOURCES
    mlc_tvm_wrapper.cpp
)

# Create MLC-LLM wrapper library
add_library(mlc_tvm_wrapper SHARED ${MLC_RUNTIME_SOURCES})

# Include directories for MLC-LLM and TVM
target_include_directories(mlc_tvm_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../mlc_llm/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../tvm/include
)

# Link libraries
target_link_libraries(mlc_tvm_wrapper
    ${log-lib}
    ${android-lib}
    # MLC-LLM and TVM runtime libraries
    tvm_runtime
    mlc_llm
    dl
    # GPU support libraries
    opencl
    vulkan
)

# Compiler flags for optimization
target_compile_options(mlc_tvm_wrapper PRIVATE
    -Wall
    -Wextra
    -fPIC
    -fvisibility=hidden
    -funroll-loops
    -ffast-math
)

# Linker flags
set_target_properties(mlc_tvm_wrapper PROPERTIES
    LINK_FLAGS "-Wl,--gc-sections -Wl,--as-needed"
)
# MLC-LLM and TVM runtime integration
# These libraries should be downloaded and placed in the libs directory

# Add TVM runtime library
add_library(tvm_runtime SHARED IMPORTED)
set_target_properties(tvm_runtime PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI}/libtvm_runtime.so
)

# Add MLC-LLM library
add_library(mlc_llm SHARED IMPORTED)
set_target_properties(mlc_llm PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI}/libmlc_llm.so
)

# Add MLC model library
add_library(mlc_model_lib SHARED IMPORTED)
set_target_properties(mlc_model_lib PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI}/libmlc_model.so
)

# Link all MLC-LLM libraries
target_link_libraries(mlc_tvm_wrapper
    tvm_runtime
    mlc_llm
    mlc_model_lib
)

# GPU support libraries (OpenCL/Vulkan)
if(ANDROID)
    # OpenCL support for GPU acceleration
    find_library(opencl-lib OpenCL)
    if(opencl-lib)
        target_link_libraries(mlc_tvm_wrapper ${opencl-lib})
        add_definitions(-DMLC_USE_OPENCL=1)
        message(STATUS "OpenCL support enabled")
    endif()
    
    # Vulkan support for advanced GPU features  
    find_library(vulkan-lib vulkan)
    if(vulkan-lib)
        target_link_libraries(mlc_tvm_wrapper ${vulkan-lib})
        add_definitions(-DMLC_USE_VULKAN=1)
        message(STATUS "Vulkan support enabled")
    endif()
endif()

# Legacy llama.cpp support removed - MLC-LLM is now the primary implementation
# Legacy files are kept in cpp_backup_llamacpp/ for reference only

# Installation targets
install(TARGETS mlc_tvm_wrapper
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Print configuration summary
message(STATUS "=== MLC-LLM Android Build Configuration ===")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Android ABI: ${ANDROID_ABI}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "TVM Runtime: Stub (will be integrated)")
message(STATUS "GPU Support: ${ANDROID}")
message(STATUS "Legacy llama.cpp: Disabled (MLC-LLM primary)")
message(STATUS "===========================================")

