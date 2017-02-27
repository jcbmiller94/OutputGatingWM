% WM Simon task (Jacob Miller - github.com/jcbmiller94)
%   cue: arrows (4 directions)
%   movement metric: velocity-based (20 ms averaging) 
%   probe: recall

function WM_Simon_phase2_word_keypress_practice_SLOW

%%% timestamp movement onset and add to results printout 

%%
rng('default'); %sometimes, if you've recently initiated the legacy random number generator, it wont let you use rng until you reset it to default, or something
rng('shuffle');

KbName('UnifyKeyNames'); 
esc = KbName('ESCAPE');
    
% % message pops up in the command window to ask for subject number   
% subject = input('Enter SUBJECT number ', 's');
% 
% % name of data output file 
% datafilename = strcat('MotorData/WM_Simon_phase2_word_keypress_', subject, '.txt'); 
% 
% % if a file with that same info already exists in the data folder, give a
% %  new subject #, or overwrite the existing file
% if exist(datafilename)==2
%     disp ('A file with this name already exists')
%     overwrite = input('overwrite?, y/n \n', 's');
%     if strcmpi(overwrite, 'n')
%         %disp('enter new subject number');
%         newsub = input('New SUBJECT number? ', 's');
%         datafilename = strcat('MotorData/WM_Simon_phase2_word_keypress_', newsub, '.txt');
%     end
% end
% 
% % make a space-delimited text output file where each trial is a row
% fid = fopen(datafilename, 'w');
% fprintf(fid, 'subject block trial CurrentCondition TrialType CurrentSampleIndex CurrentSample cueColor correctResp Resp ACC msecRT move_init_msecRT move_init_bound_msecRT enter_box_msecRT velocity_drop_msecRT correctProbeResp probeResp probeACC probemsecRT probe_move_init_msecRT probe_move_init_bound_msecRT probe_enter_box_msecRT probe_velocity_drop_msecRT\n');
% 
% % make a cell array to hold data for tracking the cursor path 
% %  in this cell array, each row is a block and each column is a trial
% %  (each element being the path for that trial in that block)

cursor_path = {};
cursor_path_probe = {};
cursor_velocity = {}; 
cursor_velocity_probe = {}; 

%% Some PTB and Screen set-up  
AssertOpenGL;    
HideCursor;
ListenChar(2);

% make dummy calls to initialize some functions
KbCheck; 
WaitSecs(0.1);
GetSecs;

% I use this later cause I call on some custom subfunctions that 
%  need to know the keyboard number in order to receive key input
KeyBoardNum = GetKeyboardIndices; 


    Screen('Preference', 'SkipSyncTests', 2); %1 skips the tests, 0 conducts them
    Screen('Preference', 'VisualDebugLevel', 3);% to suppress the PTB survey screen
    Screen('Preference', 'VBLTimestampingMode', 1);
    
    % you can either use the highest screen index in a multiple monitor
    %  set-up, or specify which of several screens you want to use. 0 will
    %  take up all available screen real estate
    screenNumber=max(Screen('Screens')); 
    %screenNumber=0;
    
    % give values for screen elements
    screenColor = [128 128 128];
    fixColor = [255 255 255];
    sampleColor = [0 0 0];
    
    [win, wRect]=Screen('OpenWindow',screenNumber, screenColor);
    
    priorityLevel=MaxPriority(win);
    Priority(priorityLevel);    
    
    Screen('TextSize', win, 36);
    Screen('TextFont', win, 'Arial');
    Screen('TextColor', win, fixColor);
    
    % we probably don't actually need this for this task, but I like to
    %  include it in case we want to incorporate any interesting color or
    %  graphical things
    Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
   
