## DolceSDK Toolchain CMake functions
## Copyright (C) 2020 Asakura Reiko
## Copyright (C) 2020 GrapheneCt
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, version 3 of the License.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.

## Copyright (C) 2016 Yifan Lu
## See LICENSE/vitasdk

## Advanced users may be interested in setting the following
##   - DOLCE_ELF_CREATE_FLAGS
##   - DOLCE_MAKE_FSELF_FLAGS
##   - DOLCE_ELF_EXPORT_FLAGS
##   - DOLCE_LIBS_GEN_FLAGS
##   - DOLCE_MKSFOEX_FLAGS
##   - DOLCE_PACK_VPK_FLAGS

## add_include_guard() has been added in 3.10, but it's too recent so we don't use it
if(__DOLCE_CMAKE_INCLUDED__)
  return()
endif()
set(__DOLCE_CMAKE_INCLUDED__ TRUE)

include(CMakeParseArguments)

##################################################
## FUNCTION: dolce_create_self
##
## Generate a SELF from an ARM EABI ELF
##   dolce_create_self(target source
##                    [CONFIG file]
##                    [UNCOMPRESSED]
##                    [UNSAFE])
##
## @param target
##   A CMake custom target of this given name
## @param source
##   The ARM EABI ELF target (from add_executable for example)
##   or path to a provided ELF file
## @param[opt] UNCOMPRESSED
##   Do NOT compress the result SELF (compression is default)
## @param[opt] UNSAFE
##   The homebrew uses private/system APIs and requires extended permissions
## @param[opt] CONFIG file
##   Path to a YAML config file defining exports and other optional information
## @param[opt] BOOT_PARAM file
##   Path to a binary file specifying the boot param section of the SELF
##
function(dolce_create_self target source)
  set(DOLCE_ELF_CREATE_FLAGS "${DOLCE_ELF_CREATE_FLAGS}" CACHE STRING "dolce-elf-create flags")
  set(DOLCE_MAKE_FSELF_FLAGS "${DOLCE_MAKE_FSELF_FLAGS}" CACHE STRING "dolce-make-fself flags")

  set(options UNCOMPRESSED UNSAFE)
  set(oneValueArgs CONFIG BOOT_PARAM)
  cmake_parse_arguments(dolce_create_self "${options}" "${oneValueArgs}" "" ${ARGN})

  if(dolce_create_self_CONFIG)
    get_filename_component(fconfig ${dolce_create_self_CONFIG} ABSOLUTE)
    set(DOLCE_ELF_CREATE_FLAGS "${DOLCE_ELF_CREATE_FLAGS} -e ${fconfig}")
  endif()
  if(dolce_create_self_BOOT_PARAM)
    get_filename_component(fbootparam ${dolce_create_self_BOOT_PARAM} ABSOLUTE)
    set(DOLCE_MAKE_FSELF_FLAGS "${DOLCE_MAKE_FSELF_FLAGS} -bp ${fbootparam}")
  endif()
  if(NOT dolce_create_self_UNCOMPRESSED)
    set(DOLCE_MAKE_FSELF_FLAGS "${DOLCE_MAKE_FSELF_FLAGS} -c")
  endif()
  if(NOT dolce_create_self_UNSAFE)
    set(DOLCE_MAKE_FSELF_FLAGS "${DOLCE_MAKE_FSELF_FLAGS} -s")
  endif()

  ## check source for being a target, otherwise it is a file path
  if(TARGET ${source})
    set(sourcepath ${CMAKE_CURRENT_BINARY_DIR}/${source})
  else()
    set(sourcepath ${source})
  endif()
  get_filename_component(sourcefile ${sourcepath} NAME)

  ## VELF command
  separate_arguments(DOLCE_ELF_CREATE_FLAGS)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${sourcefile}.velf
    COMMAND ${DOLCE_ELF_CREATE} ${DOLCE_ELF_CREATE_FLAGS} ${sourcepath} ${CMAKE_CURRENT_BINARY_DIR}/${sourcefile}.velf
    DEPENDS ${sourcepath} ${fconfig}
    COMMENT "Converting to Sony ELF ${sourcefile}.velf" VERBATIM
  )

  ## SELF command
  separate_arguments(DOLCE_MAKE_FSELF_FLAGS)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${target}
    COMMAND ${DOLCE_MAKE_FSELF} ${DOLCE_MAKE_FSELF_FLAGS} ${CMAKE_CURRENT_BINARY_DIR}/${sourcefile}.velf ${CMAKE_CURRENT_BINARY_DIR}/${target}
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${sourcefile}.velf ${fbootparam}
    COMMENT "Creating SELF ${target}"
  )

  ## SELF target
  add_custom_target(${target}.target
    ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${target}
  )
  if(TARGET ${source})
    add_dependencies(${target}.target ${source})
  endif()
endfunction(dolce_create_self)
##################################################

