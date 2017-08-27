/*
 * s_pst.d : PST archive scanner.
 *           This also includes OST and likely NST files.
 */

module s_pst;

import std.stdio, dfile, utils;

enum PST_MAGIC = 0x4E444221; /// PST magic, "!BDN"
private enum ushort CLIENT_MAGIC = 0x4D53;

private struct pst_header { align(1):
    // Magic
    uint crc; /// CRC
    ushort client; /// Client magic, Must be 0x4D53
    ushort version_; /// File format version
    ushort client_version; /// Client version (based on MS-PST document version)
    ubyte platform_create; /// Must be 0x1
    ubyte platform_access; /// Must be 0x1
    uint reserved1, reserved2;
    uint nextb; /// Next BID
    uint nextp; /// Next page BID
    uint unique; /// Changes everytime the PST is changed
    //TODO: Finish struct and consider another struct for ANSI/Unicode
    // Rest is reserved.
}

/// Scan a PST file.
void scan_pst() {
    pst_header h;
    scpy(&h, h.sizeof);
    //TODO: Finish PST

    with (h) {
        report("PST", false);
        printf(" archive, v%d (client v%d), ",
            version_, client_version);
        if (version_ == 14 || version_ == 15)
            printf("ANSI");
        else if (version_ >= 23)
            printf("Unicode");

        if (version_ == 37)
            printf(", probably WIP encrypted");

        writeln;

        if (More) {
            printf("crc: %08X\n", crc);
            printf("client_magic: %Xh\n", client);
            printf("file_version: %Xh\n", version_);
            printf("client_version: %Xh\n", client_version);
            printf("platform_create: %Xh\n", platform_create);
            printf("platform_access: %Xh\n", platform_access);
            printf("nextb: %Xh\n", nextb);
            printf("nextp: %Xh\n", nextp);
            printf("unique: %Xh\n", unique);
        }
    }
}