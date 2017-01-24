% WM Simon dots mouse response task - Version 3:
%   - two (L/R) WM probes and response options 
%       - no neutral cue
%   - longer WM delay 
%   - boxes on same axis as motor click 
%
%

function WM_Simon_arrow_mouse_recall_veloc 

%%% timestamp movement onset and add to results printout 

%%
rng('default'); %sometimes, if you've recently initiated the legacy random number generator, it wont let you use rng until you reset it to default, or something
rng('shuffle');

KbName('UnifyKeyNames'); 
    
%message pops up in the command window to ask for subject number   
subject = input('Enter SUBJECT number ', 's');

%name of data output file 
datafilename = strcat('MotorData/WM_Simon_arrow_mouse_recall_veloc_', subject, '.txt'); 

%if a file with that same info already exists in the data folder, give a
%new subject #, or overwrite the existing file
if exist(datafilename)==2
    disp ('A file with this name already exists')
    overwrite = input('overwrite?, y/n \n', 's');
    if strcmpi(overwrite, 'n')
        %disp('enter new subject number');
        newsub = input('New SUBJECT number? ', 's');
        datafilename = strcat('MotorData/WM_Simon_arrow_mouse_recall_', newsub, '.txt');
    end
end

%make a space-delimited text output file where each trial is a row
%(I just happen to like using text files, but you can output the data in
%any way that will work the best for your preferred analysis style)
fid = fopen(datafilename, 'w');
fprintf(fid, 'subject block trial CurrentCondition TrialType CurrentSampleIndex CurrentSample cueColor correctResp Resp ACC msecRT move_init_msecRT enter_box_msecRT correctProbeResp probeResp probeACC probemsecRT probe_move_init_msecRT probe_enter_box_msecRT\n');

% make a cell array to hold data for tracking the cursor path 
%  in this cell array, each row is a block and each column is a trial
%  (each element being the path for that trial in that block)

cursor_path = {};
cursor_path_probe = {};

%% Some PTB and Screen set-up  
AssertOpenGL;    
HideCursor;
ListenChar(2);

%make dummy calls to initialize some functions
KbCheck; 
WaitSecs(0.1);
GetSecs;

%I use this later cause I call on some custom subfunctions that 
%need to know the keyboard number in order to receive key input
KeyBoardNum = GetKeyboardIndices; 


    Screen('Preference', 'SkipSyncTests', 2); %1 skips the tests, 0 conducts them
    Screen('Preference', 'VisualDebugLevel', 3);%to suppress the PTB survey screen
    Screen('Preference', 'VBLTimestampingMode', 1);
    
    %you can either use the highest screen index in a multiple monitor
    %set-up, or specify which of several screens you want to use. 0 will
    %take up all available screen real estate
    screenNumber=max(Screen('Screens')); 
    %screenNumber=0;
    
    %give values for screen elements
    screenColor = [128 128 128];
    fixColor = [255 255 255];
    sampleColor = [0 0 0];
    
    [win, wRect]=Screen('OpenWindow',screenNumber, screenColor);
    
    priorityLevel=MaxPriority(win);
    Priority(priorityLevel);    
    
    Screen('TextSize', win, 36);
    Screen('TextFont', win, 'Arial');
    Screen('TextColor', win, fixColor);
    
    %we probably don't actually need this for this task, but I like to
    %include it in case we want to incorporate any interesting color or
    %graphical things
    Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
   
