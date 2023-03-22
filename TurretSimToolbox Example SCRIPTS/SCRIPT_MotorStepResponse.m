%% SCRIPT_MotorStepResponse
% This script illustrates a motor step response for varying PWM signals
%
%   M. Kutzer, 14Sep2023, JHU/USNA

clear all
close all
clc

%% Evaluate step response
mode = 'step';
PWMs = linspace(-1,1,100);
for i = 1:numel(PWMs)
    PWM = PWMs(i);
    control_params.stepPWM = PWM;
    [~,~,t(:,i),theta(:,i),~,duty_cycle(:,i)] = sendCmdtoDcMotor(mode,control_params);
end

PWMs = repmat(PWMs,size(t,1),1);

%% SURF PWM
fig = figure;
axs = axes('Parent',fig,'NextPlot','add');
srf = surf(axs,PWMs,t,theta);
set(srf,'EdgeColor','none');
xlabel(axs,'Signed PWM');
ylabel(axs,'Time (s)');
zlabel(axs,'Turret Angle (rad)');

xx = xlim(axs);
yy = ylim(axs);
zz = zlim(axs);
ys = 1;

% Highlight where step is applied
verts = [...
    xx(1),xx(2),xx(2),xx(1);...
    ys(1),ys(1),ys(1),ys(1);...
    zz(1),zz(1),zz(2),zz(2)].';
faces = 1:4;
ptc = patch('Parent',axs,'Vertices',verts,'Faces',faces,'EdgeColor','none',...
    'FaceColor','k','FaceAlpha',0.2);

% Highlight dead zone
X = [...
    reshape(PWMs ,1,[]);...
    reshape(t    ,1,[]);...
    reshape(theta,1,[])];
tf = ...
    X(2,:) >= 1 & X(3,:) == 0;
plot3(axs,X(1,tf),X(2,tf),X(3,tf),'.r');
%verts = X(:,tf).';
%faces = convhull(X(1,tf),X(2,tf)).';
%ptc(2) = patch('Parent',axs,'Vertices',verts,'Faces',faces,'EdgeColor','none',...
%    'FaceColor','r','FaceAlpha',0.2);

view(axs,3);
xlim(axs,xx);
ylim(axs,yy);
zlim(axs,zz);

%% SURF Duty Cycle
% This shows that the step occurs at 1 second (note that display to user is
% incorrect). 
% fig = figure;
% axs = axes('Parent',fig);
% srf = surf(axs,PWMs,t,duty_cycle);
% set(srf,'EdgeColor','none');
% xlabel(axs,'Signed PWM');
% ylabel(axs,'Time (s)');
% zlabel(axs,'Duty Cycle');