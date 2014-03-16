OrmerodSensorBoard
==================

Here are the design files for my Z-height sensor board add-on to the RepRapPro Ormerod 3D printer. This board replaces the original IR sensor board used for Z-probing. It has the following advantages over the original:

1. It uses modulated infrared light, which makes it much less sensitive to ambient infrared such as is found in sunlight and in incandescent artificial light.
2. The sensor board is mounted on the hot end so that the sensor head is in-line with the nozzle in the x-direction. This makes it much less sensitive to variations in head sag.
3. The board includes the facility to mount the hot end connectors, eliminating the need for the original 6-pin connector. The new connectors are more reliable and more easily disassembled. In particular, the crimp receptacles can more easily be removed from the connector shell.
4. The board can accommodate three Cree LEDs to direct light on the work being printed. Alternatively, it can provide 12V power to an LED strip, or a constant-current supply to external LEDs.
5. The board includes provision for thermostatic control of the hot end fan. The fan is turned on when the hot end temperature exceeds approximately 42C, or when the board detects a hot end temperature measurement fault.
6. The board can also support an experimental ultrasonic sensor. This allows z-probing to be done anywhere on the bed. Due to variation in the speed of sound with temperature, the ultrasonic sensor is a little temperature-sensitive, but this can be compensated in the firmware.

Work is in progress to adapt the board for capacitive height sensing.

For assembly and usage instructions, please visit: http://miscsolutions.wordpress.com/assembling-and-using-the-eschertech-ormerod-hot-end-board/

I supply bare boards, kits of parts with all SMD components ready-mounted, and fully assembled boards. Contact me via the RepRap Ormerod forum at http://forums.reprap.org/list.php?340 by sending a personal message to dc42.