%% Specify timing and condition values

    ITI = 1; % orig = 1
    SampleShow = 2;
    WMDelay = 2; %orig = 1.5
    responseDeadline = 3; %orig = 4
    probeDelay = 2;
    WMProbe = 2; %orig = 2
    
    feedback = 1;

    
    BlockNum = 1; %10
    TrialNum = 6; %30
    
    % change detection response keys
    leftProbeResp = 'L';
    rightProbeResp = 'R';
    upProbeResp = 'U';
    downProbeResp = 'D'; 
    
    % motor response keys
    leftResp = 'L';
    rightResp = 'R';
    upResp = 'U';
    downResp = 'D'; 
    
    leftWord = sprintf('left');
    rightWord = sprintf('right');
    upWord = sprintf('up');
    downWord = sprintf('down'); 
    
    SampleWords = [leftWord rightWord]; % possible locations of two-dot array
    
    % these RGB values were selected to be maximally different using the
    %  color tool at I Want Hue
    % four color version, with 2 colors for left and 2 for right responses
    leftRGB = [122 164 86]; % left, green 
    rightRGB = [198 89 153]; % right, pink 
    upRGB = [201 109 68];    % up, orange
    downRGB = [119 122 205]; % down, blue 
     
    leftColor = 'green'; 
    rightColor = 'pink'; 
    upColor = 'orange';
    downColor = 'blue'; 
    
    %make a vector of codes for the trial conditions    
    TrialsPer = TrialNum/2; %Divide # of trials by # of conditions, to get equal trials of each type (compatible, incompatible) 
    TrialsPer = ceil(TrialsPer);
    
    TrialsPerCongruency = TrialNum/4; % divide by number of conditions within a congruency (4: L, R, U, D) 
    TrialsPerCongruency = ceil(TrialsPerCongruency);
    
    %TrialsPerIncongruent = TrialNum/3; % number of possible colors - 1 (for randomizing for incongruent trials) 
    %TrialsPerIncongruent = ceil(TrialsPerIncongruent); 
    
    %include 3s in this vector if you want to have a neutral condition
    Condition = [ones(1, TrialsPer) 2*ones(1, TrialsPer)] % 1 = compatible, 2 = incompatible 
    %ProbeMatch = [ones(1, TrialsPer) 2*ones(1, TrialsPer)];
    SampleIndex = [ones(1, TrialsPerCongruency) 2*ones(1, TrialsPerCongruency) 3*ones(1, TrialsPerCongruency) 4*ones(1, TrialsPerCongruency)]; % 1 = left, 2 = right, 3 = up, 4 = down 
    %ColorIndex = [ones(1, TrialsPerIncongruent) 2*ones(1, TrialsPerIncongruent) 3*ones(1, TrialsPerIncongruent)]; 
    ColorIndex = [ones(1, TrialsPerCongruency) 2*ones(1, TrialsPerCongruency) 3*ones(1, TrialsPerCongruency) 4*ones(1, TrialsPerCongruency)];
    
    %determine center of screen from which to determine size and location
    %of stimuli
    h = wRect(4);
    w = wRect(3);
    centerX = wRect(3)/2;
    centerY = wRect(4)/2; 

    
    % get width and height of screen in pixels
    [screenXpixels, screenYpixels] = Screen('WindowSize', win);
    % get width and height of screen in millimeters 
    [width_mm, height_mm]=Screen('DisplaySize', screenNumber);
    
    pixels_per_mm = screenXpixels/width_mm; 
    mm_per_pixel = width_mm/screenXpixels; 
    
    Xcenter = screenXpixels/2;
    Ycenter = screenYpixels/2;    
    
    % change this to move the location of the spatial stimuli
    Xoffset = screenYpixels/3; %screenXpixels/5;
    Yoffset = screenYpixels/3; %screenXpixels/5; % should be the same as Xoffset for 4-cue version
 
    % Make a destination rectangle for stimuli
    stimSize = 150; %orig = 100
    xcorner = centerX+stimSize;
    ycorner = centerY+stimSize;
    
    % bounding circle distance (pixels), once the cursor moves this
    %  distance form the center, movement initation time is recorded 
    boundDistance = 30; % in pixels, 1/2 the stim size 
    
    %this is the general rect size we'll use for all stims
    stimRect = [centerX centerY xcorner ycorner];
    
    %this centers it on  particular location
    centerRect = CenterRectOnPointd(stimRect, Xcenter, Ycenter);
    
    leftX = Xcenter - Xoffset;
    rightX = Xcenter + Xoffset;
    upY = Ycenter - Yoffset;
    downY = Ycenter + Yoffset; 
 
    leftRect = CenterRectOnPointd(stimRect, leftX, Ycenter);
    rightRect = CenterRectOnPointd(stimRect, rightX, Ycenter);
    upRect = CenterRectOnPointd(stimRect, Xcenter, upY);
    downRect = CenterRectOnPointd(stimRect, Xcenter, downY);
    
    %specify the borders of the area in which we'll take mouse clicks for
    %the delay-spanning motor task
    clickBoxSize = stimSize/2;
    
    leftX1 = leftX - clickBoxSize;
    leftX2 = leftX + clickBoxSize;
    leftY1 = Ycenter - clickBoxSize;
    leftY2 = Ycenter + clickBoxSize;
    
    rightX1 = rightX - clickBoxSize;
    rightX2 = rightX + clickBoxSize;
    rightY1 = Ycenter - clickBoxSize;
    rightY2 = Ycenter + clickBoxSize;
    
    upX1 = Xcenter - clickBoxSize;
    upX2 = Xcenter + clickBoxSize;
    upY1 = upY - clickBoxSize;
    upY2 = upY + clickBoxSize;

    downX1 = Xcenter - clickBoxSize;
    downX2 = Xcenter + clickBoxSize;
    downY1 = downY - clickBoxSize;
    downY2 = downY + clickBoxSize;
    
    % width of the outline box for accepting clicks
    frameWidth = 5;
    
    % make a little rectangle to serve as the fixation point    
    fixSize = 15;
    fixX = centerX + fixSize;
    fixY = centerY + fixSize;
    fixRect = [centerX centerY fixX fixY];
    fixCenter = CenterRectOnPointd(fixRect, Xcenter, Ycenter);
    
    % read images for use as WM stimuli 
    left_image = imread('left_arrow_copy.png'); 
    right_image = imread('right_arrow_copy.png'); 
    up_image = imread('up_arrow_copy.png'); 
    down_image = imread('down_arrow_copy.png'); 
    
    % resize images to be slightly smaller 
    left_image = imresize(left_image, 0.6); 
    right_image = imresize(right_image, 0.6);
    up_image = imresize(up_image, 0.6);
    down_image = imresize(down_image, 0.6);
    
    % Get the size of the images 
    [s1, s2, s3] = size(left_image);

    % Here we check if the image is too big to fit on the screen and abort if
    % it is. See ImageRescaleDemo to see how to rescale an image.
    if s1 > screenYpixels || s2 > screenYpixels
        disp('ERROR! Image is too big to fit on the screen');
        sca;
        return;
    end

    % Make the image into a texture
    left_texture = Screen('MakeTexture', win, left_image);
    right_texture = Screen('MakeTexture', win, right_image);
    up_texture = Screen('MakeTexture', win, up_image);
    down_texture = Screen('MakeTexture', win, down_image);
    
