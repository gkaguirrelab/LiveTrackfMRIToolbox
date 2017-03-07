function Eg = ellipse_alg2geom (Ea)
% converts the standard algebraic params of an ellipse in the canonical
% geometric form

% Algebrainc ellipse :
%       Ax^2 + Bxy + Cy^2 +Dx + Ey + F = 0

% Ea = [a b c d e f]';


[A, B, C, D, E, F] = deal(Ea(1),Ea(2),Ea(3),Ea(4),Ea(5),Ea(6));

% verify the conversion condition

den = B^2 - 4*A*C;

if den >= 0
    error ('Degenerate case')
end

    
Eg.longAx = - (sqrt(2 * ((A * E^2) + (C * D^2) - (B * D * E) + (den * F)) * (A + C + (sqrt((A - C)^2 + B^2))))) / den;  

Eg.shortAx= - (sqrt(2 * ((A * E^2) + (C * D^2) - (B * D * E) + (den * F)) * (A + C - (sqrt((A - C)^2 + B^2))))) / den;

Eg.Xc = ((2 * C * D) - (B * E))/ den;

Eg.Yc = ((2 * A * E) - (B * D))/ den;


% phi =  angle from the positive horizontal axis (X) to the ellipse's major axis    
if B == 0 && A < C
    Eg.phi = 0;
    Eg.Xradius = longAx;
    Eg.Yradius = shortAx;
elseif B == 0 && A > C
    Eg.phi = 90; % in degrees
    Eg.Yradius = longAx;
    Eg.Xradius = shortAx;
else
    Eg.phi = deg2rad(atan((C - A - sqrt((A - C)^2 + B^2))/B)); % in rad
end
    
