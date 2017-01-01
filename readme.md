# dfile - Simple file scanner

dfile is a simple file scanner that is very similar to the UNIX `file` utility. It scans the file for a signature and will try to tell the nature of the file. I thought of making this as a native alternative mostly for Windows and adding some details here and there. The main focus was kinda executable files. Hopefully I could do more in the future.

Mostly lazy with a lot of formats, but don't be shy to request formats.

## Examples
```
D:\DOCUMENTS\D projects\dfile>dfile tests\1427685430088.webm
tests\1427685430088.webm: Matroska media container (mkv, webm)

D:\DOCUMENTS\D projects\dfile>dfile tests\aaaaah.jpg
tests\aaaaah.jpg: Joint Photographic Experts Group image (JPEG)

D:\DOCUMENTS\D projects\dfile>dfile tests\asciifull.png
tests\asciifull.png: Portable Network Graphics image (PNG)

D:\DOCUMENTS\D projects\dfile>dfile "tests\Azumanga Diaoh OP Creditless.mkv"
tests\Azumanga Diaoh OP Creditless.mkv: Matroska media container (mkv, webm)

D:\DOCUMENTS\D projects\dfile>dfile "tests\Battlefield 1 - Metal Frenzy.mp3"
tests\Battlefield 1 - Metal Frenzy.mp3: MPEG-2 Audio Layer III audio file (MP3)

D:\DOCUMENTS\D projects\dfile>dfile tests\CIL.exe
tests\CIL.exe: PE32 (GUI) Windows Executable (EXE) for x86 systems

D:\DOCUMENTS\D projects\dfile>dfile tests\dfile
tests\dfile: ELF64 Executable file for x86-64 (Little-endian) systems

D:\DOCUMENTS\D projects\dfile>dfile tests\dfile.exe
tests\dfile.exe: PE32 (CUI) Windows Executable (EXE) for x86 systems

D:\DOCUMENTS\D projects\dfile>dfile tests\SETUP.EXE
tests\SETUP.EXE: NE Executable (Windows) with 8086 instructions

D:\DOCUMENTS\D projects\dfile>dfile tests\BPIU.EXE
tests\BPIU.EXE: LX Program module (OS/2), Intel 80386 CPU and up

D:\DOCUMENTS\D projects\dfile>dfile tests\DOOM2.WAD
tests\DOOM2.WAD: PWAD holding 2935 entries at DF767Dh
```