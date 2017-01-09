# dfile - Simple file scanner

dfile is a simple file scanner that is very similar to the UNIX `file` utility.

Don't be shy to request more formats or format scans (e.g. PE32 gives more details)!

It currently recognizes quite a few signatures.

It tells more details of:
- Game files
  - PWAD/IWAD
  - GTA Text files
  - RPF GTA archives

It does a detailed scan of:
- Exectuable files
  - LE/LX (OS/2)
  - NE (MS-DOS 4.x - Windows 3.x)
  - PE32/PE32+ (Win32)
  - ELF (POSIX)
  - Mach-O (macOS)

File formats I wish to implement:
- Exectuable files
  - [OS/360](https://en.wikipedia.org/wiki/OS/360_Object_File_Format)
  - [a.out](https://en.wikipedia.org/wiki/A.out)