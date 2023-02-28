function [x,y] = getShotPattern(range,nShots)
% GETSHOTPATTERN generates a shot pattern given a range and total number of
% shots.
%   [x,y] = GETSHOTPATTERN(range,nShots) calculates the x and y coordinates
%   for the point of impact relative to the point of aim in centimeters
%   given the range to the target (range, specified in centimeters and a 
%   total number of shots (nShots).
%
%   M. Kutzer, 01Apr2020, USNA

%% Check inputs
narginchk(2,2);

%% Get mean and covariance
[mu,Sigma] = MVfit2MVstats(range);

%% Generate shot pattern
xy = mvnrnd(mu,Sigma,nShots);

%% Format outputs
x = xy(:,1);
y = xy(:,2);