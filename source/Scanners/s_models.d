/*
 * s_models.d : 3D models, textures, etc.
 */

module s_models;

import std.stdio, dfile, utils;

// https://gist.github.com/ulrikdamm/8274171
void scan_pmx(File file)
{
    struct pmx_hdr {
        //char[4] sig;
        float ver; // 4 bytes
        char len; // 8
        char char_encoding, // 0 = UTF-16, 1 = UTF-8
             uv,
             vertex_size,
             texture_size,
             material_size,
             bone_size,
             morph_size,
             body_size;
    }

    pmx_hdr h;
    scpy(file, &h, h.sizeof);

    report("PMX model v", false);
    write(h.ver, " ", h.char_encoding ? "UTF-8" : "UTF-16");

    if (More)
    {
        try
        {
            file.seek(-3, SEEK_CUR);
            uint l;
            scpy(file, &l, l.sizeof);
            writefln(" -- l : %X", l);
            file.seek(l, SEEK_CUR); // Skip Japanese name
            scpy(file, &l, l.sizeof);
            writefln(" -- l : %X", l);
            if (l) {
                if (h.char_encoding)
                { // UTF-8
                    char[] c = file.rawRead(new char[l]);
                    write(c);
                }
                else
                { // UTF-16
                    wchar[] c = file.rawRead(new wchar[l/2]);
                    write(c);
                }
            }
        }
        catch (Throwable)
        {

        }
    }

    writeln();
}