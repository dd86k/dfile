/*
 * s_fatelf.d : FatELF file scanner
 */

module s_fatelf;

import std.stdio;
import dfile;
import s_elf;
import utils;

private struct fat_header
{
    uint magic; // 0x1F0E70FA
    ushort version_;
    ubyte num_records;
    ubyte reserved0;
}

private struct fat_subheader_v1
{
    ushort machine; /* maps to e_machine. */
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
    structcpy(file, &fh, fh.sizeof, true);

    report("FatELF", false);
    
    switch (fh.version_)
    {
        default:
            write(" with invalid version");
            break;
        case 1: {
            fat_subheader_v1 fhv1;
            structcpy(file, &fhv1, fhv1.sizeof);

            elf_print_class(fhv1.word_size);
            elf_print_data(fhv1.byte_order);
            elf_print_osabi(fhv1.osabi);
            write(" binary for ");
            elf_print_machine(fhv1.machine);
            write(" machines");
        }
            break;
    }
    
    writeln();
}