%% Start task block loop
        
    %show instruction screen
    
    instructions=sprintf(['This is a practice of the experiment you will be doing\n\n\nThe word up, down, left, or right will appear\n\n\n' ... 
        'Remember the word/direction....\n\n\n(Press space to continue)']); 
    DrawFormattedText(win, instructions, 'center', 'center', 0);
    Screen('Flip', win);    
    if IsOSX
        getKey('space', KeyBoardNum); %OSX requires a device number whereas windows requires none
    else
        getKey('space');
    end
    
    instructions=sprintf(['Four boxes will then appear, with your cursor on the middle of the screen\n\n\n Based on the color of the middle box, click in one of the other boxes\n\n' ... 
    'green: left \n pink: right \n orange: up \n blue: down\n\n\n(Press space to continue)']); 
    DrawFormattedText(win, instructions, 'center', 'center', 0);
    Screen('Flip', win);    
    if IsOSX
        getKey('space', KeyBoardNum); %OSX requires a device number whereas windows requires none
    else
        getKey('space');
    end  
    

    instructions=sprintf(['On the next screen, you will be asked to indicate the word/direction \n\n\n Press the arrow key on the keyboard to indicate the word/direction\n\n\n(Press space to continue)']);
    DrawFormattedText(win, instructions, 'center', 'center', 0);
    Screen('Flip', win);    
    if IsOSX
        getKey('space', KeyBoardNum); %OSX requires a device number whereas windows requires none
    else
        getKey('space');
    end  
    
    
    welcome=sprintf('Clink in box indicated by color \n green: left \n pink: right \n orange: up \n blue: down \n\nThen, press arrowkey indicated by remembered word \n\n\nPress space to begin the experiment \n \n \n');
    DrawFormattedText(win, welcome, 'center', 'center', 0);
    Screen('Flip', win);
    
    % Wait for a key press using the custom getkey function (appended to
    % end of script)
    if IsOSX
        getKey('space', KeyBoardNum); %OSX requires a device number whereas windows requires none
    else
        getKey('space');
    end
    
    
    for block = 1:BlockNum
        
        % build second row of Sample Index to be random numbers of
        %  complementary set to SampleIndex first row (to randomize for
        %  incompatible trials which of other 3 boxes is presented as cue) 
        for i = 1:length(SampleIndex)
            if SampleIndex(1,i) == 1
            SampleIndex(2,i) = datasample([2,3,4],1);
            elseif SampleIndex(1,i) == 2
            SampleIndex(2,i) = datasample([1,3,4],1);
            elseif SampleIndex(1,i) == 3
            SampleIndex(2,i) = datasample([1,2,4],1);
            elseif SampleIndex(1,i) == 4
            SampleIndex(2,i) = datasample([1,2,3],1);
            end
        end
    
    % shuffle the order of the condition vectors at the start of each block
    % for a random selection    
    Condition = Shuffle(Condition);    
    %ProbeMatch = Shuffle(ProbeMatch);
    SampleIndex = Shuffle(SampleIndex);
    ColorIndex = Shuffle(ColorIndex); 
    
    disp(SampleIndex); 
    

    
        for trial = 1:TrialNum
                       
            % show fixation
            Screen('FillRect', win, fixColor, fixCenter);
            Screen('Flip', win);
            WaitSecs(ITI);   
            
            % choose the congruency condition for this trial
            CurrentCondition = Condition(trial);
            
            % define what sample word will be shown on this trial
            CurrentSampleIndex = SampleIndex(1,trial); % 1:L, 2:R, 3:U ,4:D
            CurrentIncompatibleSampleIndex = SampleIndex(2, trial); 
            
            % define what color cue will be shown on this trial
            CurrentColorIndex = ColorIndex(trial); 
            
            % CurrentSample = SampleWords(CurrentSampleIndex); 
            % CurrentSample = sprintf(CurrentSample);

            
            switch CurrentCondition
                case 1 % compatible
                    TrialType = 'compatible';
                    
                    if CurrentSampleIndex == 1 % L cue  
                       CurrentSample = leftWord;
                       % assign motor direction 
                       CurrentMotor = leftRGB;
                       cueColor = leftColor;                   
                       % assign probe direction 
                       correctResp = leftResp;  
                       correctProbeResp = leftResp; % response to probe (arrow direction)
                       % assign image to present
                       texture = left_texture; 
                        
                    elseif CurrentSampleIndex == 2 % R cue
                       CurrentSample = rightWord;
                       % assign motor direction
                       CurrentMotor = rightRGB;
                       cueColor = rightColor;
                       % assign probe direction 
                       correctResp = rightResp;
                       correctProbeResp = rightResp;
                       % assign image to present 
                       texture = right_texture;    
                     
                    elseif CurrentSampleIndex == 3 % U cue
                       CurrentSample = upWord;
                       % assign motor direction
                       CurrentMotor = upRGB;
                       cueColor = upColor;
                       % assign probe direction 
                       correctResp = upResp;
                       correctProbeResp = upResp;
                       % assign image to present 
                       texture = up_texture;
                       
                    elseif CurrentSampleIndex == 4 % D cue
                       CurrentSample = downWord;
                       % assign motor direction
                       CurrentMotor = downRGB;
                       cueColor = downColor;
                       % assign probe direction 
                       correctResp = downResp;
                       correctProbeResp = downResp;
                       % assign image to present 
                       texture = down_texture;

                    end 
                    
                case 2 %incompatible
                    TrialType = 'incompatible';
                    
                    if CurrentSampleIndex == 1 % L cue
                        CurrentSample = leftWord; 
                        correctProbeResp = leftResp; % response to probe (arrow direction)
                        texture = left_texture;
                    elseif CurrentSampleIndex == 2 % R cue
                        CurrentSample = rightWord; 
                        correctProbeResp = rightResp;
                        texture = right_texture; 
                    elseif CurrentSampleIndex == 3 % U cue 
                        CurrentSample = upWord;
                        correctProbeResp = upResp;
                        texture = up_texture; 
                    elseif CurrentSampleIndex == 4 % D cue   
                        CurrentSample = downWord;
                        correctProbeResp = downResp;
                        texture = down_texture; 

                    end
                    
                    switch CurrentIncompatibleSampleIndex 
                        case 1 
                           % assign motor direction 
                           CurrentMotor = leftRGB;
                           cueColor = leftColor;                   
                           % assign probe direction 
                           correctResp = leftResp;                            
                           % assign image to present
                                                                
                        case 2
                           % assign motor direction 
                           CurrentMotor = rightRGB;
                           cueColor = rightColor;                   
                           % assign probe direction 
                           correctResp = rightResp;                            
                           % assign image to present
                        case 3   
                           % assign motor direction 
                           CurrentMotor = upRGB;
                           cueColor = upColor;                   
                           % assign probe direction 
                           correctResp = upResp;                            
                           % assign image to present
                        case 4   
                           % assign motor direction 
                           CurrentMotor = downRGB;
                           cueColor = downColor;                   
                           % assign probe direction 
                           correctResp = downResp;                            
                           % assign image to present
                    end
            end

            
        %show WM sample 
        
            Screen('TextSize', win, 48);
            DrawFormattedText(win, CurrentSample, 'center', 'center', 0);
            % for arrows: Screen('DrawTexture', win, texture);
            Screen('Flip', win);
            WaitSecs(SampleShow); 
            Screen('TextSize', win, 36);
            
            DrawFormattedText(win, '+', 'center', 'center', 0);
            Screen('Flip', win);
            WaitSecs(WMDelay);            

        %show motor cue during WM delay
        
            Screen('FillRect', win, CurrentMotor, centerRect);    
            Screen('FrameRect', win, sampleColor, leftRect, frameWidth);
            Screen('FrameRect', win, sampleColor, rightRect, frameWidth);
            Screen('FrameRect', win, sampleColor, upRect, frameWidth);
            Screen('FrameRect', win, sampleColor, downRect, frameWidth);

            %Screen('Flip', win);
            %WaitSecs(MotorShow); 
                        
            
                    ShowCursor('Arrow');

                    %puts mouse at center--but can be weird on multi-display
                    %setups
                    SetMouse(Xcenter, Ycenter);
                    [~, cueStart] = Screen('Flip', win);

                    enterResp=false;

                    resp = 9999; %reset this variable before each response phase to avoid wonky behavior if they don't respond at all

                    trial_path = [];
                    cursor_dist = [];
                    cursor_v = [];
                    cursor_moved = false; 
                    cursor_moved_bound = false; 
                    cursor_in_box = false; 
                    cursor_velocity_drop = false; 
                    
                    % SAMPLING RATE 
                    % code for setting a constant sampling rate of the while loop for getting mouse position 
                    tic;
                    begintime = GetSecs;
                    nextsampletime = begintime;
                    k = 0;
                    desiredSampleRate = 500; % in Hz  % Set to 500
                   %veloc_thresh = 15; 
                    
                    
                    % LOOP FOR COLLECTING MOUSE RESPONSE DATA FOR MOTOR
                    % TASK 
                    % this loop will listen for clicks inside the boxes
                    %  associated with the color cue
                    while enterResp==false                        
                        
                        % Exits experiment when ESC key is pressed. 
                        [keyIsDown, secs, keyCode] = KbCheck;
                        if keyIsDown
                            if keyCode(esc)
                    %             Screen('CloseAll')
                                break
                            end
                        end
                        
                        k = k+1;
                                                                      
                        [responseX, responseY, mouseClick] = GetMouse;
                        
                        %if any(buttons)                        
                        if mouseClick(1) == 1
                        
                            % if a click falls within the response box range, response is entered 
                            if responseX > leftX1 && responseX < leftX2 && responseY > leftY1 && responseY < leftY2
                                enterResp = true;
                                resp = leftResp;                                   
                                
                            elseif responseX > rightX1 && responseX < rightX2 && responseY > rightY1 && responseY < rightY2
                                enterResp = true;
                                resp = rightResp;
                            
                            elseif responseX > upX1 && responseX < upX2 && responseY > upY1 && responseY < upY2                                  
                                    enterResp = true;
                                    resp = upResp;                              
                                
                            elseif responseX > downX1 && responseX < downX2 && responseY > downY1 && responseY < downY2                               
                                    enterResp = true;
                                    resp = downResp;             
                                
                            % if a click surrounds the response box, but doesn't fall inside it, do nothing     
                            else enterResp=false;   
                            end                                                 
                        end
                                                
                        
                        % MOUSE POSITION SECTION 
                        % recording the coordinates of the cursor until the loop is broken with click inside a box 
                        [x,y,buttons] = GetMouse(win);
                        current_pos = [x, y, buttons];
                        trial_path = [trial_path; current_pos];
                    
                        % calculating distance cursor has moved 
                        cursor_dist(k) = sqrt((x-Xcenter)^2 + (y-Ycenter)^2);
                        if k >=6
                            % v is calculated by looking at distance traveled over 5 samples
                            %  (which should equal 10 ms if sampling at 500 Hz); 
                            %  (given USB sampling rate limit of 125 Hz, this
                            %   must be greater than 8 ms); 
                            % converting into mm/sec requires dividing by .01 (10 ms in s) 
                            %  and multiplying by (mm/pixel) conversion factor
                            cursor_v(k) = (((cursor_dist(k)-cursor_dist(k-5))/(.01))*mm_per_pixel);
                        else
                            cursor_v(k) = 0;
                        end          

                        % RECORDING INITIAL MOVEMENT TIMES
                        
                        %if cursor moves for the FIRST time from the
                        % center position, get the time of that movement 
                        if cursor_moved == false && isequal(current_pos(1:2),trial_path(1,1:2)) == 0
                            move_init = GetSecs;
                            cursor_moved = true;                           
                        elseif cursor_moved == true
                        else move_init = 0;
                        end 
                        
                        % if cursor moves farther away than the bounding distance
                        %  from the center position, get the time of that movement 
                        if cursor_moved_bound == false && cursor_dist(k) > boundDistance
                            move_init_bound = GetSecs;
                            cursor_moved_bound = true;                           
                        elseif cursor_moved_bound == true
                        else move_init_bound = 0;
                        end 
                        
                        % RECORDING TIME ENTERING THE BOX 
                        %if cursor moves into correct box for the FIRST time
                        % center position, get the time of that movement 
                        %enter_box = 0;
                        if cursor_in_box == false                          
                            if correctResp == leftResp && current_pos(1) > leftX1 && current_pos(1) < leftX2 && current_pos(2) > leftY1 && current_pos(2) < leftY2
                                enter_box = GetSecs; 
                                cursor_in_box = true;  
                            elseif correctResp == rightResp && current_pos(1) > rightX1 && current_pos(1) < rightX2 && current_pos(2) > rightY1 && current_pos(2) < rightY2
                                enter_box = GetSecs; 
                                cursor_in_box = true;  
                            elseif correctResp == upResp && current_pos(1) > upX1 && current_pos(1) < upX2 && current_pos(2) > upY1 && current_pos(2) < upY2    
                                enter_box = GetSecs; 
                                cursor_in_box = true;
                            elseif correctResp == downResp && current_pos(1) > downX1 && current_pos(1) < downX2 && current_pos(2) > downY1 && current_pos(2) < downY2    
                                enter_box = GetSecs; 
                                cursor_in_box = true;
                            else enter_box = 0; 
                            end 
                        elseif cursor_in_box == true
                        %else enter_box = 0; 
                        end
                         
                        
                        % check if cursor is in BOX and velocity is below
                        %  threshold ==> record that time 
                        if cursor_velocity_drop == false 
                            if current_pos(1) > leftX1 && current_pos(1) < leftX2 && current_pos(2) > leftY1 && current_pos(2) < leftY2
                                    % here we want to set a threshold value of 30 mm/s over x (= 10) number of
                                    % consecutive samples (see Tseng et al. 2007)
                                    if k > 10 && all(cursor_v(k-10:k)<30) % 20 ms must have passed 
                                        velocity_drop = GetSecs;
                                        cursor_velocity_drop = true; 
                                    end
                            elseif current_pos(1) > rightX1 && current_pos(1) < rightX2 && current_pos(2) > rightY1 && current_pos(2) < rightY2
                                    if k > 10 && all(cursor_v(k-10:k)<30) %15 samples = 30ms
                                        velocity_drop = GetSecs; 
                                        cursor_velocity_drop = true; 
                                    end
                            elseif current_pos(1) > upX1 && current_pos(1) < upX2 && current_pos(2) > upY1 && current_pos(2) < upY2    
                                    if k > 10 && all(cursor_v(k-10:k)<30)
                                        velocity_drop = GetSecs;
                                        cursor_velocity_drop = true; 
                                    end
                            elseif current_pos(1) > downX1 && current_pos(1) < downX2 && current_pos(2) > downY1 && current_pos(2) < downY2
                                    if k > 10 && all(cursor_v(k-10:k)<30)
                                        velocity_drop = GetSecs; 
                                        cursor_velocity_drop = true; 
                                    end
                            else velocity_drop = 0; 
                            end
                        elseif cursor_velocity_drop == true 
                        end
                        
                                                                       
                        % SAMPLING RATE     
                        t(k) = GetSecs - begintime;
                        
                        sampletime(k) = GetSecs;
                        nextsampletime = nextsampletime + 1/desiredSampleRate;
                        while GetSecs < nextsampletime
                        end
                        
                        % BREAK LOOP AFTER RESPONSE DEADLINE HAS PASSED 
                        % break the response loop after a designated
                        % deadline
                        if GetSecs - cueStart > responseDeadline 
                            enterResp = true; 
                        end
                        
                    end
                    
                    % GET DATA FOR ACTUAL WHILE LOOP TIMING 
                    % timing for sampling rate 
                    endtime = GetSecs; 
                    elapsedTime = endtime - begintime; 
                    numberOfSamples = k; 
                    actualSampleRate = 1/(elapsedTime / numberOfSamples); 
                    %disp(actualSampleRate); 
                    %disp(sprintf('Actual sample rate: %d', actualSampleRate)); 
                    
                    % save the trial path and velocity data to the cell array of paths for
                    % each trial 
                    cursor_path{block, trial} = trial_path;
                    cursor_velocity{block, trial} = cursor_v; 
                    
                    %calculate RT, time from the start of the cue to the
                    %response click
                    rt = GetSecs - cueStart;
                    msecRT=round(1000*rt);
                    
                    if msecRT > (responseDeadline*1000)-1
                        msecRT = 'Time-out';
                    else
                        msecRT = num2str(msecRT);
                    end
                    
                    % calculate movement initializing RT, time from cue to
                    % the first movement of the cursor
                    init_rt = move_init - cueStart; 
                    if move_init == 0
                        init_rt = 0;
                    end                 
                    move_init_msecRT = round(1000*init_rt); 
                    if move_init_msecRT == 0
                        move_init_msecRT = 'No-move';
                    else
                        move_init_msecRT = num2str(move_init_msecRT);
                    end
                    
                    % calculate movement initializing RT (bounding distance), time from cue to
                    % the first movement of the cursor
                    init_rt_bound = move_init_bound - cueStart; 
                    if move_init_bound == 0
                        init_rt_bound = 0;
                    end                 
                    move_init_bound_msecRT = round(1000*init_rt_bound); 
                    if move_init_bound_msecRT == 0
                        move_init_bound_msecRT = 'No-move';
                    else
                        move_init_bound_msecRT = num2str(move_init_bound_msecRT);
                    end
                        
                    %calculate movement into box RT, time from cue to
                    % the first movement into the correct box 
                    box_rt = enter_box - cueStart; 
                    if enter_box == 0
                        box_rt = 0;
                    end                 
                    enter_box_msecRT = round(1000*box_rt); 
                    if enter_box_msecRT == 0
                        enter_box_msecRT = 'No-move';
                    else
                        enter_box_msecRT = num2str(enter_box_msecRT);
                    end
                    
                    %calculate when cursor is in box and velocity has dropped  
                    velocity_rt = velocity_drop - cueStart; 
                    if velocity_drop == 0
                        velocity_rt = 0;
                    end                 
                    velocity_drop_msecRT = round(1000*velocity_rt); 
                    if velocity_drop_msecRT == 0
                        velocity_drop_msecRT = 'No-drop';
                    else
                        velocity_drop_msecRT = num2str(velocity_drop_msecRT);
                    end
                    
                %calculate accuracy
                Accuracy = strcmp(resp,correctResp); 

