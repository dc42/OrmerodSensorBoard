// Insulator for sensor board

$fn=40;

difference() {
	union() {
		cube([41,28,1.5]);
		translate([9,14,1]) cylinder(h=4,r=3.5);
		translate([9+23,14,1]) cylinder(h=4,r=3.5);
	}
	translate([9,14,-1]) cylinder(h=7,r=1.3);
	translate([9+23,14,-1]) cylinder(h=7,r=1.3);
	translate([9,14,-1]) cylinder(r1=3.2,r2=0,h=6.4);
	translate([9+23,14,-1]) cylinder(r1=3.2,r2=0,h=6.4);
	// cutout to allow in-situ programming
	translate([hole1X+1,holeY+4.5,-overlap]) cube([10,7.5,thickness+2*overlap]);
}