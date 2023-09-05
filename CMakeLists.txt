cmake_minimum_required(VERSION 3.24)
project(metal-proj CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)

add_executable(${PROJECT_NAME} metal-impl.cpp
        src/main.cpp
        src/mtl_engine.hpp
        src/mtl_engine.mm)
target_include_directories(${PROJECT_NAME} PRIVATE lib/metal-cpp)

# Link libraries

add_subdirectory(lib)

target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Foundation" "-framework Metal" "-framework QuartzCore" glfw)
