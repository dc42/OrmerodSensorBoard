cube_length = 40;
cube_width = 40;
cube_height = 6;

blade_angle = 35;

use <fan_deflector_v4_aerofoil.scad>

module foil()
{
      ratio = 1.8;
      translate([-2,-cube_width/2,1
]){
         rotate([-6,blade_angle,0]){
            rotate([-90,0,0]){
               linear_extrude(height = cube_width/2,twist = -blade_angle/2, scale = 0.5){
                  scale([cube_height *ratio,cube_height *ratio,0]){
                     aerofoil();
                  }
               }
               
            }
         }
      }

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
         translate([0,0,1.5]){
               cylinder(h= cube_height,r=10,$fn=20);
         }
      }
   }
}

module screw_hole()
{
     translate([0, 0, -1]){
        cylinder(2, 3.25, 3.25, $fn=20);
     }
     translate([0, 0, 1]){
        cylinder(1.75, 3.25, 1.5, $fn=20);
     }
     translate([0, 0, -1]){
        cylinder(cube_height + 2, 1.5, 1.5, $fn=20);
     }
}


module fan_backwash_plate() {
   difference() {
      translate([-1,-1,0]){
      		cube([cube_length + 2, cube_width + 2, cube_height]);
      }
      translate([cube_length/2,cube_width/2,-10]){
         cylinder(20,19,19, $fn=50);
      } 

      //holes at bottom
      translate([4, 4, 0]){
         screw_hole();
      }
      translate([4, cube_width-4, 0]){
         screw_hole();
      }
   } // difference
} // module

module skirt()
{
   difference(){
      translate([-2,-2,0]){
         cube([cube_length + 4,cube_width + 4, cube_height + 2]);
      }
      translate([-.30,-.30,0]){
         cube([cube_length + .6,cube_width + .6, cube_height + 2]);
      }
   }
}


//module clasp() {
//
//      width = 4;
//      d = 1.2;
//      c_cen = cube_height + 3.75 + d ;
//      c_r = sqrt( 2 * d * d);
//     // echo ("circle radius = " , c_r);
//    //  echo("to end = ",c_cen + c_r - cube_height);
//      rotate(a=[0,270,90]){
//          translate([0,0,-width/2]){
//            linear_extrude(height = width) {
//					union(){
//                  translate([c_cen/2,d +.5 ,0]){
//							square([c_cen,2.5],center = true);
//						}
//						translate ([c_cen,d,0]){
//							circle(r=c_r,$fn= 20);
//                   }
//					}
//            } // extrude
//      }// rotate
//		}
//} // clasp

union() {

   fan_backwash_plate();
   skirt();

//	translate([0,8,0]){
//
//         clasp();
//   }
//   translate([0,cube_width - 8,0]){
//         clasp();
//   }
  
//   translate([cube_length,8,0]){
//      rotate([0,0,180]){
//         clasp();
//      }
//   }

//	translate([cube_length,cube_width - 8,0]){
//      rotate([0,0,180]){
//         clasp();
//      }
//   }

  blades();
 
}

