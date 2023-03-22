function buildFigures
% BUILDFIGURES builds the complete figures used for the TurretSimToolbox
% using individual images and saved parent/child structure.

%% Define paths
buildPath = 'buildFigures';
savePath = 'TurretSimToolboxFunctions';

%% Define filename info
roomNames = {'Ri078','Ri080'};
wallNames = {'NE Wall','NW Wall','SE Wall','SW Wall'};

%% Create temp figure & axes
tmpFig = figure('Visible','Off','Tag','Temp Figure, buildFigures.m');
tmpAxs = axes('Parent',tmpFig,'Tag','Temp Axes, buildFigures.m');

%% Create updated figures
warning off
for i = 1:numel(roomNames)
    % Open figure
    figureName = sprintf('Camera FOV, %s.fig',roomNames{i});
    open( fullfile(buildPath,figureName) );

    % Status update
    fprintf('Creating "%s"...\n',figureName);

    % Recover figure handle
    fig = findobj('Type','Figure',...
        'Name','Simulated Camera FOV (Approximate)');
    
    if ~isempty(fig)
        fig = fig(1);
    else
        error('No figure was found.');
    end
    
    for j = 1:numel(wallNames)
        % Define image tag & name
        imageTag = sprintf('%s Image',wallNames{j});
        imageName = sprintf('%s, %s.png',imageTag,roomNames{i});

        % Status update
        fprintf('\tAdding "%s"...',imageTag);

        % Load image
        im = imread( fullfile(buildPath,imageName) );

        % Define image parent tag & parent
        parentTag = sprintf('%s Dewarp Frame',wallNames{j});
        mom = findobj(fig(1),'Tag',parentTag,'Type','hgTransform');

        % Plot image
        img = imshow(im,'Parent',tmpAxs);
        set(img,'Parent',mom,'Tag',imageTag);

        drawnow

        % Status update
        fprintf('[COMPLETE]\n');
    end

    % Status update
    fprintf('\tSaving figure...');

    % Save figure
    saveas(fig, fullfile(savePath,figureName) );

    % Status update
    fprintf('[COMPLETE]\n');

    % Delete figure
    delete(fig);

    drawnow
end
warning on

% Delete temp figure
delete(tmpFig)