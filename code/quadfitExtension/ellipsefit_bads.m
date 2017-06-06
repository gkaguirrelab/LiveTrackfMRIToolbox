function [p,e,d] = ellipsefit_bads(x,y, lb, ub, plb, pub)
% Fit an ellipse to data by minimizing point-to-curve distance.
%
% This function uses an iterative procedure. For a non-iterative approach, use
% a direct least squares fit.
%
% Output arguments:
% p:
%    parameters of ellipse expressed in implicit form
% e:
%    sqrt sum square distance
% d:
%    distance from data points to fitted ellipse
%
% See also: ellipsefit_direct

% Copyright 2011 Levente Hunyadi
% Modified 2017 Geoffrey Aguirre

if ~exist('bads','file')
    error('LiveTrackfMRIToolbox:DependencyMissing', 'This function requires the BADS Bayesian non-linear search tool.\n');
end

% if the plausible upper and lower bounds not set, use the hard bounds
if ~isempty(plb)
    plb=lb;
end
if ~isempty(pub)
    pub=ub;
end

% compute a close-enough initial estimate
pinit = quad2dfit_taubin(x,y);
switch imconic(pinit,0)
    case 'ellipse'  % use Taubin's fit, which has produced an ellipse
    otherwise  % use direct least squares ellipse fit to obtain an initial estimate
        pinit = ellipsefit_direct(x,y);
end

% Perform Bayesian Adaptive Direct Search (BADS) optimization
% https://github.com/lacerbi/bads
opts = bads('defaults');   % Get a default OPTIONS struct
opts.Display = 'off';      % Print only basic output ('off' turns off)
peinit = ellipse_im2ex(pinit);
% We will minimize the sqrt of the sum of squared distance values
% of the points to the ellipse fit
myFun = @(p) sqrt(sum(ellipsefit_distance(x,y,p).^2));
[pe,e] = bads(myFun, peinit, lb, ub, plb, pub, [], opts);
p = ellipse_ex2im(pe);

if nargout > 2
    d = ellipsefit_distance(x,y,pe);
end

e = e / numel(x);



function [d,ddp] = ellipsefit_distance(x,y,p)
% Distance of points to ellipse defined with parameters center, axes and tilt.
% P = b^2*((x-cx)*cos(theta)-(y-cy)*sin(theta))
%   + a^2*((x-cx)*sin(theta)+(y-cy)*cos(theta))
%   - a^2*b^2 = 0

pcl = num2cell(p);
[cx,cy,ap,bp,theta] = pcl{:};

% get foot points
if ap > bp
    a = ap;
    b = bp;
else
    a = bp;
    b = ap;
    theta = theta + 0.5*pi;
    if theta > 0.5*pi
        theta = theta - pi;
    end
end
[xf,yf] = ellipsefit_foot(x,y,cx,cy,a,b,theta);

% calculate distance from foot points
d = realsqrt((x-xf).^2 + (y-yf).^2);

% use ellipse equation P = 0 to determine if point inside ellipse (P < 0)
f = b^2.*((x-cx).*cos(theta)-(y-cy).*sin(theta)).^2 + a^2.*((x-cx).*sin(theta)+(y-cy).*cos(theta)).^2 - a^2.*b^2 < 0;

% convert to signed distance, d < 0 inside ellipse
d(f) = -d(f);

