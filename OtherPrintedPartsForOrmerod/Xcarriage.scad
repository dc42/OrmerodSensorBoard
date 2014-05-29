// Ormerod X-carriage. This does not include mounting for the z-probe, because I use my hot-end sensor board instead.

useFSR = 0;			// set nonzero to include slot for FSR

overlap=1;			// used when adding/subtracting parts to avoid problems
lots=60;				// used for subtracting parts that need to extend beyond everything else
radius=10.65;			// redius to fit linear bearing
mxlPitch=2.032;		// tooth pitch of MXL belt
toothSize=1.2;		// side of cube we use for making teeth to grip the MXL belt
toothOffset=4.1;		// y-offset of teeth
nutTrapWidth=5.8;	// M3 nut is 5.4mm across flats, 6.1mm across widest point.
						// Setting nut trap width to 5.6mm, we actually got 5.3mm.
nutTrapDepth=3.0;	// M3 nut is 2.3mm thick. Allow at least 0.4mm extra.
slotXstart=29;
slotZ=4.3;
slotWidth=3;

difference () {
	union() {
		difference() {
			// Main body
			cube([45,31,57]);
			// Hole for linear bearing
			translate([4.4+radius,9.3+radius,-overlap]) cylinder(r=radius,h=60,$fn=100);
			translate([-overlap,26.2,-overlap]) cube([24,20,37+overlap]);
			translate([-overlap,28,-overlap]) cube([lots,20,37+overlap]);
			translate([11,19,9]) cube([lots,20,60]);
			translate([26.5,-overlap,9]) cube([lots,30,80]);
			translate([23,-overlap,9]) cube([lots,6.3+overlap,lots]);
			translate([-overlap,-overlap,48]) cube([lots,10+overlap,lots]);
			translate([9.5,-overlap,48]) cube([lots,25,lots]);
			translate([-overlap,26.2,37]) rotate([-45,0,0]) cube([lots,lots,lots]);
			translate([19.7+overlap,-overlap,-overlap]) cube([lots,5.8+overlap,20]);
			// Belt slot
			translate([12.5,4.25,-overlap]) cube([10,1.4,lots]);
			translate([12.5,3.6,-overlap]) cube([10,1,22+overlap]);
			translate([12.5,3.6,22]) rotate([-45,0,0]) cube([10,1,1]);

			// Slot for x-runner nut
			translate([slotXstart-2.3,11,slotZ-(nutTrapWidth/2)])
				cube([slotWidth+2.3+3,3.3,20]);
			// Slot for x-runner screw
			translate([slotXstart,0,slotZ-1.6]) cube([slotWidth,13,3.2]);
			translate([slotXstart,0,slotZ]) rotate([-90,0,0]) cylinder(r=1.6,h=13,$fn=12);
			translate([slotXstart+slotWidth,0,slotZ])
				rotate([-90,0,0]) cylinder(r=1.6,h=13,$fn=12);
			// Screw holes
			translate([-overlap,7,12.3]) rotate([0,90,0]) cylinder(r=1.6,h=10+overlap,$fn=14);
			translate([-overlap,7,12.3+15]) rotate([0,90,0]) cylinder(r=1.6,h=10+overlap,$fn=14);
			// Nut traps
			translate([2.8,-overlap,12.3-(nutTrapWidth/2)])
				cube([nutTrapDepth,10+overlap,nutTrapWidth]);
			translate([2.8,-overlap,12.3+15-(nutTrapWidth/2)])
				cube([nutTrapDepth,10+overlap,nutTrapWidth]);
			if (useFSR != 0)
			{
				// Separate runner screw slot from main body
				translate([21,0,-overlap]) rotate([0,0,-29.95]) cube([1,21.3,lots]);
				// Slot for FSR
				translate([38,0,-overlap]) cube([0.6,12,lots]);
				translate([38,12.5-overlap,-overlap]) rotate([0,0,34.8]) cube([0.8,7.87,lots]);
				translate([31.5,17.96,-overlap]) cube([1,5,lots]);
				translate([33.5,17.96,-overlap]) cube([1,5,lots]);
				// Shave off bottom corner
				translate([48,0,-overlap]) rotate([0,0,20]) cube([lots,lots,lots]);
			} else {
				// Shave off bottom corner
				translate([43,0,-overlap]) rotate([0,0,20]) cube([lots,lots,lots]);
				translate([38,0,-overlap]) cube([lots,lots,lots]);
			}
			translate([21,0,9]) rotate([0,0,-30]) cube([lots,25,lots]);
		}
		// Teeth to grip belt
		difference() {
			union () {
				translate([12.5-overlap,toothOffset,25])
					rotate([45,0,0]) cube([10,toothSize,toothSize]);
				translate([12.5-overlap,toothOffset,25+mxlPitch])
					rotate([45,0,0]) cube([10,toothSize,toothSize]);
				translate([12.5-overlap,toothOffset,25+2*mxlPitch])
					rotate([45,0,0]) cube([10,toothSize,toothSize]);
				translate([12.5-overlap,toothOffset,25+3*mxlPitch])
					rotate([45,0,0]) cube([10,toothSize,toothSize]);
			}
			// Blunt the teeth to allow sufficient belt clearance
			translate([12.5,toothOffset+0.6,-overlap]) cube([10,0.5,lots]);
		}
	}
	translate([19.5,-overlap,-overlap]) cube([6.1,6.3+overlap,60]);
}