//Ormerod Duet enclosure replacement
// RJT 16 May 2014
// Overall depth for extra room
// Extra mounts to allow better horizontal positioning
// PC board can be separate from main mounts to allow enclosure mounting with PCB in place
// Base can be solid or hollow (using original acrylic plate)
// Wall near cables can be cut out or filled in
// Ventillation holes

//Main customisable options parameters
Enc_X4_stacked=true;			//Set true to accommodate Duet+DuetX4 boards, false for Duet only
Enc_hollowbase=false;			//Set true to cutout base
Enc_wall_cutout=false;			//Set true to cut out cable wall
Enc_extra_width=8.0;			//Amount of extra width to give separate PCB mount, if 0 then like standard
Enc_ventillation=3;				//If non zero set size of ventilation hole size
Enc_ventillation_spacing=8.0;	//Spacing of vent holes, should be > double ventillation size
Enc_basic_inner_height=21.0;	//Inner depth (x) of the enclosure when Enc_X4 is false (18.0 in RRP original)
Enc_X4_separation=6.5;			//Duet and X4 boards are separated by this less one PCB thickness
Enc_5V_cutout=false;			//Enables cutout for 5V connection

//PC mount parameters
Enc_X4_standoff=16;				//How far the X4 board stands off from the base
Enc_duet_standoff=(Enc_X4_stacked) ? Enc_X4_standoff+Enc_X4_separation : 2.5;
Enc_standoff_radius=3.6;		// increased because if left at 3.5, slic3r tends to generate 2 circles instead of 3

//Main dimensions
Enc_inner_height=(Enc_X4_stacked) ? Enc_basic_inner_height+Enc_duet_standoff : Enc_basic_inner_height;
Enc_inner_length=125.0;			//Inner length (y) of the enclosure
Enc_innerduet_width=102.0;		//Duet nominal width
Enc_lid_width=(Enc_extra_width==0) 
	? Enc_innerduet_width+Enc_wall+Enc_upperlid_groove
	: 107.7;	// if not generating lid feet cutouts, slot needs to be longer
Enc_inner_width=Enc_innerduet_width+Enc_extra_width; // Derived real width
Enc_bottomshelf_width=3.0;		//shelf width under PCB
Enc_base=3.0;						//Thickness of base under PCB
Enc_wall=3.0;						//Thickness of the walls
Enc_upperlid_groove = 1.0;		//Grooves in wall for lid
Enc_upperlid_height=3.7;
Enc_upperlock_height=0.5;		//little wedge to retain acrylic
Enc_upperlock_width=5.0;
Enc_lidfoot_length=5.0;
Enc_sidecutout_offset=8.5;		//Where to cutout wall for cable access
Enc_sidecutout_length=106.0;
Enc_top_extra = (Enc_X4_stacked) ? 1.0 : 0.0;	// extra clearance at top for ribbon cable

//Mounting Holes 
Enc_holes_radius=2.25;
Enc_holes_radius_tap=2.0;
Enc_holes_outerradius=4.5;
// Mounting pillars for the X4 board need to be smaller in order to clear the connectors.
// As the mounting holes in them are smaller than 4mm (like early Duet boards), we can use 3mm screws instead.
Enc_holes_radius_tap_X4=1.5;
Enc_holes_outerradius_X4=3.5;
Enc_holes_countersinkdepth=1.3;
Enc_holes_countersinkradius=4.0;
Enc_holes_offsets=8.0;
Enc_holes_ext_xoffset=5.6;
Enc_holes_ext_yoffset=20.0;
Enc_holes_ext_height = 2.0;
Enc_Extra_holecount=5;

//Connectors - wall			Rerap values with wall=3
Enc_Ethernet_y_offset=8.0;		//10.45
Enc_Ethernet_z_offset=0;		//0.0
Enc_Ethernet_width=17.9;		//17.05
Enc_Ethernet_height=16.0;		//20.00
Enc_SD_y_offset=32.5;			//35.00
Enc_SD_width=14.0;				//13.00
Enc_SD_height=4.0;				//2.60
Enc_SD_z_offset=1.00;			//1.75
Enc_USB_y_offset=47.5;			//50.0
Enc_USB_width=14.0;			//12.50
Enc_USB_height=8.0;			//6.50
Enc_USB_z_offset=0;			//0.0
Enc_Power_y_offset=47.0;		//52.0
Enc_Power_width=16.5;			//12.50
Enc_Power_height=9.0;			//6.00
Enc_Power_z_offset=1.5;		//3.00
Enc_5V_y_offset=66.0;			//New
Enc_5V_width=12.0;				//New
Enc_5V_height=7.0;				//New
Enc_5V_z_offset=1.5;			//New
Enc_X4Power_y_offset=29.5;
Enc_X4Power_z_offset=-Enc_Power_height;
overlap=1;

