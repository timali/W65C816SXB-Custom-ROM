set CC65_PATH=C:\code_projects\65x_C\6502\CC65\bin

%CC65_PATH%\ca65.exe -l bin\listing.txt X-LED-Flash.s -o bin\X-LED-Flash.o
%CC65_PATH%\ld65.exe -vm -m bin\map.txt -C W65c816SXB-Custom-ROM-App.cfg bin\X-LED-Flash.o -o bin\X-LED-Flash.bin

pause