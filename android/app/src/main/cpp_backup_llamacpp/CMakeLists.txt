cmake_minimum_required(VERSION 3.18.1)
project("offline_ai_companion")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Android-specific configuration
if(ANDROID)
    # Override CMake's threading detection completely
    set(CMAKE_THREAD_LIBS_INIT "")
    set(CMAKE_HAVE_THREADS_LIBRARY 1)
    set(CMAKE_USE_WIN32_THREADS_INIT 0)
    set(CMAKE_USE_PTHREADS_INIT 1)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    set(Threads_FOUND TRUE)
    
    # Create dummy Threads target
    add_library(Threads::Threads INTERFACE IMPORTED)
    set_target_properties(Threads::Threads PROPERTIES
        INTERFACE_COMPILE_OPTIONS ""
        INTERFACE_LINK_LIBRARIES ""
    )
    
    # Override find_package for Threads
    macro(find_package name)
        if(${name} STREQUAL "Threads")
            message(STATUS "Android: Skipping Threads find_package (already configured)")
        else()
            _find_package(${name} ${ARGN})
        endif()
    endmacro()
endif()

# Create Android compatibility library
add_library(android_compat STATIC android_compat.cpp)
set_property(TARGET android_compat PROPERTY POSITION_INDEPENDENT_CODE ON)

# Configure llama.cpp with minimal features for Android compatibility
# Use CACHE FORCE to override llama.cpp's own settings
set(LLAMA_STATIC ON CACHE BOOL "Build static library" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Build examples" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Build server" FORCE)

if(ANDROID)
    # Disable ALL optimizations that cause problems on Android - use CACHE FORCE
    set(LLAMA_NATIVE OFF CACHE BOOL "Enable native optimizations" FORCE)
    set(LLAMA_AVX OFF CACHE BOOL "Enable AVX" FORCE)
    set(LLAMA_AVX2 OFF CACHE BOOL "Enable AVX2" FORCE)
    set(LLAMA_AVX512 OFF CACHE BOOL "Enable AVX512" FORCE)
    set(LLAMA_FMA OFF CACHE BOOL "Enable FMA" FORCE)
    set(LLAMA_F16C OFF CACHE BOOL "Enable F16C" FORCE)
    set(LLAMA_NEON OFF CACHE BOOL "Enable NEON" FORCE)
    
    # Disable ALL advanced features that cause compilation issues - use CACHE FORCE
    set(GGML_USE_LLAMAFILE OFF CACHE BOOL "Use llamafile" FORCE)
    set(LLAMA_LLAMAFILE OFF CACHE BOOL "Use llamafile" FORCE)
    set(GGML_USE_CPU_REPACK OFF CACHE BOOL "Use CPU repack" FORCE)
    set(GGML_USE_OPENMP OFF CACHE BOOL "Use OpenMP" FORCE)
    set(LLAMA_OPENMP OFF CACHE BOOL "Use OpenMP" FORCE)
    set(GGML_USE_THREADING OFF CACHE BOOL "Use threading" FORCE)
    set(LLAMA_THREADING OFF CACHE BOOL "Use threading" FORCE)
    
    # Force single-threaded, basic mode
    add_definitions(-DGGML_MAX_THREADS=1)
    add_definitions(-DGGML_USE_THREADING=0)
    
    # Android NDK compatibility
    add_definitions(-DPOSIX_MADV_WILLNEED=3)
    add_definitions(-DPOSIX_MADV_RANDOM=1)
    add_definitions(-DPOSIX_MADV_SEQUENTIAL=2)
    add_definitions(-DPOSIX_MADV_DONTNEED=4)
    
    # Include compatibility header and define stub
    include_directories(${CMAKE_CURRENT_SOURCE_DIR})
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -include android_compat.h -Dposix_madvise=android_posix_madvise_stub")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -include android_compat.h -Dposix_madvise=android_posix_madvise_stub")
endif()

# Add llama.cpp
add_subdirectory(llama.cpp)

# Link our compatibility library to the llama target
if(ANDROID AND TARGET llama)
    target_link_libraries(llama PRIVATE android_compat)
endif()

# Create our wrapper library
add_library(llama_cpp_wrapper SHARED 
    llama_cpp_wrapper.cpp
)

# Link with llama.cpp and our compatibility layer
target_link_libraries(llama_cpp_wrapper 
    llama
    android_compat
    log
    android
    z
    m
)

# Set include directories
target_include_directories(llama_cpp_wrapper PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/src
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/ggml/include
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/ggml/src
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Compiler flags for Android
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-unused-parameter -Wno-unused-variable -O2")
endif()

# Enable position independent code
set_property(TARGET llama_cpp_wrapper PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET llama PROPERTY POSITION_INDEPENDENT_CODE ON)