$fn=25;
include <MCAD/boxes.scad>;

//include <DuetEncMeasure.scad>;
//translate([0,0,-30]) measure();

module baseBox() {
	difference() {
		//Start with solid roundex box
		translate([(Enc_inner_length+2*Enc_wall)/2,(Enc_inner_width+2*Enc_wall+Enc_top_extra)/2-Enc_top_extra,(Enc_inner_height+Enc_base)/2])
			roundedBox([Enc_inner_length+2*Enc_wall,Enc_inner_width+2*Enc_wall+Enc_top_extra,Enc_inner_height+Enc_base], 1, false);
		//Hollow out with another
		translate([(Enc_inner_length)/2+Enc_wall,(Enc_inner_width)/2+Enc_wall-Enc_top_extra,(Enc_inner_height+Enc_base)/2+Enc_base])
			roundedBox([Enc_inner_length,Enc_inner_width+Enc_top_extra,Enc_inner_height+Enc_base], 1, false);
		//Hollow out for top lip
		translate([Enc_wall-Enc_upperlid_groove,-0.1-Enc_top_extra,Enc_base+Enc_inner_height-Enc_upperlid_height])
			cube([Enc_inner_length+2*Enc_upperlid_groove,Enc_lid_width+0.1,Enc_upperlid_height+0.2]);
		//Cut out the base if needed
		if(Enc_hollowbase) {
			translate([Enc_wall+Enc_bottomshelf_width,Enc_wall+Enc_bottomshelf_width,-0.1])
				cube([Enc_inner_length-2*Enc_bottomshelf_width,Enc_innerduet_width-2*Enc_bottomshelf_width,Enc_base+0.2]);
		}
		//Cut out side for cable entry
		if(Enc_wall_cutout) {
			translate([Enc_wall+Enc_sidecutout_offset,Enc_inner_width,Enc_base])
				cube([Enc_sidecutout_length,3*Enc_wall,Enc_inner_height+0.2]);
		}
		//Cut outs for connectors
		connectorCutouts();
		if(Enc_ventillation>0) {
			if(Enc_wall_cutout) {
				ventillation(0);
			} else {
				ventillation(Enc_inner_width);
			}
		}
		if(Enc_extra_width==0) {
			//Lid feet cutouts
			lidFeetCutouts();
		}
	}
	//Add extra bit of base around extra mounting holes
	if(Enc_hollowbase) {
		translate([Enc_wall+Enc_bottomshelf_width,Enc_inner_width+2*Enc_wall-Enc_holes_offsets-Enc_holes_outerradius])
			cube([Enc_Extra_holecount*Enc_holes_offsets,Enc_holes_offsets,Enc_base]);
	}
	// Add lidLocks and mounting stands
	lidLocks();
	mountingStands();
}

//mounting hole xpos, ypos, countersink,tap(smaller hole)
module mountingHole(x,y,ht,cs,t,ex) {
	zoffset = (ht+ex>=7) ? ht+ex-7 : -0.05;	// make holes no more than 7mm deep
	translate([x,y,zoffset]) {
		if(t) {
			cylinder(r=Enc_holes_radius_tap,h=ht+ex+1);
		} else {
			cylinder(r=Enc_holes_radius,h=ht+ex+1);
		}
		if(cs) {
			translate([0,0,ht-Enc_holes_countersinkdepth+0.2])
			cylinder(r1=Enc_holes_radius,r2=Enc_holes_countersinkradius,h=Enc_holes_countersinkdepth);
		}
	}
}

//mounting hole xpos, ypos, countersink,tap(smaller hole)
module mountingHoleX4(x,y,ht,cs,t,ex) {
	translate([x,y,ht+ex-7]) {
		cylinder(r=Enc_holes_radius_tap_X4,h=ht+ex+1);
		if(cs) {
			translate([0,0,ht-Enc_holes_countersinkdepth+0.2])
			cylinder(r1=Enc_holes_radius,r2=Enc_holes_countersinkradius,h=Enc_holes_countersinkdepth);
		}
	}
}

