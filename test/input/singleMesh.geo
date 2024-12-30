meshSize = 1000;
ySize = meshSize+1;
xSize = meshSize*5+1;

width = 50; //meshSize*2;
height = 10; //meshSize;

Point(1) = {0, 0, 0, 1.0};
Point(2) = {width, 0, 0, 1.0};
Point(3) = {width, height, 0, 1.0};
Point(4) = {0, height, 0, 1.0};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};


Curve Loop(1) = {4, 1, 2, 3};
Plane Surface(1) = {1};

// Ensure point is in surface
Transfinite Surface {1};

Transfinite Curve {2, 4} = ySize Using Progression 1;
Transfinite Curve {3, 1} = xSize Using Progression 1;

Physical Curve("right", 1) = {2};
Physical Curve("left", 2) = {4};

Recombine Surface {1};

Mesh 2;
Save "singleMesh.msh";
