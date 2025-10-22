% HALIP task
% quick matlab implementation for demo purposes (not precise)
% TO HU Berlin 2025

close all force
clear all

%task settings
fs=192000;             %sampling rate
signal_time = 0.5;     %in seconds
noise_time = 20;       %max noise presentation time for each trial in seconds
data.nTrials=200;      %max, can be terminated earlier
signal_max_volume=60;  %dB SPL but arbitrary
noise_volume=40;       %dB SPL but arbitrary
data=struct(); %initialize data struct

%prestim delay dist
pre_stim_delay_min=0.1;
pre_stim_delay_max=0.5;
pre_stim_delay_tau=0.2;
pre_stim_delay_dist = makedist('Exponential','mu',pre_stim_delay_tau);
data.pre_stim_delay_dist = truncate(pre_stim_delay_dist,pre_stim_delay_min,pre_stim_delay_max);

%generate signal of varying strength
%note: usually full random loudness between 0 and MAX,
%      but here precalculate to save time during running trials
data.nSNR=10;
VOL = linspace(0,signal_max_volume,data.nSNR); %dB SPL
signal=zeros(data.nSNR,2,fs*signal_time);
AUDIOPLAYERS_SIGNAL=cell(1,data.nSNR);
for k=1:data.nSNR
    vol=VOL(k);%dB SPL
    signal(k,:,:)=GenerateSignal(vol,fs);
    data.audioplayers_signal{k}=audioplayer(squeeze(signal(k,:,:)),fs);
end

%generate noise
noise = GenerateNoise(noise_volume,fs,noise_time);
%noise player
data.noise_player = audioplayer(noise,fs);

%set up GUI
h_fig=uifigure('Color',[1,1,1],'Units','normalized','Position',[0.3,0.3,0.3,0.3]);
set(h_fig,'KeyPressFcn',@f_key_press);
handles.h_fig=h_fig;
handles.h_feedback=uicontrol(handles.h_fig ,'Style','text','String','','Units','normalized','Position',[0.4,0.2,0.2,0.2],'BackgroundColor',[1,1,1],'FontWeight','bold','FontSize',18);
handles.h_question=uicontrol(handles.h_fig ,'Style','text','String','','Units','normalized','Position',[0.25,0.5,0.5,0.2],'BackgroundColor',[1,1,1],'FontSize',15);
handles.h_trial_count=uicontrol(handles.h_fig ,'Style','text','String','0','Units','normalized','Position',[0.01,0.01,0.05,0.05],'BackgroundColor',[1,1,1]);
handles.h_signal_cue=uicontrol(handles.h_fig ,'Style','text','String','','Units','normalized','Position',[0.45,0.8,0.1,0.15],'BackgroundColor',[.7,.7,.7]);
handles.input_state = 0; %0=no reaction to button press

%initialize data 
data.signal_trial=nan(data.nTrials,1);
data.signal_level=nan(data.nTrials,1);
data.choice=nan(data.nTrials,1);
data.confidence=nan(data.nTrials,1);
data.correct=nan(data.nTrials,1);

%run trials
data.trial=0;
handles.data=data;
guidata(handles.h_fig, handles)
next_trial_state(handles.h_fig);


function f_key_press(obj,eventdata)
handles = guidata(obj);
input_state=handles.input_state;
data=handles.data;
% disp(['input_state=',num2str(input_state)]);
switch input_state
    case 0
        %don't react to input
    case 1
        %choice input received
        trial = data.trial;
        choice = str2double(eventdata.Key);
        handles.h_question.String='';
        if ismember(choice,[1,0])
            data.choice(trial)=choice;
            %contine to confidence input
            handles.data=data;
            guidata(obj, handles)
            confidence_state(obj);
        else
            data.choice(trial)=NaN;
            handles.h_feedback.String='Invalid response!';
            handles.data=data;
            guidata(obj, handles)
            next_trial_state(obj);
        end
    case 2
        %confidence input received
        trial = data.trial;
        confidence = str2double(eventdata.Key);
        handles.h_question.String='';
        if ismember(confidence,[1,2,3,4,5])
            data.confidence(trial)=confidence;
            %provide feedback about outcome
            if data.choice(trial)==data.signal_trial(trial)
                data.correct(trial)=1;
                handles.h_feedback.String='CORRECT!';
            else
                data.correct(trial)=0;
                handles.h_feedback.String='WRONG!';
            end
        else
            data.confidence(trial)=NaN;
            handles.h_feedback.String='Invalid confidence!';
        end
        %continue to next trial state
        handles.data=data;
        guidata(obj, handles)        
        next_trial_state(obj);
    case 3
        %next trial input received
        key = eventdata.Key;
        if strcmpi(key,'x')
            stop(handles.data.noise_player);
            save('HALIPDATA.mat','data')
            fprintf('Task terminated. Data saved in HALIPDATA.mat.\n')
            close(obj)
            return
        else
        %ITI
        handles.h_question.String='';
        handles.h_feedback.String='';
        pause(0.5);
        %next trial
        handles.data=data;
        guidata(obj, handles)        
        start_trial(obj);
        end
end
end

function start_trial(obj)
handles = guidata(obj);
data=handles.data;
input_state = 0;
if data.trial>=data.nTrials
    stop(handles.data.noise_player);
    save('HALIPDATA.mat','data')
    fprintf('Task terminated. Data saved in HALIPDATA.mat.\n')
    return
else
    %trial count 
    data.trial = data.trial+1;
%     disp(['trial=',num2str(data.trial)]);
    handles.h_trial_count.String=num2str(data.trial);
    handles.data=data;
    handles.input_state=input_state;
    guidata(obj, handles)

    %start signal state
    signal_state(obj);
end
end

function signal_state(obj)
handles = guidata(obj);
data=handles.data;

%pre stim delay
pre_stim_delay=random(data.pre_stim_delay_dist);
pause(pre_stim_delay);

trial = data.trial;
    %determine if signal trial or not
    if rand(1,1)<0.5
        %signal trial
        data.signal_trial(trial)=1;
        idx_snr = randi(data.nSNR);
        data.signal_level(trial)=idx_snr;
        %play back signal
        handles.h_signal_cue.BackgroundColor=[.8,.2,.2];
        play(data.audioplayers_signal{idx_snr});
    else
        %no-signal trial
        handles.h_signal_cue.BackgroundColor=[.8,.2,.2];
        data.signal_trial(trial)=0;
        data.signal_level(trial)=0;  
    end
    pause(0.5);
    handles.h_signal_cue.BackgroundColor=[.7,.7,.7];

    handles.input_state = 1; %wait for choice input
    handles.h_question.String="Did you hear a signal? (1=yes, 0=no)";
    handles.data=data;
    guidata(obj, handles)
end

function confidence_state(obj)
handles = guidata(obj);
handles.h_question.String='How confidence are you? (1=low, 5=high)';
handles.input_state=2; %wait for confidence input
guidata(obj, handles)
end

function next_trial_state(obj)
handles = guidata(obj);
stop(handles.data.noise_player);
play(handles.data.noise_player);
handles.h_question.String='Press any key to to continue, press x to terminate.';
handles.input_state = 3; %wait for next trial ipnut
guidata(obj, handles)
end