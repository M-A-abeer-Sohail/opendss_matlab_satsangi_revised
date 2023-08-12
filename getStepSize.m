function [stepSize] = getStepSize(multiplier)
%getStepSize: Gets step size compatible with OpenDSS in seconds
%   OpenDSS accepts a stepsize with a unit of 's', 'm' or 'h' to denote
%   seconds, minutes, and hours respectively. If not provided, 's' is
%   assumed. Therefore, output is just a number denoted as seconds
    
    stepSize = string(floor(3600/ multiplier));
end

