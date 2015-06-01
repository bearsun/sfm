function durations = ana_pilot_sfm(filepath)

%% function to analyze pilot data

%% load in
data = readtable(filepath);

fperrun = 210*60;
%% for loop...to scan
durations = cell2table({});
nrow = size(data , 1);
init = data.flip(1);
for k = 1:nrow
    if strcmp(data.direction{k}, 'Escape')
        disp(data(k,:));
        break
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
end