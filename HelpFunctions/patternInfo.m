%% patternInfo
% patternInfo returns information about code issue patterns. Pattern names,
% ids of code issues (code-analyzer warnings), sample code snippets and
% the code-analyzer messages.
%
% Syntax:
% [patternNames,warningId,snippet,msg] = patternInfo;

function [patternNames,warningId,snippet,msg] = patternInfo
patternInfoArray = { ...
    'preallocation'    , 'AGROW' , '<missing preallocation>' , 'Variable appears to change size on every loop iteration. Consider preallocating for speed.'; ...
    'logical and'      , 'AND2'  , 'A & B'                   , 'When both arguments are numeric scalars, consider replacing & with && for performance.'; ...
    'exist'            , 'EXIST' , 'exist(''varName'')'      , 'EXIST with two input arguments is generally faster and clearer than with one input argument.'; ...
    'isscalar'         , 'ISCL'  , 'length(A) == 1'          , 'To improve performance, use ''isscalar'' instead of length comparison.'; ...
    'preallocation'    , 'SAGROW', '<missing preallocation>' , 'Variable appears to change size on every loop iteration (within a script). Consider preallocating for speed.'; ...
    };

patternNames = patternInfoArray(:,1);
warningId = patternInfoArray(:,2);
snippet = patternInfoArray(:,3);
msg = patternInfoArray(:,4);
end
