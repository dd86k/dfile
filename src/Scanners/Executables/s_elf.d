/*
 * s_elf.d : ELF format Scanner
 */

module s_elf;

import core.stdc.stdio;
import dfile;

private struct Elf32_Ehdr {
    ubyte[EI_NIDENT-4] e_ident;
    ushort e_type;
    ushort e_machine;
    uint e_version;
    uint e_entry;
    uint e_phoff;
    uint e_shoff;
    uint e_flags;
    ushort e_ehsize;
    ushort e_phentsize;
    ushort e_phnum;
    ushort e_shentsize;
    ushort e_shnum;
    ushort e_shstrndx;
}

private enum {
    EI_CLASS = 4,
    EI_DATA = 5,
    EI_OSABI = 7,
    EI_NIDENT = 16,
    EV_NONE = 0,
    EV_CURRENT = 1,
    ET_NONE = 0,        /// No file type
    ET_REL = 1,         /// Relocatable file
    ET_EXEC = 2,        /// Executable file
    ET_DYN = 3,         /// Shared object file
    ET_CORE = 4,        /// Core file
    ET_LOPROC = 0xFF00, /// Processor-specific
    ET_HIPROC = 0xFFFF  /// Processor-specific
}

enum : ushort { // Public for FatELF
    EM_NONE = 0,  /// No machine
    EM_M32 = 1,   /// AT&T WE 32100
    EM_SPARC = 2, /// SPARC
    EM_386 = 3,   /// Intel Architecture
    EM_68K = 4,   /// Motorola 68000
    EM_88K = 5,   /// Motorola 88000
    EM_860 = 7,   /// Intel 80860
    EM_MIPS = 8,  /// MIPS RS3000
    EM_MIPS_RS4_BE = 10, /// MIPS RS4000 Big-Endian
    // Rest is from http://wiki.osdev.org/ELF
    EM_POWERPC = 0x14, /// PowerPC
    EM_ARM = 0x28,     /// ARM
    EM_SUPERH = 0xA2,  /// SuperH
    EM_IA64 = 0x32,    /// Intel IA64
    EM_AMD64 = 0x3E,   /// x86-64
    EM_AARCH64 = 0xB7  /// 64-bit ARM
}

/// Scan an ELF image
void scan_elf()
{
    debug dbg("Started scanning ELF file");

    Elf32_Ehdr h;
    //rewind(fp);
    fread(&h, h.sizeof, 1, fp);

    debug
    {
        import utils : print_array;
        dbgl("e_ident: ");
        print_array(&h.e_ident, h.e_ident.length);
        printf("\n");
    }

    report("ELF", false);
    elf_print_class(h.e_ident[EI_CLASS-4]);
    elf_print_data(h.e_ident[EI_DATA-4]);
    elf_print_osabi(h.e_ident[EI_OSABI-4]);
    printf(" ");
    elf_print_type(h.e_type);
    printf(" for ");
    elf_print_machine(h.e_machine);
    printf(" machines\n");

    if (More) {
        printf("e_type: %X\n", h.e_type);
        printf("e_machine: %X\n", h.e_machine);
        printf("e_version: %X\n", h.e_version);
        printf("e_entry: %X\n", h.e_entry);
        printf("e_phoff: %X\n", h.e_phoff);
        printf("e_shoff: %X\n", h.e_shoff);
        printf("e_flags: %X\n", h.e_flags);
        printf("e_ehsize: %X\n", h.e_ehsize);
        printf("e_phentsize: %X\n", h.e_phentsize);
        printf("e_phnum: %X\n", h.e_phnum);
        printf("e_shentsize: %X\n", h.e_shentsize);
        printf("e_shnum: %X\n", h.e_shnum);
        printf("e_shstrndx: %X\n", h.e_shstrndx);
    }
}

// These functions are also used by FATELF.

/**
 * Print the ELF's class type (32/64-bit)
 * Params: c = Unsigned byte
 */
void elf_print_class(ubyte c)
{
    switch (c) {
    case 1: printf("32 "); break;
    case 2: printf("64 "); break;
    default: printf(" (Invalid class) ");  break;
    }
}

/**
 * Print the ELF's data type (LE/BE)
 * Params: c = Unsigned byte
 */
void elf_print_data(ubyte c)
{
    switch (c) {
    case 1: printf("LE "); break;
    case 2: printf("BE "); break;
    default: printf("(Invalid encoding) ");  break;
    }
}

/**
 * Print the ELF's OS ABI (calling convention)
 * Params: c = Unsigned byte
 */
void elf_print_osabi(ubyte c)
{
    switch (c) {
    default:   printf("Unknown DECL"); break;
    case 0x00: printf("System V"); break;
    case 0x01: printf("HP-UX"); break;
    case 0x02: printf("NetBSD"); break;
    case 0x03: printf("Linux"); break;
    case 0x06: printf("Solaris"); break; 
    case 0x07: printf("AIX"); break;
    case 0x08: printf("IRIX"); break;
    case 0x09: printf("FreeBSD"); break;
    case 0x0C: printf("OpenBSD"); break;
    case 0x0D: printf("OpenVMS"); break;
    case 0x0E: printf("NonStop Kernel"); break;
    case 0x0F: printf("AROS"); break;
    case 0x10: printf("Fenix OS"); break;
    case 0x11: printf("CloudABI"); break;
    case 0x53: printf("Sortix"); break;
    }
}

/**
 * Print the ELF's type (exec/lib/etc.)
 * Params: c = Unsigned byte
 */
void elf_print_type(ushort c)
{
    switch (c) {
    default:        printf("Unknown Type"); break;
    case ET_NONE:   printf("(No file type)"); break;
    case ET_REL:    printf("Relocatable"); break;
    case ET_EXEC:   printf("Executable"); break;
    case ET_DYN:    printf("Shared object"); break;
    case ET_CORE:   printf("Core"); break;
    case ET_LOPROC: printf("Professor-specific (LO)"); break;
    case ET_HIPROC: printf("Professor-specific (HI)"); break;
    }
}

/**
 * Print the ELF's machine type (system)
 * Params: c = Unsigned byte
 */
void elf_print_machine(ushort c)
{
    switch (c) {
    case EM_NONE:    printf("no"); break;
    case EM_M32:     printf("AT&T WE 32100 (M32)"); break;
    case EM_SPARC:   printf("SPARC"); break;
    case EM_860:     printf("Intel 80860"); break;
    case EM_386:     printf("x86"); break;
    case EM_IA64:    printf("IA64"); break;
    case EM_AMD64:   printf("x86-64"); break;
    case EM_68K:     printf("Motorola 68000"); break;
    case EM_88K:     printf("Motorola 88000"); break;
    case EM_MIPS:    printf("MIPS RS3000"); break;
    case EM_POWERPC: printf("PowerPC"); break;
    case EM_ARM:     printf("ARM"); break;
    case EM_SUPERH:  printf("SuperH"); break;
    case EM_AARCH64: printf("ARM (64-bit)"); break;
    default:         printf("Unknown Machine"); break;
    }
}