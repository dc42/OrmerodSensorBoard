// Ormerod nozzle mount

numNozzles = 2;				// how many nozzles (must be 1 or 2)
nozzleSeparation2n = 14;	// spacing between nozzles, if more than one
width2n = 50;
nozzleScrewHoleSeparation2n = 40;
width1n = 38;
nozzleScrewHoleSeparation1n = 15;
nozzleScrewHoleOffset = 9;
fullDepth = 16;
mainDepth = 9;
height = 13;
smallHeight = 4.5;
xCarriageScrewHoleOffset = 7;
xCarriageScrewHoleSeparation = 15;
m3clearance = 3.4;
m3head = 6.5;
bowdenClearance = 5.2;

overlap = 1;
tinyOverlap = 0.01;
lots = 50;

width = (numNozzles == 2) ? width2n : width1n;
nozzleScrewHoleSeparation = (numNozzles == 2) 
									? nozzleScrewHoleSeparation2n : nozzleScrewHoleSeparation1n;

module xCarriageScrewHole() {
	translate([0,0,-overlap]) cylinder(r=m3clearance/2,h=height+2*overlap,$fn=24);
	translate([0,0,smallHeight-tinyOverlap]) cylinder(r=m3head/2,h=height+2*overlap,$fn=24);
	translate([0,0,smallHeight-(m3head-m3clearance)/2])
		cylinder(r1=m3clearance/2,r2=m3head/2,h=(m3head - m3clearance)/2,$fn=24);
}

module bowdenSlot() {
	translate([-overlap,0,0])
		union () {
			rotate([0,90,0]) cylinder(r=bowdenClearance/2,h=mainDepth + 2*overlap, $fn=24);
			translate([0,-bowdenClearance/2,0])
				cube([mainDepth + 2*overlap,bowdenClearance,lots]);
		}
}

difference () {
	translate([0,-width/2,0])
		union () {
 			cube([fullDepth,width,smallHeight]);
			cube([mainDepth,width,height]);
		}
	translate([mainDepth,-width/2,-overlap])
		rotate([0,0,-45]) cube([20,20,smallHeight+2*overlap]);
	translate([mainDepth,width/2,-overlap])
		rotate([0,0,-45]) cube([20,20,smallHeight+2*overlap]);
	translate([xCarriageScrewHoleOffset,xCarriageScrewHoleSeparation/2,0])
		xCarriageScrewHole();
	translate([xCarriageScrewHoleOffset,-xCarriageScrewHoleSeparation/2,0])
		xCarriageScrewHole();
	translate([-overlap,-nozzleScrewHoleSeparation/2,nozzleScrewHoleOffset])
		rotate([0,90,0]) cylinder(r=m3clearance/2,h=mainDepth + 2*overlap, $fn=24);
	translate([-overlap,nozzleScrewHoleSeparation/2,nozzleScrewHoleOffset])
		rotate([0,90,0]) cylinder(r=m3clearance/2,h=mainDepth + 2*overlap, $fn=24);
	if (numNozzles == 2) {
		translate([0,-nozzleSeparation2n/2,nozzleScrewHoleOffset]) bowdenSlot();
		translate([0,nozzleSeparation2n/2,nozzleScrewHoleOffset]) bowdenSlot();
	} else {
		translate([0,0,nozzleScrewHoleOffset]) bowdenSlot();
	}
}
