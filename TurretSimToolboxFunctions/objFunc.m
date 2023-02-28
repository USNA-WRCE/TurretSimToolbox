function metric = objFunc(x,dat)
%OBJFUNC The objective function for the EW309 turret model.
%   metric = OBJFUNC(x,dat) specifies the fit parameters for the EW309
%   turrent model "x" and the data used to fit the model.
%       x ------ 1x3 array
%           x = [b, a, delta] where b is the numerator of the plant 
%               transfer function, and a and delta are the poles.
%       dat ---- nx3 array
%       metric - scalar root mean squared describing the "goodness of fit" 
%
%   Example Usage:
%       t = ___;	- Data collected from mbed (Nx1 vector)
%       PWM = ___;	- Data collected from mbed (Nx1 vector)
%       theta = ___; 	- Data collected from mbed (Nx1 vector)
%
%       uniform_t = linspace(min(t),max(t),numel(t))';
%       uniform_PWM = interp1(t,PWM,uniform_t);
%       uniform_theta = interp1(t,theta,uniform_t);
%
%       dat = [uniform_PWM, uniform_t, uniform_theta];
%       x = [b,a,delta];
%
%       metric = objFunc(x,dat)
%
%   L. DeVries, 22Mar2020, USNA

s = tf('s');
H = x(1)/((s+x(2))*(s+x(3)));
out = lsim(H,dat(:,1),dat(:,2));
metric = sqrt(mean((dat(:,3)-out).^2));

end

