function varargout = TurretSimToolboxVer
% TURRETSIMTOOLBOXVER provides version information for the EW309 Corona Software
% package.
%
%   M. Kutzer, 14Apr2020, USNA

A.Name = 'EW309 NERF Blaster & 1D Turret Simulation Toolbox';
A.Version = '1.3.0';
A.Release = '(R2019a)';
A.Date = '28-Apr-2020';
A.URLVer = 1;

msg{1} = sprintf('MATLAB %s Version: %s %s',A.Name, A.Version, A.Release);
msg{2} = sprintf('Release Date: %s',A.Date);

n = 0;
for i = 1:numel(msg)
    n = max( [n,numel(msg{i})] );
end

fprintf('%s\n',repmat('-',1,n));
for i = 1:numel(msg)
    fprintf('%s\n',msg{i});
end
fprintf('%s\n',repmat('-',1,n));

if nargout == 1
    varargout{1} = A;
end