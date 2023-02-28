function h = moveTurretFOV(h,varargin)
% MOVETURRETFOV rotates and potentially positions an EW309 turret within an
% existing EW309 room.
%
%   h = MOVETURRETFOV(h,theta) rotates the turret by a specified angle 
%   (theta) defined in ratians. The first parameter is the structured array
%   returned by createEW309RoomFoV.m
%
%   h = MOVETURRETFOV(h,x,y) changes the x/y position of the turret The
%   first parameter is the structured array returned by 
%   createEW309RoomFoV.m
%
%   M. Kutzer, 23Mar2020, USNA

%% Check input(s) 
narginchk(2,3);

% TODO - check h!
% TODO - check theta, x, and y

% Get current pose
H_r2b_0 = get(h.Frames.h_r2b,'Matrix');
% Parse parameters
x0 = -H_r2b_0(1,4); % current x-position
y0 = -H_r2b_0(2,4); % current y-position
z0 = -H_r2b_0(3,4); % current z-position
% -> Assumes z-rotation only
theta0 = -atan2(H_r2b_0(2,1),H_r2b_0(1,1)); % current z-rotation

theta0
varargin{1}

% Update theta only
if nargin == 2
    theta = theta0 + varargin{1};
    x = x0;
    y = y0;
    z = z0;
end
% Update x/y only
if nargin == 3
    theta = theta0;
    x = varargin{1};
    y = varargin{2};
    z = z0;
end

theta

%% Update turret FOV
H_r2b = Tx(-x)*Ty(-y)*Tz(-z)*Rz(-theta);

h.H_r2b = H_r2b;
set(h.Frames.h_r2b,'Matrix',H_r2b);