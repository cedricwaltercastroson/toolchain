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

#include "elf-create-argp.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int parse_arguments(int argc, char *argv[], elf_create_args *arguments)
{
	int c;

	arguments->log_level = 0;
	arguments->check_stub_count = 1;
	arguments->heap_size = -1;

	while ((c = getopt(argc, argv, "vne:h:")) != -1)
	{
		switch (c)
		{
		case 'v':
			arguments->log_level++;
			break;
		case 'e':
			arguments->exports = optarg;
			break;
		case 'n':
			arguments->check_stub_count = 0;
			break;
		case 'h':
			arguments->heap_size = strtol(optarg, NULL, 0);
			break;
		case '?':
			fprintf(stderr, "unknown option -%c\n", optopt);
			return -1;
		default:
			abort();
		}
	}

	if (argc - optind < 2)
	{
		printf("too few arguments\n");
		return -1;
	}
	
	arguments->input = argv[optind];
	arguments->output = argv[optind+1];
	
	if (argc - optind > 2)
	{
		arguments->extra_imports = &argv[optind+2];
		arguments->extra_imports_count = argc-(optind+2);
	}
	
	return 0;
}