%% Specify timing and condition values

    ITI = 1; % orig = 1
    SampleShow = 1;
    WMDelay = 2; %orig = 1.5
    responseDeadline = 3; %orig = 4
    probeDelay = 1;
    WMProbe = 2; %orig = 2
    
    BlockNum = 1; %4
    TrialNum = 4; %30
    
    %change detection response keys
    leftProbeResp = 'L';
    rightProbeResp = 'R';
    
    %motor response keys
    leftResp = 'L';
    rightResp = 'R';
    %upResp = 'U';
    
    leftWord = sprintf('left');
    rightWord = sprintf('right');
    %topWord = sprintf('top');
    
    SampleWords = [leftWord rightWord]; %possible locations of two-dot array
    
    %these RGB values were selected to be maximally different using the
    %color tool at I Want Hue
    % four color version, with 2 colors for left and 2 for right responses
    leftRGB1 = [122 164 86]; % left, green 
    leftRGB2 = [198 89 153]; % left, pink 
    rightRGB1 = [201 109 68]; % right, orange
    rightRGB2 = [119 122 205]; % right, blue 
    
    %leftRGB = [164 108 183]; %left, purple
    %rightRGB = [203 106 73]; %right, orange
    %upRGB = [122 164 87]; %up, green
    
    leftColor1 = 'green'; 
    leftColor2 = 'pink'; 
    rightColor1 = 'orange';
    rightColor2 = 'blue'; 
    
    %leftColor = 'purple';
    %rightColor = 'orange';
    %upColor = 'green';
    
    %make a vector of codes for the trial conditions    
    TrialsPer = TrialNum/2; %Divide # of trials by # of conditions, to get equal trials of each type
    TrialsPer = ceil(TrialsPer);
    
    TrialsPerCongruency = TrialNum/2; % divide by number of congruency conditions 
    TrialsPerCongruency = ceil(TrialsPerCongruency);
    
    %include 3s in this vector if you want to have a neutral condition
    Condition = [ones(1, TrialsPerCongruency) 2*ones(1, TrialsPerCongruency)] % 1 = compatible, 2 = incompatible, 3 = neutral    
    ProbeMatch = [ones(1, TrialsPer) 2*ones(1, TrialsPer)];
    SampleIndex = [ones(1, TrialsPer) 2*ones(1, TrialsPer)]; % 1 = left, 2 = right
    ColorIndex = [ones(1, TrialsPer) 2*ones(1, TrialsPer)]; % 1 = color 1, 2 = color 2
    
    %determine center of screen from which to determine size and location
    %of stimuli
    h = wRect(4);
    w = wRect(3);
    centerX = wRect(3)/2;
    centerY = wRect(4)/2; 

    [screenXpixels, screenYpixels] = Screen('WindowSize', win);
    Xcenter = screenXpixels/2;
    Ycenter = screenYpixels/2;    
    
    %change this to move the location of the spatial stimuli
    Xoffset = screenXpixels/4;
    Yoffset = screenYpixels/4;
    %Xoffset = (1/2)*screenYpixels; %screenXpixels
    %Yoffset = (3/4)*screenYpixels;
 
    %Make a destination rectangle for stimuli
    stimSize = 150; %orig = 100
    xcorner = centerX+stimSize;
    ycorner = centerY+stimSize;
    
    %this is the general rect size we'll use for all stims
    stimRect = [centerX centerY xcorner ycorner];
    
    %this centers it on  particular location
    centerRect = CenterRectOnPointd(stimRect, Xcenter, Ycenter);
    
    leftX = Xcenter-Xoffset;
    rightX = Xcenter+Xoffset;
 
    
    leftRect = CenterRectOnPointd(stimRect, leftX, Ycenter);
    rightRect = CenterRectOnPointd(stimRect, rightX, Ycenter);
    % topRect = CenterRectOnPointd(stimRect, Xcenter, topY);
%     bottomRect = CenterRectOnPointd(stimRect, Xcenter, bottomY);

    
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

    %width of the outline box for accepting clicks
    frameWidth = 5;
    
    %make a little rectangle to serve as the fixation point    
    fixSize = 15;
    fixX = centerX + fixSize;
    fixY = centerY + fixSize;
    fixRect = [centerX centerY fixX fixY];
    fixCenter = CenterRectOnPointd(fixRect, Xcenter, Ycenter);
    
    % read images for use as WM stimuli 
    left_image = imread('left_arrow_copy.png'); 
    right_image = imread('right_arrow_copy.png'); 
    left_image = imresize(left_image, 0.8); 
    right_image = imresize(right_image, 0.8);
    
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
    
