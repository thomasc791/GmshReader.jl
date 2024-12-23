meshSize = 2;
ySize = meshSize/2+1;
xSize = meshSize*2+1;

width = meshSize*2;
height = meshSize;

Point(1) = {0, 0, 0, 1.0};
Point(2) = {width, 0, 0, 1.0};
Point(3) = {width, height/2, 0, 1.0};
Point(4) = {width, height, 0, 1.0};
Point(5) = {0, height, 0, 1.0};
Point(6) = {0, height/2, 0, 1.0};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 5};
Line(5) = {5, 6};
Line(6) = {6, 1};
Line(7) = {6, 3};


Curve Loop(1) = {1, 2, -7, 6};
Plane Surface(1) = {1};
Curve Loop(2) = {3, 4, 5, 7};
Plane Surface(2) = {2};

Transfinite Surface {1};
Transfinite Surface {2};

Physical Curve("right", 1) = {2, 3};
Physical Curve("left", 2) = {5, 6};

Transfinite Curve {2, 6} = ySize Using Progression 1;
Transfinite Curve {3, 5} = ySize Using Progression 1;
Transfinite Curve {4, 7, 1} = xSize Using Progression 1;

Recombine Surface {1, 2};
Mesh 2;

Save "squareMesh.msh";
