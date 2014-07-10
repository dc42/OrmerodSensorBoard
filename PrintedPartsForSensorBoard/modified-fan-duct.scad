// Fan duct without cable tie

overlap = 1;

difference() {
	translate([-160,0,-20.45]) import ("original-rrp-fan-duct.stl");
	translate([18,56.2,-overlap]) cube([50,20,10]);
}



