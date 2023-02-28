function im = getTargetImage(varargin)
% GETTARGETIMAGE creates a simulated image of a target on the chalkboard of
% Ri080. 
%   im = GETTARGETIMAGE(range) creates a simulated image of a target on an
%   EW309 classroom chalkboard. The variable "range" must be specified in 
%   *centimeters*.
%
%   im = GETTARGETIMAGE(range,angle) creates a simulated image of a target
%   with the turret rotated by a specified angle. The variable "angle" must
%   be specified in *radians*.
%
%   im = GETTARGETIMAGE(range,angle,targetSpecs) creates a target matching 
%   a set of target specifications. Use "createTargetSpecs.m".
%
%   im = GETTARGETIMAGE(h,range,angle,targetSpecs) uses a pre-defined FOV
%   specified using the structured array h. Use "createEW309RoomFOV.m".
%
%   M. Kutzer, 31Mar2020, USNA

% TODO - address relative movement use case
%   (1) Students get an initial image (theta_init)
%   (2) Students calculate a relative angle (theta_desired)
%   (3) Students run their controller to get a relative angle 
%       (theta_actual)
%   (4) The turret needs to move *relative* to its initial orientation
%       (theta_init + theta_actual)

%% Define global FOV simulation
% Yes, I realize that globals are generally lazy coding, but I am doing
% this to (a) simplify the function syntax, and (b) speed up simplified
% execution.
global hFOV_global

%% Check input(s)
narginchk(1,4);

% Set default(s)
targetSpecs0.Diameter = 5*25.4;         % Diameter in millimeters
targetSpecs0.HorizontalBias = 0;        % Horizontal bias in millimeters
targetSpecs0.VerticalBias = 0;          % Vertical bias in millimeters
targetSpecs0.Color = 'Dark Orange';     % Target color
targetSpecs0.Wobble = rand*deg2rad(10); % Wobble in radians
targetSpecs0.Shape = 'Circle';          % Target shape

% Default angle
angle0 = deg2rad( 25*(2*rand - 1) ); % Random value between -25 and 25.
angle = angle0;

% Use global FOV
useGlobal = false;
if nargin < 4
    if isstruct(hFOV_global)
        if isfield(hFOV_global,'Figure')
            if ishandle(hFOV_global.Figure)
                useGlobal = true;
            end
        end
    end
    
    if useGlobal
        % Check for pre-existing target(s)
        if isfield(hFOV_global,'getTargetImage')
            % Return turret to zero configuration
            set(hFOV_global.Frames.h_r2b,'Matrix',hFOV_global.getTargetImage.H_r2b_0)
            hFOV_global.Frames.H_r2b = hFOV_global.getTargetImage.H_r2b_0;
            % Remove pre-existing target(s)
            delete(hFOV_global.getTargetImage.h_a2r);
            % Remove "getTargetImage" field
            hFOV_global = rmfield(hFOV_global,'getTargetImage');
        end
        % Update turret struct
        h = hFOV_global;
    else
        h = createEW309RoomFOV('Ri080');
        hFOV_global = h;
        useGlobal = true;
    end
    set(h.Figure,'Visible','off');
    
    idxSTART = 1;
else
    h = varargin{1};
    idxSTART = 2;
end

% Parse remaining inputs and 
% range,angle,targetSpecs
if nargin > idxSTART - 1
    range = varargin{idxSTART}*10;
    idxSTART = idxSTART+1;
end
if nargin > idxSTART - 1
    angle = varargin{idxSTART};
    idxSTART = idxSTART+1;
    
    if isempty(angle)
        angle = angle0;
    end
end
if nargin > idxSTART - 1
    targetSpecs = varargin{idxSTART};
    idxSTART = idxSTART+1;
else
    targetSpecs = targetSpecs0;
end

%% Check target specs
if ~isstruct(targetSpecs)
    error('"targetSpecs" must be defined as a structured array. Please use "createTargetSpecs" to create this variable.'); 
end
fieldNames = {'Diameter','HorizontalBias','VerticalBias','Color','Wobble','Shape'};
bin = isfield(targetSpecs,fieldNames);
% Populate default values
for i = 1:numel(bin)
    if ~bin(i)
        targetSpecs.(fieldNames{i}) = targetSpecs0.(fieldNames{i});
    end
end

%% Set room defaults
%{
walls = {'NE','NW','SW','SE'};
% Set room defaults
switch h.Room
    case 'Ri078'
        error('Offset settings for Ri078 are not defined, please use Ri080.');
    case 'Ri080'
        turretSpecs.HorizontalOffset = -6.0*12*25.4;
        turretSpecs.VerticalOffset   =  0.5*25.4;
        turretSpecs.Angle = angle;
        wall = walls{3};
    otherwise
        error('Room "%s" is not recognized.',h.Room);
end
%}
[turretSpecs,wall] = getDefaultsEW309RoomFOV(h,angle);

%% Place target
[hNEW,h_a2r] = setupTurretAndTarget(h,targetSpecs,range,turretSpecs,wall);
drawnow;

%% Get an image
im = getFOVSnapshot(hNEW);

%% Return FOV to original state
if useGlobal
    % Update global
    hFOV_global = hNEW;
    % Append zero configuration
    hFOV_global.getTargetImage.H_r2b_0 = h.H_r2b;
    % Append parent of target(s)
    hFOV_global.getTargetImage.h_a2r = h_a2r;
    % Append angle information
    hFOV_global.getTargetImage.angle = angle;
    % Append range information
    hFOV_global.getTargetImage.range = range;
    % Append bias information
    % TODO - This needs to have an equivalent in the "else" category!!!
    hFOV_global.getTargetImage.xbias = targetSpecs.HorizontalBias;
    hFOV_global.getTargetImage.ybias = targetSpecs.VerticalBias;
else
    set(hNEW.Frames.h_r2b,'Matrix',h.H_r2b);
    hNEW.H_r2b = h.H_r2b;
    
    % Debugging calculations
    %{
H_a2r = h_a2r.Matrix;
H_r2b = h.Frames.h_r2b.Matrix;
H_b2c = h.Frames.h_b2c.Matrix;

H_r2c = H_a2r^(-1);
H_a2c = H_b2c*H_r2b*H_a2r
    %}
    
    delete(h_a2r);
end