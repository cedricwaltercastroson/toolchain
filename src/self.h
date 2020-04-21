#pragma once

#include <inttypes.h>

// some info taken from the wiki, see https://www.psdevwiki.com/ps3/SELF_-_SPRX
// For more information on boot params, see https://forum.devchroma.nl/index.php/topic,141.0.html

#pragma pack(push, 1)
typedef struct {
	uint32_t magic;                      /* 53434500 = SCE\0 */
	uint32_t version;                    /* header version 3*/
	uint16_t sdk_type;                   /* */
	uint16_t header_type;                /* 1 self, 2 unknown, 3 pkg */
	uint32_t metadata_offset;            /* metadata offset */
	uint64_t header_len;                 /* self header length */
	uint64_t elf_filesize;               /* ELF file length */
	uint64_t self_filesize;              /* SELF file length */
	uint64_t unknown;                    /* UNKNOWN */
	uint64_t self_offset;                /* SELF offset */
	uint64_t appinfo_offset;             /* app info offset */
	uint64_t elf_offset;                 /* ELF #1 offset */
	uint64_t phdr_offset;                /* program header offset */
	uint64_t shdr_offset;                /* section header offset */
	uint64_t section_info_offset;        /* section info offset */
	uint64_t sceversion_offset;          /* version offset */
	uint64_t supplemental_hdr_offset;    /* supplemental header offset */
	uint64_t supplemental_hdr_size;      /* supplemental header size */
	uint64_t padding;
} SCE_header;

typedef struct {
	uint64_t authid;                /* auth id */
	uint32_t vendor_id;             /* vendor id */
	uint32_t self_type;             /* app type */
	uint64_t version;               /* app version */
	uint64_t padding;               /* UNKNOWN */
} SCE_appinfo;

typedef struct {
	uint32_t unk1;
	uint32_t unk2;
	uint32_t unk3;
	uint32_t unk4;
} SCE_version;

typedef struct {
	uint32_t type; // 5 - npdrm_hdr, 6 - boot_param_hdr, 7 - shared_secret_hdr
	uint32_t size;
	uint32_t next; // 1 if another Supplemental Header element follows else 0
	uint32_t pad;
} SCE_supplemental_hdr;

typedef struct {
	SCE_supplemental_hdr common;
	char unk[0x100];
} SCE_npdrm_hdr;

typedef struct {
	SCE_supplemental_hdr common;
	uint32_t is_used;                  // always 1
	uint32_t attribute;
	uint32_t phy_memsize;              // in kilobytes
	uint32_t app_memsize;              // in kilobytes
	uint32_t file_open_max_num;
	uint32_t directory_max_level;
	uint32_t encrypt_mount_max_num;
	uint32_t redirect_mount_max_num;
	uint32_t reserved[0x38];
} SCE_boot_param_hdr;

typedef struct {
	SCE_supplemental_hdr common;
	char unk[0x40];
} SCE_shared_secret_hdr;

typedef struct {
	uint64_t offset;
	uint64_t length;
	uint64_t compression; // 1 = uncompressed, 2 = compressed
	uint64_t encryption; // 1 = encrypted, 2 = plain
} segment_info;
#pragma pack(pop)

enum {
	HEADER_LEN = 0x1000
};
