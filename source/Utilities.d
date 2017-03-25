/*
 * utils.d : Utilities
 */

module utils;

import std.stdio : File;

version (X86)
    version = X86_ANY;
else version (X86_64)
    version = X86_ANY;

/*
 * File utilities.
 */

/// Read file with a struct.
void scpy(File file, void* s, size_t size, bool rewind = false)
{
    if (rewind) file.rewind();
    ubyte[] buf = new ubyte[size];
    file.rawRead(buf);
    ubyte* sp = cast(ubyte*)s, bp = &buf[0];
    do *sp++ = *bp++; while (size--);
}

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

/// Get a formatted size.
string formatsize(long size) pure
{
    import std.format : format;

    enum : long {
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

/// Swap bytes.
version (X86_ANY) ushort invert(ushort num) pure
{
    asm pure { naked;
        xchg AH, AL;
        ret;
    }
}
else ushort invert(ushort num) pure
{
    version (LittleEndian)
    {
        if (num)
        {
            ubyte* p = cast(ubyte*)&num;
            return p[1] | p[0] << 8;
        }
    }

    return num;
}

/// Swap bytes.
version (X86) uint invert(uint num) pure
{
    asm pure { naked;
        bswap EAX;
        ret;
    }
}
else version (X86_64) uint invert(uint num) pure
{
    asm pure { naked;
        mov EAX, ECX;
        bswap EAX;
        ret;
    }
}
else uint invert(uint num) pure
{
    version (LittleEndian)
    {
        if (num)
        {
            ubyte* p = cast(ubyte*)&num;
            return p[3] | p[2] << 8 | p[1] << 16 | p[0] << 24;
        }
    }
    
    return num;
}

/// Swap bytes.
version (X86) ulong invert(ulong num) pure
{
    asm pure { naked;
        xchg EAX, EDX;
        bswap EDX;
        bswap EAX;
        ret;
    }
}
else version (X86_64) ulong invert(ulong num) pure
{
    asm pure { naked;
        bswap RAX;
        ret;
    }
}
else ulong invert(ulong num) pure
{
    version (LittleEndian)
    {
        if (num)
        {
            ubyte* p = cast(ubyte*)&num;
            ubyte c;
            for (int a, b = 7; a < 4; ++a, --b) {
                c = *(p + b);
                *(p + b) = *(p + a);
                *(p + a) = c;
            }
            return num;
        }
    }

    return num;
}

/// Invert byte sequence.
void invert(ubyte* a, size_t length) pure
{
    size_t l = length / 2;
    if (l)
    {
        ubyte* b = a + length - 1;
        ubyte c;
        while (l--)
        {
            c = *b;
            *b = *a;
            *a = c;
            --b; ++a;
        } 
    }
}