%% Start task block loop
        
    %show instruction screen
    welcome=sprintf('Move to left box for green or pink \n           right box for orange or blue \n\n\nThen, move to box where arrow pointed\n\n\n\n\nPress space to begin the experiment \n \n \n');
    DrawFormattedText(win, welcome, 'center', 'center', 0);
    Screen('Flip', win);
    %'Flip' called to put stimuli onto screen 
    
    % Wait for a key press using the custom getkey function (appended to
    % end of script)
    if IsOSX
        getKey('space', KeyBoardNum); %OSX requires a device number whereas windows requires none
    else
        getKey('space');
    end
    
    
    for block = 1:BlockNum
        
        
    % shuffle the order of the condition vectors at the start of each block
    % for a random selection    
    Condition = Shuffle(Condition);    
    ProbeMatch = Shuffle(ProbeMatch);
    SampleIndex = Shuffle(SampleIndex);
    ColorIndex = Shuffle(ColorIndex); 
    %disp(ProbeMatch);
    
        for trial = 1:TrialNum
                       
            % show fixation
            Screen('FillRect', win, fixColor, fixCenter);
            Screen('Flip', win);
            WaitSecs(ITI);   
            
            % choose the congruency condition for this trial
            CurrentCondition = Condition(trial);
            
            % define what sample word will be shown on this trial
            CurrentSampleIndex = SampleIndex(trial);
            
            % define what color cue will be shown on this trial
            CurrentColorIndex = ColorIndex(trial); 
            
            % CurrentSample = SampleWords(CurrentSampleIndex); 
            % CurrentSample = sprintf(CurrentSample);

            
            switch CurrentCondition
                case 1 %compatible
                    TrialType = 'compatible';
                    
                    if CurrentSampleIndex == 1 % L cue  
                       CurrentSample = leftWord;
                       
                       % if statement for color cue b/c of 4 color mapping 
                       if CurrentColorIndex == 1; % Color of cue 
                          CurrentMotor = leftRGB1;
                          cueColor = leftColor1; 
                       else 
                          CurrentMotor = leftRGB2;
                          cueColor = leftColor2; 
                       end                       
                       
                       correctResp = leftResp;          
                       % assign image to present
                       texture = left_texture; 
                        
                    elseif CurrentSampleIndex == 2 % R cue
                       CurrentSample = rightWord;
                       
                       if CurrentColorIndex == 1; % Color of cue 
                          CurrentMotor = rightRGB1;
                          cueColor = rightColor1; 
                       else 
                          CurrentMotor = rightRGB2;
                          cueColor = rightColor2; 
                       end  
                       
                       correctResp = rightResp;
                        
                       texture = right_texture;                       
                    end 
                    
                case 2 %incompatible
                    TrialType = 'incompatible';
                    
                    if CurrentSampleIndex == 2 % R cue
                        CurrentSample = rightWord;
                        
                       if CurrentColorIndex == 1; % Color of cue 
                          CurrentMotor = leftRGB1;
                          cueColor = leftColor1; 
                       else 
                          CurrentMotor = leftRGB2;
                          cueColor = leftColor2; 
                       end  
                      
                        correctResp = rightResp;
                        
                        texture = right_texture;  % incompatible image direction
                        
                        
                    elseif CurrentSampleIndex == 1
                        CurrentSample = leftWord;
                        
                       if CurrentColorIndex == 1; % Color of cue 
                          CurrentMotor = rightRGB1;
                          cueColor = rightColor1; 
                       else 
                          CurrentMotor = rightRGB2;
                          cueColor = rightColor2; 
                       end    
                      
                        correctResp = leftResp;   
                        
                        texture = left_texture; 
                    end
            end

            
        %show WM sample 
        
            %DrawFormattedText(win, CurrentSample, 'center', 'center', 0);
            % Draw the image to the screen
            %Screen('DrawTexture', window, texture, [], [], 0);
            Screen('DrawTexture', win, texture);
            Screen('Flip', win);
            WaitSecs(SampleShow); 
            
            DrawFormattedText(win, '+', 'center', 'center', 0);
            Screen('Flip', win);
            WaitSecs(WMDelay);            

        %show motor cue during WM delay
        
            Screen('FillRect', win, CurrentMotor, centerRect);    
            Screen('FrameRect', win, sampleColor, leftRect, frameWidth);
            Screen('FrameRect', win, sampleColor, rightRect, frameWidth);
            %Screen('FrameRect', win, sampleColor, topRect, frameWidth);
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
                    cursor_moved = false; 
                    cursor_in_box = false; 
                    
                    % SAMPLING RATE 
                    % code for setting a constant sampling rate of the while loop for getting mouse position 
                    tic;
                    begintime = GetSecs;
                    nextsampletime = begintime;
                    k = 0;
                    desiredSampleRate = 125; % in Hz  
                    veloc_thresh = 15; 
                    
                    
                    % LOOP FOR COLLECTING MOUSE RESPONSE DATA FOR MOTOR
                    % TASK 
                    % this loop will listen for clicks inside the boxes
                    %  associated with the color cue
                    while enterResp==false                        
                        
                        % CLICK SECTION 
                        %[~, responseX, responseY, buttons] = GetClicks(win, 0);%gives coords of each click                         
