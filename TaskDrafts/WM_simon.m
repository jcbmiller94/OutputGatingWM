function WM_simon
%this version uses a spatial WM cue (a box on either side of the screen),
%and a delay-spanning symbolic cue (a color) associated with a response 
%that has motor implications (e.g., left, right)
%%
rng('default'); %sometimes, if you've recently initiated the legacy random number generator, it wont let you use rng until you reset it to default, or something
rng('shuffle');

KbName('UnifyKeyNames'); 
    
%message pops up in the command window to ask for subject number and current stimulation site   
subject = input('Enter SUBJECT number ', 's');

%name of data output file 
datafilename = strcat('MotorData/WM_simon_', subject, '.txt'); 

%if a file with that same info already exists in the data folder, give a
%new subject #, or overwrite the existing file
if exist(datafilename)==2
    disp ('A file with this name already exists')
    overwrite = input('overwrite?, y/n \n', 's');
    if strcmpi(overwrite, 'n')
        %disp('enter new subject number');
        newsub = input('New SUBJECT number? ', 's');
        datafilename = strcat('MotorData/WM_simon_', newsub, '.txt');
    end
end

%make a comma-delimited text output file where each trial is a row
%(I just happen to like using text files, but you can output the data in
%any way that will work the best for your preferred analysis style)
fid = fopen(datafilename, 'w');
fprintf(fid, 'subject CurrentCondition CurrentSample cueColor correctResp Resp ACC msecRT CurrentProbeMatch ProbeWord correctProbeResp probeResp probeACC probemsecRT CurrentSampleIndex\n');

%% Some PTB and Screen set-up  
AssertOpenGL;    
HideCursor;
ListenChar(2);
KbCheck; 
WaitSecs(0.1);
GetSecs;

%I use this later cause I call on some custom subfunctions that take
%need to know the keyboard number in order to receive key input
KeyBoardNum = GetKeyboardIndices; 

    Screen('Preference', 'SkipSyncTests',1); %1 skips the tests, 0 conducts them
    Screen('Preference', 'VBLTimestampingMode', 1);
    screenNumber=max(Screen('Screens')); 
    %screenNumber=1;
    
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

    ITI = 1.5;
    SampleShow = 1;
    WMDelay = 1.5;
    MotorShow = 2;
    WMProbe = 3;
    
    BlockNum = 2;
    TrialNum = 24;
    
    %change detection response keys
    matchResp = 's';
    nonmatchResp = 'd';
    
    %delay-spanning motor response keys
    leftResp = 'L';
    rightResp = 'R';
    upResp = 'U';
    
    %these RGB values were selected to be maximally different using the
    %color tool "I Want Hue"
    purpleCue = [164 108 183]; %left
    orangeCue = [203 106 73]; %right
    greenCue = [122 164 87]; %up
      
    
    %make a vector of codes for the trial conditions    
    TrialsPer = TrialNum/2;%Divide # of trials by # of conditions, to get equal trials of each type
    TrialsPer = ceil(TrialsPer);
    
    %include 3s in this vector if you want to have a neutral condition
    Condition = [ones(1, TrialsPer) 2*ones(1, TrialsPer) 3*ones(1, TrialsPer)]; % 1 = compatible, 2 = incompatible, 3 = neutral    
    ProbeMatch = [ones(1, TrialsPer) 2*ones(1, TrialsPer)];
    SampleIndex = [ones(1, TrialsPer) 2*ones(1, TrialsPer)];
        
    %determine center of screen from which to determine size and location
    %of stimuli
    centerX = wRect(3)/2;
    centerY = wRect(4)/2; 

    [screenXpixels, screenYpixels] = Screen('WindowSize', win);
    Xcenter = screenXpixels/2;
    Ycenter = screenYpixels/2;
    
    %designate the size of the spatial stimuli--here it's hard-coded as a
    %certain number of pixels, but could also be designated as a certain
    %fraction of the screen size
    stimSize = 100;
    xcorner = centerX+stimSize;
    ycorner = centerY+stimSize;
    
    
    %Specify the corners of destination rectangle for stimuli
    
    %this is the general rect size we'll use for all stims
    stimRect = [centerX centerY xcorner ycorner];
    
    %this centers it on  particular location
    centerRect = CenterRectOnPointd(stimRect, Xcenter, Ycenter);
    
    %change this to move the location of the spatial stimuli--smaller
    %number will make them farther from center, larger will make them
    %closer
    Xoffset = screenXpixels/4;
    Yoffset = screenYpixels/4;
    
    leftRect = CenterRectOnPointd(stimRect, Xcenter-Xoffset, Ycenter);
    rightRect = CenterRectOnPointd(stimRect, Xcenter+Xoffset, Ycenter);
    topRect = CenterRectOnPointd(stimRect, Xcenter, Ycenter-Yoffset);
    bottomRect = CenterRectOnPointd(stimRect, Xcenter, Ycenter+Yoffset);
    
    
    %make a little rectangle to serve as the fixation point
    fixSize = 15;
    fixX = centerX + fixSize;
    fixY = centerY + fixSize;
    fixRect = [centerX centerY fixX fixY];
    fixCenter = CenterRectOnPointd(fixRect, Xcenter, Ycenter);    
    
    SampleSpots = [leftRect rightRect];
    
    
