function TurretSimPerformanceEval
% TURRETSIMPERFORMANCEEVAL displays the target and shot pattern in a
% body-fixed coordinate frame allowing users to easily assess hits. 
%
%   M. Kutzer, 03Apr2020, USNA
%
% NOTE: This function was originally named with a typo was identified by 
%       T. Severson on 20Apr2020.

global hFOV_global

%% Get hangles
kids = get(hFOV_global.getTargetImage.h_a2r,'Children');

h_aw2a = findobj(kids,'Type','hgtransform','Tag','Wobble Frame');
h_s2a  = findobj(kids,'Type','hgtransform','Tag','Shot Pattern Frame');

ptc_nShots = findobj( h_s2a,'Type','patch');
ptc_Target = findobj(h_aw2a,'Type','patch');

%% Create figure
fig = figure('Name','EW309corona Performance Summary','Units','Normalized',...
    'Position',[0,0,0.75,0.75]);
centerfig(fig);
axs = axes('Parent',fig);
title(axs,'EW309corona Performance Summary');
hold(axs,'on');
daspect(axs,[1 1 1]);
xlabel('x (mm)');
ylabel('y (mm)');

% Create a new target "aim" frame relative to axes
h_a = triad('Parent',axs,'Visible','off');
% Create a new wobbled frame relative to target "aim" frame 
H_aw2a = get(h_aw2a,'Matrix');
h_aw2a = triad('Parent',h_a,'Matrix',H_aw2a,'Visible','off');
% Create a new shot pattern frame relative to the target "aim" frame
H_s2a = get(h_s2a,'Matrix');
if isempty(H_s2a)
    warning('No shot pattern found! Please run getShotPatternImage.m before running this function.');
    H_s2a = eye(4);
end
h_s2a = triad('Parent',h_a,'Matrix',H_s2a,'Visible','off');

% Display target
ptc = copyobj(ptc_Target,h_aw2a);
set(ptc,'EdgeColor','k','FaceAlpha',0.3);
% Display shots
sho = copyobj(ptc_nShots,h_s2a);
set(sho,'EdgeColor','k','FaceAlpha',0.5);
% Number shots
for i = 1:numel(sho)
    % Get vertices
    v = get(sho(i),'Vertices').';
    % Find centroid
    polyin = polyshape(v(1,:),v(2,:));
    [x,y] = centroid(polyin);
    % Add number 
    txt(i) = text(x,y,sprintf('%d',i),'Parent',h_s2a,'HorizontalAlignment','Center','VerticalAlignment','Middle');
end

axis(axs,'tight');