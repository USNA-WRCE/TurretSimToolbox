function [h_a2r,objs] = createCrosshair(varargin)
% CREATECROSSHAIR creates a series of patch and text objects to render a
% crosshair.
%   [h_a2r] = CREATECROSSHAIR
%
%   [h_a2r] = CREATECROSSHAIR(axs)
%
%   [h_a2r] = CREATECROSSHAIR(axs,lims)
%
%       lims = [lower, upper];
%
%   [h_a2r] = CREATECROSSHAIR(axs,lims,dtick)
%
%       dtick - scalar value 0:dtick:lims(2) & 0:-dtick:lims(1)...
%
%   [h_a2r] = CREATECROSSHAIR(axs,lims,dtick,units)
%
%       units = {'millimeters',['centimeters'],'meters','inches','feet'}
%
%   [h_a2r] = CREATECROSSHAIR(axs,lims,dtick,units,color)
%
%   [h_a2r] = CREATECROSSHAIR(axs,lims,dtick,units,color,width)
%
%       width - scalar width of "lines"
%
%   [h_a2r,objs] = CREATECROSSHAIR(___)
%   
%   M. Kutzer, 30Mar2020

%% Check input(s)
narginchk(0,6);

% Set defaults
axs = gca;
lims = [-50, 50];
dtick = 10;
units = 'centimeters';
color = 'w';
width = 1;

% Parse input(s)
if nargin > 0
    axs = varargin{1};
end
if nargin > 1
    lims = varargin{2};
end
if nargin > 2
    dtick = varargin{3};
end
if nargin > 3
    units = varargin{4};
end
if nargin > 4
    color = varargin{5};
end
if nargin > 5
    width = varargin{6};
end

switch lower( get(axs,'type') )
    case 'axes'
        hold(axs,'on');
end

%% Convert to standard units
switch lower( units )
    case 'millimeters'
        conversion = 1;
        sUnits = 'mm';
    case 'centimeters'
        conversion = 10;
        sUnits = 'cm';
    case 'meters'
        conversion = 1000;
        sUnits = 'm';
    case 'inches'
        conversion = 25.4;
        sUnits = 'in';
    case 'feet'
        conversion = 25.4*12;
        sUnits = 'ft';
    otherwise
        error('Specified units "%s" are not recognized.',units);
end

mm_lims  = lims.*conversion;
mm_dtick = dtick.*conversion;
mm_width = width.*conversion;

%% Render crosshair and ticks
h_a2r = triad('Parent',axs,'Scale',0.75*diff(mm_lims)/2,'LineWidth',1.5);
hideTriad(h_a2r);

faces = 1:4;
hVerts = [...
     mm_lims(1), mm_lims(2), mm_lims(2), mm_lims(1);...
    -mm_width/2,-mm_width/2, mm_width/2, mm_width/2];
vVerts = [...
    -mm_width/2, mm_width/2, mm_width/2,-mm_width/2;...
     mm_lims(1), mm_lims(1), mm_lims(2), mm_lims(2)];

objs(1) = patch('Parent',h_a2r,'Vertices',hVerts.','Faces',faces,...
    'FaceColor',color,'EdgeColor','None','FaceLighting','none');
objs(2) = patch('Parent',h_a2r,'Vertices',vVerts.','Faces',faces,...
    'FaceColor',color,'EdgeColor','None','FaceLighting','none');

tlims = 5*[-mm_width, mm_width];
% Horizontal ticks
hTicks = [...
        tlims(1),    tlims(2),    tlims(2),    tlims(1);...
     -mm_width/2, -mm_width/2,  mm_width/2,  mm_width/2];
tPos_p = 0: mm_dtick:mm_lims(2);
tPos_n = 0:-mm_dtick:mm_lims(1);
tPos_p(1) = [];
tPos_n(1) = [];
tPos = [sort(tPos_n),tPos_p];
for i = 1:numel(tPos)
    XY = repmat([0; tPos(i)], 1, 4);
    objs(end+1) = patch('Parent',h_a2r,'Vertices',(hTicks+XY).',...
        'Faces',faces,'FaceColor',color,'EdgeColor','None',...
        'FaceLighting','none');
    hTickIDX(i) = numel(objs);
end

% Vertical ticks
vTicks = [...
     -mm_width/2,  mm_width/2,  mm_width/2, -mm_width/2;...
        tlims(1),    tlims(1),    tlims(2),    tlims(2)];
tPos_p = 0: mm_dtick:mm_lims(2);
tPos_n = 0:-mm_dtick:mm_lims(1);
tPos_p(1) = [];
tPos_n(1) = [];
tPos = [sort(tPos_n),tPos_p];
for i = 1:numel(tPos)
    XY = repmat([tPos(i); 0], 1, 4);
    objs(end+1) = patch('Parent',h_a2r,'Vertices',(vTicks+XY).',...
        'Faces',faces,'FaceColor',color,'EdgeColor','None',...
        'FaceLighting','none');
    vTickIDX(i) = numel(objs);
end

%% Add text
% Horizontal text
tPos_p = 0: dtick:lims(2);
tPos_n = 0:-dtick:lims(1);
tPos_p(1) = [];
tPos_n(1) = [];
tPos = [sort(tPos_n),tPos_p];
for i = 1:numel(hTickIDX)
    j = hTickIDX(i);
    str = sprintf('%.2f%s',tPos(i),sUnits);
    verts = get(objs(j),'Vertices');
    switch sign(tPos(i))
        case 1
            XY = [verts(2,:); verts(3,:)].';
            hAlign = 'Left';
            vAlign = 'Middle';
        case -1
            XY = [verts(1,:); verts(4,:)].';
            hAlign = 'Right';
            vAlign = 'Middle';
        otherwise
            error('HELP ME');
    end
    objs(end+1) = text(h_a2r,mean(XY(1,:)),mean(XY(2,:)),str,...
        'HorizontalAlignment',hAlign,'VerticalAlignment',vAlign,...
        'FontSize',8,'Color',color);%,'Rotation',90);
end

% Vertical text
tPos_p = 0: dtick:lims(2);
tPos_n = 0:-dtick:lims(1);
tPos_p(1) = [];
tPos_n(1) = [];
tPos = [sort(tPos_n),tPos_p];
for i = 1:numel(vTickIDX)
    j = vTickIDX(i);
    str = sprintf('%.2f%s',tPos(i),sUnits);
    verts = get(objs(j),'Vertices');
    switch sign(tPos(i))
        case 1
            XY = [verts(1,:); verts(2,:)].';
            hAlign = 'Right';
            vAlign = 'Middle';
        case -1
            XY = [verts(3,:); verts(4,:)].';
            hAlign = 'Left';
            vAlign = 'Middle';
        otherwise
            error('HELP ME');
    end
    objs(end+1) = text(h_a2r,mean(XY(1,:)),mean(XY(2,:)),str,...
        'HorizontalAlignment',hAlign,'VerticalAlignment',vAlign,...
        'FontSize',8,'Color',color,'Rotation',90);
end

%% Update tag(s)
set(h_a2r,'Tag','Crosshair');
