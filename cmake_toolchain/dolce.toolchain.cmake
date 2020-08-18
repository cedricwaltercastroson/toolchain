# Copyright (c) 2016, Yifan Lu
# See LICENSE/vitasdk

# Copyright (c) 2010-2011, Ethan Rublee
# Copyright (c) 2011-2014, Andrey Kamaev
# See LICENSE/android-toolchain

cmake_minimum_required( VERSION 2.6.3 )

if( DEFINED CMAKE_CROSSCOMPILING )
  # subsequent toolchain loading is not really needed
  return()
endif()

if( CMAKE_TOOLCHAIN_FILE )
  # touch toolchain variable to suppress "unused variable" warning
endif()

set( CMAKE_SYSTEM_NAME Generic )
set( CMAKE_SYSTEM_VERSION 1 )

# search for DolceSDK path 1) where this toolchain file is, 2) in environment var, 3) manually defined
if( NOT DEFINED ENV{DOLCESDK} )
  get_filename_component(__dolcesdk_path ${CMAKE_CURRENT_LIST_DIR} DIRECTORY)
  if( EXISTS "${__dolcesdk_path}" )
    set( DOLCESDK "${__dolcesdk_path}" )
    set( ENV{DOLCESDK} "${__dolcesdk_path}" )
  endif()
else()
  set( DOLCESDK "$ENV{DOLCESDK}" )
endif()
set( DOLCESDK "${DOLCESDK}" CACHE PATH "Path to DolceSDK root" )

if( NOT EXISTS "${DOLCESDK}" )
  message( FATAL_ERROR "Cannot find DolceSDK at ${DOLCESDK}" )
endif()

set( TOOL_OS_SUFFIX "" )
if( CMAKE_HOST_WIN32 )
 set( TOOL_OS_SUFFIX ".exe" )
endif()

set( CMAKE_SYSTEM_PROCESSOR "armv7-a" )
set( CMAKE_C_COMPILER    "${DOLCESDK}/bin/arm-dolce-eabi-gcc${TOOL_OS_SUFFIX}"         CACHE PATH "C compiler" )
set( CMAKE_CXX_COMPILER  "${DOLCESDK}/bin/arm-dolce-eabi-g++${TOOL_OS_SUFFIX}"         CACHE PATH "C++ compiler" )
set( CMAKE_ASM_COMPILER  "${DOLCESDK}/bin/arm-dolce-eabi-gcc${TOOL_OS_SUFFIX}"         CACHE PATH "assembler" )
set( CMAKE_STRIP         "${DOLCESDK}/bin/arm-dolce-eabi-strip${TOOL_OS_SUFFIX}"       CACHE PATH "strip" )
set( CMAKE_AR            "${DOLCESDK}/bin/arm-dolce-eabi-gcc-ar${TOOL_OS_SUFFIX}"      CACHE PATH "archive" )
set( CMAKE_LINKER        "${DOLCESDK}/bin/arm-dolce-eabi-ld${TOOL_OS_SUFFIX}"          CACHE PATH "linker" )
set( CMAKE_NM            "${DOLCESDK}/bin/arm-dolce-eabi-gcc-nm${TOOL_OS_SUFFIX}"      CACHE PATH "nm" )
set( CMAKE_OBJCOPY       "${DOLCESDK}/bin/arm-dolce-eabi-objcopy${TOOL_OS_SUFFIX}"     CACHE PATH "objcopy" )
set( CMAKE_OBJDUMP       "${DOLCESDK}/bin/arm-dolce-eabi-objdump${TOOL_OS_SUFFIX}"     CACHE PATH "objdump" )
set( CMAKE_RANLIB        "${DOLCESDK}/bin/arm-dolce-eabi-gcc-ranlib${TOOL_OS_SUFFIX}"  CACHE PATH "ranlib" )

# Vita specific tools
set( DOLCE_ELF_CREATE      "${DOLCESDK}/bin/dolce-elf-create${TOOL_OS_SUFFIX}"      CACHE PATH "dolce-elf-create" )
set( DOLCE_ELF_EXPORT      "${DOLCESDK}/bin/dolce-elf-export${TOOL_OS_SUFFIX}"      CACHE PATH "dolce-elf-export" )
set( DOLCE_LIBS_GEN        "${DOLCESDK}/bin/dolce-libs-gen${TOOL_OS_SUFFIX}"        CACHE PATH "dolce-libs-gen" )
set( DOLCE_MAKE_FSELF      "${DOLCESDK}/bin/dolce-make-fself${TOOL_OS_SUFFIX}"      CACHE PATH "dolce-make-fself" )
set( DOLCE_MKSFOEX         "${DOLCESDK}/bin/dolce-mksfoex${TOOL_OS_SUFFIX}"         CACHE PATH "dolce-mksfoex" )
set( DOLCE_PACK_VPK        "${DOLCESDK}/bin/dolce-pack-vpk${TOOL_OS_SUFFIX}"        CACHE PATH "dolce-pack-vpk" )
set( DOLCE_MAKE_BOOTPARAM  "${DOLCESDK}/bin/dolce-make-bootparam${TOOL_OS_SUFFIX}"  CACHE PATH "dolce-make-bootparam" )

# cache flags
set( CMAKE_CXX_FLAGS           ""                        CACHE STRING "c++ flags" )
set( CMAKE_C_FLAGS             ""                        CACHE STRING "c flags" )
set( CMAKE_CXX_FLAGS_RELEASE   "-O3 -DNDEBUG"            CACHE STRING "c++ Release flags" )
set( CMAKE_C_FLAGS_RELEASE     "-O3 -DNDEBUG"            CACHE STRING "c Release flags" )
set( CMAKE_CXX_FLAGS_DEBUG     "-O0 -g -DDEBUG -D_DEBUG" CACHE STRING "c++ Debug flags" )
set( CMAKE_C_FLAGS_DEBUG       "-O0 -g -DDEBUG -D_DEBUG" CACHE STRING "c Debug flags" )
set( CMAKE_SHARED_LINKER_FLAGS ""                        CACHE STRING "shared linker flags" )
set( CMAKE_MODULE_LINKER_FLAGS ""                        CACHE STRING "module linker flags" )
set( CMAKE_EXE_LINKER_FLAGS    "-Wl,-z,nocopyreloc"      CACHE STRING "executable linker flags" )

# we require the relocation table
set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wl,-q" )
set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wl,-q" )

# set these global flags for cmake client scripts to change behavior
set( VITA True )
set( BUILD_VITA True )

# where is the target environment
set( CMAKE_FIND_ROOT_PATH "${DOLCESDK}/bin" "${DOLCESDK}/arm-dolce-eabi" "${CMAKE_INSTALL_PREFIX}" "${CMAKE_INSTALL_PREFIX}/share" )
set( CMAKE_INSTALL_PREFIX "${DOLCESDK}/arm-dolce-eabi" CACHE PATH "default install path" )

# only search for libraries and includes in DolceSDK toolchain
if( NOT CMAKE_FIND_ROOT_PATH_MODE_LIBRARY )
  set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
endif()
if( NOT CMAKE_FIND_ROOT_PATH_MODE_INCLUDE )
  set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
endif()
