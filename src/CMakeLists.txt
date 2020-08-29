set(libyaml_INCLUDE_DIRS ${libyaml_INCLUDE_DIR})
set(libyaml_LIBRARIES ${libyaml_LIBRARY})
set(libelf_INCLUDE_DIRS ${libelf_INCLUDE_DIR})
set(libelf_LIBRARIES ${libelf_LIBRARY})
set(zlib_INCLUDE_DIRS ${zlib_INCLUDE_DIR})
set(zlib_LIBRARIES ${zlib_LIBRARY})

include_directories(${libelf_INCLUDE_DIRS})
include_directories(${zlib_INCLUDE_DIRS})

set(CMAKE_C_FLAGS "-fvisibility=hidden -g -std=gnu99")

if(USE_BUNDLED_ENDIAN_H)
	add_definitions(-DUSE_BUNDLED_ENDIAN_H)
endif()

if (WIN32)
	# See "Dynamic-Link Library Search Order (Windows)
	# Standard Search Order for Desktop Applications"
	# https://msdn.microsoft.com/en-us/library/windows/desktop/ms682586(v=vs.85).aspx#standard_search_order_for_desktop_applications
	set(runtime_destination bin)
	add_definitions(-DYAML_DECLARE_STATIC)
else()
	set(runtime_destination lib)
endif()

add_library(vita-yaml yamltree.c yamltreeutil.c)
add_library(vita-export vita-export-parse.c sha256.c)
add_library(vita-import vita-import.c vita-import-parse.c)

set_target_properties(vita-yaml PROPERTIES
	INCLUDE_DIRECTORIES "${libyaml_INCLUDE_DIRS};${CMAKE_CURRENT_SOURCE_DIR}/build")
set_target_properties(vita-export PROPERTIES
	INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/build
	PUBLIC_HEADER "vita-toolchain-public.h;vita-export.h")
set_target_properties(vita-import PROPERTIES
	INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/build
	PUBLIC_HEADER "vita-toolchain-public.h;vita-import.h")

target_include_directories(vita-yaml PRIVATE
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
	$<INSTALL_INTERFACE:include>)

target_include_directories(vita-export PUBLIC
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
	$<INSTALL_INTERFACE:include>)

target_include_directories(vita-import PUBLIC
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
	$<INSTALL_INTERFACE:include>)

add_executable(dolce-libs-gen vita-libs-gen.c)
add_executable(dolce-elf-create vita-elf-create.c elf-create-argp.c vita-elf.c elf-defs.c sce-elf.c varray.c elf-utils.c)
add_executable(dolce-mksfoex vita-mksfoex.c getopt_long.c)
add_executable(dolce-make-fself vita-make-fself.c sha256.c)
add_executable(dolce-elf-export vita-elf-export.c yamlemitter.c)
add_executable(dolce-make-bootparam dolce-make-bootparam.c)

target_link_libraries(vita-yaml ${libyaml_LIBRARIES})
target_link_libraries(vita-import vita-yaml)
target_link_libraries(vita-export vita-yaml)
target_link_libraries(dolce-libs-gen vita-import)
target_link_libraries(dolce-elf-create vita-export vita-import ${libelf_LIBRARIES})
target_link_libraries(dolce-elf-export vita-yaml vita-export)
target_link_libraries(dolce-make-fself ${zlib_LIBRARIES} vita-export vita-import)

if(BUILD_SHARED_LIBS)
	target_compile_definitions(vita-yaml PUBLIC VITA_TOOLCHAIN_SHARED)
	target_compile_definitions(vita-import PUBLIC VITA_TOOLCHAIN_SHARED)
	target_compile_definitions(vita-export PUBLIC VITA_TOOLCHAIN_SHARED)
	install(TARGETS vita-yaml
		DESTINATION lib
		RUNTIME DESTINATION ${runtime_destination})
endif()

install(TARGETS vita-export
	DESTINATION lib
	PUBLIC_HEADER DESTINATION include
	RUNTIME DESTINATION ${runtime_destination})
install(TARGETS vita-import
	DESTINATION lib
	PUBLIC_HEADER DESTINATION include
	RUNTIME DESTINATION ${runtime_destination})
install(TARGETS dolce-libs-gen DESTINATION bin)
install(TARGETS dolce-elf-create DESTINATION bin)
install(TARGETS dolce-mksfoex DESTINATION bin)
install(TARGETS dolce-make-fself DESTINATION bin)
install(PROGRAMS dolce-make-pkg.py DESTINATION bin RENAME dolce-make-pkg)
install(TARGETS dolce-elf-export DESTINATION bin)
install(TARGETS dolce-make-bootparam DESTINATION bin)
