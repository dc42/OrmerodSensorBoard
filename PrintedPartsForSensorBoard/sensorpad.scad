// X-axis homing target for dc42's modulated IR

$fn=25;
thickness = 2;


difference() {
	union() {
		translate([15,10,0]) roundedRect([23,13,thickness], 3);
		translate([20,2,0]) cube([30,10,thickness]);
		translate([40,12-thickness,thickness]) cube([10,thickness,25]);
       	translate([44,2,thickness]) cube([thickness,10-thickness,15]);
		translate([5,5,thickness]) cylinder(h=1,r=3);
		translate([5,15,thickness]) cylinder(h=1,r=3);
	}
	translate([5,5,0]) cylinder(h=thickness+1,r=1.7);
	translate([5,15,0]) cylinder(h=thickness+1,r=1.7);
	translate([15,6,0]) cube([8.5,8,thickness]);
	translate([44,0,9]) rotate([45,0,0]) cube([thickness,12,12]);
	translate([53,-7,0]) rotate([0,0,45]) cube([10,10,thickness]);
	
}

module roundedRect(size, radius)
{
	x = size[0];
	y = size[1];
	z = size[2];

	linear_extrude(height=z)
	hull()
	{
		// place 4 circles in the corners, with the given radius
		translate([(-x/2)+(radius/2), (-y/2)+(radius/2), 0])
		circle(r=radius);
	
		translate([(x/2)-(radius/2), (-y/2)+(radius/2), 0])
		circle(r=radius);
	
		translate([(-x/2)+(radius/2), (y/2)-(radius/2), 0])
		circle(r=radius);
	
		translate([(x/2)-(radius/2), (y/2)-(radius/2), 0])
		circle(r=radius);
	}
}