%                         [responseX, responseY, mouseClick] = GetMouse;
%                         
%                         %if any(buttons)                        
%                         if mouseClick(1) == 1
%                         
%                             % if a click falls within the response box range, response is entered 
%                             if responseX > leftX1 && responseX < leftX2 && responseY > leftY1 && responseY < leftY2
%                                 enterResp = true;
%                                 resp = leftResp;                                   
%                                 
%                             elseif responseX > rightX1 && responseX < rightX2 && responseY > rightY1 && responseY < rightY2
%                                 enterResp = true;
%                                 resp = rightResp;
%                                 
%                             %elseif responseX > topX1 && responseX < topX2 && responseY > topY1 && responseY < topY2
%                              %   enterResp = true;
%                               %  resp = upResp;              
%                                 
%                             % if a click surrounds the response box, but doesn't fall inside it, do nothing     
%                             else enterResp=false;   
%                             end                                                 
%                         end
                        
                        % MOUSE POSITION SECTION 
                        % recording the coordinates of the cursor until the loop is broken with click inside a box 
                        [x,y,buttons] = GetMouse(win);
                        current_pos = [x, y, buttons];
                        trial_path = [trial_path; current_pos];
                        
                        % SAMPLING RATE  
                        k = k+1;   
                        t(k) = GetSecs - begintime;
                        
                        sampletime(k) = GetSecs;
                        nextsampletime = nextsampletime + 1/desiredSampleRate;
                        while GetSecs < nextsampletime
                        end
                        
                        % RECORDING INITIAL MOVEMENT TIME 
                        %if cursor moves for the FIRST time from the
                        % center position, get the time of that movement 
                        if cursor_moved == false && isequal(current_pos(1:2),trial_path(1,1:2)) == 0
                            move_init = GetSecs;
                            cursor_moved = true;                           
                        elseif cursor_moved == true
                        else move_init = 0;
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
                            else enter_box = 0; 
                            end 
                        elseif cursor_in_box == true
                        %else enter_box = 0; 
                        end
                        
                        % CALCULATING VELOCITY 
                                        
                        if k > 6
                            
                            mx = diff(trial_path(k-5:k,1)); % motion in x direction 
                            my = diff(trial_path(k-5:k,2)); % motion in y direction 
                            m = sqrt(mx.^2 + my.^2); % displacement vector length 
                            v = mean(abs(diff(m))); % mean of the absolute value of velocity (speed) for last 5 data points sampled 
                             
