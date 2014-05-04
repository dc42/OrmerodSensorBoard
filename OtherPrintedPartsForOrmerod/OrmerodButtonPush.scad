use <mcad/shapes.scad>;

translate([0,-10,0]) rotate([90,0,0]) hexagon(size=2.5, height=35);
cube(size=[3,20,2.5],center=true);