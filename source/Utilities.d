/*
 * utils.d : Utilities
 */

module utils;

string asciz(char[] str)
{
    if (str[0] == '\0') return null;
    char* p, ip; p = ip = &str[0];
    while (*++p != '\0') {}
    return str[0 .. p - ip].idup;
}

string tarstr(char[] str)
{
    size_t p;
    while (str[p] == '0') ++p;
    return str[p .. $ - 1].idup;
}

string isostr(char[] str)
{
    if (str[0] == ' ') return null;
    if (str[$ - 1] != ' ') return str.idup;
    size_t p = str.length - 1;
    while (str[p] == ' ') --p;
    return str[0 .. p + 1].idup;
}

uint invert(uint num) pure
{
    ubyte* p = cast(ubyte*)&num;
    return p[3] | p[2] << 8 | p[1] << 16 | p[0] << 24;
}