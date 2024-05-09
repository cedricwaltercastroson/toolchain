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
*/

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "self.h"

#define PARSE_ARG(bp, name, argv)\
	(strcmp(argv[0], #name) == 0) {\
		bp.name = strtoul(argv[1], NULL, 0);\
	}

int main(int argc, const char **argv) {
	if (argc < 2) {
		fprintf(stderr, "usage: %s [<name> <value>] ... <output>\n", argv[0] ? argv[0] : "dolce-make-bootparam");
		return 1;
	}
	argc--;
	argv++;

	SCE_boot_param_hdr bp = {0};
	bp.is_used = 1;

	while (argc > 2) {
		if PARSE_ARG(bp, attribute, argv)
		else if PARSE_ARG(bp, phy_memsize, argv)
		else if PARSE_ARG(bp, app_memsize, argv)
		else if PARSE_ARG(bp, file_open_max_num, argv)
		else if PARSE_ARG(bp, directory_max_level, argv)
		else if PARSE_ARG(bp, encrypt_mount_max_num, argv)
		else if PARSE_ARG(bp, redirect_mount_max_num, argv)
		else {
			fprintf(stderr, "unknown argument: %s\n", argv[0]);
			return 1;
		}
		argc -= 2;
		argv += 2;
	}

	if (argc != 1) {
		fprintf(stderr, "unexpected number of arguments\n");
		return 1;
	}

	const char *output_path = argv[0];
	FILE *fout = fopen(output_path, "wb");
	if (!fout) {
		perror("Failed to open output file");
		return 1;
	}

	size_t sz = fwrite(&bp.is_used, sizeof(bp) - sizeof(bp.common), 1, fout);
	fclose(fout);

	if (sz == 1) {
		return 0;
	} else {
		perror("Failed to write to output file");
		return 1;
	}
}
