function h = createEW309RoomFOV(varargin)
% CREATEEW309ROOM initializes one of the EW309 classrooms and returns a
% structured array containing useful handles. 
%   h = createEW309Room initializes a random EW309 classroom (either Ri078
%   or Ri080) and returns the h, a structured array containing useful
%   graphics object handles and values.
%
%   h = createEW309Room(room) inializes a specified classroom (either Ri078
%   or Ri080) and returns the h.
%
%   The variable h is a structured array containing the following fields:
%       Room -------------- String containing the room idenfier
%       Figure ------------ Figure containing simulated FOV
%       Axes -------------- Axes containing simulated FOV
%       Frames
%           Barrel (h_b2c) ----------- NERF barrel frame 
%           Room_Center (h_r2b) ------ HgTransform located in the center 
%                   of the room. This is "frame r" which is how we 
%                   reference the room to the barrel of the NERF gun and 
%                   ultimately to the camera.
%           Room_West_Corner (h_w2r) - HgTransform located in the west  
%                   corner of the room. 
%           SW_Wall (h_sw2w) --------- HgTransform located on SW Wall
%           SE_Wall (h_se2w) --------- HgTransform located on SE Wall
%           NE_Wall (h_ne2w) --------- HgTransform located on NE Wall
%           NW_Wall (h_nw2w) --------- HgTransform located on NW Wall
%       Lights ------------ Light objects in the room
%       H_b2c
%       H_r2c ------------- Transformation relating the room center frame
%               to the camera frame.
%       H_w2r ------------- Transformation relating the west corner frame
%               to the room center frame.
%       Room_Length ------- Length of the room (mm)
%       Room_Width -------- Width of the room (mm)
%       Room_Height ------- Height of the room (mm)
%       Light_Height ------ Height of lights above the ceiling (mm)
%
%   M. Kutzer, 23Mar2020, USNA

%% Parse input(s)
narginchk(0,1);

validRooms = {'Ri078','Ri080'};
if nargin < 1
    idx = randi(2);
    room = validRooms{idx};
else
    room = varargin{1};
end

%% Check input(s)
switch room
    case validRooms{1}
        
    case validRooms{2}
        
    otherwise
        error('The specified room must be either "%s" or "%s".',validRooms{1},validRooms{2});
end

%% Open "room" 
fname = sprintf('Camera FOV, %s.fig',room);
fprintf('Loading "%s"...',fname);
warning off
open(fname);
warning on
fprintf('[COMPLETE]\n');

%% Define tags
figTag = sprintf('Figure, FOV %s',room);
axsTag = sprintf('Axes, FOV %s',room);
centerTag = 'Room Center Frame';
westTag = 'West Corner Frame';
SW_Tag = 'SW Wall Base Frame';
SE_Tag = 'SE Wall Base Frame';
NE_Tag = 'NE Wall Base Frame';
NW_Tag = 'NW Wall Base Frame';

%% Get figure and axes handles
h.Room = room;
h.Figure = findobj('Type','Figure','Tag',figTag);
if numel(h.Figure) > 1
    warning('Multiple FOV figures are open!');
    h.Figure = h.Figure(1);
end

h.Axes = findobj('Type','Axes','Tag',axsTag,'Parent',h.Figure);
set(h.Figure, 'Visible','off'); % Hide figure until adjustments are finishd
drawnow;

%% Get frame handles
% Introduce "Barrel" frame
h.Frames.Barrel            = triad('Parent',h.Axes,'Scale',500,'Tag','Barrel Frame','Matrix',Ty(100)*Tz(-330)*Rx(pi/2));

% Recover center frame and reconfigure parent/child relationship
h.Frames.Room_Center       = findobj('Type','HgTransform','Tag',centerTag,'Parent',h.Axes);
set(h.Frames.Room_Center,'Parent',h.Frames.Barrel,'Matrix',eye(4));

% Recover remaining frames
h.Frames.Room_West_Corner  = findobj('Type','HgTransform','Tag',  westTag,'Parent',h.Frames.Room_Center);
h.Frames.SW_Wall           = findobj('Type','HgTransform','Tag',   SW_Tag,'Parent',h.Frames.Room_West_Corner);
h.Frames.SE_Wall           = findobj('Type','HgTransform','Tag',   SE_Tag,'Parent',h.Frames.Room_West_Corner);
h.Frames.NE_Wall           = findobj('Type','HgTransform','Tag',   NE_Tag,'Parent',h.Frames.Room_West_Corner);
h.Frames.NW_Wall           = findobj('Type','HgTransform','Tag',   NW_Tag,'Parent',h.Frames.Room_West_Corner);

% Define "convenient" naming
h.Frames.h_b2c  = h.Frames.Barrel;
h.Frames.h_r2b  = h.Frames.Room_Center; 
h.Frames.h_w2r  = h.Frames.Room_West_Corner;
h.Frames.h_sw2w = h.Frames.SW_Wall;
h.Frames.h_se2w = h.Frames.SE_Wall;
h.Frames.h_ne2w = h.Frames.NE_Wall;
h.Frames.h_nw2w = h.Frames.NW_Wall;

%% Recover lighting handles
h.Lights = flipud( findobj('Type','Light','Parent',h.Frames.Room_West_Corner) );
set(h.Lights,'Color',1.0*[244, 255, 250]./256); % Adjust light intensity & color
%set(h.Lights([1,2,3,6,7,8]),'Visible','Off');   % Turn off Southwest and Northeast lights

% Move the lights higher (or lower)
delta_H_ft = 15;                    % Change in height (ft)
delta_H_mm = delta_H_ft*12*25.4;    % Change in height (mm)

p0 = get(h.Lights,'Position');
for i = 1:numel(p0)
    p = p0{i,1};
    p(3) = p(3) + delta_H_mm;
    set(h.Lights(i),'Position',p);
end

%% Get Transformations and dimensions
h.H_b2c = get(h.Frames.Barrel,          'Matrix'); % This should remain fixed
h.H_r2b = get(h.Frames.Room_Center,     'Matrix'); % This should be adjusted to "move" the Barrel (Tx * Ty * Rz)
h.H_w2r = get(h.Frames.Room_West_Corner,'Matrix'); % This should remain fixed

% Adjust to barrel height instead of camera height
h.H_w2r(3,4) = -1300; 
set(h.Frames.Room_West_Corner,'Matrix',h.H_w2r);

% Get room length and width
h.Room_Length = -h.H_w2r(2,4) * 2;
h.Room_Width  = -h.H_w2r(1,4) * 2;
switch room
    case 'Ri078'
        h.Room_Height = 2.83e3;
    case 'Ri080'
        h.Room_Height = 2.71e3; 
end
h.Light_Height = delta_H_mm;

%% Hide triads
hgALL = findobj(h.Figure,'Type','hgtransform');
hideTriad(hgALL);

%% Increase x/y limits
xx = xlim(h.Axes);
yy = ylim(h.Axes);
xlim(h.Axes,3*xx);
ylim(h.Axes,2*yy);

%% Show figure
set(h.Figure, 'Visible','on'); % Show figure
drawnow;