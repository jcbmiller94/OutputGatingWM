function WM_Simon_dots_mouse_v2
%this version uses a verbal WM cue, and an intervening symbolic cue to
%click the screen at an associated location--this is to best approximate a
%reaching movement

%%% timestamp movement onset and add to results printout 

%%
rng('default'); %sometimes, if you've recently initiated the legacy random number generator, it wont let you use rng until you reset it to default, or something
rng('shuffle');

KbName('UnifyKeyNames'); 
    
%message pops up in the command window to ask for subject number   
subject = input('Enter SUBJECT number ', 's');

%name of data output file 
datafilename = strcat('MotorData/WM_Simon_dots_mouse_v2_', subject, '.txt'); 

%if a file with that same info already exists in the data folder, give a
%new subject #, or overwrite the existing file
if exist(datafilename)==2
    disp ('A file with this name already exists')
    overwrite = input('overwrite?, y/n \n', 's');
    if strcmpi(overwrite, 'n')
        %disp('enter new subject number');
        newsub = input('New SUBJECT number? ', 's');
        datafilename = strcat('MotorData/WM_Simon_dots_mouse_v2_', newsub, '.txt');
    end
end

%make a space-delimited text output file where each trial is a row
%(I just happen to like using text files, but you can output the data in
%any way that will work the best for your preferred analysis style)
fid = fopen(datafilename, 'w');
fprintf(fid, 'subject block trial CurrentCondition TrialType CurrentSampleIndex CurrentSample cueColor correctResp Resp ACC msecRT move_init_msecRT enter_box_msecRT CurrentProbeMatch ProbeSide correctProbeResp probeResp probeACC probemsecRT\n');

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
    responseDeadline = 3; %orig = 4
    WMProbe = 2; %orig = 2
    
    BlockNum = 1; %4
    TrialNum = 6; %30
    
    %change detection response keys
    matchResp = 's';
    nonmatchResp = 'd';
    
    %motor response keys
    leftResp = 'L';
    rightResp = 'R';
    %upResp = 'U';
    
    leftWord = sprintf('left');
    rightWord = sprintf('right');
    topWord = sprintf('top');
    
    SampleWords = [leftWord rightWord topWord]; %possible locations of two-dot array
    
    %these RGB values were selected to be maximally different using the
    %color tool at I Want Hue
    leftRGB = [164 108 183]; %left, purple
    rightRGB = [203 106 73]; %right, orange
    upRGB = [122 164 87]; %up, green
    
    leftColor = 'purple';
    rightColor = 'orange';
    %upColor = 'green';
    
    %make a vector of codes for the trial conditions    
    TrialsPer = TrialNum/2; %Divide # of trials by # of conditions, to get equal trials of each type
    TrialsPer = ceil(TrialsPer);
    
    TrialsPerCongruency = TrialNum/3;
    TrialsPerCongruency = ceil(TrialsPerCongruency);
    
    %include 3s in this vector if you want to have a neutral condition
    Condition = [ones(1, TrialsPerCongruency) 2*ones(1, TrialsPerCongruency) 3*ones(1, TrialsPerCongruency)] % 1 = compatible, 2 = incompatible, 3 = neutral    
    ProbeMatch = [ones(1, TrialsPer) 2*ones(1, TrialsPer)];
    SampleIndex = [ones(1, TrialsPer) 2*ones(1, TrialsPer)]; % 1 = left, 2 = right
    
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
    Xoffset = (1/2)*screenYpixels; %screenXpixels
    Yoffset = (3/4)*screenYpixels;
 
    %Make a destination rectangle for stimuli
    stimSize = 150; %orig = 100
    xcorner = centerX+stimSize;
    ycorner = centerY+stimSize;
    
    %this is the general rect size we'll use for all stims
    stimRect = [centerX centerY xcorner ycorner];
    
    %this centers it on  particular location
    centerRect = CenterRectOnPointd(stimRect, Xcenter, Yoffset);
    
    leftX = Xcenter-Xoffset;
    rightX = Xcenter+Xoffset;
    topY = Ycenter-((1/4)*screenYpixels);
    bottomY = Yoffset;
    
    leftRect = CenterRectOnPointd(stimRect, leftX, bottomY);
    rightRect = CenterRectOnPointd(stimRect, rightX, bottomY);
    topRect = CenterRectOnPointd(stimRect, Xcenter, topY);
