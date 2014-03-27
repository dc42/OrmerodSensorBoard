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
		cube([63.5,28,thickness]);
		translate([hole1X,holeY,thickness-overlap]) cylinder(h=pillarHeight+overlap,r=4.5);
		translate([hole2X,holeY,thickness-overlap]) cylinder(h=pillarHeight+overlap,r=4.5);
		translate([0,transducerY-7,0]) cube([8.3,14,pillarHeight+thickness-2.5]);
		translate([8.3,transducerY-7,0]) rotate([0,0,45]) cube([5,5,thickness]);
	}
	translate([hole1X,holeY,-overlap]) cylinder(h=20,r=1.4);
	translate([hole2X,holeY,-overlap]) cylinder(h=20,r=1.4);
	translate([hole1X,holeY,pillarHeight-2.9]) cylinder(r1=2.65,r2=0,h=5.3);
	translate([hole2X,holeY,pillarHeight-2.9]) cylinder(r1=2.65,r2=0,h=5.3);
	translate([hole1X,holeY,-overlap]) cylinder(r=2.65,h=pillarHeight-2.8+overlap);
	translate([hole2X,holeY,-overlap]) cylinder(r=2.65,h=pillarHeight-2.8+overlap);
	translate([-overlap,transducerY,transducerZ]) rotate([0,90,0]) cylinder(r=transducerR,h=8.3);
	translate([0,transducerY-2.5,transducerZ]) rotate([0,90,0]) cylinder(r=1.1,h=10);
	translate([0,transducerY+2.5,transducerZ]) rotate([0,90,0]) cylinder(r=1.1,h=10);
}