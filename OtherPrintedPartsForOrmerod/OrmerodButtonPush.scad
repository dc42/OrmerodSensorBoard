use <mcad/shapes.scad>;

HandleLength = 20;
PushLength = 20;
overlap=1;

module ButtonPush() {
	translate([0,-PushLength/2,0]) rotate([90,0,0]) hexagon(size=2.5, height=PushLength+overlap);
	translate([0,HandleLength/2,0]) cube(size=[3,HandleLength,2.5],center=true);
}

translate([-10,0,0]) ButtonPush();
translate([10,0,0]) ButtonPush();
