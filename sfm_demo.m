function sfm_demo(debug)
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

flag_return = 0;

sid = input('identifier for this session?','s');
abbreviatedFilename = sid;
fid = fopen([sid '.txt'], 'w');
fprintf(fid, 'run\tflip\tdirection\n');

% Run / Trial Parameters
nCond = 3; % 3 conditions: passive, maintainence, alternation
% kCond = 1:nCond;
nrunpercond = 3; % 3 runs for each condition
nRuns = nCond * nrunpercond;
secsperrun = 180; %3 min per run
tcatchperrun = 4; % 4 catch trial per run
catchpert = 5; % 5 secs per trial
runseq = [ones(1,nrunpercond), repmat(2:nCond, [1,nrunpercond])];

assert(numel(runseq) == nRuns);

instructs = {'';
    'Please try to maintain every perception as long as possible.\n';
    'Please try to switch between every perception as fast as possible.\n'};

condinst = instructs(runseq);

% key
kspace = KbName('Space');
kreturn=KbName('Return');
kback = KbName('BackSpace');
kNames = {'Left', 'Right', 'Down', 'Escape'};
kvalid = KbName(kNames);
kesc = kvalid(4);
keyW = KbName('w');

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
dim = [80 80 80];


[window, mrect] = Screen('OpenWindow', screenid, black);
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

[center(1), center(2)] = RectCenter(mrect);

mainwin = window;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Calibration
if ~debug
    Eyelink('Shutdown');
    Eyelink('Initialize');
    HideCursor;
    
    Eyelink('StartSetup')
    pause(2)
    
    
    whichKey=0;
    
    keysWanted=[kspace kreturn kback];
    flushevents('keydown');
    while 1
        pressed = 0;
        while pressed == 0
            [pressed, ~, kbData] = kbcheck;
        end;
        
        for keysToCheck = 1:length(keysWanted)
            if kbData(keysWanted(keysToCheck)) == 1
                
                keyPressed = keysWanted(keysToCheck);
                if keyPressed == kback
                    whichKey=9;
                    flushevents('keydown');
                    waitsecs(.1)
                elseif keyPressed == kspace
                    whichKey=1;
                    flushevents('keydown');
                    waitsecs(.1)
                elseif keyPressed == kreturn
                    whichKey=5;
                    flushevents('keydown');
                    waitsecs(.1)
                else
                end
                flushevents('keydown');
                
            end;
        end;
        
        if whichKey == 1
            whichKey=0;
            [~, tx, ty] = Eyelink('TargetCheck');
            Screen('FillRect', mainwin ,white, [tx-20 ty-5 tx+20 ty+5]);
            Screen('FillRect', mainwin ,white, [tx-5 ty-20 tx+5 ty+20]);
            Screen('Flip', mainwin);
        elseif whichKey == 5
            whichKey=0;
            Eyelink('AcceptTrigger');
        elseif whichKey == 9
            break;
        end
    end;
    status = Eyelink('OpenFile',abbreviatedFilename);
    if status
        error(['openfile error, status: ', num2str(status)]);
    end
    Eyelink('StartRecording');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up our screen
if ~debug
    Eyelink('Message','session_start');
end


DrawFormattedText(window, 'Please fixate at the center of the sceen and report your perception.\nLeft for rotation to the left,\n Right for rotation to the right,\nDown for both.\n', 'center', 'center', white);
Screen('Flip', window);

WaitSpace;
for run = 1:nRuns
    if run == nrunpercond + 1
        DrawFormattedText(window, 'Plese wait for the experimenter.\n', 'center', 'center', white);
        Screen('Flip', window);
        while 1
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown && find(keyCode) == keyW
                break;
            end
        end
    end
    
    DrawFormattedText(window, ['Block No. ', num2str(run), ',\n', condinst{run}, 'Presse space to start.\n'], 'center', 'center', white);
    Screen('Flip', window);
    WaitSpace;

    rng('Shuffle');
    % insert catch flips
    fcatchstart = randsample(1:fcatfpert:fperrun, tcatchperrun);
    fcatchorient = randi(2, size(fcatchstart));
    disp([fcatchstart; fcatchorient]);
    % calculate x and y for each dot
    angle = [rand(1,ndots).*360; rand(1,ndots).* 180 - 90];
    Updateangle = spdsphere /  FrameRate; % vd per frame
    
    catchcountdown = NaN;
    
    if ~debug
        Eyelink('Message','run_start');
    end
    
    for flip = 1:fperrun
        [bcatch, k] = ismember(flip, fcatchstart);
        if bcatch
            catchcountdown = fcatfpert;
            kcatch = k;
            
            if fcatchorient(kcatch) == 1
                fprintf(fid, '%d\t%d\t%s\n', run, flip, 'CatchLeft');
            elseif fcatchorient(kcatch) == 2
                fprintf(fid, '%d\t%d\t%s\n', run, flip, 'CatchRight');
            end
            
        elseif catchcountdown == 1
            fprintf(fid, '%d\t%d\t%s\n', run, flip, 'CatchEnd');
        end
        
        if catchcountdown > 0
            % catch flip
            if fcatchorient(kcatch) == 1
                angle_back = angle(:, angle(1,:) > 180);
                angle_front = angle(:, angle(1,:) <= 180);
            elseif fcatchorient(kcatch) == 2
                angle_back = angle(:, angle(1,:) < 180);
                angle_front = angle(:, angle(1,:) >= 180);
            end
            
            pix_back = projection(angle_back);
            pix_front = projection(angle_front);
            
            Screen('DrawDots', window, pix_back, ang2pix(vddot), dim, center);
            Screen('DrawDots', window, pix_front ,ang2pix(vddot), white, center);
            catchcountdown = catchcountdown - 1;
        else
            pix = projection(angle);
            Screen('DrawDots', window, pix ,ang2pix(vddot), white, center);
        end
        Screen('DrawDots', window, center, ang2pix(vdfix), white);
        Screen('Flip', window);
        angle = update(angle);
        CheckResp;
        if flag_return == 1
            return
        end
    end
    
    if ~debug
        Eyelink('Message','run_end');
    end
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
    end[keyIsDown, ~, keyCode] = KbCheck;

    function pixels=ang2pix(ang)
        pixpercm=mrect(4)/monitorh;
        pixels=tand(ang/2)*distance*2*pixpercm;
    end

    function session_end
        if ~debug
            Eyelink('Message','session_end');
            Eyelink('Stoprecording');
            Eyelink('CloseFile');
            Eyelink('ReceiveFile');
        end
        fclose(fid);
        ShowCursor;
        sca;
        flag_return = 1;
    end

    function CheckResp
        [keyIsDown, ~, keyCode] = KbCheck;
        knum = find(keyCode);
        if keyIsDown && numel(knum) == 1
            [bin, kkey] = ismember(knum, kvalid);
            if bin
                direction = kNames{kkey};
                fprintf(fid, '%d\t%d\t%s\n', run, flip, direction);
                if knum == kesc
                    session_end;
                end
            end
        end
    end

    function WaitSpace
        WaitSecs(1);
        while 1
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                knum = find(keyCode);
                if knum == kspace
                    break
                end
            end
        end
    end

end
