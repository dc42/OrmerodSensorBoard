// Ormerod fan inlet duct

cube_length = 40;
cube_width = 40;
cube_height = 6;
wall = 1.5;
skirt = 2;
overlap = 1;

blade_angle = 35;

use <fan_deflector_v4_aerofoil.scad>

module foil()
{
	ratio = 1.8;
		translate([-2,-cube_width/2,1])
			rotate([-6,blade_angle,0])
				rotate([-90,0,0])
					linear_extrude(height = cube_width/2,twist = -blade_angle/2, scale = 0.5)
						scale([cube_height *ratio,cube_height *ratio,0])
							aerofoil();
}

module blades()
{
   numblades = 9;
   translate([20, 20, 0]) {
      difference(){
         union(){
            intersection(){
               cylinder(h=cube_height,r=19.5,$fn=20);
               union(){
                  for ( x = [0 : numblades -1] ){
                     rotate([180,0, x * 360 / numblades]){
                        foil();
                     }
                  }
               }
            }
            cylinder(h=cube_height,r=11,$fn=20);
         }
         translate([0,0,1.5]) cylinder(h= cube_height,r=10,$fn=20);
      }
   }
}

module screw_hole()
{
	translate([0, 0, -1]) cylinder(2, 3.25, 3.25, $fn=20);
	translate([0, 0, 1]) cylinder(1.75, 3.25, 1.5, $fn=20);
	translate([0, 0, -1]) cylinder(cube_height + 2, 1.5, 1.5, $fn=20);
}


module fan_backwash_plate() {
   difference() {
      translate([-wall,-wall,0])
			cube([cube_length + 2*wall, cube_width + 2*wall, cube_height + skirt]);
      translate([cube_length/2,cube_width/2,-10]) cylinder(20,19,19, $fn=50);

      translate([-.30,-.30,cube_height])
         cube([cube_length + .6,cube_width + .6, cube_height + skirt + overlap]);

      //holes at bottom
      translate([4, 4, 0]) screw_hole();
      translate([4, cube_width-4, 0]) screw_hole();
   } // difference
} // module

union() {

   fan_backwash_plate();
	blades(); 
}