%                 if Accuracy == 1 
%                     ACC = 1;
%                 else ACC = 0;
%                 end  
                
                 if Accuracy == 1 
                    ACC = 1;
                    DrawFormattedText(win, 'Correct!', 'center', 'center', 0);
                    Screen('Flip', win); 
                    WaitSecs(feedback);
                else ACC = 0;
                    DrawFormattedText(win, 'Incorrect', 'center', 'center', 0);
                    Screen('Flip', win); 
                    WaitSecs(feedback);
                end   
                       
            
            HideCursor;
                
            DrawFormattedText(win, '+', 'center', 'center', 0);
            Screen('Flip', win);
            WaitSecs(probeDelay); 
            
%                 % determine whether L or R response is the correct response
%                 if CurrentSampleIndex == 1
%                     correctProbeResp = leftProbeResp; 
%                 elseif CurrentSampleIndex == 2
%                     correctProbeResp = rightProbeResp;  
%                 end
                
            
            %[minSmoothPointSize, maxSmoothPointSize, minAliasedPointSize, maxAliasedPointSize] = Screen('DrawDots', win, xy, 15, [0 0 0], center, 1);
            %DrawFormattedText(win, ProbeSide, 'center', 'center', 0);
            DrawFormattedText(win, 'Word?', 'center', 'center', 0);
