function R = rodrigues(r)
% rodrigues:

% Input:
%   r - 3x1 vector
% Output:
%   R - 3x3 rotation matrix
R = [];
%% get the magnitude and angle direction
theta = norm(r);
if theta == 0
    R = eye(3);
else
    normm = norm(r);
    thetaSkew = [0    , -r(3), r(2) ;
                r(3) , 0    , -r(1);
                -r(2), r(1) , 0    ;];
    R = eye(3) + thetaSkew/normm * sin(normm) + thetaSkew^2/normm^2 * (1-cos(normm));
    %{
    u = r./theta;
    
    ux = [0    , -u(3), u(2) ;
          u(3) , 0    , -u(1);
          -u(2), u(1) , 0    ;];
    %% recover R
    R = eye(3)*cos(theta) + (1-cos(theta)).*u*u' + ux*sin(theta);
    %}
end

end
