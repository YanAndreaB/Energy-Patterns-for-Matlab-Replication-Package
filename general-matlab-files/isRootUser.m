% isRoot

function res = isRootUser
[~,res] = system('whoami');
res = regexp(res,['.*(?=',newline,')'],'match','once');
res = strcmp(res,'root');
end
