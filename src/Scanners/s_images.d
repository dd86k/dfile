/*
 * s_images.d : Image scanner
 */

module s_images;

import core.stdc.stdio;
import dfile, utils;

/// Scan a PNG image
void scan_png() { // Big Endian, https://www.w3.org/TR/PNG-Chunks.html
    struct ihdr_chunk_full { align(1): // Includes CRC
        uint width;        // START IHDR
        uint height;
        ubyte depth;       // bit depth
        ubyte color;       // color type
        ubyte compression;
        ubyte filter;
        ubyte interlace;   // END IHDR
        uint crc;
    }
    /*enum { // Types -- future use?
        IHDR = 0x52444849,
        pHYs = 0x73594870
    }*/

    ihdr_chunk_full h;
    fseek(fp, 16, SEEK_SET); // Magic!
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
    rewind(fp);
    fread(&h, h.sizeof, 1, fp);
    report("GIF", false);

    switch (h.version_[1]) { // 87a, 89a, lazy switch
        case '7': printf("87a image"); break;
        case '9': printf("89a image"); break;
        default: printf(" image, non-supported version\n"); return;
    }

    with (h) {
        printf(", %d x %d pixels, %d-bit\n", width, height, ((packed >>> 4) & 3) + 1);

        if (More) {
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

            if (aspect)
                printf(", %d pixel ratio (reported)", (cast(float)aspect + 15) / 64);

            printf("\n");
        }
    } // with
}

/// Scan a BPG image, https://bellard.org/bpg/bpg_spec.txt
void scan_bpg() { // Big Endian
    struct heic_hdr { align(1):
        //uint magic;
        ubyte format; // format[8:5], alpha1[4], bit-depth-8[3:0]
        ubyte color; // space[8:4], extension[3], alpha2[2], limited[1], animation[0]
        //uint width;  // ue7(32), exp-golomb
        //uint height; // ue7(32), exp-golomb
        //uint length; // ue7(32), exp-golomb, size?
    }
    enum // FORMAT
        ALPHA = 0b1_0000;
    enum // COLOR
        ANIMATION = 1,
        LIMITED = 0b10, // RANGE
        ALPHA2 = 0b100;
        /*EXTENSION = 0b1000;*/

    heic_hdr h;
    fread(&h, h.sizeof, 1, fp);

    const uint width = fread_l;
    const uint height = fread_l;

    report("Better Portable Graphics image, ", false);

    printf("%d x %d", width, height);

    if (h.format & ALPHA)
        printf(", alpha1");
    if (h.color & ALPHA2) // ?
        printf(", alpha2");
    if (h.color & ANIMATION)
        printf(", animated");
    if (h.color & LIMITED)
        printf(", limited range");
    /*if (h.color & EXTENSION)
        printf(", data extension");*/

    printf("\n");

    if (More) {
        switch (h.color >>> 4) {
            default: printf("Unknown color "); break;
            case 0: printf("YCbCr (BT 709) "); break;
            case 0b0001: printf("RGB "); break;
            case 0b0010: printf("YCgCo "); break;
            case 0b0011: printf("YCbCr (BT 709) "); break;
            case 0b0100: printf("YCbCr (BT 2020) "); break;
            case 0b0101: printf("YCbCr (BT 2020, constant) "); break;
        }

        switch (h.format >>> 5) {
            default: printf("Unknown format\n"); break;
            case 0: printf("Grayscale\n"); break;
            case 0b001: printf("4:2:0 (JPEG)\n"); break;
            case 0b010: printf("4:2:2 (JPEG)\n"); break;
            case 0b011: printf("4:4:4\n"); break;
            case 0b100: printf("4:2:0 (MPEG2)\n"); break;
            case 0b101: printf("4:2:2 (MPEG2)\n"); break;
        }
    }
}

/// Scan a FLIF image, http://flif.info/spec.html
void scan_flif() {
    struct flif_hdr { align(1):
        //uint magic;
        ubyte type; // interlacing+animation[8:4], channels[3:0]
        ubyte channelbytes; // bytes per channel
    }

    flif_hdr h;
    fread(&h, h.sizeof, 1, fp);

    const int width = fread_l + 1;
    const int height = fread_l + 1;
    ubyte animf; fread(&animf, 1, 1, fp);
    //const int animf = fread_l + 1; // animation frames

    report("Free Lossless Image Format image, ", false);

    printf("%d x %d, ", width, height);

    switch (h.type >>> 4) {
        case 3: printf("\n"); break; // Still image
        case 4: printf("interlaced\n"); break;
        case 5: printf("animated\n"); break;
        case 6: printf("interlaced, animated\n"); break;
        default: printf("Unknown type\n");
    }

    if (More) {
        switch (h.type & 0b1111) {
            case 1: printf("Grayscale\n"); break;
            case 3: printf("RGB\n"); break;
            case 4: printf("RGBA\n"); break;
            default: printf("%d channels\n", h.type & 0b1111);
        }
    }
}

// Used in: BPG, FLIF
/// Private function used to read varint/ue7
private uint fread_l() {
    uint r; // result
    ubyte b; // buffer
    uint s; // Shift
    do {
        fread(&b, 1, 1, fp);
        r |= b & 0b111_1111;
        if ((b & 0b1000_0000) == 0) return r;
        s += 7;
        r <<= s;
    } while (true);
}