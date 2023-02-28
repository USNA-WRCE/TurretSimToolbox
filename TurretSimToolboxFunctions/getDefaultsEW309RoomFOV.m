function [turretSpecs,wall] = getDefaultsEW309RoomFOV(h,angle)
% GETDEFAULTSEW309ROOMFOV sets the default values for a room field of view.
%
%   M. Kutzer, 01Apr2020, USNA

walls = {'NE','NW','SW','SE'};
% Set room defaults
switch h.Room
    case 'Ri078'
        error('Offset settings for Ri078 are not defined, please use Ri080.');
    case 'Ri080'
        turretSpecs.HorizontalOffset = -6.0*12*25.4;
        turretSpecs.VerticalOffset   =  0.5*25.4;
        turretSpecs.Angle = angle;
        wall = walls{3};
    otherwise
        error('Room "%s" is not recognized.',h.Room);
end