module mountingHoles() {
	//Drill mounting holes including the extras
	//Top PCB positions
	mountingHole(Enc_holes_offsets,Enc_holes_offsets,Enc_base,false,true,Enc_duet_standoff);
	mountingHole(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_holes_offsets,Enc_base,false,true,Enc_duet_standoff);
	//Bottom PCB positions
	if(Enc_extra_width == 0) {
		mountingHole(Enc_holes_offsets,Enc_inner_width+2*Enc_wall-Enc_holes_offsets,
						Enc_base,false,false,Enc_duet_standoff);
		mountingHole(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_inner_width+2*Enc_wall-Enc_holes_offsets,
						Enc_base,false,false,Enc_duet_standoff);
	} else {
		mountingHole(Enc_holes_offsets,Enc_innerduet_width+2*Enc_wall-Enc_holes_offsets,
						Enc_base,false,true,Enc_duet_standoff);	
		mountingHole(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_innerduet_width+2*Enc_wall-Enc_holes_offsets,
						Enc_base,false,true,Enc_duet_standoff);
	}
	if (Enc_X4_stacked) {
		//Mounting holes for X4. The lower holes are 2mm further apart than the upper holes and the holes on the Duet.
		mountingHoleX4(Enc_holes_offsets,Enc_holes_offsets+14.5,Enc_base,false,true,Enc_X4_standoff);
		mountingHoleX4(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_holes_offsets+14.5,Enc_base,false,true,Enc_X4_standoff);
		mountingHoleX4(Enc_holes_offsets-1,Enc_innerduet_width+2*Enc_wall-Enc_holes_offsets-16.5,
						Enc_base,false,true,Enc_X4_standoff);	
		mountingHoleX4(Enc_inner_length+2*Enc_wall-Enc_holes_offsets+1,Enc_innerduet_width+2*Enc_wall-Enc_holes_offsets-16.5,
						Enc_base,false,true,Enc_X4_standoff);
	}
	//External hole
	mountingHole(Enc_holes_ext_xoffset+2*Enc_wall+Enc_inner_length,Enc_inner_width+2*Enc_wall-Enc_holes_offsets-Enc_holes_ext_yoffset,
						Enc_base+Enc_holes_ext_height,true,false,0);
	//Extra mount holes
	for ( i = [1 : Enc_Extra_holecount] ) {
		if(i==1) {
			if(Enc_extra_width > 0) {
				mountingHole(i*Enc_holes_offsets,Enc_inner_width+2*Enc_wall-Enc_holes_offsets,Enc_base,true,false,0);
			}
		} else {
			mountingHole(i*Enc_holes_offsets,Enc_inner_width+2*Enc_wall-Enc_holes_offsets,Enc_base,true,false,0);
		}
	}
	//Bottom left mount if not shared with PCB
	if(Enc_extra_width > 0) {
		mountingHole(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_inner_width+2*Enc_wall-Enc_holes_offsets,Enc_base,true,false,0);
	}
}

//mounting stand xpos, ypos, angle, mounting, external (hull positioning)
module mountingStand(x,y,ht,a,sth,e) {
	translate([x,y,0]) rotate([0,0,a]) {
		hull(){
			cylinder(r=Enc_holes_outerradius,h=ht);
			translate([-1.5*Enc_holes_outerradius,-1.5*Enc_holes_outerradius*e,0]) cube([1,1,ht]);
			translate([1.5*Enc_holes_outerradius-1,-1.5*Enc_holes_outerradius*e,0]) cube([1,1,ht]);
		}
		if(sth > 0) {
			cylinder(r=Enc_standoff_radius,h=ht+sth);
		}
	}
}

module mountingStands() {
	//Add stands for Duet board
	mountingStand(Enc_holes_offsets,Enc_holes_offsets,Enc_base,-45,
						Enc_duet_standoff,0);
	mountingStand(Enc_holes_offsets,Enc_innerduet_width+2*Enc_wall-Enc_holes_offsets,Enc_base,-135,
						Enc_duet_standoff,0);
	mountingStand(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_holes_offsets,Enc_base,45,
						Enc_duet_standoff,0);
	mountingStand(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_innerduet_width+2*Enc_wall-Enc_holes_offsets,Enc_base,135,
						Enc_duet_standoff,0);
	if (Enc_X4_stacked) {
		//Add stands for X4 board
		mountingStand(Enc_holes_offsets,Enc_holes_offsets+14.5,Enc_base,-45,
							Enc_X4_standoff,0);
		mountingStand(Enc_holes_offsets-1,Enc_innerduet_width+2*Enc_wall-Enc_holes_offsets-16.5,Enc_base,-135,
							Enc_X4_standoff,0);
		mountingStand(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_holes_offsets+14.5,Enc_base,45,
							Enc_X4_standoff,0);
		mountingStand(Enc_inner_length+2*Enc_wall-Enc_holes_offsets+1,Enc_innerduet_width+2*Enc_wall-Enc_holes_offsets-16.5,Enc_base,135,
							Enc_X4_standoff,0);
	}
	//External mount
	mountingStand(Enc_holes_ext_xoffset+2*Enc_wall+Enc_inner_length,Enc_inner_width+2*Enc_wall-Enc_holes_offsets-Enc_holes_ext_yoffset,Enc_base+Enc_holes_ext_height,-90,0,1);
	//Extra mount stands
	for ( i = [1 : Enc_Extra_holecount] ) {
		mountingStand(i*Enc_holes_offsets,Enc_inner_width+2*Enc_wall-Enc_holes_offsets,Enc_base,180,0,1);
	}
	//bottom case mount if needed
	mountingStand(Enc_inner_length+2*Enc_wall-Enc_holes_offsets,Enc_inner_width+2*Enc_wall-Enc_holes_offsets,Enc_base,135,0,0);
}

