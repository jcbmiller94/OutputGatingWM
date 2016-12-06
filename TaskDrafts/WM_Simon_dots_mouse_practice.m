function WM_Simon_dots_mouse_practice
%this version uses a verbal WM cue, and an intervening symbolic cue to
%click the screen at an associated location--this is to best approximate a
%reaching movement

%%% timestamp movement onset and add to results printout 

%%
rng('default'); %sometimes, if you've recently initiated the legacy random number generator, it wont let you use rng until you reset it to default, or something
rng('shuffle');

KbName('UnifyKeyNames'); 
    
%message pops up in the command window to ask for subject number   
%subject = input('Enter SUBJECT number ', 's');

% %name of data output file 
% datafilename = strcat('MotorData/WM_Simon_dots_mouse_', subject, '.txt'); 
% 
% %if a file with that same info already exists in the data folder, give a
% %new subject #, or overwrite the existing file
% if exist(datafilename)==2
%     disp ('A file with this name already exists')
%     overwrite = input('overwrite?, y/n \n', 's');
%     if strcmpi(overwrite, 'n')
%         %disp('enter new subject number');
%         newsub = input('New SUBJECT number? ', 's');
%         datafilename = strcat('MotorData/WM_Simon_dots_mouse_', newsub, '.txt');
%     end
% end

%make a space-delimited text output file where each trial is a row
%(I just happen to like using text files, but you can output the data in
%any way that will work the best for your preferred analysis style)
% fid = fopen(datafilename, 'w');
% fprintf(fid, 'subject CurrentCondition TrialType CurrentSampleIndex CurrentSample cueColor correctResp Resp ACC msecRT move_init_msecRT CurrentProbeMatch ProbeSide correctProbeResp probeResp probeACC probemsecRT\n');

% make a cell array to hold data for tracking the cursor path 
%  in this cell array, each row is a block and each column is a trial
%  (each element being the path for that trial in that block)

cursor_path = {}; 

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
    responseDeadline = 4;
    WMProbe = 3;
    
    feedback = 1; %amount of time feedback is displayed on the screen 
    
    BlockNum = 1;
    TrialNum = 5; %orig = 24 %play around with 3 of trials in 20-25 min %40 trials per condition? 
    %adjust # of blocks and trials
    
    %change detection response keys
    matchResp = 's';
    nonmatchResp = 'd';
    
    %motor response keys
    leftResp = 'L';
    rightResp = 'R';
    upResp = 'U';
    
    leftWord = sprintf('left');
    rightWord = sprintf('right');
    
    SampleWords = [leftWord rightWord];
    %SampleSpots = [leftDots rightDots]; %possible locations of two-dot array
    
    %these RGB values were selected to be maximally different using the
    %color tool at I Want Hue
    leftRGB = [164 108 183]; %left, purple
    rightRGB = [203 106 73]; %right, orange
    upRGB = [122 164 87]; %up, green
    
    leftColor = 'purple';
    rightColor = 'orange';
    upColor = 'green';
    
    %make a vector of codes for the trial conditions    
    TrialsPer = TrialNum/2; %Divide # of trials by # of conditions, to get equal trials of each type
    TrialsPer = ceil(TrialsPer);
    
    TrialsPerCongruency = TrialNum/3;
    TrialsPerCongruency = ceil(TrialsPerCongruency);
    
    %include 3s in this vector if you want to have a neutral condition
    Condition = [ones(1, TrialsPerCongruency) 2*ones(1, TrialsPerCongruency) 3*ones(1, TrialsPerCongruency)]; % 1 = compatible, 2 = incompatible, 3 = neutral    
    ProbeMatch = [ones(1, TrialsPer) 2*ones(1, TrialsPer)];
    SampleIndex = [ones(1, TrialsPer) 2*ones(1, TrialsPer)];
    
    %determine center of screen from which to determine size and location
    %of stimuli
    h = wRect(4);
    w = wRect(3);
    centerX = wRect(3)/2;
    centerY = wRect(4)/2; 

    [screenXpixels, screenYpixels] = Screen('WindowSize', win);
    Xcenter = screenXpixels/2;
    Ycenter = screenYpixels/2;    
    
    %make spatial dot WM cues 
    
    %Make a destination rectangle for stimuli
    stimSize = 70; %orig = 100
    xcorner = centerX+stimSize;
    ycorner = centerY+stimSize;
    
    %this is the general rect size we'll use for all stims
    stimRect = [centerX centerY xcorner ycorner];
    
    %this centers it on  particular location
    centerRect = CenterRectOnPointd(stimRect, Xcenter, Ycenter);
    
    %change this to move the location of the spatial stimuli
    Xoffset = 400;   %orig = 200
    Yoffset = 400;   %orig = 200
    %can be hard-coded as a certain distance, or made a proportion of the
    %screen
