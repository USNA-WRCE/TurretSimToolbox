function im = getCalibrationImage(varargin)
% GETCALIBRATIONIMAGE creates a simulated image of a calibration grid on 
% the SW chalkboard of the Ri080.
%   im = GETCALIBRATIONIMAGE(range) creates a simulated image of a
%   calibration grid on an EW309 classroom chalkboard. The variable "range"
%   must be specified in *centimeters*.
%
%   im = GETCALIBRATIONIMAGE(h,range) creates a simulated image of a
%   calibration grid on an EW309 classroom chalkboard. The variable "h" is
%   the structured array returned by "createEW309RoomFOV" and "range" must 
%   be specified in *centimeters*.
%
%   M. Kutzer, 30Mar2020, USNA

%% Define global FOV simulation
% Yes, I realize that globals are generally lazy coding, but I am doing
% this to (a) simplify the function syntax, and (b) speed up simplified
% execution.
global hFOV_global

%% Check input(s)
narginchk(1,2);

if nargin == 1
    range = varargin{1};
    useGlobal = false;
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
    end
    set(h.Figure,'Visible','off');
end

if nargin == 2
    h = varargin{1};
    range = varargin{2};
end

%% Convert range to millimeters
range = 10*range;

%% Get image
% Set room defaults
%{
walls = {'NE','NW','SW','SE'};
switch h.Room
    case 'Ri078'
        error('Offset settings for Ri078 are not defined, please use Ri080.');
    case 'Ri080'
        hOffset = -6*12*25.4;
        vOffset = 0.5*25.4;
        theta = 0;
        w = 3;
    otherwise
        error('Room "%s" is not recognized.',h.Room);
end


% Define turret specs
turretSpecs.HorizontalOffset = hOffset;
turretSpecs.VerticalOffset = vOffset;
turretSpecs.Angle = theta;

wall = walls{w};
%}
[turretSpecs,wall] = getDefaultsEW309RoomFOV(h,0);

% Define target specs
hBias = 0;              % Align the target with the camera
vBias = h.H_b2c(2,4);   % Align the target with the camera

targetSpecs.Diameter = 5*25.4;      % Unused
targetSpecs.HorizontalBias = hBias; % Horizontal bias
targetSpecs.VerticalBias = vBias;   % Vertical bias
targetSpecs.Color = 'w';            % Crosshair color
targetSpecs.Wobble = 0;             % Wobble
targetSpecs.Shape = 'Crosshair';    % Type

[hNEW,h_a2r] = setupTurretAndTarget(h,targetSpecs,range,turretSpecs,wall);
drawnow;
im = getFOVSnapshot(hNEW);

%% Return FOV to original state
hNEW.Frames.h_r2b = h.H_r2b;
hNEW.H_r2b = h.H_r2b;

% Debugging calculations
%{
H_a2r = h_a2r.Matrix;
H_r2b = h.Frames.h_r2b.Matrix;
H_b2c = h.Frames.h_b2c.Matrix;

H_r2c = H_a2r^(-1);
H_a2c = H_b2c*H_r2b*H_a2r;
%}

delete(h_a2r);