%             Screen('FrameRect', win, sampleColor, leftRect, frameWidth);
%             Screen('FrameRect', win, sampleColor, rightRect, frameWidth);
%             Screen('FrameRect', win, sampleColor, upRect, frameWidth);
%             Screen('FrameRect', win, sampleColor, downRect, frameWidth);
            Screen('Flip', win);
            %WaitSecs(WMProbe);            
            probeTime = GetSecs;
            
        %collect probe response data - MOUSE MOVEMENT AND CLICKING VERSION 
                
%             ShowCursor('Arrow');
% 
%                     %puts mouse at center--but can be weird on multi-display
%                     %setups
%                     SetMouse(Xcenter, Ycenter);
%                     [~, probeTime] = Screen('Flip', win);
% 
%                     enterResp=false;
% 
%                     %resp = 9999; %reset this variable before each response phase to avoid wonky behavior if they don't respond at all
% 
%                     trial_path = [];
%                     cursor_dist = [];
%                     cursor_v = [];
%                     cursor_moved = false; 
%                     cursor_moved_bound = false; 
%                     cursor_in_box = false; 
%                     cursor_velocity_drop = false; 
%                     
%                     % SAMPLING RATE 
%                     % code for setting a constant sampling rate of the while loop for getting mouse position 
%                     tic;
%                     begintime = GetSecs;
%                     nextsampletime = begintime;
%                     k = 0;
%                     %desiredSampleRate = 500; 
%                     
%                     
%                     % LOOP FOR COLLECTING MOUSE RESPONSE DATA FOR MOTOR
%                     % TASK 
%                     % this loop will listen for clicks inside the boxes
%                     %  associated with the color cue
%                     while enterResp==false                           
%                         
%                         % Exits experiment when ESC key is pressed. 
%                         [keyIsDown, secs, keyCode] = KbCheck;
%                         if keyIsDown
%                             if keyCode(esc)
%                     %             Screen('CloseAll')
%                                 break
%                             end
%                         end
%                         
%                         k = k+1;
%                         
%                         [responseX, responseY, mouseClick] = GetMouse;
%                         
%                         %if any(buttons)                        
%                         if mouseClick(1) == 1
%                         
%                             % if a click falls within the response box range, response is entered 
%                             if responseX > leftX1 && responseX < leftX2 && responseY > leftY1 && responseY < leftY2
%                                 enterResp = true;
%                                  probeResp = leftResp;                                   
%                                 
%                             elseif responseX > rightX1 && responseX < rightX2 && responseY > rightY1 && responseY < rightY2
%                                 enterResp = true;
%                                  probeResp = rightResp;
%                             
%                             elseif responseX > upX1 && responseX < upX2 && responseY > upY1 && responseY < upY2                                  
%                                     enterResp = true;
%                                      probeResp = upResp;                              
%                                 
%                             elseif responseX > downX1 && responseX < downX2 && responseY > downY1 && responseY < downY2                               
%                                     enterResp = true;
%                                      probeResp = downResp;             
%                                 
%                             % if a click surrounds the response box, but doesn't fall inside it, do nothing     
%                             else enterResp=false;   
%                             end                                                 
%                         end                      
%                  
%                         % MOUSE POSITION SECTION 
%                         % recording the coordinates of the cursor until the loop is broken with click inside a box 
%                         [x,y,buttons] = GetMouse(win);
%                         current_pos = [x, y, buttons];
%                         trial_path = [trial_path; current_pos]; 
%                         
%                         % calculating distance cursor has moved 
%                         cursor_dist(k) = sqrt((x-Xcenter)^2 + (y-Ycenter)^2);
%                         if k >=6
%                             % v is calculated by looking at distance traveled over 5 samples
%                             %  (which should equal 10 ms if sampling at 500 Hz); 
%                             %  (given USB sampling rate limit of 125 Hz, this
%                             %   must be greater than 8 ms); 
%                             % converting into mm/sec requires dividing by .01 (10 ms in s) 
%                             %  and multiplying by (mm/pixel) conversion factor
%                             cursor_v(k) = (((cursor_dist(k)-cursor_dist(k-5))/(.01))*mm_per_pixel);
%                         else
%                             cursor_v(k) = 0;
%                         end          
% 
%                         % RECORDING INITIAL MOVEMENT TIME
%                         % if cursor moves for the FIRST time from the
%                         % center position, get the time of that movement 
%                         if cursor_moved == false && isequal(current_pos(1:2),trial_path(1,1:2)) == 0
%                             move_init = GetSecs;
%                             cursor_moved = true;                           
%                         elseif cursor_moved == true
%                         else move_init = 0;
%                         end 
%                         
%                         % if cursor moves farther away than the bounding distance
%                         %  from the center position, get the time of that movement 
%                         if cursor_moved_bound == false && cursor_dist(k) > boundDistance
%                             move_init_bound = GetSecs;
%                             cursor_moved_bound = true;                           
%                         elseif cursor_moved_bound == true
%                         else move_init_bound = 0;
%                         end 
%                         
%                         % RECORDING TIME ENTERING THE BOX 
%                         %if cursor moves into correct box for the FIRST time
%                         % center position, get the time of that movement 
%                         %enter_box = 0;
%                         if cursor_in_box == false                          
%                             if correctProbeResp == leftResp && current_pos(1) > leftX1 && current_pos(1) < leftX2 && current_pos(2) > leftY1 && current_pos(2) < leftY2
%                                 enter_box = GetSecs; 
%                                 cursor_in_box = true; 
%                             elseif correctProbeResp == rightResp && current_pos(1) > rightX1 && current_pos(1) < rightX2 && current_pos(2) > rightY1 && current_pos(2) < rightY2
%                                 enter_box = GetSecs; 
%                                 cursor_in_box = true; 
%                              elseif correctProbeResp == upResp && current_pos(1) > upX1 && current_pos(1) < upX2 && current_pos(2) > upY1 && current_pos(2) < upY2    
%                                 enter_box = GetSecs; 
%                                 cursor_in_box = true;
%                             elseif correctProbeResp == downResp && current_pos(1) > downX1 && current_pos(1) < downX2 && current_pos(2) > downY1 && current_pos(2) < downY2    
%                                 enter_box = GetSecs; 
%                                 cursor_in_box = true;
%                             else enter_box = 0; 
%                             end 
%                         elseif cursor_in_box == true
%                         %else enter_box = 0; 
%                         end
%                         
% %                         % CALCULATING VELOCITY                                       
% %                         if k > 6
% % %                             vx = diff(trial_path(k-1:k,1));
% % %                             vy = diff(trial_path(k-1:k,1));
% % %                             v = sqrt(vx.^2 + vy.^2);
% %                             
% %                             mx = diff(trial_path(k-5:k,1)); % motion in x direction 
% %                             my = diff(trial_path(k-5:k,2)); % motion in y direction 
% %                             m = sqrt(mx.^2 + my.^2); % displacement vector length 
% %                             v = mean(abs(diff(m))); % mean of the absolute value of velocity (speed) for last 5 data points sampled 
% %                             
% %                         end 
%                         
%                        % check if cursor is in BOX and velocity is below
%                         %  threshold ==> record that time 
%                         if cursor_velocity_drop == false 
%                             if current_pos(1) > leftX1 && current_pos(1) < leftX2 && current_pos(2) > leftY1 && current_pos(2) < leftY2
%                                     % here we want to set a threshold value of 30 mm/s over x (= 10) number of
%                                     % consecutive samples (see Tseng et al. 2007)
%                                     if k > 10 && all(cursor_v(k-10:k)<30) % 20 ms must have passed 
%                                         velocity_drop = GetSecs;
%                                         cursor_velocity_drop = true; 
%                                     end
%                             elseif current_pos(1) > rightX1 && current_pos(1) < rightX2 && current_pos(2) > rightY1 && current_pos(2) < rightY2
%                                     if k > 10 && all(cursor_v(k-10:k)<30) %15 samples = 30ms
%                                         velocity_drop = GetSecs; 
%                                         cursor_velocity_drop = true; 
%                                     end
%                             elseif current_pos(1) > upX1 && current_pos(1) < upX2 && current_pos(2) > upY1 && current_pos(2) < upY2    
%                                     if k > 10 && all(cursor_v(k-10:k)<30)
%                                         velocity_drop = GetSecs;
%                                         cursor_velocity_drop = true; 
%                                     end
%                             elseif current_pos(1) > downX1 && current_pos(1) < downX2 && current_pos(2) > downY1 && current_pos(2) < downY2
%                                     if k > 10 && all(cursor_v(k-10:k)<30)
%                                         velocity_drop = GetSecs; 
%                                         cursor_velocity_drop = true; 
%                                     end
%                             else velocity_drop = 0; 
%                             end
%                         elseif cursor_velocity_drop == true 
%                         end
%                         
%                         % SAMPLING RATE  
%                         t(k) = GetSecs - begintime;
%                         
%                         sampletime(k) = GetSecs;
%                         nextsampletime = nextsampletime + 1/desiredSampleRate;
%                         while GetSecs < nextsampletime
%                         end
%                         
%                         % BREAK LOOP AFTER RESPONSE DEADLINE HAS PASSED 
%                         % break the response loop after a designated
%                         % deadline
%                         if GetSecs - probeTime > WMProbe 
%                             enterResp = true; 
%                         end
%                         
%                     end
                    
                    
%                     %save the trial path to the cell array of paths for
%                     %each trial 
%                     cursor_path_probe{block, trial} = trial_path;  
%                     cursor_velocity_probe{block, trial} = cursor_v; 
%                     
%                     %calculate RT, time from the start of the cue to the
%                     %response click
%                     probert = GetSecs - probeTime;
%                     probemsecRT=round(1000*probert);
%                     
%                     if probemsecRT > (WMProbe*1000)-1
%                         probemsecRT = 'Time-out';
%                         probeResp = 'NA';
%                     else
%                         probemsecRT = num2str(probemsecRT);
%                     end
%                     
%                     %calculate movement initializing RT, time from cue to
%                     %the first movement of the cursor
%                     init_rt = move_init - probeTime; 
%                     if move_init == 0
%                         init_rt = 0;
%                     end                 
%                     probe_move_init_msecRT = round(1000*init_rt); 
%                     if probe_move_init_msecRT == 0
%                         probe_move_init_msecRT = 'No-move';
%                     else
%                         probe_move_init_msecRT = num2str(probe_move_init_msecRT);
%                     end
%                     
%                     % calculate movement initializing RT (bounding distance), time from cue to
%                     % the first movement of the cursor
%                     init_rt_bound = move_init_bound - probeTime; 
%                     if move_init_bound == 0
%                         init_rt_bound = 0;
%                     end                 
%                     probe_move_init_bound_msecRT = round(1000*init_rt_bound); 
%                     if probe_move_init_bound_msecRT == 0
%                         probe_move_init_bound_msecRT = 'No-move';
%                     else
%                         probe_move_init_bound_msecRT = num2str(probe_move_init_bound_msecRT);
%                     end
%                         
%                     %calculate movement into box RT, time from cue to
%                     % the first movement into the correct box 
%                     box_rt = enter_box - probeTime; 
%                     if enter_box == 0
%                         box_rt = 0;
%                     end                 
%                     probe_enter_box_msecRT = round(1000*box_rt); 
%                     if probe_enter_box_msecRT == 0
%                         probe_enter_box_msecRT = 'No-move';
%                     else
%                         probe_enter_box_msecRT = num2str(probe_enter_box_msecRT);
%                     end
%                     
%                     %calculate when cursor is in box and velocity has dropped  
%                     velocity_rt = velocity_drop - probeTime; 
%                     if velocity_drop == 0
%                         velocity_rt = 0;
%                     end                 
%                     probe_velocity_drop_msecRT = round(1000*velocity_rt); 
%                     if probe_velocity_drop_msecRT == 0
%                         probe_velocity_drop_msecRT = 'No-drop';
%                     else
%                         probe_velocity_drop_msecRT = num2str(probe_velocity_drop_msecRT);
%                     end
%                     
%                 %calculate accuracy
%                 probeAccuracy = strcmp(probeResp,correctProbeResp); 
% 
%                 if probeAccuracy == 1 
%                     probeACC = 1;
%                 else probeACC = 0;
%                 end            
%                        
%             
%             HideCursor;
              
