/*
 * s_elf.d : ELF format Scanner
 */

module s_elf;

import std.stdio;
import dfile;
import utils;

private struct Elf32_Ehdr
{
    public ubyte[EI_NIDENT] e_ident;
    public ushort e_type;
    public ushort e_machine;
    public uint e_version;
    public uint e_entry;
    public uint e_phoff;
    public uint e_shoff;
    public uint e_flags;
    public ushort e_ehsize;
    public ushort e_phentsize;
    public ushort e_phnum;
    public ushort e_shentsize;
    public ushort e_shnum;
    public ushort e_shstrndx;
}

private enum {
    EI_CLASS = 4,
    EI_DATA = 5,
    EI_OSABI = 7,
    EI_NIDENT = 16,
    EV_NONE = 0,
    EV_CURRENT = 1,
    ET_NONE = 0,        // No file type
    ET_REL = 1,         // Relocatable file
    ET_EXEC = 2,        // Executable file
    ET_DYN = 3,         // Shared object file
    ET_CORE = 4,        // Core file
    ET_LOPROC = 0xFF00, // Processor-specific
    ET_HIPROC = 0xFFFF  // Processor-specific
}

enum : ushort // Public for FatELF
{
    EM_NONE = 0,  // No machine
    EM_M32 = 1,   // AT&T WE 32100
    EM_SPARC = 2, // SPARC
    EM_386 = 3,   // Intel Architecture
    EM_68K = 4,   // Motorola 68000
    EM_88K = 5,   // Motorola 88000
    EM_860 = 7,   // Intel 80860
    EM_MIPS = 8,  // MIPS RS3000
    EM_MIPS_RS4_BE = 10, // MIPS RS4000 Big-Endian
    // Rest is from http://wiki.osdev.org/ELF
    EM_POWERPC = 0x14,
    EM_ARM = 0x28,
    EM_SUPERH = 0xA2,
    EM_IA64 = 0x32,
    EM_AMD64 = 0x3E,
    EM_AARCH64 = 0xB7
}

static void scan_elf(File file)
{
    if (Debugging)
        writefln("L%04d: Started scanning ELF file", __LINE__);

    Elf32_Ehdr h;
    structcpy(file, &h, h.sizeof, true);

    if (Debugging)
    {
        write("e_ident: ");
        foreach (c; h.e_ident) writef("%02X ", c);
        writeln();
    }

    if (Debugging || Informing)
    {
        writefln("type: %s", h.e_type);
        writefln("machine: %s", h.e_machine);
        writefln("version: %s", h.e_version);
        writefln("entry: %s", h.e_entry);
        writefln("phoff: %s", h.e_phoff);
        writefln("shoff: %s", h.e_shoff);
        writefln("flags: %s", h.e_flags);
        writefln("ehsize: %s", h.e_ehsize);
        writefln("phentsize: %s", h.e_phentsize);
        writefln("phnum: %s", h.e_phnum);
        writefln("shentsize: %s", h.e_shentsize);
        writefln("shnum: %s", h.e_shnum);
        writefln("shstrndx: %s", h.e_shstrndx);
    }
    
    report("ELF", false);
    elf_print_class(h.e_ident[EI_CLASS]);
    elf_print_data(h.e_ident[EI_DATA]);
    elf_print_osabi(h.e_ident[EI_OSABI]);
    write(" ");
    elf_print_type(h.e_type);
    write(" file for ");
    elf_print_machine(h.e_machine);
    writeln(" machines");
}

void elf_print_class(ubyte c)
{
    switch (c)
    {
    case 1: write("32 "); break;
    case 2: write("64 "); break;
    default: write(" (Invalid class) ");  break;
    }
}

void elf_print_data(ubyte c)
{
    switch (c)
    {
    case 1: write("LE "); break;
    case 2: write("BE "); break;
    default: write("(Invalid encoding) ");  break;
    }
}

void elf_print_osabi(ubyte c)
{
    switch (c)
    {
    default:   write("System V"); break;
    case 0x01: write("HP-UX"); break;
    case 0x02: write("NetBSD"); break;
    case 0x03: write("Linux"); break;
    case 0x06: write("Solaris"); break; 
    case 0x07: write("AIX"); break;
    case 0x08: write("IRIX"); break;
    case 0x09: write("FreeBSD"); break;
    case 0x0C: write("OpenBSD"); break;
    case 0x0D: write("OpenVMS"); break;
    case 0x0E: write("NonStop Kernel"); break;
    case 0x0F: write("AROS"); break;
    case 0x10: write("Fenix OS"); break;
    case 0x11: write("CloudABI"); break;
    case 0x53: write("Sortix"); break;
    }
}

void elf_print_type(ushort c)
{
    switch (c)
    {
    default:
    case ET_NONE:   write("(No file type)"); break;
    case ET_REL:    write("Relocatable"); break;
    case ET_EXEC:   write("Executable"); break;
    case ET_DYN:    write("Shared object"); break;
    case ET_CORE:   write("Core"); break;
    case ET_LOPROC: write("Professor-specific (LO)"); break;
    case ET_HIPROC: write("Professor-specific (HI)"); break;
    }
}

void elf_print_machine(ushort c)
{
    switch (c)
    {
    case EM_NONE:    write("no"); break;
    case EM_M32:     write("AT&T WE 32100 (M32)"); break;
    case EM_SPARC:   write("SPARC"); break;
    case EM_860:     write("Intel 80860"); break;
    case EM_386:     write("x86"); break;
    case EM_IA64:    write("IA64"); break;
    case EM_AMD64:   write("x86-64"); break;
    case EM_68K:     write("Motorola 68000"); break;
    case EM_88K:     write("Motorola 88000"); break;
    case EM_MIPS:    write("MIPS RS3000"); break;
    case EM_POWERPC: write("PowerPC"); break;
    case EM_ARM:     write("ARM"); break;
    case EM_SUPERH:  write("SuperH"); break;
    case EM_AARCH64: write("AArch64"); break;
    default:         write("Unknown"); break;
    }
}