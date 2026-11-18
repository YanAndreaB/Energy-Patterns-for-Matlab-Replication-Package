%% runFileAndCatchError

function runFile(file,numRuns)
for idx = 1:numRuns
    run(file)
end
end