%                             mvx = diff(trial_path(k-1:k,1)); 
%                             mvy = diff(trial_path(k-1:k,2)); 
%                             mv = sqrt(mvx.^2 + mvy.^2);                              
%                             v = diff(mv);                                                         
%                             vx = diff(trial_path(k-1:k,1));
%                             vy = diff(trial_path(k-1:k,2));
%                             v = sqrt(vx.^2 + vy.^2);
                        end 
                        
                        % check if cursor is in BOX and velocity is below
                        % threshold of 10 
                        if current_pos(1) > leftX1 && current_pos(1) < leftX2 && current_pos(2) > leftY1 && current_pos(2) < leftY2
                                if v < veloc_thresh
                                    enterResp = true;
                                    resp = leftResp; 
                                end
                        elseif current_pos(1) > rightX1 && current_pos(1) < rightX2 && current_pos(2) > rightY1 && current_pos(2) < rightY2
                                if v < veloc_thresh
                                    enterResp = true;
                                    resp = rightResp; 
                                end
                        else enterResp=false;
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
                    
                    %save the trial path to the cell array of paths for
                    %each trial 
                    cursor_path{block, trial} = trial_path;                    
                    
                    %calculate RT, time from the start of the cue to the
                    %response click
                    rt = GetSecs - cueStart;
                    msecRT=round(1000*rt);
                    
                    if msecRT > (responseDeadline*1000)-1
                        msecRT = 'Time-out';
                    else
                        msecRT = num2str(msecRT);
                    end
                    
                    %calculate movement initializing RT, time from cue to
                    %the first movement of the cursor
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
                    
                %calculate accuracy
                Accuracy = strcmp(resp,correctResp); 

                if Accuracy == 1 
                    ACC = 1;
                else ACC = 0;
                end            
                       
            
            HideCursor;
                
            DrawFormattedText(win, '+', 'center', 'center', 0);
            Screen('Flip', win);
            WaitSecs(probeDelay); 
            
                % determine whether L or R response is the correct response
                if CurrentSampleIndex == 1
                    correctProbeResp = leftProbeResp; 
                elseif CurrentSampleIndex == 2
                    correctProbeResp = rightProbeResp;  
                end
                
            
            %[minSmoothPointSize, maxSmoothPointSize, minAliasedPointSize, maxAliasedPointSize] = Screen('DrawDots', win, xy, 15, [0 0 0], center, 1);
            %DrawFormattedText(win, ProbeSide, 'center', 'center', 0);
            DrawFormattedText(win, 'Arrow?', 'center', 'center', 0);
            Screen('FrameRect', win, sampleColor, leftRect, frameWidth);
            Screen('FrameRect', win, sampleColor, rightRect, frameWidth);
            %Screen('Flip', win);
            %WaitSecs(WMProbe);            
            %probeTime = GetSecs;
            
        %collect probe response data 
                
            ShowCursor('Arrow');

                    %puts mouse at center--but can be weird on multi-display
                    %setups
                    SetMouse(Xcenter, Ycenter);
                    [~, probeTime] = Screen('Flip', win);

                    enterResp=false;

                    %resp = 9999; %reset this variable before each response phase to avoid wonky behavior if they don't respond at all

                    trial_path = [];
                    cursor_moved = false; 
                    cursor_in_box = false; 
                    
                    % SAMPLING RATE 
                    % code for setting a constant sampling rate of the while loop for getting mouse position 
                    tic;
                    begintime = GetSecs;
                    nextsampletime = begintime;
                    k = 0;
                    desiredSampleRate = 125; 
                    
                    
                    % LOOP FOR COLLECTING MOUSE RESPONSE DATA FOR MOTOR
                    % TASK 
                    % this loop will listen for clicks inside the boxes
                    %  associated with the color cue
                    while enterResp==false                        
                        
                        % CLICK SECTION 
                        %[~, responseX, responseY, buttons] = GetClicks(win, 0);%gives coords of each click                         