module connectorCutouts() {
	translate([0,Enc_wall,Enc_base+Enc_duet_standoff]) {
		//Ethernet
		translate([-0.1,Enc_Ethernet_y_offset,Enc_Ethernet_z_offset])
			cube([Enc_wall+0.2,Enc_Ethernet_width,Enc_Ethernet_height]);
		//SD
		translate([-0.1,Enc_SD_y_offset,Enc_SD_z_offset])
			cube([Enc_wall+0.2,Enc_SD_width,Enc_SD_height]);
		//USB
		translate([-0.1,Enc_USB_y_offset,Enc_USB_z_offset])
			cube([Enc_wall+0.2,Enc_USB_width,Enc_USB_height]);
		//Power
		translate([Enc_inner_length+Enc_wall-0.1,Enc_Power_y_offset,Enc_Power_z_offset])
			cube([Enc_wall+0.2,Enc_Power_width,Enc_Power_height]);
		if(Enc_5V_cutout) {
			//5V
			translate([Enc_inner_length+Enc_wall-0.1,Enc_5V_y_offset,Enc_5V_z_offset])
				cube([Enc_wall+0.2,Enc_5V_width,Enc_5V_height]);
		}
	}
	if(Enc_X4_stacked) {
		//X4 power
		translate([0,Enc_wall,Enc_base+Enc_X4_standoff]) {
			translate([Enc_inner_length+Enc_wall-0.1,Enc_X4Power_y_offset,Enc_X4Power_z_offset])
				cube([Enc_wall+0.2,Enc_Power_width,Enc_Power_height]);
		}
	}
}

module lidFeetCutouts() {
	translate([Enc_wall-Enc_upperlid_groove,Enc_inner_width+Enc_wall-0.1,Enc_base+Enc_inner_height-Enc_upperlid_height])
		cube([Enc_lidfoot_length,Enc_wall+0.2,Enc_upperlid_height+0.2]);
	translate([Enc_inner_length+Enc_wall+Enc_upperlid_groove-Enc_lidfoot_length,Enc_inner_width+Enc_wall-0.1,Enc_base+Enc_inner_height-Enc_upperlid_height])
		cube([Enc_lidfoot_length,Enc_wall+0.2,Enc_upperlid_height+0.2]);
}

module ventillation(l) {
	for(x=[Enc_wall+Enc_holes_offsets+Enc_ventillation
			: Enc_ventillation_spacing
			: Enc_inner_length+Enc_wall-Enc_ventillation-Enc_holes_offsets]) {
		for(z=[Enc_base+2*Enc_ventillation
				: Enc_ventillation_spacing
				: Enc_inner_height+Enc_base-Enc_ventillation-Enc_upperlid_height]) {
			translate([x,-overlap-Enc_top_extra,z]) rotate([0,45,0])
				cube([Enc_ventillation,Enc_wall+2*overlap,Enc_ventillation]);
			translate([x,l+Enc_wall-overlap,z]) rotate([0,45,0])
				cube([Enc_ventillation,Enc_wall+2*overlap,Enc_ventillation]);
		}
	}
}

module lidLock(m) {
	mirror([m,0,0]) difference() {
		cube([Enc_upperlock_height,Enc_upperlock_width,Enc_upperlock_height]);
		rotate([0,45,0]) cube([Enc_upperlock_height,Enc_upperlock_width,1.5*Enc_upperlock_height]);
	}
}

module lidLocks() {
	translate([Enc_wall-Enc_upperlid_groove,Enc_wall-Enc_top_extra,Enc_base+Enc_inner_height-Enc_upperlock_height]) lidLock(0);
	translate([Enc_inner_length+Enc_wall+Enc_upperlid_groove,Enc_wall-Enc_top_extra,Enc_base+Enc_inner_height-Enc_upperlock_height]) lidLock(1);
	translate([Enc_wall-Enc_upperlid_groove,Enc_wall+Enc_innerduet_width-Enc_upperlock_width-Enc_top_extra,Enc_base+Enc_inner_height-Enc_upperlock_height]) lidLock(0);
	translate([Enc_inner_length+Enc_wall+Enc_upperlid_groove,Enc_wall+Enc_innerduet_width-Enc_upperlock_width-Enc_top_extra,Enc_base+Enc_inner_height-Enc_upperlock_height]) lidLock(1);
}

module Duet() {
	difference() {
		baseBox();
		mountingHoles();
	}
}

Duet();