% 

 %collect probe response data - KEYBOARD ARROW VERSION
 
                % wait for button press and record when one occurs
                if IsOSX
                [probekeys, probeRT] = waitForKeys(GetSecs, WMProbe, KeyBoardNum, 1);
                else
                [probekeys, probeRT] = waitForKeys(GetSecs, WMProbe, 0, 1);
                end     
                
                % wait the remaining time until WMProbe time is up 
                %while (GetSecs - probeTime) <= WMProbe        
                %end            
                
                % record probe response and RTs 
                     if probeRT == 0
                        probert = 9999;
                        probeResp = 'NA';
                     else
                        probert = probeRT;
                        probeResp = num2str(probekeys(1));
                        % convert arrow key direcitons to U/D/L/R
                        if strcmp(probeResp, 'UpArrow') == true
                            probeResp = upResp;  
                        elseif strcmp(probeResp, 'DownArrow') == true
                            probeResp = downResp;                          
                        elseif strcmp(probeResp, 'LeftArrow') == true
                            probeResp = leftResp;   
                        elseif strcmp(probeResp, 'RightArrow') == true
                            probeResp = rightResp;                              
                        end                       
                     end   
               
                if probeRT == 0
                    probert = 9999;
                    probeResp = 'NA';
                else
                    probert = probeRT;
                end 

                probemsecRT = round(1000*probert);
                probemsecRT = num2str(probemsecRT); 

                probeAccuracy = strcmp(probeResp,correctProbeResp); 

