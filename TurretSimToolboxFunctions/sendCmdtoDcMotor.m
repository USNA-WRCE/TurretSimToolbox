function [SSE,ts,varargout] = sendCmdtoDcMotor(mode,control_params,varargin)
% SENDCMDTODCMOTOR emulates the behavior of the EW309 turret platforms
% under various user-specified operational conditions. The Primary outputs
% of the function are the steady-state error and settling time of the
% closed-loop system. However, optional input and output arguments can be
% specified to configure the system to simulate various open- or
% closed-loop configurations.
%   [SSE,ts] = SENDCMDTODCMOTOR(mode,control_params)
%
%   [SSE,ts] = SENDCMDTODCMOTOR(mode,control_params,time)
%
%   [SSE,ts] = SENDCMDTODCMOTOR(mode,control_params,time,q0)
%
%   [SSE,ts,time,theta,omega,duty_cycle,eint] = SENDCMDTODCMOTOR(___)
%
%   Inputs:
%       mode: control operational mode: 'step' or 'closed'
%               'step' mode applies a step input at t=1.0 seconds of
%               user-specified PWM duty cycle
%               'closed' mode uses a PID controller with user-specified
%               gains
%       control_params: data structure containing control input parameters
%        The following parameters are necessary when in closed-loop mode
%           control_params.despos: desired pointing angle in radians. This is the
%                                  reference input to the closed-loop controller
%           control_params.Kp: proportional gain on closed-loop controller
%           control_params.Ki: integral gain on closed-loop controller
%           control_params.Kd: derivative gain on closed loop controller
%           control_params.SS_threshold: motor speed considered to be "steady-state"
%                                        defaults to 1 deg/s if not
%                                        specified
%        The following parameters are necessary when in step input mode
%           control_params.stepPWM: PWM duty cycle magnitude (0-1) of step
%           input (only applies to open-loop operational mode)
%
%   Optional inputs:
%       [SSE,ts] = sendCmdtoDcMotor('closed',control_params,time)
%           time: time array to use in simulating the motor e.g. t=0:.1:3;
%       [SSE,ts] = sendCmdtoDcMotor('closed',control_params,time,q0)
%           q0: initial condition of motor, as a vector of initial
%           position, initial speed, initial armature current, and initial
%           integral error, e.g.
%           theta0 = 0; dtheta=0; i0 = 0; e0 = 0; q0 = [theta0;dtheta0;i0;e0]
%
%   Output: 
%       SSE: the position error, assuming the response came to rest (i.e.
%            reached steady-state). SSE is computed using the last 10% of
%            the complete response
%       ts : Structure containing the settling time and the index number
%            where the response reaches steady-state
%
%   Optional Outputs (in order of output):
%       time: Time array used in the simulation. 
%       theta: Angular position in radians at time array points given in
%              the array time
%       omega: Angular velocity in radians/secong evaluates at the
%              instances in time denoted by the time array output, time
%       duty_cycle: The duty cycle represented as a fraction [-1,1] applied
%              at the time instances given be the time array output, time
%       eint: The integral of the position error (rad*s) evaluated at the
%             time points given in the output time array, time.
%
%
%
%
% Example usage (closed-loop control):
%   cntrlprms.despos = pi/4;
%   cntrlprms.Kp = 0.5;
%   cntrlprms.Ki = 0.02;
%   cntrlprms.Kd = 0.02;
%   cntrlprms.SS_threshold = 1*pi/180; % 1 deg/s or less defines s-s
%   t = 0:.05:10;
%   [SSE,ts,t,theta,omega,dc,eint] = sendCmdtoDcMotor('closed',cntrlprms,t);
% OR
%   SSE = sendCmdtoDcMotor('closed',cntrlprms,t);
%
%
% Example usage (open-loop step input):
%   cntrlprms.stepPWM = 0.45; % 45% duty cycle step input
%   t = 0:.05:10;
%   [SSE,ts,t,theta,omega,dc,eint] = sendCmdtoDcMotor('step',cntrlprms,t);
% OR
%   SSE = sendCmdtoDcMotor('step',cntrlprms,t,[0;0;0;0]);
%
%   L. DeVries, USNA, EW309, AY2020