if nargout > 1  % FIXME derivatives
    x = xf;
    y = yf;
    % Jacobian matrix, i.e. derivatives w.r.t. parameters
    dPdp = [ ...  % Jacobian J is m-by-n, where m = numel(x) and n = numel(p) = 5
        b.^2.*cos(theta).*(cos(theta).*(cx-x)-sin(theta).*(cy-y)).*2.0+a.^2.*sin(theta).*(cos(theta).*(cy-y)+sin(theta).*(cx-x)).*2.0 ...
        a.^2.*cos(theta).*(cos(theta).*(cy-y)+sin(theta).*(cx-x)).*2.0-b.^2.*sin(theta).*(cos(theta).*(cx-x)-sin(theta).*(cy-y)).*2.0 ...
        a.*(cos(theta).*(cy-y)+sin(theta).*(cx-x)).^2.*2.0-a.*b.^2.*2.0 ...
        b.*(cos(theta).*(cx-x)-sin(theta).*(cy-y)).^2.*2.0-a.^2.*b.*2.0 ...
        a.^2.*(cos(theta).*(cy-y)+sin(theta).*(cx-x)).*(cos(theta).*(cx-x)-sin(theta).*(cy-y)).*2.0-b.^2.*(cos(theta).*(cy-y)+sin(theta).*(cx-x)).*(cos(theta).*(cx-x)-sin(theta).*(cy-y)).*2.0 ...
        ];
    dPdx = b.^2.*cos(theta).*(cos(theta).*(cx-x)-sin(theta).*(cy-y)).*-2.0-a.^2.*sin(theta).*(cos(theta).*(cy-y)+sin(theta).*(cx-x)).*2.0;
    dPdy = a.^2.*cos(theta).*(cos(theta).*(cy-y)+sin(theta).*(cx-x)).*-2.0+b.^2.*sin(theta).*(cos(theta).*(cx-x)-sin(theta).*(cy-y)).*2.0;
    
    % derivative of distance to foot point w.r.t. parameters
    ddp = bsxfun(@rdivide, dPdp, realsqrt(dPdx.^2 + dPdy.^2));
end

function [d,ddp] = ellipsefit_distance_kepler(x,y,p)
% Distance of points to ellipse defined with Kepler's parameters.

pcl = num2cell(p);
[px,py,qx,qy,a] = pcl{:};

% get foot points
[xf,yf] = ellipsefit_foot_kepler(x,y,px,py,qx,qy,a);

% calculate distance from foot points
d = realsqrt((x-xf).^2 + (y-yf).^2);

% use ellipse equation P = 0 to determine if point inside ellipse (P < 0)
f = realsqrt((x-px).^2+(y-py).^2) + realsqrt((x-qx).^2+(y-qy).^2) - 2*a < 0;

% convert to signed distance, d < 0 inside ellipse
d(f) = -d(f);

if nargout > 1
    % compute partial derivatives of ellipse equation P given with Kepler's parameters
    % in Kepler's form, the foci of an ellipse are (px;py) and (qx;qy),
    % and 2*a is the major axis such that the parameter vector is [p1 p2 q1 q2 a]
    
    % Jacobian matrix, i.e. derivatives w.r.t. parameters
    dPdp = [ ...  % Jacobian J is m-by-n, where m = numel(x) and n = numel(p) = 5
        -(xf-px)./realsqrt((xf-px).^2+(yf-py).^2), ...
        -(yf-py)./realsqrt((xf-px).^2+(yf-py).^2), ...
        -(xf-qx)./realsqrt((xf-qx).^2+(yf-qy).^2), ...
        -(yf-qy)./realsqrt((xf-qx).^2+(yf-qy).^2), ...
        -2.*ones(size(xf)) ...
        ];
    dPdx = (xf-px)./realsqrt((xf-px).^2+(yf-py).^2) + (xf-qx)./realsqrt((xf-qx).^2+(yf-qy).^2);
    dPdy = (yf-py)./realsqrt((xf-px).^2+(yf-py).^2) + (yf-qy)./realsqrt((xf-qx).^2+(yf-qy).^2);
    
    % derivative of distance to foot point w.r.t. parameters
    ddp = bsxfun(@rdivide, dPdp, realsqrt(dPdx.^2 + dPdy.^2));
end

function [xf,yf] = ellipsefit_foot(x,y,cx,cy,a,b,theta)
% Foot points obtained by projecting a set of coordinates onto an ellipse.

xfyf = quad2dproj([x y], [cx cy], [a b], theta);
xf = xfyf(:,1);
yf = xfyf(:,2);

function [xf,yf] = ellipsefit_foot_kepler(x,y,px,py,qx,qy,a)
% Foot points obtained by projecting a set of coordinates onto an ellipse.
%
% Input arguments:
% x,y:
%    coordinates to data points to project
% px,py,qx,qy:
%    coordinates of ellipse foci
% a:
%    ellipse semi-major axis length

c1 = 0.5*(px+qx);
c2 = 0.5*(py+qy);
cf2 = (c1-px)^2 + (c2-py)^2;  % distance squared from center to focus
b = realsqrt(a^2 - cf2);
theta = atan2(qy-py,qx-px);  % tilt angle
[xf,yf] = ellipsefit_foot(x,y,c1,c2,a,b,theta);