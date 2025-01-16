Point(1) = {0, 0, 0, 1.0};
Point(2) = {1, 0, 0, 1.0};
Point(3) = {1, 1, 0, 1.0};
Point(4) = {0, 1, 0, 1.0};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

Curve Loop(1) = {2, 3, 4, 1};
Plane Surface(1) = {1};

Physical Point("right", 1) = {2};
Physical Curve("right", 1) = {2};
Physical Curve("left", 2) = {4};

Mesh 2;
Save "1x1-square.msh";
