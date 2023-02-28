function im = getFOVSnapshot(h)
% GETFOVSNAPSHOT returns an image from the simulated EW309 FOV.
%   im = GETFOVSNAPSHOT(h) returns an image given the structured array "h"
%   created by createEW309RoomFOV.m.
%
%   M. Kutzer, 28Mar2020, USNA

%% Check inputs
narginchk(1,1);

% TODO - Check h

%% Get image
frm = getframe(h.Figure);
im = frm.cdata;

if size(im,1) ~= 480
    % Wrong image size!
    %   - Brute force correct!
    im = imresize(im,[480,640]);
end