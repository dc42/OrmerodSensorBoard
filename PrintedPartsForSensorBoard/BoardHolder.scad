// Holder for Ormerod sensor board

module wedge(x,y,z)
{
	polyhedron(
		points=[[0,0,0],[x,0,0],[0,y,0],[0,0,z],[x,0,z],[0,y,z]],
		triangles=[[0,2,1],[3,4,5],[0,1,3],[1,4,3],[1,2,4],[2,5,4],[0,3,2],[5,2,3]]
	);
}

//wedge(10,10,3);

difference()
{
	cube([100,60,1]);
	translate([12,16,-1])
	{
		difference()
		{	
			cube([76.2,28,3]);
			translate([0,0,-1]) wedge(10,10,5);
		}
	}
}
