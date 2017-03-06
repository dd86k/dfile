/*
 * utils.d : Utilities
 */

module utils;

string tarstr(char[] str)
{
    size_t p;
    while (str[p] == '0') ++p;
    return str[p .. $ - 1].idup;
}

uint invert(uint num) pure
{
    ubyte* p = cast(ubyte*)&num;
    return p[3] | p[2] << 8 | p[1] << 16 | p[0] << 24;
}