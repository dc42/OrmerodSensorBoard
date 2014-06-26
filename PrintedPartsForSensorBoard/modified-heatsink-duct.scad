fixingStripWidth = 9;
fixingStripThickess = 3;
fixingHoleDepth = 5;
fixingHoleYoffset = 13.5;
fixingHoleZoffset = 9;
overlap = 1;

module fixingPoint() {
	translate([0,-fixingStripWidth/2,0])
		cube([fixingStripThickess+overlap,fixingStripWidth,14.4]);
}

module fixingHole() {
	translate([-overlap,0,0])
		rotate([0,90,0])
			cylinder(h=fixingHoleDepth+overlap,r=1.2, $fn=8);		// sensor board screw hole
}

difference() {
	union () {
		translate([-0.7,-111,-20.45]) import ("original-rrp-heatsink-duct.stl");
		translate([-fixingStripThickess, fixingHoleYoffset, 0]) fixingPoint();
		translate([-fixingStripThickess, fixingHoleYoffset + 23, 0]) fixingPoint();
	}
	translate([-fixingStripThickess, fixingHoleYoffset, fixingHoleZoffset])
		fixingHole();
	translate([-fixingStripThickess, fixingHoleYoffset + 23, fixingHoleZoffset])
		fixingHole();
}



