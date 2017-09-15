/*
 * s_images.d : Image scanner
 */

module s_images;

import core.stdc.stdio : fread, printf, ftell;
import dfile, utils;

/// Scan a PNG image
void scan_png() { // Big Endian, https://www.w3.org/TR/PNG-Chunks.html
    struct ihdr_chunk_full { align(1): // Yeah.. Blame PNG
        uint magic;  // rest of it
        uint length; // Should be IHDR length
        uint type;   // IHDR
        uint width;        // START IHDR
        uint height;
        ubyte depth;       // bit depth
        ubyte color;       // color type
        ubyte compression;
        ubyte filter;
        ubyte interlace;   // END IHDR
        uint crc;
    }
    /*struct png_chunk { align(1):
        uint length;
        uint type;
        ubyte[] data;
        uint crc;
    }
    enum { // Types -- future use?
        IHDR = 0x52444849,
        pHYs = 0x73594870
    }*/

//TODO: Fix PNG

    ihdr_chunk_full h;
    debug printf("[PNG] FILE: %X\n", fp);
    debug printf("[PNG] SIZE: %d\n", h.sizeof);
    debug printf("[PNG] POS : %d\n", ftell(fp));
    fread(&h, h.sizeof, 1, fp);
    report("Portable Network Graphics image, ", false);

    with (h) {
        printf("%d x %d pixels, ", cast(int)bswap32(width), cast(int)bswap32(height));
        switch (color) {
        case 0:
            switch (depth) {
            case 1, 2, 4, 8, 16:
                printf("%d-bit ", depth);
                break;
            default:
            }
            printf("Grayscale");
            break;
        case 2:
            switch (depth) {
            case 8, 16:
                printf("%d-bit ", depth*3);
                break;
            default:
            }
            printf("RGB");
            break;
        case 3:
            switch (depth) {
            case 1, 2, 4, 8:
                printf("8-bit ");
                break;
            default:
            }
            printf("PLTE Palette");
            break;
        case 4:
            switch (depth) {
            case 8, 16:
                printf("%d-bit ", depth);
                break;
            default:
            }
            printf("Grayscale+Alpha");
            break;
        case 6:
            switch (depth) {
            case 8, 16:
                printf("32-bit ");
                break;
            default:
            }
            printf("RGBA");
            break;
        default: printf("Invalid color type"); break;
        }

        printf("\n");

        if (More) {
            switch (compression) {
            case 0: printf("Default compression"); break;
            default: printf("Invalid compression"); break;
            }

            printf(", ");

            switch (filter) {
            case 0: printf("Default filtering"); break;
            default: printf("Invalid filtering"); break;
            }

            printf(", ");

            switch (interlace) {
            case 0: printf("No interlacing"); break;
            case 1: printf("Adam7 interlacing"); break;
            default: printf("Invalid interlacing"); break;
            }

            printf("\n");
        }
    }
}

/// Scan a GIF image
void scan_gif() { // http://www.fileformat.info/format/gif/egff.htm
    struct gif_header { align(1):
        char[3] magic;
        char[3] version_;
        ushort width;
        ushort height;
        ubyte packed;
        ubyte bgcolor;
        ubyte aspect; // ratio
    }

    gif_header h;
    scpy(&h, h.sizeof, true);
    report("GIF", false);

    switch (h.version_[1]) { // 87a, 89a, lazy
        case '7': printf("87a image"); break;
        case '9': printf("89a image"); break;
        default: printf(" image, non-supported version\n"); return;
    }

    with (h) printf(", %d x %d pixels, %d-bit\n", width, height, ((packed >>> 4) & 3) + 1);

    if (More) with (h) {
        enum {
            GLOBAL_COLOR_TABLE = 0x80,
            SORT_FLAG = 8,
        }

        if (packed & GLOBAL_COLOR_TABLE) {
            printf(", Global Color Table");
            if (packed & 3)
                printf(" of %d bytes", 2 ^^ ((packed & 3) + 1));
            if (packed & SORT_FLAG)
                printf(", Sorted");
            if (bgcolor)
                printf(", BG Index of %X", bgcolor);
        }
        if (aspect) {
            printf(", %d pixel ratio (reported)", (cast(float)aspect + 15) / 64);
        }

        printf("\n");
    }
}

/// Scan a BPG image
void scan_bpg()
{ // Big Endian
    report("Better Portable Graphics image");

    //TODO: Continue BPG
    /*if (More)
    {
        struct heic_hdr { align(1):
            uint magic;
            ubyte format;
            ubyte color;
            uint width;
            uint height;
            uint length;
        }
        enum // FORMAT
            ALPHA = 0b1_0000;
        enum // COLOR
            ANIMATION = 1,
            LIMITED = 0b10, // RANGE
            ALPHA2 = 0b100,
            EXTENSION = 0b1000;

        heic_hdr h;
        scpy(file, &h, h.sizeof, true);
        write(expgol(h.width), " x ", h.height, ", ");

        switch (h.color & 0b1111_0000)
        {
            default: write("Unknown color "); break;
            case 0: write("YCbCr (BT 709) "); break;
            case 0b0001_0000: write("RGB"); break;
            case 0b0010_0000: write("YCgCo "); break;
            case 0b0011_0000: write("YCbCr (BT 709) "); break;
            case 0b0100_0000: write("YCbCr (BT 2020) "); break;
            case 0b0101_0000: write("YCbCr (BT 2020, constant) "); break;
        }

        switch (h.format & 0b1110_0000)
        {
            default: write("Unknown format"); break;
            case 0: write("Grayscale"); break;
            case 0b0010_0000: write("4:2:0 (JPEG)"); break;
            case 0b0100_0000: write("4:2:2 (JPEG)"); break;
            case 0b0110_0000: write("4:4:4"); break;
            case 0b1000_0000: write("4:2:0 (MPEG2)"); break;
            case 0b1010_0000: write("4:2:2 (MPEG2)"); break;
        }

        if (h.format & ALPHA)
            write(", Alpha");
        if (h.color & ALPHA2)
            write(", Alpha2");
        if (h.color & ANIMATION)
            write(", Animated");
        if (h.color & LIMITED)
            write(", Limited range");
        if (h.color & EXTENSION)
            write(", Data extension");
        
        writeln();
    }*/
}

/// Scan a FLIF image
void scan_flif()
{
    report("Free Lossless Image Format image");

    //TODO: Continue FLIF
    /*if (More)
    {
        struct flif_hdr { align(1):
            uint magic;
            ubyte type;
            ubyte channelbytes;
        }

        flif_hdr h;
        scpy(file, &h, h.sizeof, true);

        //1 byte determines the variable's length in bytes, first bit is set
    }*/
}