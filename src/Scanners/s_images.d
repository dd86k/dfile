/*
 * s_images.d : Image scanner
 */

module s_images;

import dfile, std.stdio, utils;

/// Scan a PNG image
void scan_png() // Big Endian
{ // https://www.w3.org/TR/PNG-Chunks.html
    struct ihdr_chunk_full { align(1): // Yeah.. Blame PNG
        uint restmagic;
        uint length;
        uint type;
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
    enum { // Types
        IHDR = 0x52444849,
        pHYs = 0x73594870
    }*/
    
    ihdr_chunk_full h;
    scpy(&h, h.sizeof);
    report("Portable Network Graphics image (PNG), ", false);

    with (h) {
        write(bswap32(width), " x ", bswap32(height), " pixels, ");
        switch (color) {
        case 0:
            switch (depth) {
            case 1, 2, 4, 8, 16:
                write(depth, "-bit ");
                break;
            default: break;
            }
            write("Grayscale");
            break;
        case 2:
            switch (depth) {
            case 8, 16:
                write(depth*3, "-bit ");
                break;
            default: break;
            }
            write("RGB");
            break;
        case 3:
            switch (depth) {
            case 1, 2, 4, 8:
                write("8-bit ");
                break;
            default: break;
            }
            write("PLTE Palette");
            break;
        case 4:
            switch (depth) {
            case 8, 16:
                write(depth, "-bit ");
                break;
            default:
            }
            write("Grayscale+Alpha");
            break;
        case 6:
            switch (depth) {
            case 8, 16:
                write("32-bit ");
                break;
            default:
            }
            write("RGBA");
            break;
        default: write("Invalid color type"); break;
        }

        writeln;

        if (More) {
            switch (compression) {
            case 0: write("Default compression"); break;
            default: write("Invalid compression"); break;
            }

            write(", ");

            switch (filter) {
            case 0: write("Default filtering"); break;
            default: write("Invalid filtering"); break;
            }

            write(", ");

            switch (interlace) {
            case 0: write("No interlacing"); break;
            case 1: write("Adam7 interlacing"); break;
            default: write("Invalid interlacing"); break;
            }

            writeln();
        }
    }
}

/// Scan a GIF image
void scan_gif()
{ // http://www.fileformat.info/format/gif/egff.htm
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

    switch (h.version_[1]) { // 87a, 89a
        case '7', '9':
            report("GIF", false);
            writeln(h.version_, " image");
            break;
        default: writeln("GIF image, invalid version"); return;
    }

    if (More)
    {
        enum {
            GLOBAL_COLOR_TABLE = 0x80,
            SORT_FLAG = 8,
        }

        with (h) {
            write(width, " x ", height, " pixels");
            if (packed & GLOBAL_COLOR_TABLE) {
                write(", Global Color Table");
                if (packed & 3)
                    write(" of ", 2 ^^ ((packed & 3) + 1), " bytes");
                if (packed & SORT_FLAG)
                    write(", Sorted");
                if (bgcolor)
                    write(", BG Index of ", bgcolor);
            }
            write(", ", ((packed >> 4) & 3) + 1, "-bit");
            if (aspect) {
                write(", ", (cast(float)aspect + 15) / 64, " pixel ratio (reported)");
            }
        }
    }

    writeln();
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