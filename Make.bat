set CC65_PATH=C:\code_projects\65x_C\6502\CC65\bin

%CC65_PATH%\ca65.exe -l bin\listing.txt W65c816SXB-Custom-ROM.s -o bin\W65c816SXB-Custom-ROM.o
%CC65_PATH%\ld65.exe -vm -m bin\map.txt -C W65c816SXB-Custom-ROM.cfg bin\W65c816SXB-Custom-ROM.o -o bin\W65c816SXB-Custom-ROM.bin

pause