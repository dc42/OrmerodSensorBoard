// Insulator for sensor board with mounting for ultrasonic transducer

DualNozzle = false;

$fn=40;
thickness = 2;
holeY=14;
hole1X=16.5;
hole2X=hole1X+23;
transducerY = 4.5;
pillarHeight = (DualNozzle) ? 2.25 : 4.0;
pillarRadius = 4.0;	// use 4.5 if using deep countersinks
countersinkStart = (pillarHeight > 3.9) ? pillarHeight - 3.9 : 0;
overlap=1;

difference() {
	union() {
		// main plate
		cube([63.5,28,thickness]);
		// pillars
		translate([hole1X,holeY,thickness-overlap]) cylinder(h=pillarHeight+overlap,r=pillarRadius);
		translate([hole2X,holeY,thickness-overlap]) cylinder(h=pillarHeight+overlap,r=pillarRadius);
	}
	// screw holes in pillars
	translate([hole1X,holeY,-overlap]) cylinder(h=20,r=1.4);
	translate([hole2X,holeY,-overlap]) cylinder(h=20,r=1.4);
	// countersinks, leaving about 3mm of screw to tap into the heatsink duct
	translate([hole1X,holeY,countersinkStart]) cylinder(r1=2.65,r2=0,h=5.3);
	translate([hole2X,holeY,countersinkStart]) cylinder(r1=2.65,r2=0,h=5.3);
	// holes for the screw heads, overlapping the countersinks by 0.1mm
	translate([hole1X,holeY,-overlap]) cylinder(r=2.7,h=countersinkStart+0.1+overlap);
	translate([hole2X,holeY,-overlap]) cylinder(r=2.7,h=countersinkStart+0.1+overlap);
	// cutout to allow in-situ programming
	translate([hole1X+1,holeY+4.5,-overlap]) cube([10,7.5,thickness+2*overlap]);
}