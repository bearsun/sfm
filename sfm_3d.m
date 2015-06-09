function sfm_3d
% a sfm demo to collect behaviour data for ambiguous structure-from-motion
% from Gijs Joost Brouwer and Raymond van Ee, 2007
% sphere: height/length: 8.2 vd, 500 dots, rotating around vertical axis
% each dot: .05 vd in diameter
% central fixation: .2 vd
% angular volecity of the sphere: 16 vd/s
% average speed of the dots: 0.75 vd/s

global GL

sid = input('identifier for this session?','s');

fid = fopen([sid '.txt'], 'w');
fprintf(fid, 'run\tflip\tdirection\n');

% Run / Trial Parameters
nRuns = 6;
secsperrun = 210; %3.5 min per run

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
% Initialise OpenGL
InitializeMatlabOpenGL;

% Open the main window with multi-sampling for anti-aliasing
[window, mrect] = PsychImaging('OpenWindow', screenid, 0);

% Start the OpenGL context (you have to do this before you issue OpenGL
% commands such as we are using here)
Screen('BeginOpenGL', window);

% For this demo we will assume our screen is 30cm in height. The units are
% essentially arbitary with OpenGL as it is all about ratios. But it is
% nice to define things in normal scale numbers
ar = mrect(3) / mrect(4);
screenHeight = 30;
screenWidth = screenHeight * ar;

% Enable lighting
glEnable(GL.LIGHTING);

% Define a local light source
glEnable(GL.LIGHT0);

% Enable proper occlusion handling via depth tests
glEnable(GL.DEPTH_TEST);

% Lets set up a projection matrix, the projection matrix defines how images
% in our 3D simulated scene are projected to the images on our 2D monitor
glMatrixMode(GL.PROJECTION);
glLoadIdentity;

% Calculate the field of view in the y direction assuming a distance to the
% objects of 100cm
dist = 100;
angle = 2 * atand(screenHeight / dist);

% Set up our perspective projection. This is defined by our field of view
% (here given by the variable "angle") and the aspect ratio of our frustum
% (our screen) and two clipping planes. These define the minimum and
% maximum distances allowable here 0.1cm and 200cm.
gluPerspective(angle, ar, -300, 300);

% Setup modelview matrix: This defines the position, orientation and
% looking direction of the virtual camera that will be look at our scene.
glMatrixMode(GL.MODELVIEW);
glLoadIdentity;

% Our point lightsource is at position (x,y,z) == (1,2,3)
glLightfv(GL.LIGHT0, GL.POSITION, [1 2 3 0]);

% Location of the camera is at the origin
cam = [0 0 0];

% Set our camera to be looking directly down the Z axis (depth) of our
% coordinate system
fix = [0 0 -100];

% Define "up"
up = [0 1 0];

% Here we set up the attributes of our camera using the variables we have
% defined in the last three lines of code
gluLookAt(cam(1), cam(2), cam(3), fix(1), fix(2), fix(3), up(1), up(2), up(3));

% Set background color to 'black' (the 'clear' color)
glClearColor(0, 0, 0, 0);

% Clear out the backbuffer
glClear;

% Change the light reflection properties of the material to blue. We could
% force a color to the cubes or do this.
glMaterialfv(GL.FRONT_AND_BACK,GL.AMBIENT, [0.0 0.0 1.0 1]);
glMaterialfv(GL.FRONT_AND_BACK,GL.DIFFUSE, [0.0 0.0 1.0 1]);

% End the OpenGL context now that we have finished setting things up
Screen('EndOpenGL', window);

[center(1), center(2)] = RectCenter(mrect);

DrawFormattedText(window, 'Please fixate at the center of the sceen and report your perception.\nLeft for rotation to the left,\n Right for rotation to the right,\nDown for both.\n', 'center', 'center', white);
Screen('Flip', window);

KbStrokeWait;

for run = 1:nRuns
    % calculate x and y for each dot
    angle = (rand(2, ndots).*2 -1) .* pi; % in 3d
    Updateangle = spdsphere /  FrameRate; % vd per frame
    
    [x,y,z] = sph2cart(angle(1,:),angle(2,:),ang2pix(vdsphere));
    xyz=[x;y;z];
    disp(xyz);

    for flip = 1:fperrun
        % Begin the OpenGL context now we want to issue OpenGL commands again
        Screen('BeginOpenGL', window);
        
        % To start with we clear everything
        glClear;
        Screen('EndOpenGL', window);
        % Draw the initial dots
        moglDrawDots3D(window, xyz, 20 , [255 255 255]);
       
        Screen('Flip', window);
        angle(1,:) = angle(1,:) + Updateangle;
        CheckResp;
    end
    
    DrawFormattedText(window, ['end of block ', num2str(run), ', presse to start the next.'], 'center', 'center', white);
    Screen('Flip', window);
    KbStrokeWait;
end
session_end;

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
            direction = [];
            direction = [direction,kNames{ismember(kvalid, knum)}];
            fprintf(fid, '%d\t%d\t%s\n', run, flip, direction);
            if knum == kesc
                session_end;
            end
        end


    end
end

