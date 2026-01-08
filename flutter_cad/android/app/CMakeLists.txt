cmake_minimum_required(VERSION 3.4.1)

# Add Teigha SDK library paths (adjust these paths based on your actual Teigha SDK installation)
set(TEIGHA_SDK_ROOT "${CMAKE_SOURCE_DIR}/third_party/teigha")
set(TEIGHA_INCLUDE_DIRS "${TEIGHA_SDK_ROOT}/include")
set(TEIGHA_LIB_DIRS "${TEIGHA_SDK_ROOT}/lib/${ANDROID_ABI}")

# Add include directories
include_directories(${TEIGHA_INCLUDE_DIRS})

# Find and link Teigha SDK libraries
# Note: These are placeholder libraries for testing. Replace with actual Teigha SDK libraries.
find_library(TEIGHA_CORE_LIB 
    NAMES TeighaCore TD_DynamicLinker libTeighaCore.so
    PATHS ${TEIGHA_LIB_DIRS}
    NO_CMAKE_FIND_ROOT_PATH
)

find_library(TEIGHA_DB_LIB 
    NAMES TD_Db libTD_Db.so
    PATHS ${TEIGHA_LIB_DIRS}
    NO_CMAKE_FIND_ROOT_PATH
)

find_library(TEIGHA_GI_LIB 
    NAMES TD_Gi libTD_Gi.so
    PATHS ${TEIGHA_LIB_DIRS}
    NO_CMAKE_FIND_ROOT_PATH
)

# Add the native library
add_library(
    teigha_sdk_jni
    SHARED
    teigha_jni.cpp
)

# Link libraries
target_link_libraries(
    teigha_sdk_jni
    ${TEIGHA_CORE_LIB}
    ${TEIGHA_DB_LIB}
    ${TEIGHA_GI_LIB}
    android
    log
    jnigraphics
)

# Add compiler definitions for testing
target_compile_definitions(teigha_sdk_jni PRIVATE
    -DTEIGHA_SDK_PLACEHOLDER
)
