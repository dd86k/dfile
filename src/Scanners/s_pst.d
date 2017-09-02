/*
 * s_pst.d : PST archive scanner. This also includes OST and likely NST files.
 *           See MS-PST in MS-OFFICE.
 */

module s_pst;

import std.stdio, dfile, utils;

enum PST_MAGIC = 0x4E444221; /// PST magic, "!BDN"
private enum ushort CLIENT_MAGIC = 0x4D53;

private struct pst_header { align(1):
    //uint magic; // Magic
    uint crc; /// CRC
    ushort client; /// Client magic, Must be 0x4D53
    ushort version_; /// File format version
    ushort client_version; /// Client version (based on MS-PST document version)
    ubyte platform_create; /// Must be 0x1
    ubyte platform_access; /// Must be 0x1
    uint reserved1, reserved2;
}

private struct pst_ansi { align(1):
    uint nextb; /// Next page BID
    uint nextp; /// Next page BID
    uint unique; /// Changes everytime the PST is changed
    ubyte[128] rgnid; /// A fixed array of 32 NIDs
    ubyte[40] root;
    ubyte[128] rgbrm;
    ubyte[128] rgbfp;
    ubyte sentinel; /// Must be 0x80
    ubyte crypt; /// See bCryptMethod table
    /*ushort rgbReserved;
    ubyte[12] res;
    uint res2; //3+1 ubytes from rgbReserved2 and bReserved
    ubyte[32] rgbReserved3;*/
}

private struct pst_unicode { align(1):
    ulong unused;
    ulong nextp; /// Next page BID
    uint unique; /// Changes everytime the PST is changed
    ubyte[128] rgnid; /// A fixed array of 32 NIDs
    ulong unused1;
    ubyte[72] root;
    uint align_;
    ubyte[128] rgbrm;
    ubyte[128] rgbfp;
    ubyte sentinel; /// Must be 0x80
    ubyte crypt; /// See bCryptMethod table
    ushort reserved3;
    ulong nextb; /// Next page BID
    uint crcfull;
    /*uint res2; //3+1 ubytes from rgbReserved2 and bReserved
    ubyte[32] rgbReserved3;*/
}

/// Scan a PST file.
void scan_pst() {
    pst_header h;
    pst_unicode uh;
    scpy(&h, h.sizeof);
    bool ansi, unicode;

    with (uh)
    with (h) {
        if (version_ == 14 || version_ == 15) {
            ansi = true;
            pst_ansi ah;
            scpy(&ah, ah.sizeof);
            uh.crypt = ah.crypt;
        } else if (version_ >= 23) {
            unicode = true;
            scpy(&uh, uh.sizeof);
        }

        report("PST", false);
        printf(" archive, v%d (client v%d), ",
            version_, client_version);
        if (ansi)
            printf("ANSI, ");
        else if (unicode)
            printf("Unicode, ");

        switch (crypt) {
            case 0x01: printf("Permutation algorithm encrypted"); break;
            case 0x02: printf("Cyclic algorithm encrypted"); break;
            case 0x10: printf("Windows Information Protection encrypted"); break;
            default: printf("Unencrypted");
        }

        writeln;

        if (More) {
            printf("crc: %08X\n", crc);
            if (unicode) printf("crc full: %08X\n", crcfull);
            printf("client_magic: %Xh\n", client);
            printf("file_version: %Xh\n", version_);
            printf("client_version: %Xh\n", client_version);
            printf("platform_create: %Xh\n", platform_create);
            printf("platform_access: %Xh\n", platform_access);
            printf("nextp: %Xh\n", nextp);
            printf("unique: %Xh\n", unique);
        }
    }
}