%                         [responseX, responseY, mouseClick] = GetMouse;
%                         
%                         %if any(buttons)                        
%                         if mouseClick(1) == 1
%                         
%                             % if a click falls within the response box range, response is entered 
%                             if responseX > leftX1 && responseX < leftX2 && responseY > leftY1 && responseY < leftY2
%                                 enterResp = true;
%                                 probeResp = leftResp;                                   
%                                 
%                             elseif responseX > rightX1 && responseX < rightX2 && responseY > rightY1 && responseY < rightY2
%                                 enterResp = true;
%                                 probeResp = rightResp;
%                                 
%                             %elseif responseX > topX1 && responseX < topX2 && responseY > topY1 && responseY < topY2
%                              %   enterResp = true;
%                               %  resp = upResp;              
%                                 
%                             % if a click surrounds the response box, but doesn't fall inside it, do nothing     
%                             else enterResp=false;   
%                             end                                                 
%                         end
%                         
                        % MOUSE POSITION SECTION 
                        % recording the coordinates of the cursor until the loop is broken with click inside a box 
                        [x,y,buttons] = GetMouse(win);
                        current_pos = [x, y, buttons];
                        trial_path = [trial_path; current_pos];
                        
                        % SAMPLING RATE  
                        k = k+1;   
                        t(k) = GetSecs - begintime;
                        
                        sampletime(k) = GetSecs;
                        nextsampletime = nextsampletime + 1/desiredSampleRate;
                        while GetSecs < nextsampletime
                        end
                        
                        % RECORDING INITIAL MOVEMENT TIME 
                        %if cursor moves for the FIRST time from the
                        % center position, get the time of that movement 
                        if cursor_moved == false && isequal(current_pos(1:2),trial_path(1,1:2)) == 0
                            move_init = GetSecs;
                            cursor_moved = true;                           
                        elseif cursor_moved == true
                        else move_init = 0;
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
                            else enter_box = 0; 
                            end 
                        elseif cursor_in_box == true
                        %else enter_box = 0; 
                        end
                        
                        % CALCULATING VELOCITY                                       
                        if k > 6
%                             vx = diff(trial_path(k-1:k,1));
%                             vy = diff(trial_path(k-1:k,1));
%                             v = sqrt(vx.^2 + vy.^2);
                            
                            mx = diff(trial_path(k-5:k,1)); % motion in x direction 
                            my = diff(trial_path(k-5:k,2)); % motion in y direction 
                            m = sqrt(mx.^2 + my.^2); % displacement vector length 
                            v = mean(abs(diff(m))); % mean of the absolute value of velocity (speed) for last 5 data points sampled 
                            
                        end 
                        
                        % check if cursor is in BOX and velocity is below
                        % threshold of 10 
                        if current_pos(1) > leftX1 && current_pos(1) < leftX2 && current_pos(2) > leftY1 && current_pos(2) < leftY2
                                if v < veloc_thresh
                                    enterResp = true;
                                    probeResp = leftResp; 
                                end
                        elseif current_pos(1) > rightX1 && current_pos(1) < rightX2 && current_pos(2) > rightY1 && current_pos(2) < rightY2
                                if v < veloc_thresh
                                    enterResp = true;
                                    probeResp = rightResp; 
                                end
                        else enterResp=false;
                        end
                        
                        % BREAK LOOP AFTER RESPONSE DEADLINE HAS PASSED 
                        % break the response loop after a designated
                        % deadline
                        if GetSecs - probeTime > WMProbe 
                            enterResp = true; 
                        end
                        
                    end
                    
                    
                    %save the trial path to the cell array of paths for
                    %each trial 
                    cursor_path_probe{block, trial} = trial_path;                    
                    
                    %calculate RT, time from the start of the cue to the
                    %response click
                    probert = GetSecs - probeTime;
                    probemsecRT=round(1000*probert);
                    
                    if probemsecRT > (WMProbe*1000)-1
                        probemsecRT = 'Time-out';
                        probeResp = 'NA';
                    else
                        probemsecRT = num2str(probemsecRT);
                    end
                    
                    %calculate movement initializing RT, time from cue to
                    %the first movement of the cursor
                    init_rt = move_init - probeTime; 
                    if move_init == 0
                        init_rt = 0;
                    end                 
                    probe_move_init_msecRT = round(1000*init_rt); 
                    if probe_move_init_msecRT == 0
                        probe_move_init_msecRT = 'No-move';
                    else
                        probe_move_init_msecRT = num2str(probe_move_init_msecRT);
                    end
                        
                    %calculate movement into box RT, time from cue to
                    % the first movement into the correct box 
                    box_rt = enter_box - probeTime; 
                    if enter_box == 0
                        box_rt = 0;
                    end                 
                    probe_enter_box_msecRT = round(1000*box_rt); 
                    if probe_enter_box_msecRT == 0
                        probe_enter_box_msecRT = 'No-move';
                    else
                        probe_enter_box_msecRT = num2str(probe_enter_box_msecRT);
                    end
                    
                %calculate accuracy
                probeAccuracy = strcmp(probeResp,correctProbeResp); 

                if probeAccuracy == 1 
                    probeACC = 1;
                else probeACC = 0;
                end            
                       
            
            HideCursor;
              
