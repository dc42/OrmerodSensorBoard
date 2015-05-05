//Ormerod Duet enclosure measurement
// RJT 16 May 2014
//measure model is just for finding measurements of the existing reprap stl
module measure(points) {
	translate([-0.87,-1.32,-20.45]) import("Duet-enclosure.stl");
	if(points) { //set true to see measure position objects
		//origin check and base depth = 3.0
		translate([0,0,0]) cube([5,5,3.0]);
		//height = 23.5, ethernet offset 10.45
		translate([0,0,23.5]) cube([5,10.45,5]);
		//x length = 131
		translate([131,0,0]) cube(5);
		//y length = 108
		translate([0,108.0,0]) cube(5);
		//insideright1 = 2.0, lip height = 23.5 -19.8 = 3.7, retainer height = 23.0
		translate([2.0,5,19.8]) cube([2,5,3.20]);
		//insideright2 = 3.0
		translate([3.0,3.0,15]) cube([2,5,2]);
		//insideright3 = 3.0
		translate([6.0,20.0,0]) cube([5,5,5]);
		//insideleft2 = 126, insideleft1 will be 127
		translate([123,5,15]) cube([3,5,2]);
		//bottom cutout x11.5-3=8.5 width 106.0
		translate([11.5,105,0]) cube([106.0,5,2]);
		//footslot offset 2.1, 3,6 from top, 5.0 wide
		translate([2.1,107,19.9]) cube([5.0,3,10]);
		//ethernet width = y27.5 - 10.45 = 17.05
		translate([0,27.5,23.5]) cube([5,5,5]);
		//sd slot offset y35-3 =32 z4.75-3=1.75,35.0 w=13, h= 2.6
		translate([0,35.0,4.75]) cube([5,13.0,2.6]);
		//usb slot offset y50-3.0=47.0 z3-3=0 w=12.5, h=6.5
		translate([0,50.0,5]) cube([5,12.5,1.0]);
		translate([0,56.25,3.0]) cube([5,2,6.5]);
		//power slot offset y52.0-3=49 z6-3=3 w=12.5, h=6.0
		translate([129,52.0,8.0]) cube([5,12.5,1.0]);
		translate([129,56.25,6.0]) cube([5,2,6.0]);
		//Holes
		//LB 8,8 inner radius 2.0 outer 4.1
		translate([8,8,0]) cylinder(h=5,r=4.1);
		//LT 8,100
		translate([8,100,0]) cylinder(h=5,r=2.0);
		//RB 123,8
		translate([123,8,0]) cylinder(h=5,r=2.0);
		//RT 123,100
		translate([123,100,0]) cylinder(h=5,r=2.0);
		//RT 123,100
		translate([123,100,0]) cylinder(h=5,r=2.0);
		//EX 123,100
		translate([136,80,0]) cylinder(h=5,r=2.0);
	}
}

//measure(true);
