function [durations, percep, rp] = ana_new_sfm(filepath)
%% function to analyze pilot data

%% load in
data = readtable(filepath, 'Delimiter', '\t');
catchmask = ismember(data.direction,{'CatchRight','CatchLeft','CatchEnd'});
raw = data(~catchmask,:);
catcht = data(catchmask,:);

nrun = raw.run(end);
fperrun = 180*60;
%% for loop...to scan
% this time I am trying a different strategy: just read the perception 1st,
% and then kick out the catch trials
percep = NaN(nrun, fperrun); 
nrow = size(raw , 1);
init = raw.flip(1);
state = raw.direction(1);
run = raw.run(1);
for k = 1:(nrow-1)

        if raw.run(k+1) ~= run
            percep(run, init:fperrun) = s2d(state);
            init = raw.flip(k+1);
            run = raw.run(k+1);
            state = raw.direction(k+1);
            continue
        end
        
        if ~strcmp(raw.direction{k+1}, state)
            percep(run, init:raw.flip(k+1))= s2d(state);
            init = raw.flip(k+1);
            state = raw.direction(k+1);
        end
end

percep(run, init:end)= s2d(state);

%% verify and kick out catch trials, each catch trial lasts 5s
% since the catch trial is always 300 flip, so we can ignore the CatchEnd
catchlen = 300-1;

catchr = catcht(strcmp(catcht.direction, 'CatchRight'),:);
catchl = catcht(strcmp(catcht.direction, 'CatchLeft'),:);
pr = [];
pl = [];

for krun = 1:nrun
    fr = catchr.flip(catchr.run == krun);
    fl = catchl.flip(catchl.run == krun);
    
    for i = 1:numel(fr)
        pr = [pr, percep(krun, fr(i):fr(i)+catchlen)]; %#ok<AGROW>
        percep(krun, fr(i):fr(i)+catchlen) = NaN;
    end
    
    for i = 1:numel(fl)
        pl = [pl, percep(krun, fl:fl+catchlen)]; %#ok<AGROW>
        percep(krun, fl:fl+catchlen) = NaN;
    end
    
end

%% catch result
disp('CatchLeft:');
rpl = mean(pl == 1) %#ok<NASGU,NOPRT>
disp('CatchRight:');
rpr = mean(pr == 2) %#ok<NASGU,NOPRT>
disp('Catch:');
rp = mean([pl == 1, pr == 2]) %#ok<NOPRT>

%% perception result
durations = cell2table({});
for krun = 1:nrun
    state = percep(krun,1);
    init = 1;
    for kp = 2:fperrun
        if percep(krun,kp) ~= state
            durations = [durations ; cell2table({krun, kp-init, d2s(state)})]; %#ok<AGROW>
            init = kp;
            state = percep(krun,kp);
        end
        
        if kp == fperrun
            durations = [durations ; cell2table({krun, fperrun-init, d2s(state)})]; %#ok<AGROW>
        end
        
    end
end
    
durations.Properties.VariableNames = {'Run', 'Duration', 'Direction'};
%% get rid of NaNs...
durations = durations(~strcmp(durations.Direction, 'NaN'),:);


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

%% function to translate state to number 1,2,3
    function d = s2d(s)
        d = find(strcmp(s, {'Left','Right','Down'}));
    end

    function s = d2s(d)
        switch d
            case 1
                s = 'Left';
            case 2
                s = 'Right';
            case 3
                s = 'Down';
        end
        
        if isnan(d)
            s = 'NaN';
        end
    end

end