// Insulator for sensor board with mounting for ultrasonic transducer

$fn=40;
thickness = 2;
holeY=14;
hole1X=16.5;
hole2X=hole1X+23;
transducerY = 4.5;
pillarHeight = 7.0;
transducerZ = 3.25;	// transducer is 0,5mm off the board
transducerR=5.1;
overlap=1;

difference() {
	union() {
		// main plate
		cube([63.5,28,thickness]);
		// pillars
		translate([hole1X,holeY,thickness-overlap]) cylinder(h=pillarHeight+overlap,r=4.5);
		translate([hole2X,holeY,thickness-overlap]) cylinder(h=pillarHeight+overlap,r=4.5);
		// transducer block
		translate([0,transducerY-7,0]) cube([8.3,14,pillarHeight+thickness-2.5]);
		// fillet between transducer block and plate
		translate([8.3,transducerY-7,0]) rotate([0,0,45]) cube([5,5,thickness]);
	}
	// screw holes in pillars
	translate([hole1X,holeY,-overlap]) cylinder(h=20,r=1.4);
	translate([hole2X,holeY,-overlap]) cylinder(h=20,r=1.4);
	// countersinks, leaving about 3mm of screw to tap into the heatsink duct
	translate([hole1X,holeY,pillarHeight-3.9]) cylinder(r1=2.65,r2=0,h=5.3);
	translate([hole2X,holeY,pillarHeight-3.9]) cylinder(r1=2.65,r2=0,h=5.3);
	// holes for the screw heads, overlapping the countersinks by 0.1mm
	translate([hole1X,holeY,-overlap]) cylinder(r=2.7,h=pillarHeight-3.8+overlap);
	translate([hole2X,holeY,-overlap]) cylinder(r=2.7,h=pillarHeight-3.8+overlap);
	// hole for the transducer
	translate([-overlap,transducerY,transducerZ]) rotate([0,90,0]) cylinder(r=transducerR,h=8.3);
	// holes for the transducer wires
	translate([0,transducerY-2.5,transducerZ]) rotate([0,90,0]) cylinder(r=1.1,h=10);
	translate([0,transducerY+2.5,transducerZ]) rotate([0,90,0]) cylinder(r=1.1,h=10);
	// cutout to allow in-situ programming
	translate([hole1X+1,holeY+4.5,-overlap]) cube([10,7.5,thickness+2*overlap]);
}