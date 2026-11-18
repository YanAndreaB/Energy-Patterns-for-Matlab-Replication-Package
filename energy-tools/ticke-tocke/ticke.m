%% ticke
% Author: jan-andrea.bard@unibe.ch
% File Dependencies:
% - tickeTocke.m
% Other Dependencies
% - Intel CPU (newer than Sandy Bridge)
% - Linux OS
% 
% ticke is the analogon to Matlabs tic. Instead of the current time stamp
% it yields the current energy counter of the RAPL interface.
% 
% Syntax:
% ticke
% startVal = ticke;

function ticke
% ticke is thought as an analogon to the matlab tic function. initializing
% an energy counter that can be used by tocke to return the amount of
% energy consumed between the calls of ticke and tocke.

tickeTocke("initialize")

end
