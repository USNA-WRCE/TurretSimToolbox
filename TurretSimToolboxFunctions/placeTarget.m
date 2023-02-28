function h_a2r = placeTarget(h_a2r,XYZ,theta,wobble)
% PLACETARGET positions target within a scene assuming the target is 
% positioned relative to the EW309 "room frame" (i.e. z-up coordinate
% frame).
%   h_a2r = PLACETARGET(h_a2r,x,y,theta) adjusts the matrix property of 
%   the specified hgTransform object given the specified translation in 
%   millimeter (XYZ) and rotation in radians (theta).  
%
%   h_a2r = PLACETARGET(h_a2r,XYZ,theta,wobble) adds orientation noise to 
%   the placement of the target in radians (i.e. making the target not
%   perfectly parallel with the wall). 
%
%   The wobble term can be defined as:
%       (1) a scalar value where "wobble" is added using a random axis of 
%           rotation constrained to the body-fixed xy-plane or 
%       (2) an element of SE(3) 
%
%   M. Kutzer, 26Mar2020, USNA

%% Check input(s)
narginchk(3,4);

if numel(XYZ) ~= 3
    error('"XYZ" must be specified as a 3-element translation in millimeters.');
end

if numel(theta) ~= 1
    error('"theta" must be a scalar value in radians.');
end

if nargin < 4
    wobble = 0;
end

if (numel(wobble) ~= 1 && numel(wobble) ~= 4*4)
    error('"wobble" must be a scalar value in radians or an element of SE(3).');
end

%% Create transformation
H_wobble = makeWobbleTransform(wobble);

H_a2r = Tx(XYZ(1))*Ty(XYZ(2))*Tz(XYZ(3))*Rx(pi/2)*Ry(theta)*H_wobble;

%% Update target position
set(h_a2r,'Matrix',H_a2r);