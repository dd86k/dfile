/*
 * utils.d : Utilities
 */

module utils;

import std.stdio, dfile : Base10;

/*
 * File utilities.
 */

/**
 * Read file with a struct or array.
 * Note: MAKE SURE THE STRUCT IS BYTE-ALIGNED.
 * Params:
 *   file = Current file
 *   s = Void pointer to the first element
 *   size = Size of the struct
 *   rewind = Rewind seeker to start of the file
 */
void scpy(File file, void* s, size_t size, bool rewind = false)
{
    import std.c.string : memcpy;
    if (rewind) file.rewind();
    ubyte[] buf = new ubyte[size];
    file.rawRead(buf);
    memcpy(s, buf.ptr, size);
}

/*
 * String utilities.
 */

/**
 * Get a string from a  null-terminated buffer.
 * Params: str = ASCIZ sting
 * Returns: String (UTF-8)
 */
string asciz(char[] str) pure
{
    if (str[0] == '\0') return null;
    char* p, ip; p = ip = &str[0];
    while (*++p != '\0') {}
    return str[0 .. p - ip].idup;
}

/**
 * Get a string from a '0'-padded buffer.
 * Params: str = tar sting
 * Returns: String (UTF-8)
 */
string tarstr(char[] str) pure
{
    size_t p;
    while (str[p] == '0') ++p;
    return str[p .. $ - 1].idup;
}

/**
 * Get a ' '-padded string from a buffer.
 * Params: str = iso-string
 * Returns: String (UTF-8)
 */
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

// https://en.wikipedia.org/wiki/Exponential-Golomb_coding
//TODO: EXP-GOLOMB UTIL
/// Get a Exp-Golomb-Encoded number
/*ulong expgol(uint n)
{
    return 0;
}*/

/**
 * Get a byte-formatted size.
 * Params: size = Size to format.
 * Returns: Formatted string.
 */
string formatsize(long size) //BUG: %f is unpure?
{
    import std.format : format;

    enum : long {
        KB = 1024,
        MB = KB * 1024,
        GB = MB * 1024,
        TB = GB * 1024,
        KiB = 1000,
        MiB = KiB * 1000,
        GiB = MiB * 1000,
        TiB = GiB * 1000
    }

	const float s = size;

	if (Base10)
	{
		if (size > TiB)
			if (size > 100 * TiB)
				return format("%d TiB", size / TiB);
			else if (size > 10 * TiB)
				return format("%0.1f TiB", s / TiB);
			else
				return format("%0.2f TiB", s / TiB);
		else if (size > GiB)
			if (size > 100 * GiB)
				return format("%d GiB", size / GiB);
			else if (size > 10 * GiB)
				return format("%0.1f GiB", s / GiB);
			else
				return format("%0.2f GiB", s / GiB);
		else if (size > MiB)
			if (size > 100 * MiB)
				return format("%d MiB", size / MiB);
			else if (size > 10 * MiB)
				return format("%0.1f MiB", s / MiB);
			else
				return format("%0.2f MiB", s / MiB);
		else if (size > KiB)
			if (size > 100 * MiB)
				return format("%d KiB", size / KiB);
			else if (size > 10 * KiB)
				return format("%0.1f KiB", s / KiB);
			else
				return format("%0.2f KiB", s / KiB);
		else
			return format("%d B", size);
	}
	else
	{
		if (size > TB)
			if (size > 100 * TB)
				return format("%d TB", size / TB);
			else if (size > 10 * TB)
				return format("%0.1f TB", s / TB);
			else
				return format("%0.2f TB", s / TB);
		else if (size > GB)
			if (size > 100 * GB)
				return format("%d GB", size / GB);
			else if (size > 10 * GB)
				return format("%0.1f GB", s / GB);
			else
				return format("%0.2f GB", s / GB);
		else if (size > MB)
			if (size > 100 * MB)
				return format("%d MB", size / MB);
			else if (size > 10 * MB)
				return format("%0.1f MB", s / MB);
			else
				return format("%0.2f MB", s / MB);
		else if (size > KB)
			if (size > 100 * KB)
				return format("%d KB", size / KB);
			else if (size > 10 * KB)
				return format("%0.1f KB", s / KB);
			else
				return format("%0.2f KB", s / KB);
		else
			return format("%d B", size);
	}
}

/*
 * 16-bit swapping
 */

/// Byte swap 2 bytes.
ushort bswap(ushort num) pure
{
    version (LittleEndian)
        version (X86) asm pure {
            naked;
            xchg AH, AL;
            ret;
        } else version (X86_64)
            version (Windows) asm pure {
                naked;
                mov AX, CX;
                xchg AL, AH;
                ret;
            } else asm pure { // System V AMD64 ABI
                naked;
                mov EAX, EDI;
                xchg AL, AH;
                ret;
            }
        else
        {
            if (num)
            {
                ubyte* p = cast(ubyte*)&num;
                return p[1] | p[0] << 8;
            }
        }
    else return num;
}

/*
 * 32-bit swapping
 */

/// Byte swap 4 bytes.
uint bswap(uint num) pure
{
    version (LittleEndian)
        version (X86) asm pure {
            naked;
            bswap EAX;
            ret;
        } else version (X86_64)
            version (Windows) asm pure {
                naked;
                mov EAX, ECX;
                bswap EAX;
                ret;
            } else asm pure { // System V AMD64 ABI
                naked;
                mov RAX, RDI;
                bswap EAX;
                ret;
            }
        else
        {
            if (num)
            {
                ubyte* p = cast(ubyte*)&num;
                return p[3] | p[2] << 8 | p[1] << 16 | p[0] << 24;
            }
        }
    else return num;
}

/*
 * 64-bit swapping
 */

/// Byte swap 8 bytes.
ulong bswap(ulong num) pure
{
    version (LittleEndian)
        version (X86) asm pure {
            naked;
            xchg EAX, EDX;
            bswap EDX;
            bswap EAX;
            ret;
        } else version (X86_64)
            version (Windows) asm pure {
                naked;
                mov RAX, RCX;
                bswap RAX;
                ret;
            } else asm pure { // System V AMD64 ABI
                naked;
                mov RAX, RDI;
                bswap RAX;
                ret;
            }
        else
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
    else return num;
}

/// Swap an array of bytes.
void bswap(ubyte* a, size_t length) pure
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

ushort make_ushort(char[] buf) pure
{
    return buf[0] | buf[1] << 8;
}
ushort make_ushort(ubyte[] buf) pure
{
    return buf[0] | buf[1] << 8;
}
uint make_uint(char[] buf) pure
{
    return buf[0] | buf[1] << 8 | buf[2] << 16 | buf[3] << 24;
}
uint make_uint(ubyte[] buf) pure
{
    return buf[0] | buf[1] << 8 | buf[2] << 16 | buf[3] << 24;
}

void print_array(void* arr, size_t length)
{
    ubyte* p = cast(ubyte*)arr;
    writef("%02X", p[--length]);
    do writef("-%02X", p[--length]); while (length);
    writeln;
}