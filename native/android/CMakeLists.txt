# CMakeLists.txt for llama.cpp Android build
# This builds the native library for on-device LLM inference

cmake_minimum_required(VERSION 3.10)
project(llama_bridge)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Android-specific settings
if(ANDROID)
    # Target Android API level 21+
    set(CMAKE_ANDROID_API 21)
    
    # Enable NEON for ARM architectures
    if(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a+fp+simd")
        add_definitions(-DGGML_USE_NEON)
    elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mfpu=neon -mfloat-abi=softfp")
        add_definitions(-DGGML_USE_NEON)
    endif()
    
    # Enable Vulkan if available (Android 7.0+)
    find_package(Vulkan)
    if(Vulkan_FOUND)
        add_definitions(-DGGML_USE_VULKAN)
        include_directories(${Vulkan_INCLUDE_DIRS})
    endif()
endif()

# Source files
set(LLAMA_BRIDGE_SOURCES
    ../cpp/llama_bridge.cpp
)

# llama.cpp sources (when integrated)
# set(LLAMA_SOURCES
#     llama.cpp/ggml.c
#     llama.cpp/ggml-alloc.c
#     llama.cpp/ggml-backend.c
#     llama.cpp/ggml-quants.c
#     llama.cpp/llama.cpp
#     llama.cpp/common/common.cpp
# )

# Create shared library
add_library(
    llama_bridge
    SHARED
    ${LLAMA_BRIDGE_SOURCES}
    # ${LLAMA_SOURCES}
)

# Link libraries
target_link_libraries(
    llama_bridge
    log
    android
)

# If Vulkan is available
if(Vulkan_FOUND)
    target_link_libraries(llama_bridge ${Vulkan_LIBRARIES})
endif()

# Set properties
set_target_properties(
    llama_bridge
    PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON
)

# Installation
install(TARGETS llama_bridge DESTINATION lib/${CMAKE_ANDROID_ARCH_ABI})
