function sfm_demo
% a sfm demo to collect behaviour data for ambiguous structure-from-motion
% from Gijs Joost Brouwer and Raymond van Ee, 2007
% sphere: height/length: 8.2 vd, 500 dots, rotating around vertical axis
% each dot: .05 vd in diameter
% central fixation: .2 vd
% angular volecity of the sphere: 16 vd/s
% average speed of the dots: 0.75 vd/s
% catch periord 20s per run


AssertOpenGL;
Priority(1);

sid = input('identifier for this session?','s');

fid = fopen([sid '.txt'], 'w');
fprintf(fid, 'run\tflip\tdirection\n');

% Run / Trial Parameters
nRuns = 6;
secsperrun = 180; %3 min per run
tcatchperrun = 4; % 4 catch trial per run
catchpert = 5; % 5 secs per trial

% key
kNames = {'Left', 'Right', 'Down', 'Escape'};
kvalid = KbName(kNames);
kesc = kvalid(4);

% Sti Parameters
vddot = .05; % In vd
vdsphere = 8.2;
ndots = 500;
vdfix = .2;
spdsphere = 16; % in vd/s

screenid = max(Screen('Screens'));
FrameRate = Screen('NominalFrameRate', screenid);

fperrun = secsperrun * FrameRate;
fcatfpert = catchpert * FrameRate;

if screenid
    monitorh=30; %12;% in cm
    distance=55;
else
    monitorh=19;
    distance=45;
end

% Determine the values of black and white
black = BlackIndex(screenid);
white = WhiteIndex(screenid);
gray = GrayIndex(screenid);
red = [255 0 0];
green = [0  255 0];

% Set up our screen
[window, mrect] = Screen('OpenWindow', screenid, black, [1920 0 1920+1024 768]);

[center(1), center(2)] = RectCenter(mrect);

DrawFormattedText(window, 'Please fixate at the center of the sceen and report your perception.\nLeft for rotation to the left,\n Right for rotation to the right,\nDown for both.\n', 'center', 'center', white);
Screen('Flip', window);

KbStrokeWait;
for run = 1:nRuns
    rng('default');
    % insert catch flips
    fcatchstart = randsample(1:fcatfpert:fperrun, tcatchperrun);
    disp(fcatchstart);
    % calculate x and y for each dot
    angle = rand(2, ndots).* 360; % in 3d
    Updateangle = spdsphere /  FrameRate; % vd per frame
    
    catchcountdown = NaN;
    for flip = 1:fperrun
        
        if ismember(flip, fcatchstart)
            catchcountdown = fcatfpert;
            fprintf(fid, '%d\t%d\t%s\n', run, flip, 'CatchStart');
        end
        
        if 1|| catchcountdown > 0
            % catch flip
            angle_back = angle(:, angle(2,:) < 90);
            angle_front = angle(:, angle(2,:) >=90);
            pix_back = projection(angle_back);
            pix_front = projection(angle_front);
            
            if ~isempty(pix_back)
                Screen('DrawDots', window, pix_back, ang2pix(vddot), green, center);
            else
                Screen('DrawDots', window, pix_front ,ang2pix(vddot), red, center);
            end
            DrawFormattedText(window,'Catch', 'center', 300, white);
            catchcountdown = catchcountdown - 1;
        else
            pix = projection(angle);
            Screen('DrawDots', window, pix ,ang2pix(vddot), white, center);
        end
        Screen('DrawDots', window, center, ang2pix(vdfix), white);
        Screen('Flip', window);
        angle = update(angle);
        CheckResp;
    end
    
    DrawFormattedText(window, ['End of block ', num2str(run), ', presse to start the next.'], 'center', 'center', white);
    Screen('Flip', window);
    KbStrokeWait;
end
session_end;

    function fangle = update(fangle)
        fangle(1,:) = fangle(1,:) + Updateangle;
        fangle(1, fangle(1,:) > 360) = fangle(1, fangle(1,:) > 360) - 360;
    end

    function fpix = projection(fangle)
        vd(2,:) = sind(fangle(2,:)).* (vdsphere / 2);
        vd(1,:) = cosd(fangle(1,:)).*cosd(fangle(2,:)).* (vdsphere / 2);
        fpix = ang2pix(vd);
    end

    function pixels=ang2pix(ang)
        pixpercm=mrect(4)/monitorh;
        pixels=tand(ang/2)*distance*2*pixpercm;
    end

    function session_end
        fclose(fid);
        ShowCursor;
        sca;
        return
    end

    function CheckResp
        [keyIsDown, ~, keyCode] = KbCheck;
        knum = find(keyCode);
        if keyIsDown && numel(knum) == 1
            direction = kNames{ismember(kvalid, knum)};
            fprintf(fid, '%d\t%d\t%s\n', run, flip, direction);
            if knum == kesc
                session_end;
            end
        end


    end
end