This folder contains the following files:

OrmerodSensor.cppproj - Atmel Studio 6 project file
OrmerodSensor.cpp - source code, configured for ATTiny45A with 12MHz ceramic resonator
ecv.h - macros to make the Verified design-by-Contract annotations in the source code invisible to the compiler

The ATTiny45A fuse settings required when the ceramic resonator is fitted are: low 0xFF, high 0xDF, extended 0xFF.

If the ultrasonic functionality is not required then it should be possible to use the internal 8MHz clock, by changing F_CPU in the source code and adjusting the fuse settings.