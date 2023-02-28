function [mu,Sigma] = MVfit2MVstats(range)
% MVFIT2MVSTATS calculates the mean and covariance for a given range using
% loaded "MVfit" data.
%   [mu,Sigma] = MVFIT2MVSTATS(range) calculates the mean and covariance
%   for a designated range in centimeters.
%
%   M. Kutzer, 01Apr2020, USNA

%% Check input(s)
narginchk(1,1);

%% Load MVfit
load('MVfit.mat','MVfit');

%% Get fit parameters for designated range
sigFit.Axis(1,1) = polyval(MVfit.Axis1,range);
sigFit.Axis(1,2) = polyval(MVfit.Axis2,range);
sigFit.Angle = polyval(MVfit.Angle,range);
mu(1,1) = polyval(MVfit.MeanX,range);
mu(1,2) = polyval(MVfit.MeanY,range);

%% Recover Sigma
% Sigma.Axis(i,:)  = sqrt(diag(D)).';
D = diag( (sigFit.Axis.^2).' );

% Sigma.Angle(i,1) = atan2(V(2,1),V(1,1));
V = [...
    cos(sigFit.Angle),-sin(sigFit.Angle);...
    sin(sigFit.Angle), cos(sigFit.Angle)];

Sigma = V*D*V^(-1);