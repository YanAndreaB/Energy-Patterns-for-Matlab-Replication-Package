%% EnergyTestScript
% Author: jan-andrea.bard@unibe.ch
% File Dependencies:
% - ticke.m
% - tocke.m
% - tickeTocke.m
% Other Dependencies
% - Intel CPU (newer than Sandy Bridge)
% - Linux OS
% 
% EnergyTestScript is used to execute a software energy consumption
% experiment. It handles random execution order of code variants A and B,
% pausing between measurements for CPU cooldown, running code without
% measurement to bring CPU to working temperature, handling statistical
% analysis of measurements.
% 
% Syntax:
% TestingClass = EnergyTestScript;
% 
% TestingClass.prepareA = @handleToPreparationFunctionA;
% TestingClass.prepareB = @handleToPreparationFunctionB;
% TestingClass.cleanUpA = @handleToCleanUpFunctionA;
% TestingClass.cleanUpB = @handleToCleanUpFunctionB;
% 
% TestingClass.benchmarkA = @handleToBenchmarkA;
% TestingClass.benchmarkB = @handleToBenchmarkB;
% 
% TestingClass.matFileFolder = folderForSavingMatfiles;
% TestingClass.execute

% Turn-off wire-less!

% Close Firefox and other applications!

% Only plug to electricity (no docking-station) and dim screen!

