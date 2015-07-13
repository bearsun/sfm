function durations = ana_pilot_sfm(filepath)
%% function to analyze pilot data
% not working, abandoned 7/13/15
%% load in
data = readtable(filepath, 'Delimiter', '\t');

fperrun = 180*60;
%% for loop...to scan
durations = cell2table({});
nrow = size(data , 1);
init = [];
flag_catch = 0;
state = [];
run = [];
k = 0;
while k < nrow - 1
    k = k+1
    %% init the flip counter at the beginning of the run
    if isempty(init) && ~flag_catch
        init = data.flip(k);
    end
    
    if isempty(state) && any(strcmp(data.direction{k}, {'Left', 'Right'}))
        state = data.direction{k};
    end
    
    if isempty(run)
        run = data.run(k);
    end
    
    %% check catch trial
    if any(strcmp(data.direction{k}, {'CatchLeft', 'CatchRight'}))
        flag_catch = 1;
        duration = data.flip(k) - init;
        if duration % if not the beginning of the run
            durations = [durations ; cell2table({data.run(k), duration, state})]; %#ok<AGROW>
        elseif data.run(k) ~= run
            run = data.run(k);
            state = [];
        end
        init = [];
        continue
    end
    
    if strcmp(data.direction{k}, 'CatchEnd')
        flag_catch = 0;
        init = data.flip(k);
        continue
    end
    
    if flag_catch % skip but update the perception
        state =  data.direction{k};
        continue
    end
    
    %% delete the flip counter at the end of the run and record the last direction
    if data.run(k) ~= run
        duration = fperrun - init;
        if duration % if that's not zero
            durations = [durations ; cell2table({run, duration, state})]; %#ok<AGROW>
        end
        run = data.run(k);
        init = data.flip(k);
        state = data.direction{k};
        continue
    end
    
    %% if the direction/flag of the next flip is different or the run is different
    if ~strcmp(data.direction{k},data.direction{k+1}) && ~flag_catch
        duration = data.flip(k+1) - init;
        durations = [durations ; cell2table({data.run(k), duration, state})]; %#ok<AGROW>
        init = data.flip(k+1);
        state = data.direction{k+1};
    end
    
end
durations.Properties.VariableNames = {'Run', 'Duration', 'Direction'};

%% baseline
disp('Baseline: Left / Right / Down / All');
baseline = durations(durations.Run<4,:);
display_data(baseline);

%% maintainance
disp('Maintain: Left / Right / Down / All');
maintain = durations(rem(durations.Run,2) == 0 & durations.Run>4,:);
display_data(maintain);


%% alternation
disp('Alternation: Left / Right / Down / All');
alter = durations(rem(durations.Run,2) == 1 & durations.Run>4,:);
display_data(alter);

function display_data(d)
disp(mean(d.Duration(strcmp(d.Direction,'Left')))/60);
disp(mean(d.Duration(strcmp(d.Direction,'Right')))/60);
disp(mean(d.Duration(strcmp(d.Direction,'Down')))/60);
disp(mean(d.Duration/60));
end
end