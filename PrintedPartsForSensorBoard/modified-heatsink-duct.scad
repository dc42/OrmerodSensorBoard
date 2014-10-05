// Modified Ormerod hot end heatsink duct with fixings for DC's hot end board

dualNozzle = true;			// set true for dual nozzle head, false for single nozzle

// Main configuration constants
fixingStripWidth = 9;
fixingStripThickness1 = (dualNozzle) ? 5.5 : 3;
fixingHoleDepth1 = fixingStripThickness1 + 2;
fixingHoleYoffset = 14.2;
fixingHoleZoffset = 9.5;

// Cable tie
cableTieThickness = 2.4;
cableTieWidth = 7;
cableTieHoleDiameter = 4;
cableTieXoffset = 44;
cableTieHoleYoffset1 = 5;
cableTieHoleYoffset2 = 12;


// Misc
overlap = 1;

module fixingPoint(thickness) {
	translate([0,-fixingStripWidth/2,0])
		cube([thickness,fixingStripWidth,14.4]);
}

module fixingHole(depth) {
	rotate([0,90,0])
		cylinder(h=depth,r=1.2, $fn=8);		// sensor board screw hole
}

difference() {
	union () {
		translate([-0.7,-111,-20.45]) import ("original-rrp-heatsink-duct.stl");
		translate([-fixingStripThickness1, fixingHoleYoffset, 0])
			fixingPoint(fixingStripThickness1+overlap);
		translate([-fixingStripThickness1, fixingHoleYoffset + 23, 0])
			fixingPoint(fixingStripThickness1+overlap);
		// cable tie point
		translate([cableTieXoffset - (cableTieWidth/2), -cableTieHoleYoffset2, 0])
			cube([cableTieWidth,cableTieHoleYoffset2 + overlap, cableTieThickness]);
		translate([cableTieXoffset, -cableTieHoleYoffset2, 0])
			cylinder(r=cableTieWidth/2, h=cableTieThickness, $fn=32);
	}
	translate([-fixingStripThickness1 - overlap, fixingHoleYoffset, fixingHoleZoffset])
		fixingHole(fixingHoleDepth1 + overlap);
	translate([-fixingStripThickness1 - overlap, fixingHoleYoffset + 23, fixingHoleZoffset])
		fixingHole(fixingHoleDepth1 + overlap);
	// cable tie hole
	translate([cableTieXoffset, -cableTieHoleYoffset1, -overlap])
		cylinder(r=cableTieHoleDiameter/2, h=cableTieThickness + 2*overlap, $fn=16);
	translate([cableTieXoffset, -cableTieHoleYoffset2, -overlap])
		cylinder(r=cableTieHoleDiameter/2, h=cableTieThickness + 2*overlap, $fn=16);
}



