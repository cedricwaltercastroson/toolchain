cmake_minimum_required(VERSION 2.6)
project(vita-toolchain)

add_subdirectory(src)

install(FILES
  cmake_toolchain/dolce.cmake
  cmake_toolchain/dolce.toolchain.cmake
  DESTINATION share
)

install(DIRECTORY
  livearea
  DESTINATION share
)
