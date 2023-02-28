function H_wobble = makeWobbleTransform(wobble)
% MAKEWOBBLETRANSFORM generates a pseudorandom "wobble" transformation 
% using a scalar "wobble" parameter.
%   H_wobble = MAKEWOBBLETRANSFORM(wobble)
%
%   M. Kutzer, 08Apr2020, USNA

if numel(wobble) == 1
    if wobble ~= 0
        v_wobble = 2*rand(2,1) - 1;
        v_wobble(3,:) = 0;
        v_wobble = v_wobble./norm(v_wobble);
        r_wobble = wedge( wobble * v_wobble );
        R_wobble = expm( r_wobble );
        H_wobble = eye(4);
        H_wobble(1:3,1:3) = R_wobble;
    else
        H_wobble = eye(4);
    end
else
    if size(wobble,1) ~= 4 || size(wobble,2) ~= 4
        error('"wobble" must be a scalar value in radians or an element of SE(3).');
    end
    % TODO - check the 4x4 matrix 
    H_wobble = wobble;
end