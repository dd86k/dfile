/*
 * s_images.d : Image scanner
 */

module s_images;

import dfile, std.stdio, utils;

static void scan_png(File file) // Big Endian
{
    report("Portable Network Graphics image (PNG)");

    if (Informing)
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
        {
            import core.stdc.string : memcpy;
            enum s = ihdr_chunk_full.sizeof;
            ubyte[s] b;
            file.seek(8);
            file.rawRead(b);
            memcpy(&h, &b, s);
        }

        with (h) {
            write(invert(width), "x", invert(height), " pixels, ");

            switch (color)
            {
                case 0:
                    write("Grayscale");
                    switch (depth)
                    {
                        case 1, 2, 4, 8, 16:
                            write(" ", depth * 3, "-bit depth");
                            break;
                        default: write(" with invalid depth"); break;
                    }
                    break;
                case 2:
                    write("RGB");
                    switch (depth)
                    {
                        case 8, 16:
                            write(" ", depth * 3, "-bit depth");
                            break;
                        default: write(" with invalid depth"); break;
                    }
                    break;
                case 3:
                    write("PLTE Palette");
                    switch (depth)
                    {
                        case 1, 2, 4, 8:
                            write(" 8-bit depth");
                            break;
                        default: write(" with invalid depth"); break;
                    }
                    break;
                case 4:
                    write("Grayscale+Alpha");
                    switch (depth)
                    {
                        case 8, 16:
                            write(" ", depth * 3, "-bit depth");
                            break;
                        default: write(" with invalid depth"); break;
                    }
                    break;
                case 6:
                    write("RGBA");
                    switch (depth)
                    {
                        case 8, 16:
                            write(" ", depth * 3, "-bit depth");
                            break;
                        default: write(" with invalid depth"); break;
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

