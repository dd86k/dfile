/*
 * s_images.d : Image scanner
 */

module s_images;

import dfile, std.stdio, utils;

static void scan_png(File file) // Big Endian
{ // https://www.w3.org/TR/PNG-Chunks.html
    report("Portable Network Graphics image (PNG)");

    if (More)
    {
        struct ihdr_chunk_full { // Yeah.. Blame PNG
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

        /*struct png_chunk {
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
        scpy(file, &h, h.sizeof);

        with (h) {
            write(invert(width), "x", invert(height), " pixels, ");

            switch (color)
            {
                case 0:
                    write("Grayscale ");
                    switch (depth)
                    {
                        case 1, 2, 4, 8, 16:
                            write(depth, "-bit depth");
                            break;
                        default: write("with invalid depth"); break;
                    }
                    break;
                case 2:
                    write("RGB ");
                    switch (depth)
                    {
                        case 8, 16:
                            write(depth * 3, "-bit depth");
                            break;
                        default: write("with invalid depth"); break;
                    }
                    break;
                case 3:
                    write("PLTE Palette ");
                    switch (depth)
                    {
                        case 1, 2, 4, 8:
                            write("8-bit depth");
                            break;
                        default: write("with invalid depth"); break;
                    }
                    break;
                case 4:
                    write("Grayscale+Alpha ");
                    switch (depth)
                    {
                        case 8, 16:
                            write(depth, "-bit depth");
                            break;
                        default: write("with invalid depth"); break;
                    }
                    break;
                case 6:
                    write("RGBA ");
                    switch (depth)
                    {
                        case 8, 16:
                            write(depth * 3, "-bit depth");
                            break;
                        default: write("with invalid depth"); break;
                    }
                    break;
                default: write("Invalid color type"); break;
            }

            write(", ");

            switch (compression)
            {
                case 0: write("Default compression"); break;
                default: writeln("Invalid compression"); break;
            }

            write(", ");

            switch (filter)
            {
                case 0: write("Default filtering"); break;
                default: writeln("Invalid filtering"); break;
            }

            write(", ");

            switch (interlace)
            {
                case 0: write("No interlacing"); break;
                case 1: write("Adam7 interlacing"); break;
                default: writeln("Invalid interlacing"); break;
            }

            writeln();
        }
    }
}

static void scan_gif(File file)
{ // http://www.fileformat.info/format/gif/egff.htm
    struct gif_header {
        char[3] magic;
        char[3] version_;
        ushort width;
        ushort height;
        ubyte packed;
        ubyte bgcolor;
        ubyte aspect; // ratio
    }

    gif_header h;
    scpy(file, &h, h.sizeof, true);

    switch (h.version_[1])
    { // 87a, 89a
        case '7', '9':
            report("GIF", false);
            writeln(h.version_, " image");
            break;
        default: writeln("GIF with invalid version"); return;
    }

    if (More)
    {
        enum {
            GLOBAL_COLOR_TABLE = 0x80,
            SORT_FLAG = 8,
        }

        with (h) {
            write(width, "x", height, " pixels");
            if (packed & GLOBAL_COLOR_TABLE) {
                write(", Global Color Table");
                if (packed & 3)
                    write(" of ", 2 ^^ ((packed & 3) + 1), " bytes");
                if (packed & SORT_FLAG)
                    write(", Sorted");
                if (bgcolor)
                    write(", BG Index of ", bgcolor);
            }
            write(", ", ((packed >> 4) & 3) + 1, "-bit Color Resolution");
            if (aspect) {
                write(", ", (cast(float)aspect + 15) / 64, " pixel ratio (approx)");
            }
        }
    }

    writeln();
}