##################################################
## FUNCTION: dolce_create_stubs
##
## Generate stub libraries from a Sony ELF and config file
##   dolce_create_stubs(target-dir source config
##                     [LIB lib1 [lib2 ...]]
##                     [KERNEL])
##
## @param target-dir
##   A CMake custom target of this given name (will be a directory containing
##   the stubs)
## @param source
##   The ARM EABI ELF target (from add_executable for example)
## @param config
##   Path to a YAML config file defining exports
## @param[opt] LIB
##   Stub libraries to create targets for. This argument can be given multiple times.
## @param[opt] KERNEL
##   Specifies that this module makes kernel exports
##
function(dolce_create_stubs target-dir source config)
  set(DOLCE_ELF_EXPORT_FLAGS "${DOLCE_ELF_EXPORT_FLAGS}" CACHE STRING "dolce-elf-export flags")
  set(DOLCE_LIBS_GEN_FLAGS "${DOLCE_LIBS_GEN_FLAGS}" CACHE STRING "dolce-libs-gen flags")

  set(options KERNEL)
  set(multiValueArgs LIB)
  cmake_parse_arguments(dolce_create_stubs "${options}" "" "${multiValueArgs}" ${ARGN})

  if(dolce_create_stubs_KERNEL)
    set(kind kernel)
  else()
    set(kind user)
  endif()

  ## check source for being a target, otherwise it is a file path
  if(TARGET ${source})
    set(sourcepath ${CMAKE_CURRENT_BINARY_DIR}/${source})
  else()
    set(sourcepath ${source})
  endif()
  get_filename_component(sourcefile ${sourcepath} NAME)

  ## ELF EXPORT command
  separate_arguments(DOLCE_ELF_EXPORT_FLAGS)
  get_filename_component(fconfig ${config} ABSOLUTE)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}.yml
    COMMAND ${DOLCE_ELF_EXPORT} ${kind} ${DOLCE_ELF_EXPORT_FLAGS} ${sourcepath} ${fconfig} ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}.yml
    DEPENDS ${sourcepath}
    DEPENDS ${fconfig}
    COMMENT "Generating imports YAML for ${sourcefile}"
  )

  if(dolce_create_stubs_LIB)
    foreach(lib ${dolce_create_stubs_LIB})
      set(libs ${libs} ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}/lib${lib}.a)
    endforeach()
  else()
    set(libs "${target-dir}")
  endif()

  ## LIBS GEN command
  separate_arguments(DOLCE_LIBS_GEN_FLAGS)
  add_custom_command(OUTPUT ${libs}
    COMMAND ${DOLCE_LIBS_GEN} ${DOLCE_LIBS_GEN_FLAGS} ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}.yml ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}
    COMMAND make -C ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}.yml
    COMMENT "Building stubs ${target-dir}"
  )

  ## LIBS GEN target
  add_custom_target(${target-dir}.target
    ALL
    DEPENDS ${libs}
  )
  if(TARGET ${source})
    add_dependencies(${target-dir}.target ${source})
  endif()

  ## stub lib targets
  foreach(lib ${dolce_create_stubs_LIB})
    add_library(${lib} STATIC IMPORTED GLOBAL)
    add_dependencies(${lib} ${target-dir}.target)
    set_target_properties(${lib} PROPERTIES
      IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}/lib${lib}.a
    )
  endforeach()
endfunction(dolce_create_stubs)
##################################################

