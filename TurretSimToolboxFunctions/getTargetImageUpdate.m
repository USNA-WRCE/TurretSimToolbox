function im = getTargetImageUpdate(relative_angle)
%GETTARGETIMAGEUPDATE update global FOV simulation with relative angle
%information.
%   im = GETTARGETIMAGEUPDATE(relative_angle) moves the current turret FOV
%   by a designated relative angle in radians.
%
%   M. Kutzer, 02Apr2020, USNA


%% Define global FOV simulation
% Yes, I realize that globals are generally lazy coding, but I am doing
% this to (a) simplify the function syntax, and (b) speed up simplified
% execution.
global hFOV_global

%% Check input(s)
narginchk(1,1);

% Check global
useGlobal = false;
if isstruct(hFOV_global)
    if isfield(hFOV_global,'Figure')
        if ishandle(hFOV_global.Figure)
            useGlobal = true;
        end
    end
end

errSTR = 'You need to run "getTargetImage.m" before using this function.';
if ~useGlobal
    error(errSTR);
end

if isfield(hFOV_global,'getTargetImage')
    % Get angle
    angle = hFOV_global.getTargetImage.angle + relative_angle;
    % Update turret struct
    h = hFOV_global;
else
    error(errSTR);
end

%% Move the turret
%
% Review frame definitions
%   Frame c - camera frame 
%   Frame r - room center frame
%   Frame b - barrel frame
%   Frame a - target "aim" frame
%   Frame e - barrel "end" frame 
%   Frame w - room "west" frame (in lower west corner)
%
% Review of hgTransforms contained in h.Frames
%   h_b2c - Barrel relative to Camera   (FIXED TRANSFORM)
%   h_r2b - Room relative to Barrel
%   h_w2r - West relative to Room       (FIXED TRANSFORM)

% Get current pose of the room relative to the barrel frame
H_r2b = get(h.Frames.h_r2b,'Matrix');
% Get current pose of the barrel relative to the room frame
H_b2r = H_r2b^(-1);
% Define updated pose of barrel relatove to room
H_b2r_NEW = H_b2r*Rz(relative_angle);
% Define updated pose of room relative to barrel
H_r2b_NEW = H_b2r_NEW^(-1);
% Set current pose of the room relative ot the barrel frame
set(h.Frames.h_r2b,'Matrix',H_r2b_NEW);
drawnow;

%% Update struct info
h.H_r2b = H_r2b_NEW;

%% Get an image
im = getFOVSnapshot(h);

%% Update global angle
% Recover target image info
getTargetImageINFO = hFOV_global.getTargetImage;

% Update global
hFOV_global = h;
% Recover getTargetImage field info
hFOV_global.getTargetImage = getTargetImageINFO;

% Update zero configuration
hFOV_global.getTargetImage.H_r2b_0 = get(h.Frames.h_r2b,'Matrix');
% Update angle information
hFOV_global.getTargetImage.angle = angle;
