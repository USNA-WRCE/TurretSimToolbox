function im = getShotPatternImage(varargin)
% GETSHOTPATTERNIMAGE creates a simulated image of a shot pattern on the SW
% chalkboard of Ri080.
%   im = GETSHOTPATTERNIMAGE(range,nShots) creates a simulated image of a 
%   shot pattern and point of ain on an EW309 chalkboard. The variable 
%   "range" must be specified in *centimeters*. The number of shots is  
%   specified using "nShots". The variable "nShots" must be an integer 
%   value greater than 0. 
%
%   im = GETSHOTPATTERNIMAGE(nShots) can only be run after getTargetImage.m
%
%   im = GETSHOTPATTERNIMAGE(h,range,nShots) uses a pre-defined FOV 
%   specified using the strucured array h. Use "createEW309RoomFOV.m".
%
%   M. Kutzer, 01Apr2020, USNA

%% Define global FOV simulation
% Yes, I realize that globals are generally lazy coding, but I am doing
% this to (a) simplify the function syntax, and (b) speed up simplified
% execution.
global hFOV_global

%% Check input(s)
narginchk(1,3);

% Set default(s)
targetSpecs.Diameter = 20;             % Diameter in millimeters
targetSpecs.HorizontalBias = 0;        % Horizontal bias in millimeters
targetSpecs.VerticalBias = 0;          % Vertical bias in millimeters
targetSpecs.Color = 'Bright Green';    % Target color
targetSpecs.Wobble = 0;                % Wobble in radians
targetSpecs.Shape = 'Circle';          % Target shape
% Define default xbias
% TODO - we need this information when h is specified?
xbias = 0;

% Use global FOV
useGlobal = false;
if nargin < 3
    if isstruct(hFOV_global)
        if isfield(hFOV_global,'Figure')
            if ishandle(hFOV_global.Figure)
                useGlobal = true;
            end
        end
    end
    
    if useGlobal
        if nargin > 1 % <- We want a "fresh" shot pattern
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
        end
        % Get xbias information <--- KUTZER FIX, 28Apr2020
        if isfield(hFOV_global,'getTargetImage')
            if isfield(hFOV_global.getTargetImage,'xbias')
                xbias = hFOV_global.getTargetImage.xbias;
            end
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

if nargin > idxSTART - 1
    rangeCM = varargin{idxSTART}; % Range in centimeters
    rangeMM = rangeCM*10;         % Range im millimeters
    idxSTART = idxSTART+1;
end
if nargin > idxSTART - 1
    nShots = varargin{idxSTART};
    idxSTART = idxSTART+1;
end

if nargin > 1
    %% Set room defaults
    [turretSpecs,wall] = getDefaultsEW309RoomFOV(h,0);
    
    %% Place target frame
    [hNEW,h_a2r,objs] = setupTurretAndTarget(h,targetSpecs,rangeMM,turretSpecs,wall); % Range must be spefi
    drawnow;
    
    % Hide target
    set(objs,'Visible','off');
else
    if ~isfield(hFOV_global,'getTargetImage')
        error('You need to run getTargetImage.m prior to running this function with a single input.');
    end
    % Recover range
    rangeCM = (hFOV_global.getTargetImage.range)/10;
    % Define shots
    nShots = varargin{1};
    % Define shot reference frame
    h_a2r = hFOV_global.getTargetImage.h_a2r;
    % Define "unwobbled" shot reference frame
    % Review of hgTransforms contained in h.Frames
    %   h_b2c - Barrel relative to Camera   (FIXED TRANSFORM)
    %   h_r2b - Room relative to Barrel
    %   h_w2r - West relative to Room       (FIXED TRANSFORM)
    %
    % Additional frame definitions
    %   Frame aw - "wobbled" target "aim" frame (target parent)
    %   Frame a  - "unwobbled" target "aim" frame
    
    H_a2r = get(h_a2r,'Matrix'); % Unwobbled frame
    H_r2a = H_a2r^(-1);
    H_r2b = get(hFOV_global.Frames.h_r2b,'Matrix');
    H_b2r = H_r2b^(-1);
    
    % Define barrel relative to unwobbled frame 
    H_b2a = H_r2a*H_b2r;     % barrel relative to target "aim" frame
    y_b2a = H_b2a(1:3,2);
    phi = atan2(y_b2a(1),-y_b2a(3));
    a = H_b2a(3,4);
    x = a*tan(phi);        % <---- ORIGINAL CODE!
    %x = a*tan(phi) - xbias; % <--- KUTZER FIX, 28Apr2020
    y = H_b2a(2,4);
    H_s2a = Tx(x)*Ty(y);
    
    % Define unwobbled frame
    h_s2a  = triad('Parent',h_a2r,'Scale',150,'LineWidth',1.5,...
        'Tag','Shot Pattern Frame','Matrix',H_s2a);
    hideTriad(h_s2a); % Hide the "triad" visualization
    
    % Find xy plane of 
    % Overwrite shot pattern parent
    % -> This bastardizes the notation for this one special case
    h_a2r = h_s2a;
    
    hNEW = hFOV_global;
end

%% Get Shot Pattern
[x,y] = getShotPattern(rangeCM,nShots);

%% Render shot pattern
objs = renderShotPattern(h_a2r,x,y);
drawnow;
im = getFOVSnapshot(hNEW);

%% Return FOV to original state
if useGlobal && (nargin == 1)
    % Get Info
    hFOV_global.getShotPatternImage.x = x;
    hFOV_global.getShotPatternImage.y = y;
else
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
end
