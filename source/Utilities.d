/*
 * utils.d : Utilities
 */

module utils;

import std.stdio;

/*
 * File utilities.
 */

/// Read file with a struct.
void structcpy(File file, void* s, size_t size, bool rewind = false)
{
    ubyte[] buf = new ubyte[size];
    if (rewind) file.rewind();
    file.rawRead(buf);
    ubyte* sp = cast(ubyte*)s;
    for (--size; size > 0; --size)
        *(sp + size) = buf[size];
    *(sp) = buf[0];
}

//TODO: structcpy_reverse

/*
 * String utilities.
 */

/// Get a null-terminated string.
string asciz(char[] str) pure
{
    if (str[0] == '\0') return null;
    char* p, ip; p = ip = &str[0];
    while (*++p != '\0') {}
    return str[0 .. p - ip].idup;
}

/// Get a Tar-like string ('0' padded).
string tarstr(char[] str) pure
{
    size_t p;
    while (str[p] == '0') ++p;
    return str[p .. $ - 1].idup;
}

/// Get a ISO-like string (' ' padded).
string isostr(char[] str) pure
{
    if (str[0] == ' ') return null;
    if (str[$ - 1] != ' ') return str.idup;
    size_t p = str.length - 1;
    while (str[p] == ' ') --p;
    return str[0 .. p + 1].idup;
}

/*
 * Number utilities.
 */

/// Get byte size, formatted.
string formatsize(ulong size)
{
    import std.format : format;
    enum : ulong {
        KB = 1024,
        MB = KB * 1024,
        GB = MB * 1024,
        TB = GB * 1024
    }

    if (size < KB)
        return format("%d B", size);
    else if (size < MB)
        return format("%d KB", size / KB);
    else if (size < GB)
        return format("%d MB", size / MB);
    else if (size < TB)
        return format("%d GB", size / GB);
    else
        return format("%d TB", size / TB);
}

/// Invert endian.
ushort invert(ushort num) pure
{
    version (LittleEndian)
    {
        ubyte* p = cast(ubyte*)&num;
        return p[1] | p[0] << 8;
    }
    else return num;
}

/// Invert endian.
uint invert(uint num) pure
{
    version (LittleEndian)
    {
        ubyte* p = cast(ubyte*)&num;
        return p[3] | p[2] << 8 | p[1] << 16 | p[0] << 24;
    }
    else return num;
}

/// Invert endian.
ulong invert(ulong num) pure
{
    version (LittleEndian)
    {
        ubyte* p = cast(ubyte*)&num;
        ubyte c;
        for (int a, b = 7; b > 3; ++a, --b) {
            c = *(p + b);
            *(p + b) = *(p + a);
            *(p + a) = c;
        }
        return num;
    }
    else return num;
}