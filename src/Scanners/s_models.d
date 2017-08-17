/*
 * s_models.d : 3D models, textures, etc.
 */

module s_models;

import std.stdio, dfile, utils;

// https://gist.github.com/ulrikdamm/8274171
/// Scan a PMX model
void scan_pmx()
{
    struct pmx_hdr { align(1):
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
    scpy(CurrentFile, &h, h.sizeof);

    report("PMX model v", false);
    write(h.ver, " ", h.char_encoding ? "UTF-8" : "UTF-16");

    if (More)
    {
        try
        {
            uint l;
            scpy(CurrentFile, &l, l.sizeof);
            printf(" -- l : %X\n", l);
            CurrentFile.seek(l, SEEK_CUR); // Skip Japanese name
            scpy(CurrentFile, &l, l.sizeof);
            printf(" -- l : %X\n", l);
            if (l) {
                if (h.char_encoding)
                { // UTF-8
                    char[] c = CurrentFile.rawRead(new char[l]);
                    write(c);
                }
                else
                { // UTF-16
                    wchar[] c = CurrentFile.rawRead(new wchar[l/2]);
                    write(c);
                }
            }
        }
        catch (Exception)
        {

        }
    }

    writeln();
}