%     Xoffset = screenXpixels/4;
%     Yoffset = screenYpixels/4;
    %I also have other code that can put stimuli at points along a circle
    %that are all equidistant from the center, so maybe we'll want that for
    %more advanced task versions
    
    
    leftX = Xcenter-Xoffset;
    rightX = Xcenter+Xoffset;
    topY = Ycenter-Yoffset;
    bottomY = Ycenter+Yoffset;
    
    leftRect = CenterRectOnPointd(stimRect, leftX, Ycenter);
    rightRect = CenterRectOnPointd(stimRect, rightX, Ycenter);
    topRect = CenterRectOnPointd(stimRect, Xcenter, topY);
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
    
    topX1 = Xcenter - clickBoxSize;
    topX2 = Xcenter + clickBoxSize;
    topY1 = topY - clickBoxSize;
    topY2 = topY + clickBoxSize;
    
    %width of the outline box for accepting clicks
    frameWidth = 5;
    
    %make a little rectangle to serve as the fixation point    
    fixSize = 15;
    fixX = centerX + fixSize;
    fixY = centerY + fixSize;
    fixRect = [centerX centerY fixX fixY];
    fixCenter = CenterRectOnPointd(fixRect, Xcenter, Ycenter);
    
%% Start task block loop
   
    %show instruction screen
    instructions=sprintf(['This is a practice of the experiment you will be doing\n\n\nA series of dots will appear on either the right or left side of the screen\n\n\n' ... 
        'Remember the side of the screen on which the dots appear....\n\n\n(Press space to continue)']) 
    DrawFormattedText(win, instructions, 'center', 'center', 0);
    Screen('Flip', win);    
    if IsOSX
        getKey('space', KeyBoardNum); %OSX requires a device number whereas windows requires none
    else
        getKey('space');
    end
    
    instructions=sprintf(['Four boxes will then appear, with your cursor on the middle of the screen\n\n\n Based on the color of the middle box, click one of the other boxes\n\n' ... 
    'purple: click left box\n\norange: click right box\n\ngreen: click top box\n\n\n(Press space to continue)']) 
    DrawFormattedText(win, instructions, 'center', 'center', 0);
    Screen('Flip', win);    
    if IsOSX
        getKey('space', KeyBoardNum); %OSX requires a device number whereas windows requires none
    else
        getKey('space');
    end  
     
    instructions=sprintf(['After a click, dots will appear again on the right or left side\n\n\nUse "S" (same) or "D" (different) to indicate whether this is the same side as before\n\n\n(Press space to continue)'])
    DrawFormattedText(win, instructions, 'center', 'center', 0);
    Screen('Flip', win);    
    if IsOSX
        getKey('space', KeyBoardNum); %OSX requires a device number whereas windows requires none
    else
        getKey('space');
    end  

    welcome=sprintf('Click left box for purple, right for orange, top for green\n\n\nPress "S" for same side, "D" for different\n\n\n\nPress space to begin the experiment \n \n \n');
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
        
        
    %shuffle the order of the condition vectors at the start of each block
    %for a random selection    
    Condition = Shuffle(Condition);    
    ProbeMatch = Shuffle(ProbeMatch);
    SampleIndex = Shuffle(SampleIndex);
    
        for trial = 1:TrialNum
            
            %making random two-dot arrays for L and R sides of screen 
            Lxy = zeros(2,2);
            Lxy(1,1) = w/16 + rand(1)*(6*w/16-2*w/16); % orig = w/16 + rand(1)*(7*w/16-w/16)
            Lxy(1,2) = w/16 + rand(1)*(6*w/16-2*w/16); 
            Lxy(2,1) = h/16 + rand(1)*(14*h/16-2*h/16); 
            Lxy(2,2) = h/16 + rand(1)*(14*h/16-2*h/16); 
            Lcenter = [0, 0];
            
            Rxy = zeros(2,2);
            Rxy(1,1) = 9*w/16 + rand(1)*(14*w/16-10*w/16); % orig = 9*w/16 + rand(1)*(15*w/16-9*w/16)
            Rxy(1,2) = 9*w/16 + rand(1)*(14*w/16-10*w/16); 
            Rxy(2,1) = h/16 + rand(1)*(14*h/16-2*h/16); 
            Rxy(2,2) = h/16 + rand(1)*(14*h/16-2*h/16); 
            Rcenter = [0, 0];
            
            
            %show fixation
            Screen('FillRect', win, fixColor, fixCenter);
            Screen('Flip', win);
            WaitSecs(ITI);   
            
            %choose the congruency condition for this trial
            CurrentCondition = Condition(trial);
            
            %define what sample word will be shown on this trial
            CurrentSampleIndex = SampleIndex(trial);
            
            CurrentSample = SampleWords(CurrentSampleIndex); 
            %CurrentSample = sprintf(CurrentSample);

            
            switch CurrentCondition
                case 1 %compatible
                    TrialType = 'compatible';
                    
                    if CurrentSampleIndex == 1
                       CurrentSample = leftWord;
                       CurrentMotor = leftRGB;
                       cueColor = leftColor;                    
                       correctResp = leftResp;
                        
                       xy = Lxy; %left dot array 
                       center = Lcenter;
                        
                    elseif CurrentSampleIndex == 2
                       CurrentSample = rightWord;
                       CurrentMotor = rightRGB;
                       cueColor = rightColor;
                       correctResp = rightResp;
                        
                       xy = Rxy; %Right dot array
                       center = Rcenter;
                    end 
                    
                case 2 %incompatible
                    TrialType = 'incompatible';
                    
                    if CurrentSampleIndex == 1
                        CurrentSample = leftWord;
                        CurrentMotor = rightRGB;
                        cueColor = rightColor;                       
                        correctResp = rightResp;
                        
                        xy = Lxy; %left dot array 
                        center = Lcenter;
                        
                    elseif CurrentSampleIndex == 2
                        CurrentSample = rightWord;
                        CurrentMotor = leftRGB;
                        cueColor = leftColor;                        
                        correctResp = leftResp;   
                        
                        xy = Rxy; %Right dot array
                        center = Rcenter;
                    end
                    
                case 3 %neutral
                    TrialType = 'neutral';
                    
                    if CurrentSampleIndex == 1
                        CurrentSample = leftWord; 
                        xy = Lxy; %left dot array 
                        center = Lcenter;
                    elseif CurrentSampleIndex == 2
                        CurrentSample = rightWord;
                        xy = Rxy; %Right dot array
                        center = Rcenter;
                    end
                    
                        CurrentMotor = upRGB;
                        cueColor = upColor;                        
                        correctResp = upResp;
            end

            
        %show WM sample 
        
            %DrawFormattedText(win, CurrentSample, 'center', 'center', 0);
            [minSmoothPointSize, maxSmoothPointSize, minAliasedPointSize, maxAliasedPointSize] = Screen('DrawDots', win, xy, 15, [0 0 0], center, 1);
            Screen('Flip', win);
            WaitSecs(SampleShow); 
            
            DrawFormattedText(win, '+', 'center', 'center', 0);
            Screen('Flip', win);
            WaitSecs(WMDelay);            

        %show motor cue during WM delay
        
            Screen('FillRect', win, CurrentMotor, centerRect);    
            Screen('FrameRect', win, sampleColor, leftRect, frameWidth);
            Screen('FrameRect', win, sampleColor, rightRect, frameWidth);
            Screen('FrameRect', win, sampleColor, topRect, frameWidth);
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
                    
                    %this loop will listen for clicks inside the boxes
                    %associated with the color cue
                    while enterResp==false                        
                   
                        %[~, responseX, responseY, buttons] = GetClicks(win, 0);%gives coords of each click                         
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
                                
                            elseif responseX > topX1 && responseX < topX2 && responseY > topY1 && responseY < topY2
                                enterResp = true;
                                resp = upResp;              
                                
                            % if a click surrounds the response box, but doesn't fall inside it, do nothing     
                            else enterResp=false;   
                            end                                                 
                        end
                        
                        % recording the coordinates of the cursor until the loop is broken with click inside a box 
                        [x,y,buttons] = GetMouse(win);
                        current_pos = [x, y, buttons];
                        trial_path = [trial_path; current_pos];
                        
                        %if cursor moves for the FIRST time form the
                        %center position, get the time of that movement 
                        if cursor_moved == false && isequal(current_pos(1:2),trial_path(1,1:2)) == 0
                            move_init = GetSecs;
                            cursor_moved = true;                           
                        elseif cursor_moved == true
                        else move_init = 0;
                        end 
                        
                        % break the response loop after a designated
                        % deadline
                        if GetSecs - cueStart > responseDeadline 
                            enterResp = true; 
                        end
                        
                    end
                    
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
                        
                %calculate accuracy
                Accuracy = strcmp(resp,correctResp); 
                   
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
            WaitSecs(WMDelay); 

        %show WM probe stimulus
        
            CurrentProbeMatch = ProbeMatch(trial);
            
            switch CurrentProbeMatch
                case 1 %match           
                    if CurrentSampleIndex == 1
                        ProbeSide = leftWord;
                        xy = Lxy; %left dot array 
                        center = Lcenter;
                    elseif CurrentSampleIndex == 2
                        ProbeSide = rightWord;
                        xy = Rxy; %Right dot array
                        center = Rcenter;
                    end                              
                    correctProbeResp = matchResp;
                    
                case 2 %non-match
                    if CurrentSampleIndex == 1
                        ProbeSide = rightWord;
                        xy = Rxy; %Right dot array
                        center = Rcenter;
                    elseif CurrentSampleIndex == 2
                        ProbeSide = leftWord;
                        xy = Lxy; %left dot array 
                        center = Lcenter;
                    end                  
                    correctProbeResp = nonmatchResp;
            end
            
            
            [minSmoothPointSize, maxSmoothPointSize, minAliasedPointSize, maxAliasedPointSize] = Screen('DrawDots', win, xy, 15, [0 0 0], center, 1);
            %DrawFormattedText(win, ProbeSide, 'center', 'center', 0);
            DrawFormattedText(win, '?', 'center', centerY-100, 0);
            Screen('Flip', win);
            %WaitSecs(WMProbe);            

        %collect probe response data
                probeTime = GetSecs;
   
                if IsOSX
                [probekeys, probeRT] = waitForKeys(GetSecs, WMProbe, KeyBoardNum, 1);
                else
                [probekeys, probeRT] = waitForKeys(GetSecs, WMProbe, 0, 1);
                end     

                while (GetSecs - probeTime) <= WMProbe        
                end
                     if probeRT == 0;
                        probert = 9999;
                        probeResp = 'NA';
                     else
                        probert = probeRT;
                        probeResp = num2str(probekeys(1));
                     end   

                probemsecRT = round(1000*probert);
                probemsecRT = num2str(probemsecRT); 

                probeAccuracy = strcmp(probeResp,correctProbeResp); 

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
                
                %let them know that they have completed one trial
                if trial == 1
                    DrawFormattedText(win, 'You completed one practice trial!\n\n\nNow, you will complete several trials in a row', 'center', 'center', 0);
                    Screen('Flip', win); 
                    WaitSecs(2);
                end                                
%         %add movement initiation time and data type
%         %print trial info to data file
%             fprintf(fid,'%s %i %s %d %s %s %s %s %d %s %s %i %s %s %s %d %s\n',...
%             subject,...
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
%             CurrentProbeMatch,...
%             ProbeSide,...
%             correctProbeResp,...
%             probeResp,...
%             probeACC,...
%             probemsecRT);
    
        end
    
       
    
    %kindly give participants a helpful indicator of how much more
    %excrutiating misery they have left to endure
       if block == BlockNum
           message=sprintf('You are now done with the practice \n\n\n Here, you received "correct" and "incorrect" feedback, \nbut in the real experiment you will not\n\n\nLet us know if you have any questions before the real thing! \n \n');
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
%cursor_data_filename = strcat('MotorData/WM_Simon_dots_mouse_', subject, '_cursor_data.mat'); 
%save(cursor_data_filename, 'cursor_path'); 


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
