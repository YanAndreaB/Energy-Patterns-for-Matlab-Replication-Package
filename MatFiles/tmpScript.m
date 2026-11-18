
fileNames = splitNames(:,3);
projects = splitNames(:,1);
counter = 0;
collection = {};
for idx = 1:height(filesStudy3)
    fullFileName = filesStudy3.fileName{idx};
    file = fullFileName;
    project = regexp(fullFileName,'.*?(?=__)','match','once');
    [~,file] = fileparts(file);
    IDX1 = fileNames == string(file);
    IDX2 = projects == string(project);
    if sum(IDX1 & IDX2) > 0
        counter = counter + 1;
        collection = [collection;{fullFileName}];
        % disp(find(IDX1' & IDX2'))
        disp(fullFileName)
    end
end
