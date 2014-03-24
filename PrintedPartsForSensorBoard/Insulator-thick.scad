// Insulator for sensor board

$fn=40;

difference() {
	union() {
		cube([56,28,2]);
		translate([9,14,1]) cylinder(h=6.5,r=4.5);
		translate([9+23,14,1]) cylinder(h=6.5,r=4.5);
	}
	translate([9,14,-1]) cylinder(h=20,r=1.35);
	translate([9+23,14,-1]) cylinder(h=20,r=1.35);
	translate([9,14,2.1]) cylinder(r1=2.6,r2=0,h=6.4);
	translate([9+23,14,2.1]) cylinder(r1=2.6,r2=0,h=6.4);
	translate([9,14,-1]) cylinder(r=2.6,h=3.2);
	translate([9+23,14,-1]) cylinder(r=2.6,h=3.2);
	translate([-1,-1,-1]) cube([13,6,4]);
}