%                 if probeAccuracy == 1 
%                     probeACC = 1;
%                 else probeACC = 0;
%                 end    
%                 
                if probeAccuracy == 1 
                    probeACC = 1;
                    DrawFormattedText(win, 'Correct!', 'center', 'center', 0);
                    Screen('Flip', win); 
                    WaitSecs(feedback);
                else probeACC = 0;
                    DrawFormattedText(win, 'Incorrect', 'center', 'center', 0);
                    Screen('Flip', win); 
                    WaitSecs(feedback);
                end   
                
                
                % Fill sections from mouse click version as 'NA' 
%                 probe_move_init_msecRT = 'NA'; 
%                 probe_move_init_bound_msecRT = 'NA'; 
%                 probe_enter_box_msecRT = 'NA'; 
%                 probe_velocity_drop_msecRT = 'NA'; 
                 

                %let them know that they have completed one trial
                if trial == 1
                    DrawFormattedText(win, 'You completed one practice trial!\n\n\nNow, you will complete several trials in a row', 'center', 'center', 0);
                    Screen('Flip', win); 
                    WaitSecs(2);
                end             
                
        %add movement initiation time and data type
        %print trial info to data file
%             fprintf(fid,'%s %i %i %i %s %d %s %s %s %s %d %s %s %s %s %s %s %s %d %s %s %s %s %s\n',...
%             subject,...
%             block,...
%             trial,... 
%             CurrentCondition,...
%             TrialType,...
%             CurrentSampleIndex,...
%             CurrentSample,...
%             cueColor,...
%             correctResp,...
%             resp,...
%             ACC,...
%             msecRT,...
%             move_init_msecRT,...
%             move_init_bound_msecRT,...
%             enter_box_msecRT,...
%             velocity_drop_msecRT,...
%             correctProbeResp,...
%             probeResp,...
%             probeACC,...
%             probemsecRT,...
%             probe_move_init_msecRT,...
%             probe_move_init_bound_msecRT,...
%             probe_enter_box_msecRT,...
%             probe_velocity_drop_msecRT);
    
        end
    
       
    
    %kindly give participants a helpful indicator of how much more
    %excrutiating misery they have left to endure
       if block == BlockNum
           message=sprintf('You are now done with the experiment \n \n \n Thanks for participating! \n \n');
       else
           thisblock = num2str(block);
           allblock = num2str(BlockNum);
           space = {' '};
           endmessage = strcat('You are done with block', space, thisblock, ' out of', space, allblock, '\n\n\n Press space to begin the next block');
           endmessage = char(endmessage);
           message=sprintf(endmessage);            
       end
    
    blockend = message;
    DrawFormattedText(win, blockend, 'center', 'center', 0);
    Screen('Flip', win);
    
        if IsOSX
            getKey('space', KeyBoardNum);
        else
            getKey('space');
        end
    
    
    end


