# Customized ROM Monitor for the W65C816SXB Single-Board Computer
Based on the relocatable CC65 disassembly (https://github.com/timali/W65C816SXB-ROM-Disassembly).

# Overview
This is an improved version of the built-in ROM monitor. It supports all the features of the original monitor ROM, plus some extra niceties. It can be flashed to one of the spare flash banks on the W65C816SXB, and then used in place of the original factory ROM monitor.

These are the enhancements:

 1. Reduced ROM monitor code size, and moved it all to the last flash page, leaving the rest of the flash bank available for the user's application.
 2. Reduced the RAM usage, leaving more RAM for the user's application.
 3. Support automatically executing a user's application stored in flash upon reset.

# Memory Map
|Type   |Range      |Notes
|-------|-----------|---------------------------------------------
|RAM	|\$0000-\$7EBF|Available for user's application to use.
|RAM	|\$7EC0-\$7EDB|Reserved for the monitor's usage.
|RAM	|\$7EDC-\$7EE3|Raw vectors: override if necessary.
|RAM	|\$7EE4-\$7EFF|Shadow vectors: override to handle events.
|IO 	|\$7F00-\$7FFF|Hardware IO area.
|FLASH	|\$8000-\$EFFF|Free for user's application to use.
|FLASH	|\$F000-\$FFFF|Occupied by the monitor ROM.

# Auto-Execution of User Application
When the customized ROM monitor executes after a reset, it first initializes itself and the system VIA, which is used for communicating with the debugger software on the PC. Next, it checks the first three bytes of the flash memory. If it finds the sequence `WDC`, then it jumps to the following address, allowing the user's code to be automatically executed.
|Addr	|Value
|-------|-----
|$8000	|`W`
|$8001	|`D`
|$8002	|`C`
|$8003	|Control is transferred here

If the user's application does not override the default NMI raw vector, then the NMI button can be used to break the user's application for debugging.

# Flashing Instructions
The flash on the W65C816SXB can easily by flashed using `w65c816sxb-hacker` by Andrew Jacobs (https://github.com/andrew-jacobs/w65c816sxb-hacker). This tool allows you to change which flash bank is currently mapped into the CPU's address space, erase the flash bank, and reprogram sections of it using X-Modem.

It is probably a good idea not to overwrite the factory ROM monitor (which is flash bank 3), so this example demonstrates flashing the custom ROM monitor into flash bank 1.

 1. Load `w65c816sxb-hacker` into RAM using the WDC debugger, and execute it (see the project page for more details).
 2. Select flash bank 1 using the `R 1` command.
 3. Erase the flash bank using the `E` command.
 4. Transfer and flash the custom ROM monitor to address `$F000` using the `X F000` command.

At this point, the custom monitor is programmed into the flash bank 1. It could be executed at this point by using `w65c816sxb-hacker` to jump to the custom monitor, but whenever the `RESET` button is pressed, the flash ROM mapping will go back to the default, and map the original factory ROM monitor back into the address space. Therefore, you'll want to run a jumper wire from ground (pin 49 on the XBUS-16 connector) to `FAMS` (just below the flash part), which will ensure flash bank 1 is always selected, even after a reset.

# Example User Application
A small example of an auto-executed user application is included, based on the X-LED-FLASH example by WDC. This application can be built and then flashed into flash memory starting at address `$8000`. Once there, the custom ROM monitor will automatically execute the application upon reset, causing the four X LEDs to flash in a circular pattern.

# Erasing the User Application
Once an application is set to auto-execute, the custom ROM monitor will always execute it, so to erase the application, you must boot back into the original factory ROM monitor. This is done by removing the jumper wire from ground to `FAMS`, and then resetting the board. Once booted back into the original ROM monitor, you can load `w65c816sxb-hacker` and use it to erase flash bank 1, obliterating the custom ROM image and the user application.

# Future Enhancements
It would be nice if `w65c816sxb-hacker` allowed you to erase a range of flash addresses, instead of the entire flash bank. Then you could just erase the user application, without erasing the custom ROM image. 

It would also be nice if the custom ROM monitor looked for some input to determine whether to automatically execute the user's application. For example, maybe one of the GPIOs on the PIA.