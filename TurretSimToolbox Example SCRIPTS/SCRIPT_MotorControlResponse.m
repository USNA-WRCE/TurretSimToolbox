%% SCRIPT_MotorControlResponse
% This script shows how the motor model responds to a set of control gains.
%
%   M. Kutzer, 14Feb2023, JHU/USNA

clear all
close all
clc

%% Evaluate control gains
mode = 'closed';

theta_d(1) =  deg2rad(10);    % Reference input
theta_d(2) = -deg2rad(10);    % Reference input

Kp = []; Ki = []; Kd = [];

% DeVries Student Example 01
Kp(end+1) = 0.8742;  % STUDENT DEFINED VALUE, Proportional Gain (Kp)
Ki(end+1) = 0.4653;  % STUDENT DEFINED VALUE, Integral Gain (Ki)
Kd(end+1) = 0.3504;  % STUDENT DEFINED VALUE, Derivative Gain (Kd)

% Kutzer Student Example 01
Kp(end+1) = 1.7754;  % STUDENT DEFINED VALUE, Proportional Gain (Kp)
Ki(end+1) = 0.9413;  % STUDENT DEFINED VALUE, Integral Gain (Ki)
Kd(end+1) = 0.7502;  % STUDENT DEFINED VALUE, Derivative Gain (Kd)

time = linspace(0,10,100);

for j = 1:numel(theta_d)
    control_params.despos = theta_d(j);
    for i = 1:numel(Kp)
        control_params.Kp = Kp(i);  % STUDENT DEFINED VALUE, Proportional Gain (Kp)
        control_params.Ki = Ki(i);  % STUDENT DEFINED VALUE, Integral Gain (Ki)
        control_params.Kd = Kd(i);  % STUDENT DEFINED VALUE, Derivative Gain (Kd)

        % Simulate response
        [SSE,ts,t,theta] = sendCmdtoDcMotor(mode,control_params,time);

        % Plot results
        fig = figure;
        axs = axes('Parent',fig,'NextPlot','add');

        plt(1) = plot(axs,t,theta);
        plt(2) = plot(axs,t,repmat(control_params.despos,size(t)),'--k');

        xlabel(axs,'Time (s)');
        ylabel(axs,'Turret Angle (rad)');

        xlim(axs,[time(1),time(end)]);

        yy = sort( [0,sign(theta(end))*0.2]);
        ylim(axs,yy);

        txt = text(axs,mean(xlim(axs)),control_params.despos,...
            sprintf('SSE = %.4f (rad)',SSE),...
            'HorizontalAlignment','Center','VerticalAlignment','bottom',...
            'FontSize',12);
        
        if theta(end) < 0
            set(txt,'VerticalAlignment','top');
        end

        str = sprintf('K_p = %.4f | K_i = %.4f | K_d = %.4f',Kp(i),Ki(i),Kd(i));
        ttl = title(axs,str);

        %saveas(fig,...
        %    sprintf('ControlResponse%d_%d.png',i,j),'png');
    end
end