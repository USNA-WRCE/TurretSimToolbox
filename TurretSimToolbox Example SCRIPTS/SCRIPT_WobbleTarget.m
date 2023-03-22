%% SCRIPT_WobbleTarget
% This script shows various target "wobble" configurations.
%
%   M. Kutzer, 28Feb2023, JHU/USNA

clear all
close all
clc

%% Create EW309 classroom simulation ("Classroom B")
% NOTE: Two room options are available - room \in {'Ri078', 'Ri080'}
h = createEW309RoomFOV('Ri080');

%% Create target specifications
diameter = 12.7;
hBias =  0;
vBias = 10;
%targetSpecs = createTargetSpecs;
%targetSpecs = createTargetSpecs(diameter);
targetSpecs = createTargetSpecs(diameter,hBias,vBias);
%targetSpecs = createTargetSpecs(diameter,hBias,vBias,color)
%targetSpecs = createTargetSpecs(diameter,hBias,vBias,color,shape)

%% Get target image
% Approximate crop region (for 50 cm range)
%  [248.5100  169.5100  144.9800  142.9800]
rect = [245, 170, 150, 140];
range = 50;
angle = deg2rad(0);
wobbles = deg2rad( 0:10:20 );

for wobble = wobbles
    for i = 1:6
        targetSpecs.Wobble = wobble;
        im = getTargetImage(h,range,angle,targetSpecs);
        
        % Crop image
        im = imcrop(im,rect);

        str = sprintf('Wobble%.2f_%d',rad2deg(wobble),i);
        %figure; imshow(im); title(str);
        %pause
        imwrite(im,[str,'.png'],'png');
    end
end