##################################################
## FUNCTION: dolce_create_vpk
##
## Creates a homebrew VPK from a SELF
##   dolce_create_vpk(target titleid eboot
##                   [VERSION version]
##                   [NAME name]
##                   [CONTENT_ID_LABEL label]
##                   [FILE path dest])
##
## @param target
##   A CMake custom target of this given name
## @param titleid
##   A nine character identifier for this homebrew. The recommended format is
##   XXXXYYYYY where XXXX is an author unique identifier and YYYYY is a number.
## @param eboot
##   The SELF target (from dolce_create_self for example)
##   or path to a provided SELF file
## @param[opt] VERSION
##   A version string
## @param[opt] NAME
##   The display name under the bubble in LiveArea
## @param[opt] CONTENT_ID_LABEL
##   The 16 character label part of the content ID
## @param[opt] FILE
##   Add an additional file at path to dest in the vpk (there can be multiple
##   of this parameter).
##
function(dolce_create_vpk target titleid eboot)
  set(DOLCE_MKSFOEX_FLAGS "${DOLCE_MKSFOEX_FLAGS}" CACHE STRING "dolce-mksfoex flags")
  set(DOLCE_PACK_VPK_FLAGS "${DOLCE_PACK_VPK_FLAGS}" CACHE STRING "dolce-pack-vpk flags")

  set(oneValueArgs VERSION NAME CONTENT_ID_LABEL)
  set(multiValueArgs FILE)
  cmake_parse_arguments(dolce_create_vpk "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  list(LENGTH dolce_create_vpk_FILE left)
  while(left GREATER 0)
    if(left EQUAL 1)
      message(FATAL_ERROR "Invalid number of arguments")
    endif()
    list(GET dolce_create_vpk_FILE 0 fname)
    list(GET dolce_create_vpk_FILE 1 fdest)
    get_filename_component(fpath ${fname} ABSOLUTE)
    list(APPEND resources "${fpath}")
    list(REMOVE_AT dolce_create_vpk_FILE 0 1)
    set(DOLCE_PACK_VPK_FLAGS "${DOLCE_PACK_VPK_FLAGS} -a ${fpath}=${fdest}")
    list(LENGTH dolce_create_vpk_FILE left)
  endwhile()

  if(dolce_create_vpk_VERSION)
    set(DOLCE_MKSFOEX_FLAGS "${DOLCE_MKSFOEX_FLAGS} -s APP_VER=${dolce_create_vpk_VERSION}")
  endif()

  set(DOLCE_MKSFOEX_FLAGS "${DOLCE_MKSFOEX_FLAGS} -s TITLE_ID=${titleid}")

  if(NOT dolce_create_vpk_CONTENT_ID_LABEL)
    set(DOLCE_MKSFOEX_FLAGS "${DOLCE_MKSFOEX_FLAGS} -s CONTENT_ID=HB0000-${titleid}_00-${titleid}0000000")
  else()
    set(DOLCE_MKSFOEX_FLAGS "${DOLCE_MKSFOEX_FLAGS} -s CONTENT_ID=HB0000-${titleid}_00-${dolce_create_vpk_CONTENT_ID_LABEL}")
  endif()

  if(NOT dolce_create_vpk_NAME)
    set(dolce_create_vpk_NAME "${PROJECT_NAME}")
  endif()

  ## check eboot for being a target, otherwise it is a file path
  if(TARGET ${eboot})
    set(sourcepath ${CMAKE_CURRENT_BINARY_DIR}/${eboot})
  else()
    set(sourcepath ${eboot})
  endif()
  get_filename_component(sourcefile ${sourcepath} NAME)

  ## PARAM.SFO command
  separate_arguments(DOLCE_MKSFOEX_FLAGS)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${target}_param.sfo
    COMMAND ${DOLCE_MKSFOEX} ${DOLCE_MKSFOEX_FLAGS} ${dolce_create_vpk_NAME} ${CMAKE_CURRENT_BINARY_DIR}/${target}_param.sfo
    DEPENDS ${sourcepath}
    COMMENT "Generating param.sfo for ${target}"
  )

  ## VPK command
  separate_arguments(DOLCE_PACK_VPK_FLAGS)
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${target}
    COMMAND ${DOLCE_PACK_VPK} ${DOLCE_PACK_VPK_FLAGS} -s ${CMAKE_CURRENT_BINARY_DIR}/${target}_param.sfo -b ${sourcepath} ${CMAKE_CURRENT_BINARY_DIR}/${target}
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${target}_param.sfo
    DEPENDS ${sourcepath}
    DEPENDS ${resources}
    COMMENT "Building vpk ${target}"
  )

  ## VPK target
  add_custom_target(${target}.target
    ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${target}
  )
  if(TARGET ${eboot})
    add_dependencies(${target}.target ${eboot})
  endif()
endfunction(dolce_create_vpk)
##################################################

##################################################
## FUNCTION: dolce_gen_libs
##
## Generate stub libraries from a NID database
##   dolce_create_stubs(target-dir source
##                     [LIB lib1 [lib2 ...]])
##
## @param target-dir
##   Name for a directory containing generated stub libraries
## @param source
##   Path to a NID database YAML file
## @param[opt] LIB
##   Stub libraries to create targets for. This argument can be given multiple times.
##
function(dolce_gen_libs target-dir source)
  set(DOLCE_LIBS_GEN_FLAGS "${DOLCE_LIBS_GEN_FLAGS}" CACHE STRING "dolce-libs-gen flags")

  set(multiValueArgs LIB)
  cmake_parse_arguments(dolce_gen_libs "" "" "${multiValueArgs}" ${ARGN})

  get_filename_component(fsource ${source} ABSOLUTE)
  get_filename_component(sourcefile ${fsource} NAME)

  if(dolce_gen_libs_LIB)
    foreach(lib ${dolce_gen_libs_LIB})
      set(libs ${libs} ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}/lib${lib}.a)
    endforeach()
  else()
    set(libs "${target-dir}")
  endif()

  ## LIBS GEN command
  separate_arguments(DOLCE_LIBS_GEN_FLAGS)
  add_custom_command(OUTPUT ${libs}
    COMMAND ${DOLCE_LIBS_GEN} ${DOLCE_LIBS_GEN_FLAGS} ${fsource} ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}
    COMMAND make -C ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}
    DEPENDS ${fsource}
    COMMENT "Generating libraries for ${sourcefile}"
  )

  ## LIBS GEN target
  add_custom_target(${target-dir}.target
    ALL
    DEPENDS ${libs}
  )

  ## stub lib targets
  foreach(lib ${dolce_gen_libs_LIB})
    add_library(${lib} STATIC IMPORTED GLOBAL)
    add_dependencies(${lib} ${target-dir}.target)
    set_target_properties(${lib} PROPERTIES
      IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${target-dir}/lib${lib}.a
    )
  endforeach()
endfunction(dolce_gen_libs)
##################################################
