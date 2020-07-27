/*
This file is part of DolceSDK
Copyright (C) 2020 Asakura Reiko

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

Copyright (C) 2016 Davee
See LICENSE/vitasdk
*/

#ifndef ELF_CREATE_ARGP_H
#define ELF_CREATE_ARGP_H

typedef struct elf_create_args
{
	int log_level;
	const char *exports;
	const char *input;
	const char *output;
	int extra_imports_count;
	char **extra_imports;
	int check_stub_count;
	int heap_size;
} elf_create_args;


int parse_arguments(int argc, char *argv[], elf_create_args *arguments);

#endif // ELF_CREATE_ARGP_H
