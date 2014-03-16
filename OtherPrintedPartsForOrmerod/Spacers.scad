// Spacer for Matt's y-belt mounts

module spacer(thickness)
{
	difference() {
		cube([21,24,thickness]);
		translate([3,5,-1]) cube([4,20,thickness+2]);
		translate([5,5,-1]) cylinder(h=thickness+2,r=2, $fn=20);
	}
}

translate([-22,2,0]) spacer(1.5);

translate([2,2,0]) spacer(1.0);

translate([-22,-26,0]) spacer(0.5);
