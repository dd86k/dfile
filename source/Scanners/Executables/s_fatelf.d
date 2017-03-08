/*
 * s_fatelf.d : FatELF file scanner
 */

module s_fatelf;

import std.stdio;
import dfile;
import s_elf : ELF_e_machine;

private struct fat_header
{
    uint magic; // 0x1F0E70FA
    ushort version_;
    ubyte num_records;
    ubyte reserved0;
}

private struct fat_subheader_v1
{
    ELF_e_machine machine; /* maps to e_machine. */
    ubyte osabi;           /* maps to e_ident[EI_OSABI]. */ 
    ubyte osabi_version;   /* maps to e_ident[EI_ABIVERSION]. */
    ubyte word_size;       /* maps to e_ident[EI_CLASS]. */
    ubyte byte_order;      /* maps to e_ident[EI_DATA]. */
    ubyte reserved0;
    ubyte reserved1;
    ulong offset;
    ulong size;
}

void scan_fatelf(File file)
{
    fat_header fh;
    {
        import core.stdc.string : memcpy;
        ubyte[fh.sizeof] buf;
        file.rewind();
        file.rawRead(buf);
        memcpy(&fh, &buf, fh.sizeof);
    }

    report("FatELF", false);
    
    switch (fh.version_)
    {
        default:
            write(" with invalid version");
            break;
        case 1: {
            fat_subheader_v1 fhv1;
            {
                import core.stdc.string : memcpy;
                ubyte[fhv1.sizeof] buf;
                file.rawRead(buf);
                memcpy(&fhv1, &buf, fhv1.sizeof);
            }

            switch (fhv1.word_size)
            {
                case 1: write("32 "); break;
                case 2: write("64 "); break;
                default: write(" ");  break;
            }

            switch (fhv1.byte_order)
            {
                case 1: write("LE "); break;
                case 2: write("BE "); break;
                default: write(" ");  break;
            }

            switch (fhv1.osabi)
            {
            default:
                write("System V");
                break;
            case 0x01:
                write("HP-UX");
                break;
            case 0x02:
                write("NetBSD");
                break;
            case 0x03:
                write("Linux");
                break;
            case 0x06:
                write("Solaris");
                break;
            case 0x07:
                write("AIX");
                break;
            case 0x08:
                write("IRIX");
                break;
            case 0x09:
                write("FreeBSD");
                break;
            case 0x0C:
                write("OpenBSD");
                break;
            case 0x0D:
                write("OpenVMS");
                break;
            case 0x0E:
                write("NonStop Kernel");
                break;
            case 0x0F:
                write("AROS");
                break;
            case 0x10:
                write("Fenix OS");
                break;
            case 0x11:
                write("CloudABI");
                break;
            case 0x53:
                write("Sortix");
                break;
            }
                
            write(" binary for ");

            switch (fhv1.machine)
            {
            case ELF_e_machine.EM_NONE:
                write("no");
                break;
            case ELF_e_machine.EM_M32:
                write("AT&T WE 32100 (M32)");
                break;
            case ELF_e_machine.EM_SPARC:
                write("SPARC");
                break;
            case ELF_e_machine.EM_386:
                write("x86");
                break;
            case ELF_e_machine.EM_68K:
                write("Motorola 68000");
                break;
            case ELF_e_machine.EM_88K:
                write("Motorola 88000");
                break;
            case ELF_e_machine.EM_860:
                write("Intel 80860");
                break;
            case ELF_e_machine.EM_MIPS:
                write("MIPS RS3000");
                break;
            case ELF_e_machine.EM_POWERPC:
                write("PowerPC");
                break;
            case ELF_e_machine.EM_ARM:
                write("ARM");
                break;
            case ELF_e_machine.EM_SUPERH:
                write("SuperH");
                break;
            case ELF_e_machine.EM_IA64:
                write("IA64");
                break;
            case ELF_e_machine.EM_AMD64:
                write("x86-64");
                break;
            case ELF_e_machine.EM_AARCH64:
                write("AArch64");
                break;
            default:
                write("Unknown");
                break;
            }

            write(" machines");
        }
            break;
    }
    
    writeln();
}