// Modified Ormerod hot end heatsink duct with fixings for DC's hot end board

dualNozzle = false;			// set true for dual nozzle head, false for single nozzle
secondHotEndBoard = false;	// set true to add mountinh poits for a second hot end board at the other side

// Main configuration constants
fixingStripWidth = 9;
fixingStripThickness1 = (dualNozzle) ? 5.5 : 3;
fixingHoleDepth1 = fixingStripThickness1 + 2;
fixingHoleYoffset = 13.5;
fixingHoleZoffset = 9;

// Configuration constants for second board mounting
secondBoardOffset = 58;
fixingStripThickness2 = 5;
fixingHoleDepth2 = 5;

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
		if (secondHotEndBoard) {
			translate([secondBoardOffset - 1.5, fixingHoleYoffset, 0])
				fixingPoint(fixingStripThickness2 + 1.5); 
			translate([secondBoardOffset - 1.5, fixingHoleYoffset + 23, 0])
				fixingPoint(fixingStripThickness2 + 1.5); 
		}
	}
	translate([-fixingStripThickness1 - overlap, fixingHoleYoffset, fixingHoleZoffset])
		fixingHole(fixingHoleDepth1 + overlap);
	translate([-fixingStripThickness1 - overlap, fixingHoleYoffset + 23, fixingHoleZoffset])
		fixingHole(fixingHoleDepth1 + overlap);
	if (secondHotEndBoard) {
		translate([secondBoardOffset, fixingHoleYoffset, fixingHoleZoffset])
			fixingHole(fixingHoleDepth2 + overlap); 
		translate([secondBoardOffset, fixingHoleYoffset + 23, fixingHoleZoffset])
			fixingHole(fixingHoleDepth2 + overlap); 
	}
}



