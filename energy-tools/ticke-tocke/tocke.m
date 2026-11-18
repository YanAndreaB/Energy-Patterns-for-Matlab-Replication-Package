%% tocke
% Author: jan-andrea.bard@unibe.ch
% File Dependencies:
% - tickeTocke.m
% Other Dependencies
% - Intel CPU (newer than Sandy Bridge)
% - Linux OS
% 
% tocke is the analogon to Matlabs toc. Instead of the time duration since
% tic was called it yields the energy counter difference since ticke was
% called.
% 
% Syntax:
% tocke
% endVal = tocke;

function varargout = tocke(varargin)
% tocke is thought as an analogon to the matlab toc function. initializing
% an energy counter using ticke can be used by tocke to return the amount
% of energy consumed between the calls of ticke and tocke

[varargout{1:nargout}] = tickeTocke("measure",varargin{:});

end
