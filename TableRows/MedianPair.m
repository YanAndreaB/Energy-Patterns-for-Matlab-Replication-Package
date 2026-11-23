%% MedianPair

classdef (Abstract) MedianPair < handle
    properties (Abstract)
        h_w % result of welch test
        h_wx % result of wilcoxon test
        h_wr % result of welch test for ratio
        h_wxr % result of wilcoxon test for ratio
        p_w
        p_wx
        mean1
        mean2
        yesSymbol
        noSymbol
        unitSymbol
    end

    properties (Constant)
        notDefinedSymbol = ''
    end

    properties
        rowTitle
        val1
        val2
        isSignificant
        p_value
    end

    properties (Dependent)
        string
        ratio
        gain
        significanceSymbol
    end

    methods
        function obj = MedianPair(rowTitle,matFile)
            % constructor

            obj.rowTitle = rowTitle;

            % load values
            obj.val1 = obj.loadValue(matFile,obj.mean1);
            obj.val2 = obj.loadValue(matFile,obj.mean2);

            % set significance
            [obj.isSignificant,obj.p_value] = obj.setSignificance(matFile,obj.h_w,obj.h_wx,obj.p_w,obj.p_wx);
        end

        function val = get.significanceSymbol(obj)
            val = obj.getSignificanceSymbol(obj.isSignificant);
        end

        function val = getSignificanceSymbol(obj,significanceFlag)
            % determine significance symbol depending on the significance
            % flag
            
            if isnan(significanceFlag)
                val = obj.notDefinedSymbol;
            else
                if significanceFlag
                    val = obj.yesSymbol;
                end

                if ~significanceFlag
                    val = obj.noSymbol;
                end
            end
        end

        function val = get.gain(obj)
            val = 1 - obj.ratio;
        end

        function val = get.ratio(obj)
            val = obj.val2 / obj.val1;
        end

        function val = get.string(obj)
            str = ['%s %0.2f',obj.unitSymbol,' %0.2f',obj.unitSymbol,' %0.1f%% %s (%0.1e)'];
            val = sprintf(str,obj.rowTitle,obj.val1,obj.val2,obj.gain * 100,obj.significanceSymbol,obj.p_value);
        end
    end

    methods (Access = protected)
        function [h_value,p_value] = setSignificance(~,matFile,h_w,h_wx,p_w,p_wx)
            % set value for flag isSignificant

            warning off MATLAB:load:variableNotFound
            if nargin >= 6
                loadRes = load(matFile,h_w,h_wx,p_w,p_wx);
            else
                loadRes = load(matFile,h_w,h_wx);
            end
            warning on MATLAB:load:variableNotFound

            h_value = NaN;
            if isfield(loadRes,h_w) % result of t-Welch-test
                h_value = loadRes.(h_w) == 1;
            elseif isfield(loadRes,h_wx) % result of Wilcoxon-test
                h_value = loadRes.(h_wx) == 1;
            end

            p_value = NaN;
            if nargin >= 6
                if isfield(loadRes,p_w) % result of t-Welch-test
                    p_value = loadRes.(p_w);
                elseif isfield(loadRes,p_wx) % result of Wilcoxon-test
                    p_value = loadRes.(p_wx);
                end
            end
        end
    end

    methods (Static,Access = private)
        function value = loadValue(matFile,fieldName)
            % load measured values for running time

            value = NaN;
            warning off MATLAB:load:variableNotFound
            loadRes = load(matFile,fieldName);
            warning on MATLAB:load:variableNotFound
            if isfield(loadRes,fieldName)
                value = loadRes.(fieldName);
            end
        end
    end
end
