function varargout = setupTurretAndTarget(h,varargin)
% SETUPTURRETANDTARGET creates a target and sets a designated range between
% the turret and the target.
%
%   h = SETUPTURRETANDTARGET(h,targetSpecs,range)
%
%       targetSpecs.Diameter ------- target diameter
%       targetSpecs.HorizontalBias - change in left/right relative position
%       targetSpecs.VerticalBias --- change in relative height 
%       targetSpecs.Color ---------- target color [Dark Orange]
%       targetSpecs.Wobble --------- target wobble [0]
%       targetSpecs.Shape ---------- string argument describing target
%                                    shape (e.g. 'circle')
%
%   h = SETUPTURRETANDTARGET(h,targetSpecs,range,turretSpecs)
%
%       turretSpecs.HorizontalOffset - change in turret left/right position
%       turretSpecs.VerticalBias ----- change in turret height
%       turretSpecs.Angle ------------ change in turret angle
%
%   h = SETUPTURRETANDTARGET(h,targetSpecs,range,turretSpecs,wall)
%
%       wall = {['NE'],'NW','SW','SE'};
%
%   [h,h_a2r] = SETUPTURRETANDTARGET(___)
%
%   [h,h_a2r,objs] = SETUPTURRETANDTARGET(___)
%
%   M. Kutzer, 28Mar2020, USNA

%% Check input(s)
narginchk(3,5);

% Set defaults
wall = 'NE';
wobble = deg2rad(10); % TODO - allow user to specify target wobble
color = 'Dark Orange';

% Parse input(s)
if nargin > 1
    targetSpecs = varargin{1};
end

if nargin > 2
    range = varargin{2};
end

if nargin > 3
    turretSpecs = varargin{3};
end

if nargin > 4
    wall = varargin{4};
end

%% Check target specs
if ~isstruct(targetSpecs)
    warning('"targetSpecs" must be defined as a structured array.'); 
    targetSpecs = struct;
end
fieldNames = {'Diameter','HorizontalBias','VerticalBias','Color','Wobble','Shape'};
bin = isfield(targetSpecs,fieldNames);
for i = 1:3
    if ~bin(i)
        error('The "%s" field of the target specifications input must be specified by the user.',fieldNames{i});
    end
end 
if ~bin(4) 
    targetSpecs.Color = color;
end
if ~bin(5) 
    targetSpecs.Wobble = wobble;
end
if ~bin(6) 
    targetSpecs.Shape = 'Circle';
end
%% Check turret specs
if ~isstruct(turretSpecs)
    warning('"turretSpecs" must be defined as a structured array.'); 
    turretSpecs = struct;
end
fieldNames = {'HorizontalOffset','VerticalOffset','Angle'};
bin = isfield(turretSpecs,fieldNames);
if ~bin(1)
    turretSpecs.HorizontalOffset = 0;
end
if ~bin(2)
    turretSpecs.VerticalOffset = 0;
end
if ~bin(3)
    turretSpecs.Angle = 0;
end

%% Specify position & orientation of target and turret
barrelLength = 356; % Offset between the barrel frame origin and the end 
                    % of the barrel
%
% Review frame definitions
%   Frame c - camera frame 
%   Frame r - room center frame
%   Frame b - barrel frame
%   Frame a - target "aim" frame
%   Frame e - barrel "end" frame 

% Define transformations
% -> Barrel "end" frame relative to barrel frame
H_e2b = Ty(barrelLength);
% -> Target "aim" frame relative to room frame 
switch wall
    case 'NE'
        target.XYZ(1) =  (targetSpecs.HorizontalBias + turretSpecs.HorizontalOffset);
        target.XYZ(2) =  (h.Room_Length/2 - targetSpecs.Diameter/2);
        target.theta = 0;
    case 'NW'
        target.XYZ(1) = -(h.Room_Width/2 - targetSpecs.Diameter/2);
        target.XYZ(2) =  (targetSpecs.HorizontalBias + turretSpecs.HorizontalOffset);
        target.theta = pi/2;
    case 'SW'
        target.XYZ(1) = -(targetSpecs.HorizontalBias + turretSpecs.HorizontalOffset);
        target.XYZ(2) = -(h.Room_Length/2 - targetSpecs.Diameter/2);
        target.theta = pi;
    case 'SE'
        target.XYZ(1) =  (h.Room_Width/2 - targetSpecs.Diameter/2);
        target.XYZ(2) = -(targetSpecs.HorizontalBias + turretSpecs.HorizontalOffset);
        target.theta = 3*pi/2;
    otherwise
        error('Specified wall "%s" is undefined.',wall);
end
target.XYZ(3) = (targetSpecs.VerticalBias + turretSpecs.VerticalOffset);
target.diameter = targetSpecs.Diameter;
target.color = targetSpecs.Color;
target.wobble = targetSpecs.Wobble;
target.shape = targetSpecs.Shape;

% Allow user to select a "shape" or a "crosshair"
switch lower( target.shape )
    case 'crosshair'
        lims = [-50,50];
        dtick = 10;
        units = 'Centimeters';
        width = 1;
        [h_a2r,objs] = createCrosshair(h.Frames.h_r2b,lims,dtick,units,target.color,width);
    otherwise
        [h_a2r,objs] = createTarget(h.Frames.h_r2b,targetSpecs.Shape,target.diameter,target.color);
end
% Place target without wobble (to get transformation)
h_a2r = placeTarget(h_a2r,target.XYZ,target.theta,0);
% Get transformation
H_a2r = get(h_a2r,'Matrix');
% Place target again *with* wobble
%h_a2r = placeTarget(h_a2r,target.XYZ,target.theta,target.wobble);
% -> Create wobble frame
H_aw2a = makeWobbleTransform(target.wobble);
h_aw2a = triad('Parent',h_a2r,'Scale',150,'LineWidth',1.5,...
    'Tag','Wobble Frame','Matrix',H_aw2a);
hideTriad(h_aw2a); % Hide the "triad" visualization
% -> Make target a child of wobbled frame
set(objs,'Parent',h_aw2a);

% -> Barrel "end" frame relative to target "aim" frame
H_e2a = Tz(range)*Tx(-targetSpecs.HorizontalBias)*Ty(-targetSpecs.VerticalBias)*Rx(-pi/2);
% -> Barrel frame relative to the room frame
H_b2e = H_e2b^(-1);
H_b2r = H_a2r*H_e2a*H_b2e*Rz(turretSpecs.Angle);

% Move turret
H_r2b = H_b2r^(-1);
h.H_r2b = H_r2b;
set(h.Frames.h_r2b,'Matrix',H_r2b);

%% Package Output
if nargout > 0
    varargout{1} = h;
end
if nargout > 1
    varargout{2} = h_a2r;
end
if nargout > 2
    varargout{3} = objs;
end