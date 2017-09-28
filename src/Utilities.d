/*
 * utils.d : Utilities
 */

module utils;

import dfile : Base10, fp;

/*
 * File utilities.
 */

/**
 * Read file with a struct or array.
 * Note: MAKE SURE THE STRUCT IS BYTE-ALIGNED.
 * Params:
 *   s = Void pointer to the first element
 *   size = Size of the struct
 *   rewind = Rewind seeker to start of the file
 */
void scpy(void* s, size_t size, bool rewind = false) {
    import core.stdc.stdio : fread, fseek, SEEK_SET;//rewind;
    if (rewind) fseek(fp, 0, SEEK_SET); //rewind(fp); doesn't work and idk why
    fread(s, size, 1, fp); // size * 1
}

/*
 * String utilities.
 */

/**
 * Get a tar string from a character buffer.
 * Params: str = tar-string
 * Returns: String (UTF-8)
 */
string tarstr(char[] str) pure
{
    size_t p;
    while (str[p] == '0') ++p;
    return str[p .. $ - 1].idup;
}

/**
 * Get an ISO string from a character buffer.
 * Params: str = iso-string
 * Returns: String (UTF-8)
 */
string isostr(char[] str) pure
{
    if (str[0] == ' ') return null;
    size_t p = str.length;
    if (str[--p] != ' ') return str.idup;
    while (str[p] == ' ') --p;
    return str[0 .. p + 1].idup;
}

/*
 * Number utilities.
 */

//TODO: EXP-GOLOMB UTIL for BPG and FLIF
// https://en.wikipedia.org/wiki/Exponential-Golomb_coding
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
string formatsize(ulong size)
{
    import std.format : format;

    enum : double {
        KB = 1024,
        MB = KB * 1024,
        GB = MB * 1024,
        TB = GB * 1024,
        KiB = 1000,
        MiB = KiB * 1000,
        GiB = MiB * 1000,
        TiB = GiB * 1000
    }

	const double s = size;

	if (Base10) {
		if (size > TiB)
            return format("%0.2f TiB", s / TiB);
		else if (size > GiB)
            return format("%0.2f GiB", s / GiB);
		else if (size > MiB)
            return format("%0.2f MiB", s / MiB);
		else if (size > KiB)
            return format("%0.2f KiB", s / KiB);
		else
			return format("%d B", size);
	} else {
		if (size > TB)
            return format("%0.2f TB", s / TB);
		else if (size > GB)
            return format("%0.2f GB", s / GB);
		else if (size > MB)
            return format("%0.2f MB", s / MB);
		else if (size > KB)
            return format("%0.2f KB", s / KB);
		else
			return format("%d B", size);
	}
}

/**
 * Byte swap a 2-byte number.
 * Params: num = 2-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, false) ushort bswap16(ushort num)
{
    version (X86) asm { naked;
        xchg AH, AL;
        ret;
    } else version (X86_64) {
        version (Windows) asm { naked;
            mov AX, CX;
            xchg AL, AH;
            ret;
        } else asm { naked; // System V AMD64 ABI
            mov EAX, EDI;
            xchg AL, AH;
            ret;
        }
    } else {
        if (num) {
            ubyte* p = cast(ubyte*)&num;
            return p[1] | p[0] << 8;
        } else return num;
    }
}

/**
 * Byte swap a 4-byte number.
 * Params: num = 4-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, false) uint bswap32(uint num)
{
    version (X86) asm { naked;
        bswap EAX;
        ret;
    } else version (X86_64) {
        version (Windows) asm { naked;
            mov EAX, ECX;
            bswap EAX;
            ret;
        } else asm { naked; // System V AMD64 ABI
            mov RAX, RDI;
            bswap EAX;
            ret;
        }
    } else {
        if (num) {
            ubyte* p = cast(ubyte*)&num;
            return p[3] | p[2] << 8 | p[1] << 16 | p[0] << 24;
        } else return 0;
    }
}

/**
 * Byte swap a 8-byte number.
 * Params: num = 8-byte number to swap.
 * Returns: Byte swapped number.
 */
pragma(inline, false) ulong bswap64(ulong num)
{
    version (X86) {
        version (Windows) {
            if (num) { // Temporary
                ubyte* p = cast(ubyte*)&num;
                ubyte c = *p;
                *p = *(p + 7);
                *(p + 7) = c;

                c = *(p + 1);
                *(p + 1) = *(p + 6);
                *(p + 6) = c;

                c = *(p + 2);
                *(p + 2) = *(p + 5);
                *(p + 5) = c;

                c = *(p + 3);
                *(p + 3) = *(p + 4);
                *(p + 4) = c;
            }
            return num;
//TODO: Fix bswap64 asm on Windows x86
            /*xchg EAX, EDX;
            bswap EAX;
            bswap EDX;
            ret;*/
        } else asm { naked; // System V
            xchg EAX, EDX;
            bswap EDX;
            bswap EAX;
            ret;
        }
    } else version (X86_64) {
        version (Windows) asm { naked;
            mov RAX, RCX;
            bswap RAX;
            ret;
        } else asm { naked; // System V AMD64 ABI
            mov RAX, RDI;
            bswap RAX;
            ret;
        }
    } else {
        if (num) {
            ubyte* p = cast(ubyte*)&num;
            ubyte c = *p;
            *p = *(p + 7);
            *(p + 7) = c;

            c = *(p + 1);
            *(p + 1) = *(p + 6);
            *(p + 6) = c;

            c = *(p + 2);
            *(p + 2) = *(p + 5);
            *(p + 5) = c;

            c = *(p + 3);
            *(p + 3) = *(p + 4);
            *(p + 4) = c;
        }
        return num;
    }
}

/**
 * Prints an array on screen.
 * Params:
 *   arr = Array pointer
 *   length = Array size
 */
void print_array(void* arr, size_t length) @nogc nothrow {
    import core.stdc.stdio : printf;
    ubyte* p = cast(ubyte*)arr;
    while (--length) printf("%02X ", *++p);
    printf("\n");
}