% name of data output file 
% cursor_data_filename = strcat('MotorData/WM_Simon_phase2_word_keypress_', subject, '_cursor_data.mat'); 
% save(cursor_data_filename, 'cursor_path'); 
% 
% velocity_data_filename = strcat('MotorData/WM_Simon_phase2_word_keypress_', subject, '_velocity_data.mat'); 
% save(velocity_data_filename, 'cursor_velocity'); 

% cursor_data_filename_probe = strcat('MotorData/WM_Simon_phase2_word_keypress_', subject, '_cursor_probe_data.mat'); 
% save(cursor_data_filename_probe, 'cursor_path_probe'); 
% 
% velocity_data_filename_probe = strcat('MotorData/WM_Simon_phase2_word_keypress_', subject, '_velocity_probe_data.mat'); 
% save(velocity_data_filename_probe, 'cursor_velocity_probe'); 


ListenChar(0);
Screen('CloseAll');
ShowCursor;
FlushEvents;
fclose('all');
Priority(0);
    
end


%% helper functions
function getKey(key,deviceNumber)

% Waits until user presses the specified key.
% Usage: getKey('a')
% JC 02/01/06 Wrote it.
% JC 03/31/07 Added platform check.

% Don't start until keys are released
if IsOSX
    if nargin<2
        fprintf('You are using OSX and you MUST provide a deviceNumber! getKey will fail.\n');
    end
    while KbCheck(deviceNumber) 
    end;
else
    if nargin>3
        fprintf('You are using Windows and you MUST NOT provide a deviceNumber! getKey will fail.\n');
    end
    while KbCheck end;  % no deviceNumber for Windows
end

while 1
    while 1
        if IsOSX
            [keyIsDown,secs,keyCode] = KbCheck(deviceNumber);
        else
            [keyIsDown,secs,keyCode] = KbCheck; % no deviceNumber for Windows
        end
        if keyIsDown
            break;
        end
    end
    theAnswer = KbName(keyCode);
    if ismember(key,theAnswer)  % this takes care of numbers too, where pressing 1 results in 1!
        break
    end
end
end

%--------------------------------------------------------------------------

function [keys, RT] = waitForKeys(startTime,duration,deviceNumber,exitIfKey)

% Modified from collectKeys.
% NC (after JC) 11/27/07
% Collects keypresses for a given duration.
% Duration is in seconds.
% If using OSX, you MUST provide a deviceNumber.
% If using Windows, you do not need to provide a deviceNumber -- if you do,
% it will be ignored.
% Optional argument exitIfKey: if exitIfKey==1, function returns after
% first keypress. 
%
% Example usage: do this if duration = length of event
%   [keys RT] = recordKeys(GetSecs,0.5,deviceNumber)
%
% Example usage: do this if duration = endEvent-trialStart
%   goTime = 0;
%   startTime = GetSecs;  % This is the time the trial starts
%   goTime = goTime + pictureTime;  % This is the duration from startTime to the end of the next event
%   Screen(Window,'Flip');
%   [keys RT] = recordKeys(startTime,goTime,deviceNumber);
%   goTime = goTime + blankTime;    % This is the duration from startTime to the end of the next event
%   Screen(Window,'Flip');
%   [keys RT] = recordKeys(startTime,goTime,deviceNumber);
%
% A note about the above example: it's best to calculate the duration from
% the beginning of each trial, rather than from the beginning of each
% event. Some commands may cause delays (like Flip), and if you calculate
% duration by event, these delays will accumulate. If you calculate
% duration from the beginning of the trial, your presentations may be a
% tiny bit truncated, but you'll be on schedule. It's your call.
% Even better: calculate duration from the beginning of the experiment.
%
% Using deviceNumber:
% KbCheck only collects from the first key input device found. On a laptop,
% this is usually the laptop keyboard. However, often you'll want to collect
% from another device, like the buttonbox in the scanner! You MUST specify
% the device number, or none of the input from the buttonbox will be
% collected. Device numbers change according to what order the USB devices
% were plugged in, and you may find that you can only perform this check
% ONCE using the command d=PsychHID('Devices'); so DO NOT change the device
% arrangement (which port each is plugged into) after performing the check.
% Restarting Matlab will allow you to use d=PsychHID('Devices') again
% successfully.
% On Windows, KbCheck records simultaneously from all keyboards -- you
% cannot specify.
%
% collectKeys:
% JC 02/16/2006 Wrote it.
% JC 02/28/2006 Added deviceNumber.
% JC 08/14/2006 Added break if time is up, even if key is being held down.
% recordKeys:
% JC 03/31/2007 Changed from etime to GetSecs. Added platform check. Added cell check.
% JC 07/02/2007 Added exitIfKey.
% JC 08/02/2007 Fixed "Don't start until keys are released" to check for
% duration exceeded

keys = [];
RT = [];
myStart = GetSecs;    % Record the time the function is called (not same as startTime)

% Don't start until keys are released
if IsOSX
    if ~exist('deviceNumber','var')
        fprintf('You are using OSX and you MUST provide a deviceNumber! recordKeys will fail.\n');
    end
    while KbCheck(deviceNumber) 
        if (GetSecs-startTime)>duration, break, end
    end;
else
    while KbCheck % no deviceNumber for Windows
        if (GetSecs-startTime)>duration, break, end
    end;  
end

% Now check for keys
while 1
    if IsOSX
        [keyIsDown,secs,keyCode] = KbCheck(deviceNumber);
    else
        [keyIsDown,secs,keyCode] = KbCheck; % no deviceNumber for Windows
    end
    if keyIsDown
        keys = [keys KbName(keyCode)];
        RT = [RT GetSecs-myStart];
        break
        if IsOSX
            while KbCheck(deviceNumber)
                if (GetSecs-startTime)>duration, break, end
            end
        else
            while KbCheck
                if (GetSecs-startTime)>duration, break, end
            end
        end
        if exist('exitIfKey','var')
            if exitIfKey
                break
            end
        end
    end
    if (GetSecs-startTime)>duration, break, end
end

if isempty(keys)
    keys = 'noanswer';
    RT = 0;
elseif iscell(keys)  % Sometimes KbCheck returns a cell array (if multiple keys are mashed?).
    keys = '';
    RT = 0;
end
end