%     bottomRect = CenterRectOnPointd(stimRect, Xcenter, bottomY);

    
    %specify the borders of the area in which we'll take mouse clicks for
    %the delay-spanning motor task
    clickBoxSize = stimSize/2;
    minX = w/2 - (clickBoxSize + Xoffset); % minimum X lcoation for random dot locations (bottom) 
    minY = (Yoffset - clickBoxSize); % minimum Y location for random dot locations (bottom)
    
    leftX1 = leftX - clickBoxSize;
    leftX2 = leftX + clickBoxSize;
    leftY1 = bottomY - clickBoxSize;
    leftY2 = bottomY + clickBoxSize;
    
    rightX1 = rightX - clickBoxSize;
    rightX2 = rightX + clickBoxSize;
    rightY1 = bottomY - clickBoxSize;
    rightY2 = bottomY + clickBoxSize;
    
    %topX1 = Xcenter - clickBoxSize;
    %topX2 = Xcenter + clickBoxSize;
    %topY1 = topY - clickBoxSize;
    %topY2 = topY + clickBoxSize;
    
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
    welcome=sprintf('Click left box for purple, right for orange \n\n\nPress "S" for same side, "D" for different\n\n\n\nPress space to begin the experiment \n \n \n');
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
    disp(ProbeMatch);
    
        for trial = 1:TrialNum
            
            %making random two-dot arrays for L and R sides of screen 
            Lxy = zeros(2,2);
            Lxy(1,1) = minX + rand(1)*(leftX2-leftX1);
            Lxy(1,2) = minX + rand(1)*(leftX2-leftX1); 
            Lxy(2,1) = minY + rand(1)*(leftY2-leftY1);
            Lxy(2,2) = minY + rand(1)*(leftY2-leftY1);   
            Lcenter = [0, 0];
            
            Rxy = zeros(2,2);
            Rxy(1,1) = (w-minX-clickBoxSize) + rand(1)*(rightX2-rightX1);
            Rxy(1,2) = (w-minX-clickBoxSize) + rand(1)*(rightX2-rightX1);
            Rxy(2,1) = minY + rand(1)*(leftY2-leftY1);
            Rxy(2,2) = minY + rand(1)*(leftY2-leftY1);
            Rcenter = [0, 0];
            
            Txy = zeros(2,2);
            Txy(1,1) = (w/2-clickBoxSize) + rand(1)*(rightX2-rightX1);
            Txy(1,2) = (w/2-clickBoxSize) + rand(1)*(rightX2-rightX1);
            Txy(2,1) = (h/4-clickBoxSize) + rand(1)*(leftY2-leftY1);
            Txy(2,2) = (h/4-clickBoxSize) + rand(1)*(leftY2-leftY1);
            Tcenter = [0, 0];
            
            
            %show fixation
            Screen('FillRect', win, fixColor, fixCenter);
            Screen('Flip', win);
            WaitSecs(ITI);   
            
            %choose the congruency condition for this trial
            CurrentCondition = Condition(trial);
            
            %define what sample word will be shown on this trial
            CurrentSampleIndex = SampleIndex(trial);
            
            %CurrentSample = SampleWords(CurrentSampleIndex); 
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

                        CurrentSample = topWord; 
                        xy = Txy;
                        center = Tcenter;

                       if CurrentSampleIndex == 1
                            CurrentMotor = leftRGB;
                            cueColor = leftColor;                        
                            correctResp = leftResp;
                       elseif CurrentSampleIndex == 2
                            CurrentMotor = rightRGB;
                            cueColor = rightColor;                        
                            correctResp = rightResp;                             
                       end                 
                    %if CurrentSampleIndex == 1
                     %   CurrentSample = leftWord; 
                      %  xy = Lxy; %left dot array 
                       % center = Lcenter;
                    %elseif CurrentSampleIndex == 2
                     %   CurrentSample = rightWord;
                      %  xy = Rxy; %Right dot array
                       % center = Rcenter;
                   % end
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
            %Screen('FrameRect', win, sampleColor, topRect, frameWidth);
            %Screen('Flip', win);
            %WaitSecs(MotorShow); 
                        
            
                    ShowCursor('Arrow');

                    %puts mouse at center--but can be weird on multi-display
                    %setups
                    SetMouse(Xcenter, Yoffset);
                    [~, cueStart] = Screen('Flip', win);

                    enterResp=false;

                    resp = 9999; %reset this variable before each response phase to avoid wonky behavior if they don't respond at all

                    trial_path = [];
                    cursor_moved = false; 
                    cursor_in_box = false; 
                    
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
                                
                            %elseif responseX > topX1 && responseX < topX2 && responseY > topY1 && responseY < topY2
                             %   enterResp = true;
                              %  resp = upResp;              
                                
                            % if a click surrounds the response box, but doesn't fall inside it, do nothing     
                            else enterResp=false;   
                            end                                                 
                        end
                        
                        % recording the coordinates of the cursor until the loop is broken with click inside a box 
                        [x,y,buttons] = GetMouse(win);
                        current_pos = [x, y, buttons];
                        trial_path = [trial_path; current_pos];
                        
                        %if cursor moves for the FIRST time from the
                        % center position, get the time of that movement 
                        if cursor_moved == false && isequal(current_pos(1:2),trial_path(1,1:2)) == 0
                            move_init = GetSecs;
                            cursor_moved = true;                           
                        elseif cursor_moved == true
                        else move_init = 0;
                        end 
                        
                        %if cursor moves into correct box for the FIRST time
                        % center position, get the time of that movement 
                        if cursor_in_box == false                          
                            if correctResp == leftResp && current_pos(1) > leftX1 && current_pos(1) < leftX2 && current_pos(2) > leftY1 && current_pos(2) < leftY2
                                enter_box = GetSecs; 
                                cursor_in_box = true; 
                            elseif correctResp == rightResp && current_pos(1) > rightX1 && current_pos(1) < rightX2 && current_pos(2) > rightY1 && current_pos(2) < rightY2
                                enter_box = GetSecs; 
                                cursor_in_box = true;                                
                            end 
                        elseif cursor_in_box ==true
                        else enter_box = 0; 
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
            WaitSecs(WMDelay); 

        %show WM probe stimulus
        
            CurrentProbeMatch = ProbeMatch(trial);
            
            
            switch CurrentProbeMatch
                case 1 %match           
                    if strcmp(CurrentSample,leftWord) == 1
                        ProbeSide = leftWord;
                        xy = Lxy; %left dot array 
                        center = Lcenter;
                    elseif strcmp(CurrentSample,rightWord) == 1
                        ProbeSide = rightWord;
                        xy = Rxy; %Right dot array
                        center = Rcenter;
                    elseif strcmp(CurrentSample,topWord) == 1
                        ProbeSide = topWord;
                        xy = Txy; %Top dot array
                        center = Tcenter;
                    end                              
                    correctProbeResp = matchResp;
                    
                case 2 %non-match
                    n = randi(2,1); 
                    if strcmp(CurrentSample,leftWord) == 1                      
                       switch n
                        case 1
                            ProbeSide = rightWord;
                            xy = Rxy; %Right dot array
                            center = Rcenter;
                        case 2
                            ProbeSide = topWord;
                            xy = Lxy; %top dot array 
                            center = Lcenter; 
                       end
                        
                    elseif strcmp(CurrentSample,rightWord) == 1
                       switch n
                        case 1
                            ProbeSide = leftWord;
                            xy = Lxy; %Left dot array
                            center = Lcenter;
                        case 2
                            ProbeSide = topWord;
                            xy = Lxy; %top dot array 
                            center = Lcenter; 
                       end
                       
                    elseif strcmp(CurrentSample,topWord) == 1
                       switch n
                        case 1
                            ProbeSide = rightWord;
                            xy =Rxy; %Right dot array
                            center = Rcenter;
                        case 2
                            ProbeSide = topWord;
                            xy = Lxy; %top dot array 
                            center = Lcenter; 
                       end
                    end                  
                    correctProbeResp = nonmatchResp;
            end
            
            
            [minSmoothPointSize, maxSmoothPointSize, minAliasedPointSize, maxAliasedPointSize] = Screen('DrawDots', win, xy, 15, [0 0 0], center, 1);
            %DrawFormattedText(win, ProbeSide, 'center', 'center', 0);
            DrawFormattedText(win, '?', 'center', centerY+100, 0);
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
                else probeACC = 0;
                end            
                
                                               
        %add movement initiation time and data type
        %print trial info to data file
            fprintf(fid,'%s %i %i %i %s %d %s %s %s %s %d %s %s %s %i %s %s %s %d %s\n',...
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
            CurrentProbeMatch,...
            ProbeSide,...
            correctProbeResp,...
            probeResp,...
            probeACC,...
            probemsecRT);
    
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
cursor_data_filename = strcat('MotorData/WM_Simon_dots_mouse_v2_', subject, '_cursor_data.mat'); 
save(cursor_data_filename, 'cursor_path'); 


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
