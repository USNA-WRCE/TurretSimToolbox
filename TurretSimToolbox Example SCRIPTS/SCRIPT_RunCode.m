%% SCRIPT_RunCode
% This script cycles through capabilities iturret simulation
% environment.
%
%   M. Kutzer, 14Feb2023, JHU/USNA

clear all
close all
clc

%% Create EW309 classroom simulation ("Classroom B")
% This syntax uses a structured array "h" to track the handles associated
% with the simulation.

% NOTE: Two room options are available - room \in {'Ri078', 'Ri080'}
h = createEW309RoomFOV('Ri080');

%% Get calibration image
% This allows users to get calibration images at multiple ranges
ranges = 100:100:400; % (cm)
for range = ranges
    im = getCalibrationImage(h,range);
    fname = sprintf('CalibrationImage%04dcm.png',range);
    imwrite(im,fname,'png');
end

%% Get shot pattern
% Demonstrate shot pattern at multiple ranges
ranges = 100:100:400; % (cm)
nShots = 10;
for range = ranges
    im = getShotPatternImage(h,range,nShots);
    fname = sprintf('ShotPatternImage%04dcm.png',range);
    imwrite(im,fname,'png');
end

%% Get shot pattern
% Demonstrate shot pattern at multiple ranges
range = 400; % (cm)
nShots = 10;
for i = 1:4
    im = getShotPatternImage(h,range,nShots);
    fname = sprintf('ShotPatternImage%04dcm_%d.png',range,i);
    imwrite(im,fname,'png');
end

%% Create EW309 classroom simulation ("Classroom B")
% This syntax uses a global variable to track the handles associated
% with the simulation.

clear all
close all
clc

%% Create target specifications
diameter = 12.7;
%targetSpecs = createTargetSpecs;
targetSpecs = createTargetSpecs(diameter);
%targetSpecs = createTargetSpecs(diameter,hBias,vBias)
%targetSpecs = createTargetSpecs(diameter,hBias,vBias,color)
%targetSpecs = createTargetSpecs(diameter,hBias,vBias,color,shape)

%% Get target image
range = 300;
angle = deg2rad(5);
%im = getTargetImage(range);
%im = getTargetImage(range,angle);
%im = getTargetImage(range,angle,targetSpecs);
im = getTargetImage(range,angle,targetSpecs);

%% Get shot pattern
nShots = 12;
im = getShotPatternImage(nShots);

fig = figure('Name','Shot Pattern Image');
img = imshow(im);
axs = get('Parent',img);

%% Evaluate performance
TurretSimPerformanceEval;