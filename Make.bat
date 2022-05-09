set CC65_PATH=C:\code_projects\65x_C\6502\CC65\bin

%CC65_PATH%\ca65.exe -l listing.txt W65c816SXB-Monitor.s
%CC65_PATH%\ld65.exe -vm -m map.txt -C W65c816SXB-Monitor.cfg W65c816SXB-Monitor.o -o W65c816SXB-Monitor.bin

pause