// X-axis homing target for dc42's modulated IR

$fn=25;
thickness = 1.92;
screwPadThickness = 0.24;
padWidth=13;
padOffset = 28;
padHeight=11;
padDepth=22;
overlap=1;


difference() {
	union() {
		translate([15,10,0]) roundedRect([23,13,thickness], 3);
		translate([20,2,0]) cube([padOffset+padWidth-20,padHeight,thickness]);
		translate([padOffset,padHeight+2-thickness,thickness])
			cube([padWidth,thickness,padDepth]);
      	translate([padOffset,2,thickness])
			cube([thickness,padHeight,padDepth]);
		translate([5,5,thickness-overlap]) cylinder(h=screwPadThickness+overlap,r=3);
		translate([5,15,thickness-overlap]) cylinder(h=screwPadThickness+overlap,r=3);
	}
	translate([5,5,-overlap]) cylinder(h=thickness+screwPadThickness+2*overlap,r=1.5);
	translate([5,15,-overlap]) cylinder(h=thickness+screwPadThickness+2*overlap,r=1.5);
	translate([15,6,-overlap]) cube([8.5,8,thickness+2*overlap]);
	translate([padOffset-overlap,0,6])
		rotate([59,0,0]) cube([thickness+2*overlap,30,30]);
	translate([padOffset+thickness+9,2,-overlap]) cylinder(h=thickness+2*overlap,r=9,$fn=50);
	translate([padOffset+thickness+9,0,-overlap]) cube([10,11,thickness+2*overlap]);
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