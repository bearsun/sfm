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
sid = input('identifier for this session?');

% Parameters
vddot = .1; % In vd
vdsphere = 8.2;
ndots = 500;
vdfix = .2;
spdsphere = 16; % in vd/s

screenid = max(Screen('Screens'));
FrameRate = Screen('NominalFrameRate', screenid);

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

% calculate x and y for each dot
angle = (rand(2, ndots).*2 -1) .* 180; % in 3d
Updateangle = spdsphere /  FrameRate; % vd per frame

angle_2d = NaN(size(angle));
while ~KbCheck

    angle_2d(2,:) = sind(angle(2,:)).* (vdsphere / 2);
    angle_2d(1,:) = sind(angle(1,:)).*cosd(angle(2,:)).* (vdsphere / 2);
    
    pix = ang2pix(angle_2d);

    Screen('DrawDots', window, pix,ang2pix(vddot), white, center);
    Screen('DrawDots', window, center, ang2pix(vdfix), white);

    Screen('Flip', window);

    angle(1,:) = angle(1,:) + Updateangle;

end

session_end;

    function pixels=ang2pix(ang)
        pixpercm=mrect(4)/monitorh;
        pixels=tand(ang/2)*distance*2*pixpercm;
    end

    function session_end
        ShowCursor;
        sca;
        return
    end
end