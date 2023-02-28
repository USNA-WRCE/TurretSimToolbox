function cPatch = createTargetColorPatch(varargin)
% CREATETARGETCOLORPATCH creates a patch of color that statistically
% matches the samples gathered from the EW309 classroom. 
%   cPatch = CREATETARGETCOLORPATCH(color) creates a 200x200 pixel color
%   patch for the specified color.
%
%   cPatch = CREATETARGETCOLORPATCH(color,res) creates an NxM pixel color
%   patch for the specified color where res = [N,M].
%
%   cPatch = CREATETARGETCOLORPATCH(color,res,param) specifies whether the
%   color patch should be 'random' (default), 'uniform random', or 'uniform
%   mean'. 
%       param = {['random'], 'uniform random', 'uniform mean'}
%
%   Valid color selections include:
%       'Bright Yellow'
%       'Bright Pink'
%       'Bright Green'
%       'Dark Orange'
%       'Light Orange'
%       'Dark Red'
%       'Light Red'
%
%   M. Kutzer, 25Mar2020, USNA

%% Parse inputs
narginchk(1,3);

color = varargin{1};
if nargin > 1
    res = varargin{2};
else
    res = [400,400];
end

if nargin > 2
    param = varargin{3};
else
    param = 'random';
end

%% Load statistics
%load( fullfile('targets','ColorStats.mat') );
load('ColorStats.mat');

%% Assign color statistics
switch lower(color)
    case 'bright yellow'
        mu    = colorStats.bright_yellow.mean;
        Sigma = colorStats.bright_yellow.cov;
    case 'bright pink'
        mu    = [254,  1,154];
        Sigma = colorStats.bright_yellow.cov;
    case 'bright green'
        mu    = [ 57,255, 20];
        Sigma = colorStats.bright_yellow.cov;
    case 'dark orange'
        mu    = colorStats.dark_orange.mean;
        Sigma = colorStats.dark_orange.cov;
    case 'light orange'
        mu    = colorStats.light_orange.mean;
        Sigma = colorStats.light_orange.cov;
    case 'dark red'
        mu    = [139,  0,  0];
        Sigma = colorStats.dark_orange.cov;
    case 'light red'
        mu    = [255,204,203];
        Sigma = colorStats.light_orange.cov;
    otherwise
        error('Specified color "%s" is not recognized.',color);
end

%% Statistically generate pixels
switch lower( param )
    case 'random'
        n = res(1) * res(2); % total number of values to generate
        RGB = mvnrnd(mu,Sigma,n);
        RGB = uint8(RGB);
        
        r = RGB(:,1);
        g = RGB(:,2);
        b = RGB(:,3);
        cPatch(:,:,1) = reshape(r,res(1),res(2));
        cPatch(:,:,2) = reshape(g,res(1),res(2));
        cPatch(:,:,3) = reshape(b,res(1),res(2));
    case 'uniform random'
        n = 1; % total number of values to generate
        RGB = mvnrnd(mu,Sigma,n);
        RGB = uint8(RGB);
        
        r = RGB(:,1);
        g = RGB(:,2);
        b = RGB(:,3);
        cPatch(:,:,1) = repmat(r,res(1),res(2));
        cPatch(:,:,2) = repmat(g,res(1),res(2));
        cPatch(:,:,3) = repmat(b,res(1),res(2));
    case 'uniform mean'
        r = mu(1);
        g = mu(2);
        b = mu(3);
        cPatch(:,:,1) = repmat(r,res(1),res(2));
        cPatch(:,:,2) = repmat(g,res(1),res(2));
        cPatch(:,:,3) = repmat(b,res(1),res(2));
    otherwise
        error('Unrecognized selection parameter "%s"',param);
end