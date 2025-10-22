function signal=GenerateSignal(vol,fs)

%% abbreviate variable names and clip impossible values for better handling
SamplingRate=fs;
SignalRamp=0.05; %UPDATE HERE IF NO NOISE IS USED
SignalDuration=0.5;
SignalForm='LinearUpsweep';
SignalMinFreq=100;
SignalMaxFreq=200;
SignalVolume=vol;

%make signalclose all

t=linspace(0,SignalDuration,[SamplingRate*SignalDuration]); %time vector for chirp
switch SignalForm
    case 'LinearUpsweep'
        signal=chirp(t,SignalMinFreq,SignalDuration,SignalMaxFreq);
        freqvec=SignalMinFreq+(SignalMaxFreq-SignalMinFreq)*t;
    case 'LinearDownsweep' %gaussian noise from mean 0 std .25
        signal=chirp(t,SignalMaxFreq,SignalDuration,SignalMinFreq);
        freqvec=SignalMaxFreq+(SignalMinFreq-SignalMaxFreq)*t;
    case 'QuadraticConvex'
        tnew=t-mean(t);
        signal=chirp(tnew,SignalMinFreq,SignalDuration./2,SignalMaxFreq,'quadratic',[],'convex'); %make chirp
        freqvec=SignalMinFreq+(SignalMaxFreq-SignalMinFreq)./tnew(1)*tnew.^2;
end

signal=[signal;signal];

%pseudo calibration
for s=1:2 %loop over two speakers
    toneAtt = 0.5*ones(size(freqvec)); %pseudocalibration curve
    diffSPL = SignalVolume - 60;
    attFactor = sqrt(10.^(diffSPL./10)); %sqrt(10.^(diffSPL./10)) in Torben's script WHY sqrt?
    att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
    signal(s,:)=signal(s,:).*att; %should the two speakers dB be added?
end

%put an envelope to avoide clicking sounds at beginning and end
omega=(acos(sqrt(0.1))-acos(sqrt(0.9)))/(SignalRamp/pi*2); % This is for the envelope with Ramp duration duration
t=0 : (1/SamplingRate) : pi/2/omega;
t=t(1:(end-1));
RaiseVec= (cos(omega*t)).^2;

Envelope = ones(length(signal),1); % This is the envelope
Envelope(1:length(RaiseVec)) = fliplr(RaiseVec);
Envelope(end-length(RaiseVec)+1:end) = (RaiseVec);

signal = signal.*Envelope';
