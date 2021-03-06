%% test
clear; home;

Fs=16000;
F0=200;
dur_sec=.1;
t=1/Fs:1/Fs:dur_sec;
input=sin(2*pi*F0*t)';

OALevel_dBSPL=10;
ANmodel_Fs_Hz=100000;
CF_kHz=F0/1000;
Cohc=1;
Cihc=1;
SR_sps=50;
Nreps=120;

% Resample for AN model
dBSPL_before=20*log10(sqrt(mean(input.^2))/(20e-6));
sfreq=Fs;
sfreqNEW=ANmodel_Fs_Hz;
P=round(sfreqNEW/10); Q=round(sfreq/10);  %Integers used to up sample
if(P/Q*sfreq~=sfreqNEW), disp('Integer sfreq conversion NOT exact'); end
Nfir=30;  % proportional to FIR filter length used for resampling: higher Nfir, better accuracy & longer comp time
input_model=resample(input,P,Q,Nfir);
dBSPL_after=20*log10(sqrt(mean(input_model.^2))/(20e-6));
if abs(dBSPL_before-dBSPL_after)>2;
    error(sprintf('RESAMPLING CHANGED input dBSPL by %f dB',dBSPL_after-dBSPL_before))
end

adjustment = max(OALevel_dBSPL-dBSPL_after,-dBSPL_after);
input_model = input_model*10^((adjustment)/20);

% REFIT and WINDOWwavefile at ANmodel_Fs
% Repeat or truncate waveform to fit requested stimulus duration:
input_model = refit_waveform(input_model,ANmodel_Fs_Hz,dur_sec*1000);
% Window waveform using linear rise/fall:
input_model = window_waveform(input_model,ANmodel_Fs_Hz,dur_sec*1000);         

% Run fiber (A+)
[timeout,meout,c1filterout,c2filterout,c1vihc,c2vihc,vihc,sout,psth500k] ...
    = zbcatmodel(input_model.',CF_kHz*1000,1,1/ANmodel_Fs_Hz,dur_sec+0.05,Cohc,Cihc,SR_sps);
[sptimes nspikes]= SGfast([1/ANmodel_Fs_Hz, Nreps],sout);
% Format spikes into NEL spikes format then cell array
NELspikes=ANmodelSTs2nel(sptimes,Nreps);
SpikeTrainsA_plus=nelSTs2cell(NELspikes);

% Run fiber (A-)
[timeout,meout,c1filterout,c2filterout,c1vihc,c2vihc,vihc,sout,psth500k] ...
    = zbcatmodel(-input_model.',CF_kHz*1000,1,1/ANmodel_Fs_Hz,dur_sec+0.05,Cohc,Cihc,SR_sps);
[sptimes nspikes]= SGfast([1/ANmodel_Fs_Hz, Nreps],sout);
% Format spikes into NEL spikes format then cell array
NELspikes=ANmodelSTs2nel(sptimes,Nreps);
SpikeTrainsA_minus=nelSTs2cell(NELspikes);

% Calculate env & tfs coding
% Spike Analysis
% Organize variables for CCCanal
SpikeTrains=cell(2); % {condition (1,2), polarity (plus,minus)}
SpikeTrains={SpikeTrainsA_plus,SpikeTrainsA_minus;SpikeTrainsA_plus,SpikeTrainsA_minus};

% specify params to be used
clear paramsIN
paramsIN.durA_msec=dur_sec*1000;
paramsIN.durB_msec=dur_sec*1000;
paramsIN.CF_Hz=CF_kHz*1000;

[SACSCCfunctions,SACSCCmetrics,paramsOUT] = CCCanal(SpikeTrains,paramsIN,0);

disp(sprintf('difcor = %f',SACSCCmetrics.DCpeak_A));
disp(sprintf('sumcor = %f',SACSCCmetrics.SCpeak_A));
