function sfm_demo
% a sfm demo to collect behaviour data for ambiguous structure-from-motion
% from Gijs Joost Brouwer and Raymond van Ee, 2007
% sphere: height/length: 8.2 vd, 500 dots, rotating around vertical axis
% each dot: 5.8 arcmin in diameter
% central fixation: 11.7 arcmin
% angular volecity of the sphere: 16 vd/s
% average speed of the dots: 0.75 vd/s

AssertOpenGL;
Priority(1);

sid = [];
sid = input('identifier for this session?','s');

% Run / Trial Parameters
nRuns = 10;
secsperrun = 240;

% key
kleft = KbName('Left');
kright = KbName('Right');
kesc = KbName('Escape');
kvalid = [kleft, kright, kesc];


% Sti Parameters
vddot = .1; % In vd
vdsphere = 8.2;
ndots = 500;
vdfix = .2;
spdsphere = 16; % in vd/s

screenid = max(Screen('Screens'));
FrameRate = Screen('NominalFrameRate', screenid);

fperrun = secsperrun * FrameRate;
resp = NaN(nRuns, fperrun);

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

% Set up our screen
[window, mrect] = Screen('OpenWindow', screenid, black);

[center(1), center(2)] = RectCenter(mrect);

KbStrokeWait;
for run = 1:nRuns
    % calculate x and y for each dot
    angle = (rand(2, ndots).*2 -1) .* 180; % in 3d
    Updateangle = spdsphere /  FrameRate; % vd per frame
    
    angle_2d = NaN(size(angle));
    for flip = 1:fperrun
        
        angle_2d(2,:) = sind(angle(2,:)).* (vdsphere / 2);
        angle_2d(1,:) = sind(angle(1,:)).*cosd(angle(2,:)).* (vdsphere / 2);
        
        pix = ang2pix(angle_2d);
        
        Screen('DrawDots', window, pix,ang2pix(vddot), white, center);
        Screen('DrawDots', window, center, ang2pix(vdfix), white);
        
        Screen('Flip', window);
        angle(1,:) = angle(1,:) + Updateangle;
        resp(run, flip) = CheckResp;
    end
    
    DrawFormattedText(window, ['end of block ', num2str(run), ', presse to start the next.'], 'center', 'center', black);
    Screen('Flip', window);
    KbStrokeWait;
end
session_end;

    function pixels=ang2pix(ang)
        pixpercm=mrect(4)/monitorh;
        pixels=tand(ang/2)*distance*2*pixpercm;
    end

    function session_end
        save([sid '.mat']);
        ShowCursor;
        sca;
        return
    end

    function resp = CheckResp
        [keyIsDown, ~, keyCode] = KbCheck;
        knum = find(keyCode);
        if keyIsDown && any(ismember(knum, kvalid)) && numel(knum) == 1
            resp = knum;
            if resp == kesc
                session_end;
            end
        else
            resp = NaN;
        end


    end
end