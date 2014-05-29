Other printed parts for Ormerod
===============================

This folder contains designs for the following printed parts, that are for the Ormerod but not for the sensor board:

1. PSU enclosure: this is an enclosure to cover the mains wiring and output wiring of a 12V 300W power supply sourced from eBay UK (http://www.ebay.co.uk/itm/UK-Stock-DC-12V-Universal-Regulated-Switching-Power-Supply-for-LED-Strip-CCTV-/161081134308?pt=UK_BOI_Electrical_Test_Measurement_Equipment_ET&var=&hash=item25812f0ce4). This replaces the ATX PSU supplied with the kit and supplies a more stable and adjustable 12V supply, which is useful when printing ABS. It accommodates a snap-in IEC mains inlet with switch and fuse, a neon indicator, and a 20A locking connector for the 12V output. All of these can be sourced from Maplin Electronics or from the usual component distributors.

2. Spacers for Matt's y-belt fastening posts. Y-belt slippage is a common problem with Ormerods, and Matt's y-belt mounts at https://github.com/iamburny/OrmerodUpgrades/blob/master/y-belt-clamp-v7.stl solve the problem. However, getting the y-belt tension right can be tricky because the y-belt length can only be adjusted in multiples of a whole tooth. One solution is to print Matt's y-belt tensioning device too. A simpler solution is to print these spacers to slip under the y-belt posts before tightening the mounting screws. There are 3 different thicknesses of spacer in this print, which can be used individually or in combination to get the right y-belt tension.

3. Fan inlet duct and finger guard. This is a variation on the fan inlet duct by Andy (kwikius), designed for the 7-bladed fan shipped with some Ormerod kits, and thin enough to allow the print head to slide past the Duet electronics enclosure in its normal position. His original design is here http://forums.reprap.org/read.php?340,287558,291659#msg-291659. Hint: when fitting the Duet enclosure, push the three T-nuts into the extrusion, then rotate the one nearest the y-motor into position, then push the Duet enclosure as far towards the y-motor as it will go. By rotating the nut first, you gain a few extra mm clearance between the enclosure and the hot end fan.

4. Ormerod button push: a pair of button pushers to allow the Erase and Reset buttons to be activated through the holes in the Duet enclosure back cover.

5. X-carriage: a re-working of the X-carriage in OpenScad. This version does not have the mounting points for the IR sensor, because my own IR sensor board is mounted on the hot end instead. It has an optional slot for a force-sensitive resistor, however the area around the slot needs reinforcing if you enable this option.