classdef EnergyTestScript < handle
    properties (Constant, Access = private)
        gitLabFolder = setGitLabFolder;
        numTestseries = 2; % number of test series that should be run in one experiment
        governors = {'powersave','conservative','ondemand','performance'};
        alpha_lillie = 0.05;
        alpha_welch = 0.05;
        alpha_wilcoxon = 0.05;
        varsToSave = {'energy*Brutto','dramEnergy*Brutto', 'time*','loggedInUsers','listOfGovernors','order', ...
            'pauseDuration','numRepetitions', 'gitLabFolder','date','numTestseries'};
    end

    properties (Access = public)
        numRepetitions = 30;
        pauseDuration = 30;

        % values can be overridden by initializeExperiment script
        prepareA = @()[]; % do nothing
        prepareB = @()[]; % do nothing
        cleanUpA = @()[]; % do nothing
        cleanUpB = @()[]; % do nothing
        benchmarkA
        benchmarkB
        fileDescription = ''
        matFileNameProcessed
        matFileFolder = ''
    end

    properties (Access = private)
        date
        loggedInUsers
        listOfGovernors

        order
        count1 = 1;
        count2 = 1;
        energy1Brutto
        energy2Brutto
        energy1Net
        energy2Net
        dramEnergy1Brutto
        dramEnergy2Brutto
        time1
        time2
        mean1_b
        mean2_b
        mean1_n
        mean2_n
        mean1_d
        mean2_d
        mean1_t
        mean2_t
        ratio_b
        ratio_n
        ratio_d
        ratio_t
        ratios_e
        ratios_t
        hasOverflown
    end

    methods
        function obj = EnergyTestScript
        end
    end

    methods (Access = public)
        function appendEnergyTimeRatios(obj)
            obj.calculateEnergyTimeRatios
            ratios_e = obj.ratios_e; %#ok<NASGU>
            ratios_t = obj.ratios_t; %#ok<NASGU>

            save(obj.matFileNameProcessed,'ratios*','-append')
        end

        function statisticalTests(obj)
            % Lilliefors-Test for normality
            % if the h-value is 0 the data is normally distributed at an alpha level
            [h1,~] = obj.lilliesWrapper(obj.energy1Brutto);
            [h2,~] = obj.lilliesWrapper(obj.energy2Brutto);
            doWelchTestBrutto = h1 == 0 && h2 == 0;

            % Lilliefors-Test for normality
            % if the h-value is 0 the data is normally distributed at an alpha level
            [h1_n,~] = obj.lilliesWrapper(obj.energy1Net);
            [h2_n,~] = obj.lilliesWrapper(obj.energy2Net);
            doWelchTestNet = h1_n == 0 && h2_n == 0;

            % Lilliefors-Test for normality
            % if the h-value is 0 the data is normally distributed at an alpha level
            [h1_d,~] = obj.lilliesWrapper(obj.dramEnergy1Brutto);
            [h2_d,~] = obj.lilliesWrapper(obj.dramEnergy2Brutto);
            doWelchTestDram = h1_d == 0 && h2_d == 0;

            % Lilliefors-Test for normality
            % if the h-value is 0 the data is normally distributed at an alpha level
            [h1_t,~] = obj.lilliesWrapper(obj.time1);
            [h2_t,~] = obj.lilliesWrapper(obj.time2);
            doWelchTestTime = h1_t == 0 && h2_t == 0;

            % Welch's t-test
            % -H0: The means of energy consumption of versions A and B are equal
            % -H1: The means of energy consumption of versions A and B are different
            if doWelchTestBrutto
                [h_w,p_w,~,~] = ttest2(obj.energy1Brutto,obj.energy2Brutto,"Alpha",obj.alpha_welch); %#ok<*ASGLU>
            end

            % Welch's t-test
            % -H0: The means of energy consumption of versions A and B are equal
            % -H1: The means of energy consumption of versions A and B are different
            if doWelchTestNet
                [h_wn,p_wn,~,~] = ttest2(obj.energy1Net,obj.energy2Net,"Alpha",obj.alpha_welch);
            end

            % Welch's t-test
            % -H0: The means of energy consumption of versions A and B are equal
            % -H1: The means of energy consumption of versions A and B are different
            if doWelchTestDram
                [h_wd,p_wd,~,~] = ttest2(obj.dramEnergy1Brutto,obj.dramEnergy2Brutto,"Alpha",obj.alpha_welch);
            end

            % Welch's t-test
            % -H0: The means of energy consumption of versions A and B are equal
            % -H1: The means of energy consumption of versions A and B are different
            if doWelchTestTime
                [h_wt,p_wt,~,~] = ttest2(obj.time1,obj.time2,"Alpha",obj.alpha_welch);
            end

            if ~doWelchTestBrutto
                [p_wx,h_wx] = obj.signrankWrapper(obj.energy1Brutto,obj.energy2Brutto);
            end

            if ~doWelchTestNet
                [p_wxn,h_wxn] = obj.signrankWrapper(obj.energy1Net,obj.energy2Net);
            end

            if ~doWelchTestDram
                [p_wxd,h_wxd] = obj.signrankWrapper(obj.dramEnergy1Brutto,obj.dramEnergy2Brutto);
            end

            if ~doWelchTestTime
                [p_wxt,h_wxt] = obj.signrankWrapper(obj.time1,obj.time2);
            end

            obj.calculateEnergyTimeRatios

            obj.ratios_e = removeOutliers(obj.ratios_e,3,[]);
            obj.ratios_t = removeOutliers(obj.ratios_t,3,[]);

            [h_re,~] = obj.lilliesWrapper(obj.ratios_e); % test for normality
            [h_rt,~] = obj.lilliesWrapper(obj.ratios_t); % test for normality
            doWelchTestRatios = h_re == 0 && h_rt == 0;

            if doWelchTestRatios
                [h_wr,p_wr,~,~] = ttest2(obj.ratios_e,obj.ratios_t,"Alpha",obj.alpha_welch); % t-welch-test
            end

            if ~doWelchTestRatios
                [p_wxr,h_wxr] = obj.signrankWrapper(obj.ratios_e,obj.ratios_t);
            end

            ratios_e = obj.ratios_e;
            ratios_t = obj.ratios_t;

            % append statistic results to mat file
            save(obj.matFileNameProcessed,'h1*','-append')
            save(obj.matFileNameProcessed,'h2*','-append')
            save(obj.matFileNameProcessed,'h_*','-append')
            save(obj.matFileNameProcessed,'p_*','-append')
            save(obj.matFileNameProcessed,'ratios_e','ratios_t','-append')
        end

        function readOriginalData(obj,matfile)
            res = dir(matfile); % find file when matfile contains wildcard character *
            matFileNameOriginal = res.name;
            obj.matFileNameProcessed = replace(matFileNameOriginal,'original','processed');

            load(matFileNameOriginal,'energy1Brutto','energy2Brutto','dramEnergy1Brutto','dramEnergy2Brutto','time1','time2', ...
                'loggedInUsers','listOfGovernors','order','date')
            obj.energy1Brutto = energy1Brutto;
            obj.energy2Brutto = energy2Brutto;
            obj.dramEnergy1Brutto = dramEnergy1Brutto;
            obj.dramEnergy2Brutto = dramEnergy2Brutto;
            obj.time1 = time1;
            obj.time2 = time2;
            obj.loggedInUsers = loggedInUsers;
            obj.listOfGovernors = listOfGovernors;
            obj.order = order;
            obj.date = date;
        end

        function readMeasurementData(obj,matfile)
            res = dir(matfile); % find file when matfile contains wildcard character *
            obj.matFileNameProcessed = res.name;

            load(obj.matFileNameProcessed,'energy1Brutto','energy2Brutto','ratios_e','ratios_t','time1','time2','dramEnergy1Brutto','dramEnergy2Brutto');
            obj.energy1Brutto = energy1Brutto;
            obj.energy2Brutto = energy2Brutto;
            obj.ratios_e = ratios_e;
            obj.ratios_t = ratios_t;
            obj.time1 = time1;
            obj.time2 = time2;
            obj.dramEnergy1Brutto = dramEnergy1Brutto;
            obj.dramEnergy2Brutto = dramEnergy2Brutto;
        end

        function histograms(obj)
            % % histograms
            % ax1 = axes(figure);
            % ax2 = axes(figure);
            % nbins = 17;
            % histogram(ax1,obj.energy1Brutto,nbins)
            % histogram(ax2,obj.energy2Brutto,nbins)
            % histogram(ax1,energy1Net,nbins)
            % histogram(ax2,energy2Net,nbins)

            % histograms 2
            makeHistogram(obj.energy1Brutto,obj.energy2Brutto,'Energy Brutto')

            % % Figure Format (if creating a figure of histograms)
            % ax = gca;
            % ax.Title.FontSize = 20;
            % ax.FontSize = 16;
            % ax.Legend.FontSize = 16;

            makeHistogram(obj.ratios_e,obj.ratios_t,'Ratios Energy vs. Time')

            makeHistogram(obj.time1,obj.time2,'Time')

        end

        function postProcessing(obj)
            obj.cleanData
            obj.calculateNetEnergy
            obj.calculateStandardDeviation
            obj.calculateMeanValues
            obj.calculateRatios
            obj.saveData('processed')
            obj.statisticalTests
        end

        function preProcessing(obj)
            obj.setDate
            obj.setListOfGovernors
            obj.addPaths
            obj.loadMetaData
            obj.initialize
        end

        function execute(obj)
            obj.preProcessing
            obj.testAll
            obj.postProcessing
        end
    end

    methods (Access = protected)
        function dispLoggedInUsers(obj)
            disp 'Logged in users:'
            disp(unique(obj.loggedInUsers))
        end
    end

    methods (Access = private)
        function [p_wx,h_wx] = signrankWrapper(obj,values1,values2)
            p_wx = NaN; % default value
            h_wx = NaN; % default value
            
            % Preparation for Wilcoxon test
            len = min(numel(values1),numel(values2));

            % Wilcoxon signed rank test
            % if h1 or h2 are 1 then data is not normally distributed and a Wilcoxon
            % test should be performed
            if len > 0
                [p_wx,h_wx] = signrank(values1(1:len),values2(1:len),'alpha',obj.alpha_wilcoxon);
            end
        end

        function [h,p] = lilliesWrapper(obj,values)
            h = NaN;
            p = NaN;
            if numel(values) >= 4 % lillietest throws an error if less than 4 values are supplied
                [h,p] = lillietest(values,'Alpha',obj.alpha_lillie);
            end
        end

        function setDate(obj)
            obj.date = replace(char(datetime('now')),":","_");
        end

        function addPaths(obj)
            % add locations to Matlab search path

            addpath(genpath(fullfile(obj.gitLabFolder,'general-matlab-files')))
            addpath(genpath(fullfile(obj.gitLabFolder,'matlab-tools')))
        end

        function loadMetaData(~)
            % Load metadata (deprecated method for initializing experiment)

            % metadata.mat must store function handles for benchmarkA and benchmarkB
            % load("metadata.mat")
        end

        function initialize(obj)
            % initialization

            if exist('initializeExperiment','file')
                % initalization can be performed in test-case specific
                % initialization script
                initializeExperiment

                if exist('benchmarkA','var')
                    obj.benchmarkA = benchmarkA;
                end
                if exist('benchmarkB','var')
                    obj.benchmarkB = benchmarkB;
                end
                if exist('prepareA','var')
                    obj.prepareA = prepareA;
                end
                if exist('prepareB','var')
                    obj.prepareB = prepareB;
                end
                if exist('cleanUpA','var')
                    obj.cleanUpA = cleanUpA;
                end
                if exist('cleanUpB','var')
                    obj.cleanUpB = cleanUpB;
                end
            end
        end

        function setListOfGovernors(obj)
            [~,obj.listOfGovernors] = system('cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor');
        end

        function setGovernors(~,governor)
            switch computer
                case 'PCWIN64'
                    % do nothing
                otherwise % linux
                    for idx = 0:7
                        system(sprintf('sudo cpufreq-set -c %d -g %s',idx,governor));
                    end
            end
        end

        function testAll(obj)
            % test all

            for idx0 = 3 % 3: ondemand governor
                obj.setGovernors(obj.governors{idx0})
                obj.initializeVariables

                for idx = 1:obj.numRepetitions * obj.numTestseries
                    obj.doMeasurementRun(idx)
                end

                obj.saveData('original')

                disp '---'
                disp 'Experiment done'
                obj.dispLoggedInUsers
            end

            % set governors
            obj.setGovernors('ondemand')
            % activate warnings
            warning on
        end

        function initializeVariables(obj)
            % Initialize
            obj.order = repmat(1:obj.numTestseries,1,obj.numRepetitions);
            obj.order = obj.order(randperm(obj.numRepetitions * obj.numTestseries));
            obj.count1 = 1;
            obj.count2 = 1;
            obj.energy1Brutto = zeros(obj.numRepetitions,1);
            obj.energy2Brutto = zeros(obj.numRepetitions,1);
            obj.dramEnergy1Brutto = zeros(obj.numRepetitions,1);
            obj.dramEnergy2Brutto = zeros(obj.numRepetitions,1);
            obj.time1 = zeros(obj.numRepetitions,1);
            obj.time2 = zeros(obj.numRepetitions,1);

            obj.loggedInUsers = {};
        end

        function doMeasurementRun(obj,idx)
            % make sure no other user is logged into server
            [~,obj.loggedInUsers{end + 1}] = system('sudo users');

            % clear functions and persistent variables
            clear functions %#ok<CLFUNC>
            % clear global variables
            clear global
            % close all figures
            close all
            close(findall(0,'type','figure')) % close UI-figures as well
            % deactivate warnings
            warning off

            disp("Measurement: " + idx + " (" + obj.order(idx) + ")")
            % pause
            fprintf('Pause %d sec...\n',obj.pauseDuration)
            forcePause(obj.pauseDuration)
            fprintf('Run benchmark...\n')

            switch obj.order(idx)
                case 1
                    obj.prepareA();
                    obj.benchmarkA(); % warm up

                    t1 = obj.startMeasurement;
                    obj.benchmarkA(); % measurement
                    [obj.time1(obj.count1),obj.energy1Brutto(obj.count1),obj.dramEnergy1Brutto(obj.count1)] = obj.stopMeasurement(t1);
 
                    obj.cleanUpA()
                    obj.count1 = obj.count1 + 1;
                case 2
                    obj.prepareB();
                    obj.benchmarkB(); % warm up

                    t1 = obj.startMeasurement;
                    obj.benchmarkB(); % measurement
                    [obj.time2(obj.count2),obj.energy2Brutto(obj.count2),obj.dramEnergy2Brutto(obj.count2)] = obj.stopMeasurement(t1);

                    obj.cleanUpB()
                    obj.count2 = obj.count2 + 1;
            end

            % close open matlab figures
            close all
        end

        function saveData(obj,type)
            fileName = ['measurement_',obj.fileDescription,obj.date,'_',type,'.mat'];
            fileName = fullfile(obj.matFileFolder,fileName);

            if strcmp(type,'processed')
                newVars = {'mean*','ratio*'};
                allVars = [obj.varsToSave,newVars];
                obj.matFileNameProcessed = fileName;
            else
                allVars = obj.varsToSave;
            end

            energy1Brutto = obj.energy1Brutto; %#ok<NASGU>
            energy2Brutto = obj.energy2Brutto; %#ok<NASGU>
            dramEnergy1Brutto = obj.dramEnergy1Brutto; %#ok<NASGU>
            dramEnergy2Brutto = obj.dramEnergy2Brutto; %#ok<NASGU>
            time1 = obj.time1; %#ok<NASGU>
            time2 = obj.time2; %#ok<NASGU>
            loggedInUsers = obj.loggedInUsers; %#ok<NASGU>
            listOfGovernors = obj.listOfGovernors; %#ok<NASGU>
            order = obj.order; %#ok<NASGU>
            pauseDuration = obj.pauseDuration; %#ok<NASGU>
            numRepetitions = obj.numRepetitions; %#ok<NASGU>
            gitLabFolder = obj.gitLabFolder; %#ok<NASGU>
            date = obj.date; %#ok<NASGU>
            numTestseries = obj.numTestseries; %#ok<NASGU>

            if strcmp(type,'processed')
                mean1_b = obj.mean1_b; %#ok<NASGU>
                mean2_b = obj.mean2_b; %#ok<NASGU>
                mean1_n = obj.mean1_n; %#ok<NASGU>
                mean2_n = obj.mean2_n; %#ok<NASGU>
                mean1_d = obj.mean1_d; %#ok<NASGU>
                mean2_d = obj.mean2_d; %#ok<NASGU>
                mean1_t = obj.mean1_t; %#ok<NASGU>
                mean2_t = obj.mean2_t; %#ok<NASGU>
                ratio_b = obj.ratio_b; %#ok<NASGU>
                ratio_n = obj.ratio_n; %#ok<NASGU>
                ratio_d = obj.ratio_d; %#ok<NASGU>
                ratio_t = obj.ratio_t; %#ok<NASGU>
                ratios_e = obj.ratios_e; %#ok<NASGU>
                ratios_t = obj.ratios_t; %#ok<NASGU>
            end

            save(fileName, allVars{:})
        end

        function cleanData(obj)
            % remove zeros and negative values

            obj.hasOverflown = any([obj.energy1Brutto;obj.energy2Brutto] < 0);

            [obj.energy1Brutto,IDX] = removeZerosAndNegatives(obj.energy1Brutto);
            obj.time1 = obj.time1(IDX);
            [obj.energy2Brutto,IDX] = removeZerosAndNegatives(obj.energy2Brutto);
            obj.time2 = obj.time2(IDX);
            obj.dramEnergy1Brutto = removeZerosAndNegatives(obj.dramEnergy1Brutto);
            obj.dramEnergy2Brutto = removeZerosAndNegatives(obj.dramEnergy2Brutto);
        end

        function energyBaselinePerSecond = getEnergyBaseline(obj) %#ok<MANU>
            energyBaselinePerSecond = 0;
        end

        function calculateNetEnergy(obj)
            % net energy

            energyBaselinePerSecond = obj.getEnergyBaseline;
            obj.energy1Net = obj.energy1Brutto - obj.time1 * energyBaselinePerSecond;
            obj.energy2Net = obj.energy2Brutto - obj.time2 * energyBaselinePerSecond;
        end

        function calculateStandardDeviation(obj)
            % standard deviations / remove outliers
            nstd = 3.0;

            obj.energy1Brutto = removeOutliers(obj.energy1Brutto,nstd,obj.time1);
            obj.energy2Brutto = removeOutliers(obj.energy2Brutto,nstd,obj.time2);
            obj.energy1Net = removeOutliers(obj.energy1Net,nstd,[]);
            obj.energy2Net = removeOutliers(obj.energy2Net,nstd,[]);
            obj.dramEnergy1Brutto = removeOutliers(obj.dramEnergy1Brutto,nstd,[]);
            obj.dramEnergy2Brutto = removeOutliers(obj.dramEnergy2Brutto,nstd,[]);
        end

        function calculateMeanValues(obj)
            % mean values
            obj.mean1_b = mean(obj.energy1Brutto);
            obj.mean2_b = mean(obj.energy2Brutto);
            obj.mean1_n = mean(obj.energy1Net);
            obj.mean2_n = mean(obj.energy2Net);
            obj.mean1_d = mean(obj.dramEnergy1Brutto);
            obj.mean2_d = mean(obj.dramEnergy2Brutto);
            obj.mean1_t = mean(obj.time1);
            obj.mean2_t = mean(obj.time2);
        end

        function calculateEnergyTimeRatios(obj)
            % Check if energy ratio differs significantly from time ratio
            len = min(numel(obj.energy1Brutto),numel(obj.energy2Brutto));
            obj.ratios_e = sort(obj.energy2Brutto(1:len)) ./ sort(obj.energy1Brutto(1:len));
            len = min(numel(obj.time1),numel(obj.time2));
            obj.ratios_t = sort(obj.time2(1:len)) ./ sort(obj.time1(1:len));
        end

        function calculateRatios(obj)
            % Ratios
            obj.ratio_b = obj.mean2_b / obj.mean1_b;
            obj.ratio_n = obj.mean2_n / obj.mean1_n;
            obj.ratio_d = obj.mean2_d / obj.mean1_d;
            obj.ratio_t = obj.mean2_t / obj.mean1_t;
        end
    end

    methods (Static,Access = protected)
        function t1 = startMeasurement
            t1 = tic;
            ticke
        end

        function [deltaT,deltaEnergy,deltaDramEnergy] = stopMeasurement(t1)
            deltaT = toc(t1);
            [deltaEnergy,deltaDramEnergy] = tocke;
        end
    end
end

%% Local functions

function [energyBrutto,time] = removeOutliers(energyBrutto,nstd,time)
stdMeasured = std(energyBrutto);
IDX = abs(energyBrutto - mean(energyBrutto)) > nstd * stdMeasured;
energyBrutto(IDX) = [];
if ~isempty(time)
    time(IDX) = [];
end
end

function makeHistogram(energy1Brutto,energy2Brutto,titleStr)
ax = axes(figure);
nbins = 17;
histogram(ax,energy1Brutto,nbins)
hold on
histogram(ax,energy2Brutto,nbins)
ax.Title.String = titleStr;
end

function [energyBrutto,IDX] = removeZerosAndNegatives(energyBrutto)
IDX = energyBrutto > 0;
energyBrutto = energyBrutto(IDX);
end
