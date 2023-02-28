function objs = renderShotPattern(axs,xCM,yCM)
% RENDERSHOTPATTERN renders the x/y impact coordinates of a shot pattern
% using the 2.3cm diameter of NERF Rival Ammo.
%   objs = RENDERSHOTPATTERN(axs,xCM,yCM) specifies the parent "axs" of the
%   rendered shot pattern (can be an axes or hgtransform object, and the x
%   and y position of each impact relative to the point of aim. The x and y
%   point of impact are specified in centimeters
%
%   M. Kutzer, 01Apr2020, USNA

%% Check input(s)
narginchk(3,3);

if ~ishandle(axs)
    error('Specified parent must be a valid handle.');
end

switch lower( get(axs,'type') )
    case 'axes'
        hold(axs,'on');
end

%% Render POA
objs = [];
objs(end+1,1) = plot(axs,[-150,150],[0,0],'w');
objs(end+1,1) = plot(axs,[0,0],[-150,150],'w');

%% Render shot pattern
rMM = (2.3*10)/2;   % Ball radius in millimeters
n = 50;             % Number of points used to render circle
phi = linspace(0,2*pi,n+1); 
phi(end) = [];

verts = [rMM*cos(phi); rMM*sin(phi)].';
faces = 1:n;
color = [245,225,0]./256;

scale = 1.25;
for i = 1:numel(xCM)
    xyMM = [xCM(i),yCM(i)]*10;    % xy position in millimeters
    vertsNOW = verts + repmat(xyMM,size(verts,1),1);

    x0 = [xyMM(1),xyMM(1)];
    y0 = [xyMM(2),xyMM(2)];
    xh = scale*[-rMM,rMM] + x0;
    yh = scale*[-rMM,rMM] + y0;
    
    objs(end+1,1) = patch('Parent',axs,'Faces',faces,'Vertices',vertsNOW,...
        'FaceColor',color,'EdgeColor','none','FaceLighting','none');
    %{
    objs(end+1,1) = patch('Parent',axs,'Faces',faces,'Vertices',vertsNOW,...
        'FaceColor',color,'EdgeColor','g','FaceLighting','none');
    objs(end+1,1) = plot(axs,xh,y0,'g');
    objs(end+1,1) = plot(axs,x0,yh,'g');
    %}
end

