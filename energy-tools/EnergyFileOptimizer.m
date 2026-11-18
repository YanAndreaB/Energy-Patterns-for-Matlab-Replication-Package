%% EnergyFileOptimizer
% Author: jan-andrea.bard@unibe.ch
% Dependencies:
% - mtree (undocumented utility)
% 
% EnergyFileOptimizer fixes code issues in m-files. It spots code issues
% with the following check-ids and provides a fix:
% - STTOK
% - ST2NM
% - UDIM
% - TRSRT
% - GFLD
% - SFLD
% - CCAT1
% - AGROW
% - SAGROW
% - EXIST
% - MMTC
%
% The fixes might not be correct in all situations.
% 
% Syntax:
% fileName = 'myFile.m';
% EFO = EnergyFileOptimizer(fileName);
% EFO.optimize

classdef EnergyFileOptimizer < handle
    properties (Constant)
        checkIds = {'STTOK','ST2NM','UDIM','TRSRT','GFLD','SFLD','CCAT1','AGROW','SAGROW','EXIST','MMTC'}
    end

    properties
        fileName
        tree
        issuesTable
    end

    methods
        function obj = EnergyFileOptimizer(fileName)
            fullFileName = which(fileName);
            if isempty(fullFileName) % full name might be given and function not on Matlab path
                fullFileName = fileName;
            end
            obj.fileName = fullFileName;
        end
    end

    methods (Access = public)
        function varargout = optimize(obj)
            % optimize file

            obj.getIssuesTable;
            uniqueCheckIds = unique(obj.issuesTable.CheckID);
            successfullyOptimized = false;
            if any(ismember(obj.checkIds,uniqueCheckIds))
                % open file for reading
                [str,obj.tree] = obj.readFile;
                originalString = str;

                % if root of tree is ERR then probably there's a parse
                % error in the file.
                if ~strcmp(obj.tree.root.kind,'ERR')

                    if ismember('ST2NM',uniqueCheckIds) % str2num issue
                        str = obj.fixStr2num(str);
                        [str,originalString] = obj.updateFile(str);
                    end
                    if ismember('UDIM',uniqueCheckIds) % different dimension input for sum (with transpose)
                        str = obj.fixDifferentDimension(str);
                        [str,originalString] = obj.updateFile(str);
                    end
                    if ismember('TRSRT',uniqueCheckIds) % transposing input for sort is unnecessary
                        str = obj.fixTransposingInputForSortUnnecessary(str);
                        [str,originalString] = obj.updateFile(str);
                    end
                    if ismember('CCAT1',uniqueCheckIds) % { A{I} } can usually be replaced by A(I) or A(I)'
                        str = obj.fixCellConcatenation(str);
                        [str,originalString] = obj.updateFile(str);
                    end
                    if ismember('GFLD',uniqueCheckIds) % getfield
                        str = obj.replaceGetfield(str);
                        % write and read file again because fixing getfield
                        % could interfer with setting setfield changes the
                        % number of code lines.
                        [str,originalString] = obj.updateFile(str);
                    end
                    if ismember('SFLD',uniqueCheckIds) % setfield
                        str = obj.replaceSetfield(str);
                        [str,originalString] = obj.updateFile(str);
                    end
                    if sum(ismember({'AGROW','SAGROW'},uniqueCheckIds)) > 0 % preallocation
                        str = obj.fixPreallocation(str);
                        % write and read file again because fixing preallocation
                        % changes the number of code lines.
                        [str,originalString] = obj.updateFile(str);
                    end
                    if ismember('EXIST',uniqueCheckIds) % exist
                        [str,~] = obj.fixExist(str);
                        [str,originalString] = obj.updateFile(str);
                    end
                    if ismember('MMTC',uniqueCheckIds) % mat2cell
                        str = obj.fixMat2cell(str);
                        [str,originalString] = obj.updateFile(str);
                    end

                    if ismember('STTOK',uniqueCheckIds) % strtok issue
                        str = obj.fixStrtok(str);
                        % write and read file again because fixing strtok
                        % changes the number of code lines.
                        [str,originalString] = obj.updateFile(str);
                    end

                    if isempty(str)
                        error 'An unknown error happened while autofixing'
                    end
                    if ~strcmp(originalString,str)
                        % open file for writing
                        obj.writeFile(str);
                        successfullyOptimized = true;
                    end
                end
            end

            if nargout
                varargout = {successfullyOptimized};
            end
        end
    end

    methods (Access = private)
        function [str,originalString] = updateFile(obj,str)
            % file must be updated after fixing every issue because a
            % non-fixed issue could sit on the same line as an already
            % fixed one. This will lead to an empty value for issueLine in
            % sliceDocument

            obj.writeFile(str);
            [str,obj.tree] = obj.readFile;
            originalString = str;
            obj.getIssuesTable;
        end

        function getIssuesTable(obj)
            issues = codeIssues(obj.fileName);
            obj.issuesTable = issues.Issues;
        end

        function writeFile(obj,str)
            fileID = fopen(obj.fileName,'W');
            fwrite(fileID,str);
            fclose(fileID);
        end

        function [str,tree] = readFile(obj)
            fileID = fopen(obj.fileName);
            str = fscanf(fileID,'%c');
            fclose(fileID);
            tree = mtree(obj.fileName,'-file');
        end

        function str = fixTemplate(obj,str,issueId,regexStr,regexReplacement)
            if ischar(regexStr)
                regexStr = {regexStr};
                regexReplacement = {regexReplacement};
            end
            originalStr = str;
            newIssuesTable = obj.issuesTable(obj.issuesTable.CheckID == issueId,:);
            issueLines = unique(newIssuesTable.LineStart);
            lineNos = obj.tree.lineno;
            for idx = 1:numel(issueLines)
                IDX = find(lineNos == issueLines(idx));
                nodes = obj.tree.select(IDX);
                [documentStart,issueLine,documentEnd] = sliceDocumentSimple(str,nodes);
                for idx2 = 1:numel(regexStr)
                    issueLine = regexprep(issueLine,regexStr{idx2},regexReplacement{idx2});
                end
                issueLine = removeAstBlanks(issueLine);
                str = [documentStart,issueLine,documentEnd];
            end

            if strcmp(originalStr,str)
                error 'Auto-fix hasn''t changed the code.'
            end
        end

        function str = fixCellConcatenation(obj,str)
            newIssuesTable = obj.issuesTable(obj.issuesTable.CheckID == 'CCAT1',:);
            issueLines = unique(newIssuesTable.LineStart);
            lineNos = obj.tree.lineno;
            for idx = 1:numel(issueLines)
                IDX = find(lineNos == issueLines(idx));
                nodes = obj.tree.select(IDX);
                lcNodes = nodes.mtfind('Kind','LC'); % a node of the form {...}
                indices = lcNodes.indices;
                for idx2 = 1:numel(indices)
                    lcNode = lcNodes.select(indices(idx2));
                    varName = lcNode.Arg.Arg.Left.tree2str;
                    if strcmp(lcNode.Arg.Arg.kind,'CELL') && ~isempty(varName) % otherwise it's not a node that implements the pattern
                        arg1Node = lcNode.Arg.Arg.Right;
                        if strcmp(arg1Node.kind,'FIELD') % for fields tree2str is throwing an error
                            args = arg1Node.stringval;
                        else
                            args = arg1Node.tree2str;
                        end
                        moreArgs = getMoreCellArguments(arg1Node);
                        args = [args,moreArgs(:)']; %#ok<AGROW>
                        args = strjoin(args,',');
                        [documentStart,~,documentEnd] = sliceDocument(str,lcNode);
                        if ~isempty(documentEnd) && documentEnd(1) == '''' % it's a transposition
                            documentEnd(1) = []; % remove double transposition
                            newCode = [varName,'(',args,')'];
                        else
                            newCode = [varName,'(',args,')'''];
                        end
                        newCode = removeAstBlanks(newCode);
                        str = [documentStart,newCode,documentEnd];
                    end
                end
            end
        end

        function str = fixTransposingInputForSortUnnecessary(obj,str)
            newIssuesTable = obj.issuesTable(obj.issuesTable.CheckID == 'TRSRT',:);
            issueLines = unique(newIssuesTable.LineStart);
            lineNos = obj.tree.lineno;
            for idx = 1:numel(issueLines)
                IDX = find(lineNos == issueLines(idx));
                nodes = obj.tree.select(IDX);
                funNodes = nodes.mtfind('Fun','sort');
                indices = funNodes.indices;
                for idx2 = 1:numel(indices)
                    funNode = funNodes.select(indices(idx2));
                    call = funNode.Parent;
                    if strcmp(call.Right.kind,'TRANS')
                        if strcmp(call.Right.Arg.kind,'PARENS')
                            arg = call.Right.Arg.Arg.tree2str;
                        else
                            arg = call.Right.Arg.tree2str;
                        end
                        newCode = ['sort(',arg,')'];
                        newCode = removeAstBlanks(newCode);
                        [documentStart,~,documentEnd] = sliceDocument(str,call);
                        str = [documentStart,newCode,documentEnd];
                    else
                        throwWarning(['Could not fix issue TRSRT for file "',obj.fileName,'" (line ',num2str(issueLines(idx)),').'])
                    end
                end
            end
        end

        function str = fixStr2num(obj,str)
            str = obj.fixTemplate(str,'ST2NM','(?<=\W)str2num *\(','str2double(');
        end

        function str = fixDifferentDimension(obj,str)
            % TODO:
            % - cases like a = max(B,[],1);
            % - two line cases, e.g.:
            %   transposedVar = var';
            %   a = sum(transposedVar);
            % - nodes with line breaks, e.g.:
            %   a = sum(b') + ...
            %       c + d;

            newIssuesTable = obj.issuesTable(obj.issuesTable.CheckID == 'UDIM',:);
            issueLines = unique(newIssuesTable.LineStart);
            lineNos = obj.tree.lineno;
            for idx = 1:numel(issueLines)
                IDX = find(lineNos == issueLines(idx));
                nodes = obj.tree.select(IDX);
                node = nodes.select(IDX(2)); % the second node is the content of the line
                if strcmp(node.kind,'IFHEAD')
                    node = node.Left; % the if condition node
                elseif strcmp(node.Parent.kind,'FOR')
                    node = nodes.mtfind('Kind','COLON'); % the colon expression after the for statement
                end
                [documentStart,issueLine,documentEnd] = sliceDocument(str,node);

                calls = nodes.mtfind('Kind','CALL');
                stringVals = calls.Left.stringvals;
                indices = calls.indices;
                funcs = {'mean','min','max','sum','sort','median','std','var','prod','nanmean','nanstd'};
                transArray = {};
                oldCall = {};
                funcArray = {};
                for idx2 = 1:numel(stringVals) % reverse order to begin with most nested calls
                    switch stringVals{idx2}
                        case funcs
                            call = calls.select(indices(idx2));
                            if strcmp(call.Right.kind,'TRANS')
                                funcArray{end + 1} = stringVals{idx2}; %#ok<AGROW>
                                oldCall{end + 1} = call.tree2str; %#ok<AGROW>
                                trans = call.Right;
                                arg = trans.Arg.tree2str;
                                transArray{end + 1} = arg; %#ok<AGROW>
                            end
                    end
                end
                newCall = oldCall;
                for idx2 = 1:numel(transArray)
                    pattern = replace(transArray{idx2},simpleSigns,escapedSigns);
                    switch funcArray{idx2}
                        case {'min','max'}
                            newCall{idx2} = regexprep(newCall{idx2},[pattern,''' \)'],[transArray{idx2},',[],2)']);
                        otherwise
                            newCall{idx2} = regexprep(newCall{idx2},[pattern,''' \)'],[transArray{idx2},',2)']);
                            newCall{idx2} = regexprep(newCall{idx2},[pattern,''', 1 \)'],[transArray{idx2},',2)']);
                    end
                end
                for idx2 = 1:numel(oldCall)
                    pattern = replace(oldCall{idx2},simpleSignsWithSpace,escapedSignsWithSpace);
                    issueLine = regexprep(issueLine,pattern,newCall{idx2});
                end

                issueLine = regexprep(issueLine,'(?<=\S)(\=\=|\.\*|\.\/|\.\^|\=|\+|\-|\*|\/)(?=\S)',' $1 ');
                issueLine = removeAstBlanks(issueLine);
                str = [documentStart,issueLine,documentEnd];
            end
        end

        function str = fixMat2cell(obj,str)
            newIssuesTable = obj.issuesTable(obj.issuesTable.CheckID == 'MMTC',:);
            issueLines = unique(newIssuesTable.LineStart);
            lineNos = obj.tree.lineno;
            for idx = 1:numel(issueLines)
                IDX = find(lineNos == issueLines(idx));
                nodes = obj.tree.select(IDX);
                funNodes = nodes.mtfind('Fun','mat2cell');
                indices = funNodes.indices;
                for idx2 = 1:numel(indices)
                    funNode = funNodes.select(indices(idx2));
                    call = funNode.Parent;
                    callArg = call.Right.tree2str;
                    newCall = ['num2cell(',callArg,')'];
                    newCall = removeAstBlanks(newCall);
                    [documentStart,~,documentEnd] = sliceDocument(str,call);
                    str = [documentStart,newCall,documentEnd];
                end
            end
        end

        function [str,notSuccessfulLines] = fixExist(obj,str)
            originalString = str;
            notSuccessfulLines = [];
            calls = obj.tree.mtfind('Kind','CALL');
            indices = calls.indices;
            callNames = calls.Left.stringvals;
            existCalls = callNames == "exist";
            for idx = indices(existCalls)
                call = obj.tree.select(idx);
                if call.Right.Next.isempty % there is no second argument to exist
                    callArg = call.Right.tree2str;
                    switch call.Parent.kind
                        case {'EQ','NE'} % equal or not-equal (== or ~=)
                            existExpression = call.Parent.tree2str;
                        otherwise % for example an IFHEAD
                            existExpression = call.tree2str;
                    end
                    found = false;
                    if ~isempty(regexp(existExpression,'exist\(.*\)(\=|~)\=\d','once'))
                        found = true;
                        digit = str2double(regexp(existExpression,'(?<=exist\(.*\)(\=|~)\=)\d','match','once'));
                        switch digit
                            case 1 % variables
                                idStr = 'var';
                            case {2,3,4,6} % files
                                idStr = 'file';
                            case 5 % built-in
                                idStr = 'builtin';
                            case 7 % folders
                                idStr = 'dir';
                            case 8 % classes
                                idStr = 'class';
                            case 0
                                % TODO: case 0
                                found = false;
                        end
                    elseif ~isempty(regexp(callArg,'fullfile\(','once'))
                        found = true;
                        idStr = 'file';
                    else
                        callArgNode = call.Right;
                        if strcmp(callArgNode.kind,'STRING') || strcmp(callArgNode.kind,'CHARVECTOR')
                            callArg = callArgNode.stringval;
                            found = true;
                            nameEnding = regexp(callArg,'(?<=\.)\w*$','match','once');
                            if ~obj.tree.mtfind('Var',callArg).isempty % it's a variable
                                idStr = 'var';
                            elseif ~obj.tree.mtfind('Fun',callArg).isempty % it's a function
                                idStr = 'file';
                            elseif ~isempty(nameEnding)
                                switch nameEnding
                                    case {'m','dat','csv','mat','xls','xlsx','txt'} % it's a file
                                        idStr = 'file';
                                    otherwise
                                        found = false;
                                end
                            else
                                found = false;
                            end
                            if found
                                callArg = callArgNode.tree2str;
                            end
                        end
                    end

                    if found
                        pattern = replace(call.tree2str,[{','},simpleSignsWithSpace],[{',?'},escapedSignsWithSpace]);
                        pattern = ['(?<=(\W|^))',pattern]; %#ok<AGROW>
                        newCall = ['exist(',callArg,',''',idStr,''')'];
                        [documentStart,issueLine,documentEnd] = sliceDocument(str,call);
                        issueLine = regexprep(issueLine,pattern,newCall);
                        issueLine = removeAstBlanks(issueLine);
                        str = [documentStart,issueLine,documentEnd];
                    else
                        throwWarning(['Could not fix EXIST-issue on line ',num2str(call.lineno),' for file "',obj.fileName,'".'])
                    end
                end
            end
            if strcmp(originalString,str)
                throwWarning(['Autofix didn''t change EXIST pattern for file "',obj.fileName,'".'])
            end
        end

        function str = fixStrtok(obj,str)
            newIssuesTable = obj.issuesTable(obj.issuesTable.CheckID == 'STTOK',:);
            issueLines = unique(newIssuesTable.LineStart);
            lineNos = obj.tree.lineno;
            offset = 0;
            for idx = 1:numel(issueLines)
                IDX = find(lineNos == issueLines(idx));
                nodes = obj.tree.select(IDX);
                funNode = nodes.mtfind('Fun','strtok');
                resultVariable = funNode.Parent.Parent.Left.Arg.tree2str;
                sliceVariable = funNode.Parent.Parent.Left.Arg.Next.tree2str;
                splitDelimiterNode = funNode.Parent.Right.Next;

                compactTree = mtree(obj.tree.tree2str); % tree from code without empty lines and comments
                [whileNodeInfo,successful] = analyseLoops(compactTree,'WHILE');
                if successful
                    whileNode = findParentLoop(funNode,obj.tree,compactTree,whileNodeInfo);

                    % whileNode = findParentWhile(funNode);
                    whileCondition = whileNode.Left.tree2str;
                    if strcmp(regexprep(whileCondition,{'([\(,]) *',' *([\),])'},'$1'),['~isempty(',sliceVariable,')'])  ...
                            || strcmp(whileCondition,'1') || strcmp(whileCondition,'true')
                        splitDelimiterPart = '';
                        if ~isempty(splitDelimiterNode)
                            if strcmp(splitDelimiterNode.kind,'LB') % left bracket
                                splitDelimiter = ['{',regexprep(splitDelimiterNode.Arg.tree2str,'(\d*)','char($1)'),'}'];
                                splitDelimiter = replace(splitDelimiter,'char(10)','newline');
                                splitDelimiterPart = [',',splitDelimiter];
                            else
                                splitDelimiterPart = [',',splitDelimiterNode.tree2str];
                            end
                        end
                        [documentStart,~,documentEnd,indent] = sliceDocument(str,whileNode,offset);
                        newCode = ['cell_autofix = split(',sliceVariable,splitDelimiterPart,');', char(13),newline, ...
                            indent,'for idx_autofix = 1:numel(cell_autofix)'];
                        str = [documentStart,newCode,documentEnd];
                        [documentStart,~,documentEnd,~] = sliceDocument(str,funNode.Parent.Parent,offset + 1);
                        newCode = [resultVariable,' = cell_autofix{idx_autofix};',char(13),newline];
                        documentEnd = regexprep(documentEnd,['.*?',newline],'','once'); % truncate remaining part of issue line
                        str = [documentStart,newCode,documentEnd];
                        offset = offset + 1; % offset for line numbers is necessary since code grows by one line on every loop iteration
                    else % optimization not possible
                        continue
                    end
                end
            end
        end

        function str = replaceSetfield(obj,str)
            newIssuesTable = obj.issuesTable(obj.issuesTable.CheckID == 'SFLD',:);
            issueLines = unique(newIssuesTable.LineStart);
            lineNos = obj.tree.lineno;
            for idx = 1:numel(issueLines)
                IDX = find(lineNos == issueLines(idx));
                nodes = obj.tree.select(IDX);
                funNodes = nodes.mtfind('Fun','setfield');
                indices = funNodes.indices;
                for idx2 = 1:numel(indices)
                    funNode = funNodes.select(indices(idx2));
                    call = funNode.Parent;
                    if isempty(call.Right.Next.Next.Next)
                        % if not empty then it's a call to setfield with more than
                        % three arguments that is not marked by the code analyzer
                        [structName,afterTheDot] = getStructExpressionNames(call);
                        secondArg = call.Right.Next.Next.tree2str;
                        newCode = [structName,'.',afterTheDot,' = ',secondArg];
                        newCode = removeAstBlanks(newCode);
                        assignment = call.Parent;
                        leftSide = assignment.Left.tree2str;
                        if strcmp(leftSide,structName)
                            [documentStart,~,documentEnd] = sliceDocument(str,assignment);
                            str = [documentStart,newCode,documentEnd];
                        else
                            warning 'Struct name not equal to left side of assignment.'
                        end
                    end
                end
            end
        end

        function str = replaceGetfield(obj,str)

            % TODO: Issue with fixint:
            % C:\GitLab\energy-patterns\GitHubSearch_2026_01_12\MinedGithubProjects\neurocode\utilities\eventIntervals.m

            newIssuesTable = obj.issuesTable(obj.issuesTable.CheckID == 'GFLD',:);
            issueLines = unique(newIssuesTable.LineStart);
            lineNos = obj.tree.lineno;
            for idx = 1:numel(issueLines)
                IDX = find(lineNos == issueLines(idx));
                nodes = obj.tree.select(IDX);
                calls = nodes.mtfind('Kind','CALL');
                indices = calls.indices;
                for idx2 = 1:numel(indices)
                    call = calls.select(indices(idx2));
                    funName = call.Left.tree2str;
                    if strcmp(funName,'getfield')
                        if isempty(call.Right.Next.Next)
                            % if not empty then it's a call to getfield with more than
                            % two arguments that is not marked by the code analyzer
                            [structName,afterTheDot] = getStructExpressionNames(call);
                            newCode = [structName,'.',afterTheDot];
                            newCode = removeAstBlanks(newCode);
                            [documentStart,issueLine,documentEnd] = sliceDocument(str,call);
                            if issueLine ~= newline
                                str = [documentStart,newCode,documentEnd];
                            else % otherwise something went wrong
                                str = [documentStart,issueLine,documentEnd];
                            end
                        end
                    end
                end
            end
        end

        function str = fixPreallocation(obj,str)
            % fix preallocation issue
            
            compactTree = mtree(obj.tree.tree2str); % tree from code without empty lines and comments
            [forNodeInfo,successful] = analyseLoops(compactTree,'FOR');
            if successful
                fixedLines = []; % collect lines that have already been fixed
                variableForloopPairs = {};
                structNotUsedIssues = obj.issuesTable(obj.issuesTable.CheckID == "STRNU",:);

                % loop through issues
                for idx = numel(obj.issuesTable.CheckID):-1:1
                    if obj.issuesTable.CheckID(idx) == "AGROW" || obj.issuesTable.CheckID(idx) == "SAGROW"
                        if ismember(obj.issuesTable.LineStart(idx),structNotUsedIssues.LineStart)
                            continue % struct not used issues in combination with growing array issue can't be fixed generally
                        end
                        if ismember(obj.issuesTable.LineStart(idx),fixedLines)
                            continue % if line has already been fixed
                        end

                        fixedLines = [fixedLines,obj.issuesTable.LineStart(idx)]; %#ok<AGROW>
                        lineNr = obj.issuesTable.LineStart(idx);
                        nodeLineNrs = obj.tree.lineno;
                        nodeIndices = find(nodeLineNrs == lineNr); % nodes on line lineNr
                        nodes = obj.tree.select(nodeIndices);
                        equals = nodes.mtfind('Kind','EQUALS');

                        for idx1 = 1:equals.count % there might be several assignments on a single line
                            eqIndices = equals.indices;
                            equalsNode = equals.select(eqIndices(idx1));
                            variables = nodes.mtfind('Kind',{'SUBSCR','CELL'});
                            varIndices = variables.indices;
                            % only take variables on the left side of the =
                            varIndices = varIndices(varIndices < equalsNode.Right.indices);

                            % loop through variables
                            offset = 0;
                            for idx2 = numel(varIndices):-1:1
                                varNode = variables.select(varIndices(idx2));
                                varString = varNode.Left.tree2str;
                                indexVars = findIndexVariables(varNode);
                                if ismember(indexVars,'end + 1') % growing arrays using end + 1 indexing can't be fixed generally
                                    continue
                                end

                                varType = varNode.kind;
                                rootFor = []; % outer most for loop that changes the array size of the variable

                                parentFor = findParentLoop(equalsNode,obj.tree,compactTree,forNodeInfo);
                                newVariableForloopPair = {varString,parentFor.indices};
                                if any(cellfun(@(arg)isequal(arg,newVariableForloopPair),variableForloopPairs))
                                    continue
                                end
                                variableForloopPairs{end + 1} = newVariableForloopPair; %#ok<AGROW>
                                if ~isempty(parentFor)
                                    [indexVars,rootFor] = processIndexVars(parentFor,indexVars,rootFor);

                                    % written out recursion of depth four
                                    if ~isempty(indexVars)
                                        grandParentFor = findParentLoop(parentFor,obj.tree,compactTree,forNodeInfo);
                                        if ~grandParentFor.isempty
                                            [indexVars,rootFor] = processIndexVars(grandParentFor,indexVars,rootFor);
                                            ggrandParentFor = findParentLoop(grandParentFor,obj.tree,compactTree,forNodeInfo);
                                            if ~ggrandParentFor.isempty
                                                [indexVars,rootFor] = processIndexVars(ggrandParentFor,indexVars,rootFor);
                                                gggrandParentFor = findParentLoop(ggrandParentFor,obj.tree,compactTree,forNodeInfo);
                                                if ~gggrandParentFor.isempty
                                                    [indexVars,rootFor] = processIndexVars(gggrandParentFor,indexVars,rootFor);
                                                    ggggrandParentFor = findParentLoop(gggrandParentFor,obj.tree,compactTree,forNodeInfo);
                                                    if ~ggggrandParentFor.isempty
                                                        [indexVars,rootFor] = processIndexVars(ggggrandParentFor,indexVars,rootFor);
                                                    end
                                                end
                                            end
                                        end

                                        if ~isempty(rootFor) % if a root for loop has been found
                                            if isscalar(indexVars)
                                                indexVars = [{'1'},indexVars]; %#ok<AGROW>
                                            end
                                            indexVars = join(indexVars,',');

                                            if strcmp(varType,'CELL')
                                                operation = 'cell';
                                            else
                                                operation = 'zeros';
                                            end
                                            indexVars = [varString,' = ',operation,'(',indexVars{1},');'];
                                            indexVars = removeAstBlanks(indexVars);

                                            [documentStart,issueLine,documentEnd] = sliceDocumentSimple(str,rootFor,offset);
                                            indent = regexp(issueLine,'^ *','match','once');
                                            str = [documentStart,indent,indexVars,newline,issueLine,documentEnd];
                                            offset = offset + 1;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

%% Local functions

function res = simpleSignsWithSpace
res = [{' '},simpleSigns];
end

function res = escapedSignsWithSpace
res = [{' *'},escapedSigns];
end

function res = simpleSigns
res = {'.','^','$','*','+','-','?','(',')','[',']','{','}','\','|'};
end

function res = escapedSigns
res = cellfun(@(arg)['\',arg],simpleSigns,'UniformOutput',false);
end

function node = getNextNode(node)
node = node.Next;
end

function res = getMoreCellArguments(node)
res = {};
nextNode = getNextNode(node);
while ~isempty(nextNode)
    res{end + 1} = nextNode.tree2str; %#ok<AGROW>
    nextNode = getNextNode(nextNode);
end
end

function throwWarning(msg) %#ok<INUSD>
% fprintf('\n')
% warning(msg)
end

function [documentStart,issueLine,documentEnd] = sliceDocumentSimple(str,node,offset)

if nargin == 2
    offset = 0;
end

lineNo = unique(node.lineno) + offset;
lines = regexp(str,['.*?(',char(13),newline,'|',char(13),'|',newline,'|$)']); % some files have characters [13,10] as new line and some only 13
documentStart = str(1:lines(lineNo) - 1); % start part of the document
if numel(lines) > lineNo
    issueLine = str(lines(lineNo):lines(lineNo + 1) - 1); % line with node's code
    documentEnd = str(lines(lineNo + 1):end); % end part of the document
else
    issueLine = str(lines(lineNo):end);
    documentEnd = '';
end
end

function [documentStart,issueLine,documentEnd,indent] = sliceDocument(str,node,offset)

% TODO: fix multi-line issues as in:
% C:\GitLab\energy-patterns\GitHubSearch_2026_01_12\MinedGithubProjects\spm\toolbox\mixture\spm_kmeans.m

if nargin == 2
    offset = 0;
end
lineNo = unique(node.lineno) + offset;
lines = regexp(str,['.*?(',char(13),newline,'|',char(13),'|',newline,'|$)']); % some files have characters [13,10] as new line and some only 13
documentStart = str(1:lines(lineNo) - 1); % start part of the document
lineOffset = 1;
if numel(lines) > lineNo
    issueLine = str(lines(lineNo):lines(lineNo + 1) - 1); % line with node's code

    [issueLine,lineOffset] = getFullIssueLine(issueLine,str,lines,lineNo,lineOffset);
    issueLine = regexprep(issueLine,'(?<!^[ \t]*)[ \t]*',' '); % replace multiple spaces with single space (not when at beginning of line)

    if lineNo + lineOffset <= numel(lines)
        documentEnd = str(lines(lineNo + lineOffset):end); % end part of the document
    else % it was already the last line
        documentEnd = '';
    end
else
    issueLine = str(lines(lineNo):end);
    documentEnd = '';
end
indent = regexp(issueLine,'^ *','match','once');
if ~strcmp(issueLine,newline) % only a new line character, probably because of some earlier multi-line fix...
    issueLine = replace(issueLine,char(9),repmat(char(32),1,4)); % replace tabulators with 4 spaces
    issueLine = regexprep(issueLine,'^( *)for\((.*)\)(\s*)$','$1for $2$3'); % remove () around for statement
    newSimpleSigns =  [{']'   ,'['   ,' '     ,','     },simpleSigns];
    newEscapedSigns = [{' *\]','\[ *','[ \t]*',' *,? *'},escapedSigns];
    expr = regexprep(node.tree2str,' *',' ');
    expr = regexprep(expr,[newline,'.*'],''); % remove ending new line
    expr = replace(expr,newSimpleSigns,newEscapedSigns);
    expr = regexprep(expr,'~=',' *~= *');
    expr = regexprep(expr,'[\<\>=]=?',' *$0 *');
    expr = regexprep(expr,'[:;]',' *$0 *');
    expr = regexprep(expr,'(\|\||&&|\\\(|\\\)|\\\{|\\\})',' *$0 *');
    [idx1,idx2] = regexp(issueLine,expr,'start','end','once');
    lineStart = issueLine(1:idx1 - 1);
    restOfLine = strtrim(issueLine(idx2 + 1:end));
    issueLine = issueLine(idx1:idx2);
    documentStart = [documentStart,lineStart];
    documentEnd = [restOfLine,repmat(newline,1,lineOffset),documentEnd];
    if isempty(issueLine)
        error 'Empty value for issue line.'
    end
end
end

function [issueLine,lineOffset] = getFullIssueLine(issueLine,codeStr,lines,lineNo,lineOffset)
% this function puts together a line of program code when spread on
% multiple lines using "..."

dots = regexp(issueLine,'\.\.\..*','match','once');
if ~isempty(dots)
    if lineNo + lineOffset + 1 <= numel(lines)
        nextLine = codeStr(lines(lineNo + lineOffset):lines(lineNo + lineOffset + 1) - 1); % line with node's code
    else % until end of file
        nextLine = codeStr(lines(lineNo + lineOffset):end); % line with node's code
    end
    issueLine = replace(issueLine,dots,'');
    issueLine = [issueLine,nextLine,newline];
    [issueLine,lineOffset] = getFullIssueLine(issueLine,codeStr,lines,lineNo,lineOffset + 1);
end
end

% function indices = prepareAst(tree,callName)
% calls = tree.mtfind('Kind','CALL');
% callNames = calls.Left.stringvals;
% IDX = cellfun(@(arg)strcmp(arg,callName),callNames);
% indices = calls.indices;
% indices = indices(IDX);
% end
% 
% function node = getNode(tree,indices,idx)
% index = indices(idx);
% node = tree.select(index);
% end

function [structName,afterTheDot] = getStructExpressionNames(node)
structName = node.Right.tree2str;
firstArgNode = node.Right.Next;
if strcmp(firstArgNode.kind,'CHARVECTOR')
    afterTheDot = firstArgNode.stringval; % char vector without trailing '
else
    afterTheDot = ['(',firstArgNode.tree2str,')'];
end
end

function node = findParentKind(node,type)
oldNode = node;
node = node.Parent;
if ~isempty(node)
    if ~strcmp(node.kind,type)
        node = findParentKind(node,type);
    else
        code = node.tree2str;
        endPos = regexp(code,'(?<=\s*end\s).');
        code = code(1:endPos(end) - 1);
        oldCode = oldNode.tree2str;
        code = regexprep(code,['(?<=',newline,') *'],'');
        oldCode = regexprep(oldCode,['(?<=',newline,') *'],'');
        if ~contains(code,oldCode)
            node = findParentKind(node,type);
        end
    end
end
end

function newNode = findParentLoop(node,tree,compactTree,loopNodeInfo)
newNode = mtree(''); % default value
nodeCounterpart = compactTree.select(node.indices);
if ~nodeCounterpart.isempty
    for idx = numel(loopNodeInfo):-1:1
        nodeInfo = loopNodeInfo(idx);
        % test = nodeInfo.startLine < nodeCounterpart.lineno && nodeInfo.endLine > nodeCounterpart.lineno;
        if nodeInfo.startLine < nodeCounterpart.lineno && nodeInfo.endLine > nodeCounterpart.lineno
            newNode = tree.select(nodeInfo.index);
            break
        end
    end
end
end

function code = removeAstBlanks(code)
code = regexprep(code,'\( *','(');
code = regexprep(code,' *\)',')');
code = regexprep(code,'\{ *','{');
code = regexprep(code,' *\}','}');
code = regexprep(code,'\[ *','[');
code = regexprep(code,' *\]',']');
end

function [nodeInfo,successful] = analyseLoops(compactTree,kind)
% start and end line number and index for for loops

successful = true;
forNodes = compactTree.mtfind('Kind',kind);
indices = forNodes.indices;
numNodes = numel(indices);

template.index = NaN;
template.startLine = NaN;
template.endLine = NaN;
nodeInfo = repmat(template,1,numNodes);

for idx = 1:numNodes
    node = forNodes.select(indices(idx));
    nodeInfo(idx).index = indices(idx);
    nodeInfo(idx).startLine = node.lineno;
    nodeStr = node.tree2str;
    if numel(nodeStr) > 100000 % node is too large to process a regex
        successful = false;
        return
    end
    endPos = regexp(nodeStr,[newline,'end'],'once');
    numNewlines = count(nodeStr(1:endPos),newline);
    nodeInfo(idx).endLine = node.lineno + numNewlines;
end
end

function [indexVars,rootFor] = processIndexVars(forNode,indexVars,rootFor)
counterIdx = forNode.Index.tree2str; % counter index of for loop
vectorKind = forNode.Vector.kind;
if strcmp(vectorKind,'COLON')
    maxIdx = forNode.Vector.Right.tree2str; % max index of for loop
else % example: for idx = var.field
    maxIdx = forNode.Vector.tree2str;
end
idxPos = cellfun(@(arg)strcmp(counterIdx,arg),indexVars);
if any(idxPos) % if indexing variable is found in for loop header
    rootFor = forNode;
    indexVars(idxPos) = {maxIdx};
end
end

function nodes = findIndexVariables(node)
nodes{1} = node.Right.tree2str;
node = node.Right;
while ~node.Next.isempty
    node = node.Next;
    nodeString = node.tree2str;
    nodeString = regexprep(nodeString,'^1:',''); % converts 1:maxIdx -> maxIdx
    nodes = [nodes,{nodeString}]; %#ok<AGROW>
end
% replace :-indexing with 1. :-indexing is used to define the direction of
% a vector (column or row)
IDX = cellfun(@(arg)strcmp(arg,':'),nodes);
nodes(IDX) = {'1'};
end
