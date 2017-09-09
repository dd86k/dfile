/*
 * s_models.d : 3D models, textures, etc.
 */

module s_models;

import std.stdio : write, writeln;
import dfile, utils;

// https://gist.github.com/ulrikdamm/8274171
/// Scan a PMX model
void scan_pmx()
{
    struct pmx_hdr { align(1):
        //uint sig;
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
    scpy(&h, h.sizeof);

    report("PMX model v", false);
    write(h.ver, " ", h.char_encoding ? "UTF-8" : "UTF-16");

    writeln();
}