%                 if IsOSX
%                 [probekeys, probeRT] = waitForKeys(GetSecs, WMProbe, KeyBoardNum, 1);
%                 else
%                 [probekeys, probeRT] = waitForKeys(GetSecs, WMProbe, 0, 1);
%                 end     
% 
%                 while (GetSecs - probeTime) <= WMProbe        
%                 end            
%                 
%                      if probeRT == 0
%                         probert = 9999;
%                         probeResp = 'NA';
%                      else
%                         probert = probeRT;
%                         probeResp = num2str(probekeys(1));
%                         % convert '1' and '2' to 'L' and 'R' 
%                         if strcmp(probeResp, '1') == true
%                             probeResp = 'L'; 
%                         elseif strcmp(probeResp, '2') == true
%                             probeResp = 'R'; 
%                         end                       
%                      end   

%         % mouse click version of probe response 
%                 clickResp = false; 
%                 while (GetSecs - probeTime) <= WMProbe  
%                     [responseX, responseY, mouseClick] = GetMouse;   
%                     if clickResp == false 
%                         if mouseClick(1) == 1 
%                         probeRT = GetSecs - probeTime; 
%                         clickResp = true; 
%                         probeResp = 'L'; 
%                         elseif mouseClick(2) == 1
%                         probeRT = GetSecs - probeTime; 
%                         clickResp = true;
%                         probeResp = 'R'; 
%                         else probeRT = 0; 
%                         end 
%                     elseif clickResp == true 
%                     end                  
%                 end     
                
%                 if probeRT == 0
%                     probert = 9999;
%                     probeResp = 'NA';
%                 else
%                     probert = probeRT;
%                 end 
% 
%                 probemsecRT = round(1000*probert);
%                 probemsecRT = num2str(probemsecRT); 
% 
%                 probeAccuracy = strcmp(probeResp,correctProbeResp); 
% 
%                 if probeAccuracy == 1 
%                     probeACC = 1;
%                 else probeACC = 0;
%                 end            
                
                                               
        %add movement initiation time and data type
        %print trial info to data file
            fprintf(fid,'%s %i %i %i %s %d %s %s %s %s %d %s %s %s %s %s %d %s %s %s\n',...
            subject,...
            block,...
            trial,... 
            CurrentCondition,...
            TrialType,...
            CurrentSampleIndex,...
            CurrentSample,...
            cueColor,...
            correctResp,...
            resp,...
            ACC,...
            msecRT,...
            move_init_msecRT,...
            enter_box_msecRT,...
            correctProbeResp,...
            probeResp,...
            probeACC,...
            probemsecRT,...
            probe_move_init_msecRT,...
            probe_enter_box_msecRT);
    
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


%name of data output file 
cursor_data_filename = strcat('MotorData/WM_Simon_arrow_mouse_recall_veloc_', subject, '_cursor_data.mat'); 
save(cursor_data_filename, 'cursor_path'); 

cursor_data_filename_probe = strcat('MotorData/WM_Simon_arrow_mouse_recall_veloc_', subject, '_cursor_probe_data.mat'); 
save(cursor_data_filename_probe, 'cursor_path_probe'); 


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
