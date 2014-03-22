This folder contains the following files:

<ul>
<li>OrmerodSensor.cppproj - Atmel Studio 6 project file</li>
<li>OrmerodSensor.cpp - source code</li>
<li>ecv.h - macros to make the Design-by-Contract annotations (for Escher C Verifier) in the source code invisible to the compiler</li>
</ul>

The ATTINY45A fuse settings required are: low 0xFF, high 0xDF, extended 0xFF.

The source code and the above fuse settings assume that the 12MHz ceramic resonator is fitted on the board. If the ultrasonic functionality is not required then it should be possible to omit the resonator and use the internal 8MHz clock, by changing F_CPU in the source code to 8000000uL and adjusting the fuse settings appropriately.
