// Original design by Matt (iamburny)
// Changes by dc42:
// 1. Increased thickness of cable trap from 1.5mm to 2mm because mine broke
// 2. Replaced tie wrap T at top centre by tie wrap hole at top right

$fs=0.8; // def 1, 0.2 is high res
$fa=4;//def 12, 3 is very nice
%translate([0,0,-0.5])cube([200,200,1],center=true); //build platform

irSensorOffset = 0.5;
sc = 32; //Screw Centres
wall=2;
hole = 37.5;  //fan hole
x=42;
y=x;
z=15.10;
heo = 2.5; //hot end offset
hbr = 16; //heat block recess

size=11; // size of the ball joint
joint_spacing =0; // some space between them?
joint_thickness = 3; // thickness of the arms - was 2
joint_arms = 2; // how many arms do you want?
arm_width = 5; // actually: how much is removed from the arms Larger values will remove more - was 10

ventB=(x/2)-(hbr/2)+heo-2;
ventS=(x/2)-(hbr/2)-heo;

module ball() {
	sphere(r=size);
	translate([0,0,-size]) cylinder(r1=8,r2=6,h=3);
	translate([0,0,-size-3]) cylinder(r=8,h=3);
}

module joint() {
	difference() 	{
		sphere(r=size+joint_spacing+joint_thickness);
		sphere(r=size+joint_spacing);
		translate([0,0,-size-3]) cube([size+joint_spacing+joint_thickness+25,size+joint_spacing+joint_thickness+25,18],center=true);
		for(i=[0:joint_arms])
		{
			rotate([0,0,360/joint_arms*i]) translate([-arm_width/2,0, -size/2-4])
				cube([arm_width,size+joint_spacing+joint_thickness+20,size+6]);
		}
	}
	translate([0,0,size-0]) cylinder(r2=12,r1=12,h=5);

}

module prism(l, w, h) {
	translate([0, l, 0]) rotate( a= [90, 0, 0]) 
	linear_extrude(height = l) polygon(points = [
		[0, 0],
		[w, 0],
		[0, h]
	], paths=[[0,2,1]]);
}

module vHole(len) {
	difference() {
		union() {
			cube([10-6,len,6]);
			translate([10-6,len,6]) rotate([90,0,0]) cylinder(len,6,6);
		}
		translate ([-7,-1,6]) cube([16,len+2,10]);
		translate ([-7,-1,0]) cube([6,len+2,7]);
	}
}

//Vents
translate([x,y-0.01,0]) rotate([0,0,90]) {
	difference() {
		union() {
			difference() { //Small Vent
				union() {
					prism(ventS,z,z);
					translate([z-6,0,0]) cube([4,ventS,6]); //tip
				}
				difference() {
					translate([-.01,wall/2,wall]) prism(ventS-wall,z-wall, z-wall*2);
					translate([6,0,0]) cube([6,ventS,6]);
				}
				translate([z-12,wall-1,wall]) vHole(ventS-(wall));
			}

			translate([0,ventS+hbr,0]) { 
				difference() { //Big Vent
					union() {
						prism(ventB,z,z);
						translate([z-6,0,0]) cube([4,ventB,6]);
					}
					difference() {
						translate([-.01,wall/2,wall]) prism(ventB-wall,z-wall,z-wall*2);
						translate([6,0,0]) cube([6,ventB,6]);
					}
					translate([z-12,wall-1,wall]) vHole(ventB-(wall));
				}
			}
			
			cube([z-2,y-2,wall]); //vent Base
			translate([0,ventS,wall]) cube([wall,hbr,z-(wall*2)]); //vent join			
			
			difference() {
				translate([0,0,z-wall]) cube([wall,y,wall]); //top of slope edging strip
				translate([2,y-2,-1]) rotate([0,0,45]) cube([2.8,2.8,z+2]); //bottom right bevel
			}
		}
		translate([9,-1,0]) rotate([0,45,0]) cube([10,y+2,10]); //vent bottom bevel
	}
}

//Body
difference() {
	union() {
		cube([x,y+1.9,z]); //outer block
	translate([-3,((x-sc)/2) + sc + irSensorOffset ,9]) rotate([0,90,0]) cylinder(4,3,6);	// sensor board mount
	translate([-3,((x-sc)/2) + sc + irSensorOffset - 23,9]) rotate([0,90,0]) cylinder(4,3,6);	// sensor board mount	

	}
	translate([x/2,x/2,-.1]) cylinder(20,hole/2,hole/2); //fan hole
	
	translate([wall,wall,2]) cube([x-(wall*2), x, 20]); //heatsink hole
	translate([wall-1,wall-1,z-2]) cube([x-(wall), x, 20]); //heatsink recess
	for(xp = [0:1]) { //2 x screw holes
		translate([((x-sc)/2) + (xp*sc),((x-sc)/2) + sc,-.1]) cylinder(3,1.6,1.6);
	}
	
	translate([-4,((x-sc)/2) + sc + irSensorOffset,9]) rotate([0,90,0]) cylinder(h=5,r=1.2);	// sensor board hole
	translate([-4,((x-sc)/2) + sc + irSensorOffset - 23,9]) rotate([0,90,0]) cylinder(h=5,r=1.2);	// sensor board hole
	
	translate([0,-6,-1]) rotate([0,0,45]) cube([5,5,z+2]); // top bevel
	translate([x,-6,-1]) rotate([0,0,45]) cube([5,5,z+2]); //top bevel
	translate([0,y,-1]) rotate([0,0,45]) cube([2.7,2.7,z+2]); //bottom right bevel
}

//Cable Traps
translate([x,(y/2)-10,0]) cube([wall*2,20,1.5]); //right cable trap
difference() {
	translate([x+3,(y/2)-10,0]) cube([2,20,z]); //right cable trap
	translate([x+2,(y/2)-10,z-2]) rotate([45,0,0]) cube(3); //right cable trap bevel
	translate([x+2,y-11,z-2]) rotate([45,0,0]) cube(3); //right cable trap bevel
}
translate([x+1.6,(y/2)-7.5,z-1.5]) rotate([0,45,0]) cube([2,15,2]); //right cable trap catch


//Tie Wrap hole
difference() {
	union() {
		translate([x-9,-3,0]) cube([8,4,2]);
		translate([x-5,-3,0]) cylinder(r=4,h=2);
	}
	translate([x-5,-3,-1]) cylinder(r=2,h=4);
}

/*Ball Joint
difference() {
	union() {
		rotate([0,90,0]) scale(.5)  translate([-size+1,size,97]) ball();
		//translate([20,20,2.4]) scale(.5) joint();
	}
	translate([0,0,-6]) cube([100,100,6]);
	translate([20,20,2.4]) cylinder(20,1.5,1.5);
}
*/
