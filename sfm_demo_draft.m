function sfm_demo_draft
% a sfm demo to collect behaviour data for ambiguous structure-from-motion
% from Gijs Joost Brouwer and Raymond van Ee, 2007
% sphere: height/length: 8.2 vd, 500 dots, rotating around vertical axis
% each dot: 5.8 arcmin in diameter
% central fixation: 11.7 arcmin
% angular volecity of the sphere: 16 vd/s
% average speed of the dots: 0.75 vd/s

AssertOpenGL;
Priority(1);

sid = input('identifier for this session?','s');
s = input('shape?','s');

fid = fopen([sid '.txt'], 'w');
fprintf(fid, 'run\tflip\tdirection\n');

% Run / Trial Parameters
nRuns = 6;
secsperrun = 210;

% key
kNames = {'Left', 'Right', 'Escape'};
kvalid = KbName(kNames);
kesc = kvalid(3);

% Sti Parameters
vddot = .1; % In vd
vdsphere = 8.2;
ndots = 500;
vdfix = .2;
spdsphere = 16/180*pi; % in vd/s

screenid = max(Screen('Screens'));
FrameRate = Screen('NominalFrameRate', screenid);

fperrun = secsperrun * FrameRate;

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
    angle = (rand(2, ndots).*2 -1) .* pi; % in 3d
    Updateangle = spdsphere /  FrameRate; % vd per frame
    
    angle_2d = NaN(size(angle));
    for flip = 1:fperrun
        
        angle_2d = shape(s, angle_2d, angle, vdsphere/180*pi);
        
        pix = ang2pix2(angle_2d);
        
        Screen('DrawDots', window, pix,ang2pix(vddot), white, center);
        Screen('DrawDots', window, center, ang2pix(vdfix), white);
        
        Screen('Flip', window);
        angle(1,:) = angle(1,:) + Updateangle;
        CheckResp;
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

    function pixels=ang2pix2(ang)
        pixpercm=mrect(4)/monitorh;
        pixels=tan(ang/2)*distance*2*pixpercm;
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

    function angle_2d = shape(s, angle_2d, angle, vdsphere)
        
        switch s
            case 'sphere'
                [~, angle_2d(1,:), angle_2d(2,:)] = sph2cart(angle(1,:), angle(2,:), vdsphere/2);
%                 
%                 angle_2d(2,:) = sind(angle(2,:)).* (vdsphere / 2);
%                 angle_2d(1,:) = sind(angle(1,:)).*cosd(angle(2,:)).* (vdsphere / 2);
            case 'column'
%                 angle_2d(2,:) = sind(angle(2,:)).* (vdsphere / 2);
%                 angle_2d(1,:) = sind(angle(1,:)).*cosd(angle(2,:)).* (vdsphere / 2);
                [~, angle_2d(1,:), angle_2d(2,:)] = pol2cart(angle(1,:), vdsphere/2, tan(angle(2,:)).*vdsphere/2);
            case 'try'
                [~, angle_2d(1,:), angle_2d(2,:)] = sph2cart(angle(1,:), angle(2,:), (angle(1,:)./pi.*vdsphere/2));
        end
    end
end