% handle additional input quantities
if nargin == 3
    t = varargin{1};
    % initial condition
    theta0 = 0;
    dtheta0 = 0;
    i0 = 0;
    q0 = [theta0;dtheta0;i0;0];
elseif nargin == 4
    t = varargin{1};
    q0 = varargin{2};
elseif nargin > 4
    error('Too many inputs')
else
    t = 0:.01:10;
    % initial condition
    theta0 = 0;
    dtheta0 = 0;
    i0 = 0;
    q0 = [theta0;dtheta0;i0;0];
end


% Motor constants
motorParams.Ra = 5; % Armature resistance (Ohms)
motorParams.La = 0.2*10^-1; % Armature inductance (H) (~10^-3)
motorParams.Bm = .027; % coefficient of friction (Nm*s/rad)
motorParams.Km = .95; % transducer constant (Nm*s/rad) (amp*H/rad)
motorParams.J = 0.15*10^0; % moment of inertial
motorParams.friction.a0 = 0.15; % positive spin static friction (Nm)
motorParams.friction.a1 = 0.25; % positive spin coulumb friction coefficient
motorParams.friction.a2 = 1.3; % speed decay constant on coulumb friction
motorParams.friction.a3 = .36; % negative spin static friction (Nm)
motorParams.friction.a4 = 0.25; % negative spin coulumb friction coefficient
motorParams.friction.a5 = 1; % speed decay constant on coulumb friction
motorParams.friction.del = 0.05; % rad/s "linear zone" of friction
motorParams.dzone.pos = 0.25; % ten percent duty cycle on positive side 0.25 comes from trials
motorParams.dzone.neg = 0.25; % twenty percent on negative side 0.25 comes from trials


