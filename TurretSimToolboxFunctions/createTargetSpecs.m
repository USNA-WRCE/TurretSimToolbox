function targetSpecs = createTargetSpecs(varargin)
% CREATETARGETSPECS allows a user to specify target specifications in
% centimeters to define a target using a "targetSpecs" structured array.
%   targetSpecs = CREATETARGETSPECS prompts the user to specify target
%   parameters.
%
%   targetSpecs = CREATETARGETSPECS(diameter) specifies the diameter in
%   centimeters, and uses default settings for all other parameters.
%
%   targetSpecs = CREATETARGETSPECS(diameter,hBias,vBias) specifies the
%   horizontal and vertical bias in centimeters.
%
%       NOTE: The vertical bias is referenced to the center of the NERF
%             barrel. If you want to center the target with the center of
%             the camera frame, please *add 10cm to your vBias*.
%
%   targetSpecs = CREATETARGETSPECS(diameter,hBias,vBias,color) specifies
%   the color.
%
%       color = {'Bright Yellow','Bright Pink','Bright Green',...
%           ['Dark Orange'],'Light Orange','Dark Red','Light Red'}
%
%   targetSpecs = CREATETARGETSPECS(diameter,hBias,vBias,color,shape) 
%   specifies the shape.
%
%       shape = {['Circle'],'Square','Random Rectangle',...
%           'Equilateral Triangle','Random Triangle','Random Polygon'};
%
%   NOTE: This function will assign a random "wobble" parameter to the
%   target between 0 and 10 degrees.
%
%   M. Kutzer, 31Mar2020, USNA

%% Define color and shape arrays
colors = {'Bright Yellow','Bright Pink','Bright Green',...
    'Dark Orange','Light Orange','Dark Red','Light Red'};
shapes = {'Circle','Square','Random Rectangle',...
    'Equilateral Triangle','Random Triangle','Random Polygon'};

%% Check input(s)
narginchk(0,5)

% Set defaults
targetSpecs.Diameter = 5*25.4;          % Diameter in millimeters
targetSpecs.HorizontalBias = 0;         % Horizontal bias in millimeters
targetSpecs.VerticalBias = 0;           % Vertical bias in millimeters
targetSpecs.Color = 'Dark Orange';      % Target color
targetSpecs.Wobble = rand*deg2rad(10);  % Wobble in radians
targetSpecs.Shape = 'Circle';           % Target shape

if nargin == 0
    prompt = {...
        'Enter target diameter (cm):',...
        'Enter horizontal bias (cm):',...
        'Enter vertical bias (cm):'};
    dlgtitle = 'Target Values';
    dims = [1 35];
    definput = {num2str(5*2.54),num2str(0),num2str(0)};
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    
    if isempty(answer)
        error('Please specify target values.');
    end
    
    [idxC,tf] = listdlg('ListString',colors,'SelectionMode','single',...
        'InitialValue',4,'Name','Target Color');
    
    if ~tf
        error('Please specify target color.');
    end
    
    [idxS,tf] = listdlg('ListString',shapes,'SelectionMode','single',...
        'InitialValue',1,'Name','Target Shape');
    
    if ~tf
        error('Please specify target shape.');
    end
    
    targetSpecs.Diameter = str2double(answer{1})*10;        % Diameter in millimeters
    targetSpecs.HorizontalBias = str2double(answer{2})*10;  % Horizontal bias in millimeters
    targetSpecs.VerticalBias = str2double(answer{3})*10;    % Vertical bias in millimeters
    targetSpecs.Color = colors{idxC};                       % Target color
    targetSpecs.Shape = shapes{idxS};                       % Target shape
end

if nargin > 0
    targetSpecs.Diameter = varargin{1}*10;
end
if nargin > 1
    targetSpecs.HorizontalBias = varargin{2}*10;
end
if nargin > 2
    targetSpecs.VerticalBias = varargin{3}*10;
end
if nargin > 3
    targetSpecs.Color = varargin{4};
end
if nargin > 4
    targetSpecs.Shape = varargin{5};
end

%% Check selections
if ~any( strcmpi(colors,targetSpecs.Color) )
    str01 = sprintf('"%s" is not a valid color. Please select one of the following:\n',targetSpecs.Color);
    str02 = sprintf('\t"%s"\n',colors{:});
    error('%s%s',str01,str02);
end

if ~any( strcmpi(shapes,targetSpecs.Shape) )
    str01 = sprintf('"%s" is not a valid color. Please select one of the following:\n',targetSpecs.Shape);
    str02 = sprintf('\t"%s"\n',shapes{:});
    error('%s%s',str01,str02);
end