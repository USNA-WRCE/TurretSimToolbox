%% SCRIPT_ViewRoom
% This script shows the 3D visualization of the "room" 
%
%   M. Kutzer, 14Feb2023, JHU/USNA

clear all
close all
clc

%% Define classrooms
rooms = {'Ri078','Ri080'};

%% Cycle through rooms
for k = 1:numel(rooms)
    % Close all figures
    close all

    % Define filename
    fname = sprintf('Camera FOV, %s.fig',rooms{k});

    % Open figure
    warning off
    open(fname);
    warning on

    axs_fov = findobj('Type','Axes');
    h_o2a = get(axs_fov,'Children');
    setTriad(h_o2a,'Scale',1000);

    % Create new figure & move visualization
    fig = figure;
    axs = axes('Parent',fig,'DataAspectRatio',[1 1 1],'NextPlot','add');
    set(h_o2a,'Parent',axs);
    view(axs,3);

    H_o2a = get(h_o2a,'Matrix');

    h_o2w = h_o2a;
    set(h_o2w,'Matrix',eye(4));

    H_a2o = invSE(H_o2a);
    h_a2o = triad('Parent',h_o2w,'Matrix',H_a2o,'Scale',1000);


    set(axs,'Visible','off');
    view(axs,[-40,40]);

    % Highlight lights
    lgts = findobj('Type','Light');

    for i = 1:numel(lgts)
        lgt = lgts(i);
        X_lgt = get(lgt,'Position');
        mom = get(lgt,'Parent');

        plt_lgt(i) = plot3(mom,X_lgt(1),X_lgt(2),X_lgt(3),'o',...
            'MarkerEdgeColor','w','MarkerFaceColor','m','MarkerSize',10);
    end
    drawnow
    
    % Save image
    sname = sprintf('3D View, %s.png',rooms{k});
    saveas(fig,sname,'png');
end