% switch operational modes (closed- or open-loop)
switch mode
    case 'closed'
        fprintf('Simulating closed-loop motor dynamics....\n');
        fprintf('for %.1f seconds with time step %.2f seconds...\n',t(end),t(end)-t(end-1));
        fprintf('Initial position: %.1f rad\n',q0(1))
        fprintf('Initial velocity: %.1f rad/s\n',q0(2))
        
        stopCondition = 0;
        while(stopCondition==0)
            
            motorParams.case = 3; % closed loop control case
            % integrate EOM
            fprintf('Starting model integration...')
            [~,Q] = ode45(@MotDynHF_sc,t,q0,[],motorParams,control_params);
            fprintf('Done.\n')
            fprintf('Checking if response reached steady-state...\n')
            
            % quantify if the response has settled
            dt = t(end)-t(end-1); % time step from simulation
            hlfsec_steps = 0.5/dt; % number of time steps in a half second
            
            % assume settled when speed is near zero
            ex = isfield(control_params,'SS_threshold'); % use user-specified threshold if provided, default to 1 deg/s
            if ex==0
                ind = find(abs(Q(:,2))<0.0175); % less than 1 degree per second
            else
                ind = find(abs(Q(:,2))<control_params.SS_threshold); % user-provided s-s threshold
            end
            
            lng = length(ind); % number of indices with slow speed
            
            if lng<=hlfsec_steps % if there are less indices than 1/2 second, it could not have reached steady-state
                fprintf('condition 1: not settled for 1/2 second\n')
                fprintf('Initial simulation time-span did not result in a steady-state\n')
                t = 0:dt:(t(end)+5);
                fprintf('extending simulation time to %.2f and re-simulating....',t(end))
                
                stopCondition = 0;
            else % may have reached steady-state, further analysis required
                
                if ind(end)==length(t) % if the last time step lies within "stop" condition
                    
                    % check if there is a half second of points that are slow
                    tmp = sum(diff(ind(end-uint8(hlfsec_steps):end)));
                    
                    if tmp==uint8(hlfsec_steps) % case implies the last 0.5 seconds were in s-s     
                        stopCondition = 1;
                        fprintf('Response reached steady-state.\n')
                    else % in this case the last time step was in s-s, but not long enough to be sufficient
                        fprintf('Response appears to have settled, but not long enough to be conclusive.\n')
                        t = 0:dt:(t(end)+2);
                        fprintf('Extending simulation time to %.2f and re-simulating....\n',t(end))
                        stopCondition = 0;
                    end
                else % if last time step is not slow, can't be in s-s
                    fprintf('condition 2: final speed not slow enough\n')
                    fprintf('Initial simulation time-span did not result in a steady-state\n')
                    t = 0:dt:(t(end)+5);
                    fprintf('Extending simulation time to %.2f and re-simulating....\n',t(end))
                                        
                    stopCondition = 0;
                end
            end
        end
        
        
        
        tmp = Q(end-round(hlfsec_steps):end,1);
        ssval = mean(tmp); % find the average of the last 1/2 second
        
        % steady-state error
        SSE = control_params.despos - ssval;

        % compute settling time
        ts_inds = find(abs(Q(:,1)-ssval)/ssval<=0.02); % find indices where response is within 2 percent of s-s
        ts_diffs = diff(ts_inds); % find dividers in clusters of points within 2 percent (e.g. if there is a crossing of s-s)
        clusters = find(ts_diffs>1); % jumps of greater than 1 mean a crosing of s-s
        if isempty(clusters)==1 % case where it does not overshoot
            % KUTZER FIX
            try
                % Response was found
                ts.time = t(ts_inds(1));
                ts.index = ts_inds(1);
            catch
                % No response found
                warning(sprintf('Steady state did not reach within 2%% of the steady state threshold.\n\t\t -> Check your gains!'));
                ts.time = inf;
                ts.index = nan;
            end
        else % case where it overshoots
            ts.time = t(ts_inds(clusters(end)+1)); % choose last crossing time
            ts.index = ts_inds(clusters(end)+1); % isolate last crossing index
        end
        
        % reconstruct control signal
        err = control_params.despos - Q(:,1); % position error
 
        % PID controller
        dc = control_params.Kp*err + control_params.Ki*Q(:,4) - control_params.Kd*Q(:,2);
        dc(dc>1) = 1;
        dc(dc<-1) = -1;
        
    case 'step'
        
        fprintf('Simulating motor dynamics with open-loop step input\n');
        fprintf('for %.1f seconds with time step %.2f seconds...\n',t(end),t(end)-t(end-1));
        fprintf('Initial position: %.1f rad\n',q0(1))
        fprintf('Initial velocity: %.1f rad/s\n',q0(2))
        fprintf('Step input duty cycle magnitude: %.2f \n',control_params.stepPWM)
        
        motorParams.case = 2; % step input case
        if abs(control_params.stepPWM)>1
            error('PWM Duty cycle can not have a magnitude greater than 1')
        end
        % integrate EOM
        fprintf('Starting model integration...')
        [~,Q] = ode45(@MotDynHF_sc,t,q0,[],motorParams,control_params);
        fprintf('Done\n')
        % steady-state error (non-existent for step input)
        SSE = NaN;
        
        % settling time (not applicable)
        ts = NaN;
        
        % reconstruct control signal
        dc = zeros(size(Q(:,1)));
        dc(t>=1) = control_params.stepPWM;
    otherwise
        error('Invalid operating mode. Operating mode must be step or closed');
end

% % % plot results
% % fig3 = figure(3); clf
% % plot(t,Q_cl(:,1))
% % hold on
% % plot(t,cntrlprms.despos*ones(size(t)),'--r')
% % legend('Closed-loop Response', 'Desired Position')
% % xlabel('Time (s)')
% % ylabel('Orientation (rad)')

