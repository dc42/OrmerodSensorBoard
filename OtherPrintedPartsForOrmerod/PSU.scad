// Main box
difference()
{
	cube([117,55.5,66]);		// box outside12
	translate([3,3,3]) 
	{	cube([111,49.5,63]);	// box inside
	};
	translate([23,13,0])
	{	cube([47,28.5,3]);		// cutout for IEC socket
	};
	translate([23,10,2])
	{	cube([5,34,1]);			// recess for socket clip
	};
	translate([23+42,10,2])
	{	cube([5,34,1]);			// recess for socket clip
	};
	translate([113,26,60])
	{
		rotate([0,90,0])
		{
			cylinder(h=5,r=1.5,$fs=0.1);	// side hole
		};
	};
	translate([11,-1,45])
	{	rotate([-90,0,0])
		{
			cylinder(h=5,r=2,$fs=0.1);		// front hole to access inside screw
		}
	};
	translate([12,27.75,0]) { cylinder(r=3.35,h=3,$fs=0.1); };
	translate([92,27.75,0]) { cylinder(r=11.7,h=3,$fs=0.1); };
	translate([92-9.5,27.75-12,0]) { cylinder(r=1.6,h=3,$fs=0.1); };
	translate([92+9.5,27.75+12,0]) { cylinder(r=1.6,h=3,$fs=0.1); };
};

// Cube to hold insde screw
difference()
{
	translate([3,34,40])
	{
		cube([11,10,10]);
	};
	translate([11,33,45])
	{
		rotate([-90,0,0])
		{
			cylinder(h=12,r=1.5,$fs=0.1);
		};
	};
};

// Wedge to suppot cube
polyhedron
(	points=[[3,34,29],[3,34,40],
			[14,34,40],[3,44,29],
			[3,44,40],[14,44,40]],
	triangles=[[0,1,2],[3,5,4],[0,3,1],[1,3,4],
			[0,2,3],[3,2,5],[1,4,5],[1,5,2]]
);