%% Start task block loop
        
    %show instruction screen
    welcome=sprintf('Press left for purple, right for orange, up for green\n\n\nPress S for same, D for different\n\n\n\nPress space to begin the experiment \n \n \n');
    DrawFormattedText(win, welcome, 'center', 'center', 0);
    Screen('Flip', win);
   
    % Wait for a key press to advance using the custom getkey function (appended to
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
            
            %show fixation
            Screen('FillRect', win, fixColor, fixCenter);
            Screen('Flip', win);
            WaitSecs(ITI);   
            
            %choose the congruency condition for this trial
            CurrentCondition = Condition(trial);
            
            %define what sample word will be shown on this trial
            CurrentSampleIndex = SampleIndex(trial);            
            CurrentSample = SampleSpots(CurrentSampleIndex); 
            
            switch CurrentCondition
                case 1 %compatible
                    if CurrentSampleIndex == 1
                        CurrentSample = leftRect;
                        sampleLoc = 'left';
                        CurrentMotor = purpleCue;
                        cueColor = 'purple';
                        
                        correctResp = leftResp;
                        
                    elseif CurrentSampleIndex == 2
                        CurrentSample = rightRect;
                        sampleLoc = 'right';
                        CurrentMotor = orangeCue;
                        cueColor = 'orange';
                        
                        correctResp = rightResp;                        
                    end 
                    
                case 2 %incompatible
                    if CurrentSampleIndex == 1
                        CurrentSample = leftRect;
                        sampleLoc = 'left';
                        CurrentMotor = orangeCue;
                        cueColor = 'orange';
                        
                        correctResp = rightResp;
                        
                    elseif CurrentSampleIndex == 2
                        CurrentSample = rightRect;
                        sampleLoc = 'right';
                        CurrentMotor = purpleCue;
                        cueColor = 'purple';
                        
                        correctResp = leftResp;                        
                    end
                    
                case 3 %neutral
                    if CurrentSampleIndex == 1
                        CurrentSample = leftRect; 
                    elseif CurrentSampleIndex == 2
                        CurrentSample = rightRect;
                    end
                    CurrentMotor = greenCue;
                    correctResp = upResp;
            end
            
            
        %show WM sample 
        
            Screen('FillRect', win, sampleColor, CurrentSample);
            Screen('FillRect', win, fixColor, fixCenter);
            Screen('Flip', win);
            WaitSecs(SampleShow); 
            
            Screen('FillRect', win, fixColor, fixCenter);
            Screen('Flip', win);
            WaitSecs(WMDelay);            

        %show motor cue during delay
        
            Screen('FillRect', win, CurrentMotor, centerRect);       
            Screen('Flip', win);
            %WaitSecs(MotorShow); 
            
            %collect response data             
                distTime = GetSecs;
   
                if IsOSX
                [keys, RT] = waitForKeys(GetSecs, MotorShow, KeyBoardNum, 1);
                else
                [keys, RT] = waitForKeys(GetSecs, MotorShow, 0, 1);
                end     

                while (GetSecs - distTime) <= MotorShow        
                end
                     if RT == 0;
                        rt = 9999;
                        Resp = 'NA';
                     else
                        rt = RT;
                        Resp = num2str(keys(1));
                     end   

                msecRT=round(1000*rt);
                msecRT = num2str(msecRT); 
                
                %compare subject's response to the correct response to
                %calculate accuracy
                Accuracy = strcmp(Resp,correctResp); 

                if Accuracy == 1 
                    ACC = 1;
                else ACC = 0;
                end            
                       
            
            Screen('FillRect', win, fixColor, fixCenter);
            Screen('Flip', win);
            WaitSecs(WMDelay); 
            

        %show WM probe stimulus
        
            CurrentProbeMatch = ProbeMatch(trial);
            
            switch CurrentProbeMatch
                case 1 %match
                    ProbeLoc = CurrentSample;
                    
                    correctProbeResp = matchResp;
                    
                case 2 %non-match
                    if CurrentSampleIndex == 1
                        ProbeLoc = rightRect;
                        probeSide = 'right';
                    elseif CurrentSampleIndex == 2
                        ProbeLoc = leftRect;
                        probeSide = 'left';
                    end
                    
                    correctProbeResp = nonmatchResp;
            end

            Screen('FillRect', win, sampleColor, ProbeLoc);
            %DrawFormattedText(win, '+', 'center', 'center', 0);
            DrawFormattedText(win, '?', 'center', centerY-150, 0);
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

                probemsecRT=round(1000*probert);
                probemsecRT = num2str(probemsecRT); 

                probeAccuracy = strcmp(probeResp,correctProbeResp); 

                if probeAccuracy == 1 
                    probeACC = 1;
                else probeACC = 0;
                end            
                               

        %print trial info to data file
            fprintf(fid,'%s %i %s %s %s %s %d %s %i %s %s %s %d %s %d\n',...
            subject,...
            CurrentCondition,...
            sampleLoc,...
            cueColor,...
            correctResp,...
            Resp,...
            ACC,...
            msecRT,...
            CurrentProbeMatch,...
            probeSide,...
            correctProbeResp,...
            probeResp,...
            probeACC,...
            probemsecRT,...
            CurrentSampleIndex);
    
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