% orientation
out(:,1) = t; % time vector
out(:,2) = Q(:,1); % theta
out(:,3) = Q(:,2); % omega
out(:,4) = dc;     % duty cycle
out(:,5) = Q(:,4); % error integral

% Optional outputs
nout = max(nargout,1)-2;
for k = 1:nout
    varargout{k} = out(:,k);
end

end


function dQ = MotDynHF_sc(t,Q,params,cntrlprms)
%MotDynHF simulates high fidelity dynamics of a DC motor. The model
%includes nonlinear input deadzone and Stribeck Friction.
%   INPUTS:
%       t: time, scalar value for current time of integration
%       Q: 4x1 dimensional state vector at time t, Q = [position; velocity;
%       current; error integral]
%       params: data structure containing motor parameters
%           params.Ra: motor armature resistance (Ohms)
%           params.La: motor armature inducatnce (H)
%           params.Bm: coefficient of linear friction (Nm*s/rad)
%           params.Km: transducer constant (Nm*s/rad) (amp*H/rad)
%           params.J: moment of inertia (Kg*m^2)
%           params.friction.a0: positive spin static friction (Nm)
%           params.friction.a1: positive spin coulumb friction coefficient (Nm)
%           params.friction.a2: speed decay constant on coulumb friction (unitless
%           params.friction.a3: negative spin static friction (Nm)
%           params.friction.a4: negative spin coulumb friction coefficient
%           params.friction.a5: speed decay constant on coulumb friction
%           params.friction.del: approximation of stiction range (rad/s)
%           params.dzone.pos: dead zone for positive inputs (duty cycle)
%           params.dzone.neg: dead zone for negative inputs (duty cycle)
%           params.case: operational case to simulate
%                       1 = sinusoidal input, amplitude 1, period 10 second
%                       2 = step input, user-specified magnitude (0-1),
%                       step input is applied at t=1.0 second
%                       3 = closed loop control
%            
%       cntrlprms: data structure containing operational mode (open- or closed-loop)
%                  and parameters of operation (PID control gains or
%                  open-loop step input duty cycle)
%           cntrlprms.mode: operational mode ('open' or 'closed')
%           cntrlprms.despos: desired position (rad)
%           cntrlprms.Kp: proportional gain
%           cntrlprms.Ki: integral gain
%           cntrlprms.Kd: derivative gain
%           cntrlprms.stepPWM: duty cycle magnitude of step input (0-1)
%   OUTPUT:
%       dQ: 4x1 derivative of state vector Q at time t
%
%   Example Usage: (open-loop sine wave input)
%       motorParams.Ra = 5; % Armature resistance (Ohms)
%       motorParams.La = 0.2*10^-1; % Armature inductance (H) (~10^-3)
%       motorParams.Bm = .027; % coefficient of friction (Nm*s/rad)
%       motorParams.Km = .95; % transducer constant (Nm*s/rad) (amp*H/rad)
%       motorParams.J = 0.15*10^0; % moment of inertial
%       motorParams.friction.a0 = 0.15; % positive spin static friction (Nm)
%       motorParams.friction.a1 = 0.25; % positive spin coulumb friction coefficient
%       motorParams.friction.a2 = 1.3; % speed decay constant on coulumb friction 
%       motorParams.friction.a3 = .36; % negative spin static friction (Nm)
%       motorParams.friction.a4 = 0.25; % negative spin coulumb friction coefficient
%       motorParams.friction.a5 = 1; % speed decay constant on coulumb friction
%       motorParams.friction.del = 0.05; % rad/s "linear zone" of friction
%       motorParams.dzone.pos = 0.25; % ten percent duty cycle on positive side 0.25 comes from trials 
%       motorParams.dzone.neg = 0.25; % twenty percent on negative side 0.25 comes from trials
%       cntrlprms.despos = 0;
%       cntrlprms.Kp = 0;
%       cntrlprms.Ki = 0;
%       cntrlprms.Kd = 0;
%       cntrlprms.stepPWM = 0.45;
% 
%       % initial conditions
%       t = 0:.01:3;
%       theta0 = 0; % position
%       dtheta0 = 0; % angular velocity
%       i0 = 0; % initial current
%       q0 = [theta0;dtheta0;i0;0]; % initial state vector
%       motorParams.case = 1; % (for testing/development) case one, sinusoidal input
%       [~,Q] = ode45(@MotDynHF,t,q0,[],motorParams,cntrlprms);
%
% L. DeVries, Ph.D., USNA
% EW309, AY2020
% Last edited 3/22/2020



% control input
switch params.case % test cases for simulation 
    case 1 % sinusoidal data, compare to experimental data
        if t<0.45
            dc = 0;
        else
            dc = sin(2*pi/10*t);
        end
        err = 0;
    case 2 % positive step input, compare to experimental data
        if t<1
            dc = 0;
        else
            dc = cntrlprms.stepPWM;
        end
        err = 0;
        if dc>1.0
            dc = 1.0;
        elseif dc<-1.0
            dc = -1.0;
        end
        
    case 3 % closed loop control, for students
        err = cntrlprms.despos - Q(1);
 
        % PID controller
        dc = cntrlprms.Kp*err + cntrlprms.Ki*Q(4) - cntrlprms.Kd*Q(2);
        if dc>1.0
            dc = 1.0;
        elseif dc<-1.0
            dc = -1.0;
        end
end

% introduce deadzone here! Use EW305 results to quantify!
if dc<params.dzone.pos && dc>-params.dzone.neg
    dc = 0;
end

% voltage from duty cycle
u = 12*dc;

% motor torque when assuming inductance is negligible
ia = 1/params.Ra*(u-params.Km*Q(2)); % armature current
Tm = params.Km*ia; % torque

% torque limit motor. This cold also be done by dialing in Km
if Tm>0.89294 % Nm torque limit based on torque speed curve analysis
    Tm = 0.89294;
elseif Tm<-0.89294
    Tm = -0.89294;
end

% use this motor torque when assuming inductance is not negligible
% Tm = params.Km*Q(3);

% equations of motion (EOM)
dQ(1,1) = Q(2); % dtheta = omega
dQ(2,1) = 1/params.J*(Tm - params.Bm*Q(2) - frictionNL_sc(Q(2),params)); % domega = torques and friction

% electrical circuit EOM (assumes non-negligible inductance) (set to zero
% if ignoring inductance)
dQ(3,1) = 0;%1/params.La*(u - params.Km*Q(2) - params.Ra*Q(3)); % di/dt = circuit equation with inductance

% avoid windup
alp = (err/50).^4; % weighting function approaches zero sharply as error approaches 100 rad*s

dQ(4,1) = (1-alp)*err; % error integral term
end



function Tf = frictionNL_sc(omega,params)
% compute nonlinear friction term in DC motor model
Tf = (params.friction.a0 + params.friction.a1)/params.friction.del*omega;

indmd = omega <0 & omega > -params.friction.del;
Tf(indmd) = (params.friction.a3 + params.friction.a4)/params.friction.del*omega(indmd);

indp = omega>=params.friction.del;
Tf(indp) =   params.friction.a0 + params.friction.a1*exp( - (params.friction.a2*abs( omega(indp) - params.friction.del) )) ;

indm = omega <= -params.friction.del;
Tf(indm) = -(params.friction.a3 + params.friction.a4*exp( - (params.friction.a5*abs( omega(indm) + params.friction.del) )));

end

% function [position,isterminal,direction] = SSEEventsFcn(t,Q)
% 
% if t>2
%     position = 
% end
% isterminal = 1;  % Halt integration 
% direction = 0;   % The zero can be approached from either direction 
% end