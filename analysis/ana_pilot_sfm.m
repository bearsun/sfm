function durations = ana_pilot_sfm(filepath)

%% function to analyze pilot data

%% load in
data = readtable(filepath, 'Delimiter', '\t');

fperrun = 180*60;
%% for loop...to scan
durations = cell2table({});
nrow = size(data , 1);
init = data.flip(1);
flag_catch = 0;
for k = 1:nrow
    if strcmp(data.direction{k}, 'Escape')
        disp(data(k,:));
        break
    end
    
    if strcmp(data.direction{k+1}, 'CatchLeft')
        flag_catch = 1;
    elseif strcmp(data.direction{k+1}, 'CatchRight')
        flag_catch = 2;
    end

    if strcmp(data.direction{k}, 'CatchEnd')
        flag_catch = 0;
        continue
    end
    
    if flag_catch
        continue
    end
    
    if ~strcmp(data.direction{k},data.direction{k+1}) || data.run(k) ~= data.run(k+1)
        if data.run(k)~= data.run(k+1)
            duration = fperrun - init;
        else
            duration = data.flip(k+1) - init;
        end
        durations = [durations ; cell2table({data.run(k), duration, data.direction{k}})]; %#ok<AGROW>
        init = data.flip(k+1);
    end
    
end
durations.Properties.VariableNames = {'Run', 'Duration', 'Direction'};

%% baseline
disp('Baseline: Left / Right / Down / All');
baseline = durations(durations.Run<5,:);
display_data(baseline);

%% maintainance
disp('Maintain: Left / Right / Down / All');
maintain = durations(rem(durations.Run,2) == 1 & durations.Run>4,:);
display_data(maintain);


%% alternation
disp('Alternation: Left / Right / Down / All');
alter = durations(rem(durations.Run,2) == 0 & durations.Run>4,:);
display_data(alter);

    function display_data(d)
        disp(mean(d.Duration(strcmp(d.Direction,'Left')))/60);
        disp(mean(d.Duration(strcmp(d.Direction,'Right')))/60);
        disp(mean(d.Duration(strcmp(d.Direction,'Down')))/60);
        disp(mean(d.Duration/60));
    end
end