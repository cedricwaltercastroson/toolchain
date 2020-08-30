#!/usr/bin/env python3

'''
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
'''

import sys

if sys.version_info < (3, 6):
	sys.exit("Python must be at least version 3.6")

import argparse
import os
import pathlib
import zipfile

# must resolve this before chdir
this_file_path = pathlib.Path(__file__).resolve()

# constants

must_reg_file = tuple(map(pathlib.Path, (
	'eboot.bin',
	'eboot2.bin',
	'sce_sys/about/right.gim',
	'sce_sys/about/right.png',
	'sce_sys/about/right.suprx',
	'sce_sys/icon0.png',
	'sce_sys/livearea/contents/template.xml',
	'sce_sys/param.sfo',
	'sce_sys/param2.sfo',
	'sce_sys/pic0.png',
)))

must_dir_file = tuple(map(pathlib.Path, (
	'sce_module',
	'sce_sys',
	'sce_sys/about',
	'sce_sys/livearea',
	'sce_sys/livearea/contents',
)))

must_exist_app_file = tuple(map(pathlib.Path, (
	'eboot.bin',
	'sce_sys/param.sfo',
)))

# functions

def process_paths(pathmap, pathlist, verbose=False):
	'''
	pathmap - a dict of DST:SRC (accumulator)
	pathlist - a list of (SRC, DST)
	'''

	root = pathlib.Path('/')

	for src, dst in pathlist:
		src = pathlib.Path(src).resolve(strict=True)
		dst = pathlib.Path(dst)
		if dst.is_absolute():
			raise ValueError(f'DST must be a relative path: {dst}')
		dst = (root / dst).resolve().relative_to(root)

		if verbose:
			print(f'{src} → {dst}')
		pathmap[dst] = src

		if src.is_dir():
			for child in src.iterdir():
				process_paths(pathmap, ((child, dst / child.relative_to(src)),), verbose)

def lookup_default(path):
	path = pathlib.Path(path)

	# normally installed at $DOLCESDK/bin/dolce-make-pkg
	from_this = this_file_path.parent.parent / path
	if from_this.exists() and from_this.is_file():
		return from_this

	sdk_path = os.getenv('DOLCESDK')
	if sdk_path:
		from_sdk = pathlib.Path(sdk_path) / path
		if from_sdk.exists() and from_sdk.is_file():
			return from_sdk

	return None

def make_vpk(output, pathmap):
	vpk = zipfile.ZipFile(output, mode='w', compression=zipfile.ZIP_DEFLATED)
	for dst, src in pathmap.items():
		vpk.write(src, dst)
	vpk.close()

# setup and parse command line arguments

parser = argparse.ArgumentParser(description='Package files for distribution.')

parser.add_argument(
	'output',
	metavar='OUTPUT',
	type=pathlib.Path,
	help='Output file path.')

parser.add_argument(
	'-v', '--verbose',
	action='store_true',
	help='Print more information.')

parser.add_argument(
	'-f', '--format',
	choices=('pkg', 'vpk'),
	default='vpk',
	help='Output file format.')

parser.add_argument(
	'-t', '--type',
	choices=('app', 'patch', 'addcont', 'theme'),
	default='app',
	help='Package content type.')

parser.add_argument(
	'-a', '--add',
	metavar=('SRC', 'DST'),
	nargs=2,
	default=[],
	type=pathlib.Path,
	action='append',
	help='Add file to package.')

args = parser.parse_args()

if args.format != 'vpk':
	sys.exit(f'{args.format} format is not implemented.')

if args.type != 'app':
	sys.exit(f'{args.type} type is not implemented.')

# process paths

pathmap = {} # DST:SRC
process_paths(pathmap, args.add, verbose=args.verbose)

# add default files

if args.type == 'app':
	right_gim = pathlib.Path('sce_sys/about/right.gim')
	right_png = pathlib.Path('sce_sys/about/right.png')
	right_suprx = pathlib.Path('sce_sys/about/right.suprx')
	if right_suprx not in pathmap and (right_gim in pathmap or right_png in pathmap):
		default = lookup_default('arm-dolce-eabi/module/right.suprx')
		if default:
			process_paths(pathmap, ((default, right_suprx),), verbose=args.verbose)

	icon0 = pathlib.Path('sce_sys/icon0.png')
	if icon0 not in pathmap:
		default = lookup_default('share/livearea/icon0.png')
		if default:
			process_paths(pathmap, ((default, icon0),), verbose=args.verbose)

	pic0 = pathlib.Path('sce_sys/pic0.png')
	if pic0 not in pathmap:
		default = lookup_default('share/livearea/pic0.png')
		if default:
			process_paths(pathmap, ((default, pic0),), verbose=args.verbose)

	la = pathlib.Path('sce_sys/livearea/contents/template.xml')
	bg = pathlib.Path('sce_sys/livearea/contents/bg0.png')
	if la not in pathmap:
		default_la = lookup_default('share/livearea/template.xml')
		default_bg = lookup_default('share/livearea/bg0.png')
		if default_la and default_bg:
			process_paths(pathmap, ((default_la, la), (default_bg, bg)), verbose=args.verbose)

# validate

for file in must_reg_file:
	if file in pathmap and pathmap[file].is_dir():
		sys.exit(f'{file} must be a regular file')

for file in must_dir_file:
	if file in pathmap and not pathmap[file].is_dir():
		sys.exit(f'{file} must be a directory')

if args.type == 'app':
	for file in must_exist_app_file:
		if file not in pathmap:
			sys.exit(f'{file} must exist for type app')

# create pkg

if args.format == 'vpk':
	make_vpk(args.output, pathmap)
