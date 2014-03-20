
module aerofoil()
{
	radius = 1.3;
   thickness = .15;
   angle = asin(0.5/radius);

   translate([sin(angle) * radius,-cos(angle)*radius,0]){
      union(){
         intersection(){
            difference(){
               circle(r = radius + thickness / 2, $fn = 100);
               circle(r = radius - thickness / 2, $fn = 100);
            }
            scale([2*radius,2*radius,2*radius]){
               polygon([[0,0],[-sin(angle),cos(angle)],[sin(angle),cos(angle)]]);
            }
         }
         translate([-sin(angle) * radius,cos(angle)*radius,0]){
            circle(r=thickness / 2,$fn=20);
         }
         translate([sin(angle) * radius,cos(angle)*radius,0]){
            circle(r=thickness / 2,$fn=20);
         }
      }
   }
}
aerofoil();




