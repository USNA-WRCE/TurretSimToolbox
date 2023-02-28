function [h_a2r,ptc] = createTarget(varargin)
% CREATETARGET draws a target of specified shape, size, and color and 
% returns the graphics object(s) associated with the target.
%   [h_a2r,ptc] = CREATETARGET(shape,diameter,color) creates a shape 
%   specifiedby a string argument whose overall size fits within a 
%   bounding circle of the specified diameter in millimeters. The 
%   specified color is then used to fill the patch object that is created. 
%   Both the patch object and an hgtransform parent of the patch of object 
%   are returned.
%
%   [h_a2r,ptc] = CREATETARGET(axs,shape,diameter,color) specifies the 
%   parent handle for the target (e.g. an axes or hgtransform).
%
%   Valid shape selections include:
%       'Circle'
%       'Square'
%       'Random Rectangle'
%       'Equilateral Triangle'
%       'Random Triangle'
%       'Random Polygon'
%
%   Valid color selections include:
%       'Bright Yellow'
%       'Bright Pink'
%       'Bright Green'
%       'Dark Orange'
%       'Light Orange'
%       'Dark Red'
%       'Light Red'
%
%   M. Kutzer, 25Mar2020, USNA

%% Check input(s)
narginchk(3,4);

if nargin == 3
    axs = gca;
    shape = varargin{1};
    diameter = varargin{2};
    color = varargin{3};
end

if nargin == 4
    axs = varargin{1};
    shape = varargin{2};
    diameter = varargin{3};
    color = varargin{4};
end

if ~ishandle(axs)
    error('Specified axes must be a valid axes handle.');
end
if ~isscalar(diameter)
    error('Diameter must be specified as a scalar value in millimeters.');
end

%% Parse Shape
r = diameter/2;
switch lower(shape)
    case 'circle'
        n = 100;
        theta_i = 0;
        theta_f = 2*pi;
        theta = linspace(theta_i,theta_f,n+1);
        theta(end) = [];
        verts = [r*cos(theta); r*sin(theta)].';
        faces = 1:n;
    case 'square'
        n = 4;
        theta_i = 0;
        theta_f = 2*pi;
        theta = linspace(theta_i,theta_f,n+1) + (pi/4)*ones(1,n+1);
        theta(end) = [];
        verts = [r*cos(theta); r*sin(theta)].';
        faces = 1:n;
    case 'random rectangle'
        n = 4;
        theta_i = (pi/2) * rand;
        alpha_i = pi/2 - theta_i;
        theta = [theta_i, theta_i + 2*alpha_i, 3*theta_i + 2*alpha_i, 3*theta_i + 4*alpha_i];
        verts = [r*cos(theta); r*sin(theta)].';
        faces = 1:n;
    case 'equilateral triangle'
        n = 3;
        theta_i = 0;
        theta_f = 2*pi;
        theta = linspace(theta_i,theta_f,n+1) + (pi/2)*ones(1,n+1);
        theta(end) = [];
        verts = [r*cos(theta); r*sin(theta)].';
        faces = 1:n;
    case 'isosceles triangle'
        n = 3;
        theta_i = (pi/2) * rand;
        alpha_i = pi/2 - theta_i;
        theta = [theta_i, theta_i + 2*alpha_i, 3*pi/2] + pi * ones(1,3);
        verts = [r*cos(theta); r*sin(theta)].';
        faces = 1:n;
    case 'random triangle'
        n = 3;
        dtheta = sort( (2*pi/3)*rand(1,n) );
        theta = dtheta + [(1/2)*(2*pi/3), (3/2)*(2*pi/3), (5/2)*(2*pi/3)] + (pi+pi/4)*ones(1,n);%cumsum(dtheta);
        verts = [r*cos(theta); r*sin(theta)].';
        faces = 1:n;
    case 'random polygon'
        n = randi([3,10],1);
        theta = sort( 2*pi*rand(1,n) );
        verts = [r*cos(theta); r*sin(theta)].';
        faces = 1:n;
    otherwise
        error('Specified shape "%s" is not recognized.',shape);
end

%% Load color
% TODO - update color based on dpi and diameter.
res = [1,1];
cPatch = createTargetColorPatch(color,res,'uniform mean');

%% Create patch object and triad
switch lower( get(axs,'Type') )
    case 'axes'
        hold(axs,'on');
        daspect(axs,[1 1 1]);
end

% Create target coordinate system
h_a2r = triad('Parent',axs,'Scale',0.75*r,'LineWidth',1.5);
hideTriad(h_a2r); % Hide the "triad" visualization
% Create the patch object 
ptc = patch('Parent',h_a2r,'Vertices',verts,'Faces',faces,...
    'FaceColor',double(reshape(cPatch,1,3))./256,...
    'EdgeColor','none','Tag','Target');
% Update the "material" finish of the patch object
materialsSTR = {'shiny','dull','metal'};
material(ptc,materialsSTR{2});              % Dull finish, selected by 
                                            % T. Severson & L. DeVries,
                                            % 27Mar2020, EW309.
 
%% Plot circle for debugging
%{
n = 100;
theta_i = 0;
theta_f = 2*pi;
theta = linspace(theta_i,theta_f,n+1);
verts = [r*cos(theta); r*sin(theta)].';
plot(hg,verts(:,1),verts(:,2),'m');
%}

return

%% WORK IN PROGRESS
% Based on D. Evangelista' "warp" the image
% NOTE THAT THIS CURRENTLY DOES NOT WORK.
% Easy fixes:
%   (1) If the function patch2surf exists.
%   (2) Someone can easily make a "surf" of the geometries considered.

%% Load color
nPnts = 200;
res = [nPnts,nPnts];
cPatch = createTargetColorPatch(color,res);

[X,Y] = meshgrid(linspace(-r,r,nPnts),linspace(-r,r,nPnts));

[in,on] = inpolygon(X,Y,verts(:,1),verts(:,2));
bin = in | on;
X = X(bin);
Y = Y(bin);

%plot(X,Y,'.b');

X = reshape(X,1,[]);
Y = reshape(Y,1,[]);
Z = zeros(size(X));

h_a2r = triad('Parent',axs,'Scale',0.75*r,'LineWidth',1.5);
ptc = warp( X,Y,Z,cPatch);
set(ptc,'Parent',h_a2r);

%% Update tag(s)
set(h_a2r,'Tag','Target');