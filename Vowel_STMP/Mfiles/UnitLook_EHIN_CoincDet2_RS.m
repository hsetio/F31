function UnitLook_EHIN_CoincDet2(UnitName)
% File: UnitLook_EHIN_CoincDet2.m
% updated: Jun 19, 2009 - from UnitLook_EHIN_CoincDet2_MH2.m (Reiri Sono)
%
% This version loops through all non-self freq pairs in yTemp.(each
% feature){harm, pol}, instead of just one pair, to calculate SCC.
% Then it finds SAC from the same pool of freqs to compute rho = SCC /
% sqrt(SAC_Freq1 * SAC_Freq2).
%
% This is specifically designed for EHINvNrBFi template used on 041805 (and 071305) and
% the conditions used there (4 noise attens, F1 and T1, 10 BF shifts)
%
% UnitName: '1.29' (converted later)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all

% PRINTyes=input('Do you want to print figures automatically ([0]: no; 1: yes)?? ');
% if isempty(PRINTyes)
PRINTyes=0;
% end

doSCC=1;


global ROOT_dir 
global SavedPICS SavedPICnums SavedPICSuse
global FeaturesText FormsAtHarmonicsText InvertPolarityText
SavedPICSuse=1; SavedPICS=[]; SavedPICnums=[];

path(fullfile(ROOT_dir,'MFiles','NewMfiles'),path)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PICK 04_18_05 or 071305 is Experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ExpDate='041805';  % HARDCODE
%ExpDate='071305';  % HARDCODE
if strcmp(ExpDate,'041805')
	eval(['cd ''' fullfile(ROOT_dir,filesep,'ExpData',filesep,'MH-2005_04_18-ANnorm') ''''])
elseif strcmp(ExpDate,'071305')
	eval(['cd ''' fullfile(ROOT_dir,filesep,'ExpData',filesep,'MH-2005_07_13-ANdeafcat') ''''])
else
	error('BAD dir')
end
%%%% Find the full Experiment Name
[p,ExpName,e,v]=fileparts(pwd);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data_dir=fullfile(ROOT_dir,'ExpData',ExpName);
unitdata_dir=fullfile(data_dir,'UNITSdata');
data_dir_bak = data_dir;  % backup in case it is overwritten by mat file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Verify parameters and experiment, unit are valid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('UnitName','var')
	UnitName=0;
	%%% HARD CODE FOR NOW
	UnitName='2.04';
	beep;  disp(sprintf('\n    **** HARD CODING Unit: %s ****',UnitName));
% 	while ~ischar(UnitName)
% 		UnitName=input('Enter Unit Name (e.g., ''1.29''): ');
% 	end
end

%%%% Parse out the Track and Unit Number
TrackNum=str2num(UnitName(1:strfind(UnitName,'.')-1));
UnitNum=str2num(UnitName(strfind(UnitName,'.')+1:end));


% LOAD CALCS if available to speed up figure design
SAVECALCSfilename=sprintf('UnitLook_EHIN.%d.%02d.mat',TrackNum,UnitNum);
loadBOOL=0;
if exist(fullfile(unitdata_dir,SAVECALCSfilename),'file')
	loadBOOL=input('Do you want to load the existing calculations for plotting (0: no; [1]: yes)?? ');
% 	loadBOOL=1;
	if isempty(loadBOOL)
		loadBOOL=1;
	end
	if loadBOOL
		disp(sprintf('Loading ''%s'' with all calculations already done!!',SAVECALCSfilename))
		thisPRINTyes=PRINTyes;
		eval(['load ''' fullfile(unitdata_dir,SAVECALCSfilename) ''''])
		PRINTyes=thisPRINTyes;
	end
end

if ~loadBOOL
	global DataList
	if isempty(DataList)
		if strcmp(ExpDate,'041805')
			%%% Load DataList for 041805
			disp(' ... Loading DataList for 04_18-05');
			load DataList_2005_04_18
		elseif strcmp(ExpDate,'071305')
			%%% Load DataList for 071305
			disp(' ... Loading DataList for 07_13-05');
			load DataList_2005_07_13
		end
	end
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%%%% Verify that there is data for this unit
	if isempty(DataList.Units{TrackNum,UnitNum})
		error('NO DATA FOR THIS UNIT!!');
	end
	Datafields=fieldnames(DataList.Units{TrackNum,UnitNum});
	if ~sum(strcmp(Datafields,{'EHrlv'}))
		error('NO ''EHrlv'' DATA FOR THIS UNIT, THEREFORE STOPPING!!');
	end

end

data_dir = data_dir_bak;  % restore in case it was overwritten my mat file
cd(data_dir)
disp(sprintf('Looking at Basic EHIN for Experiment: ''%s''; Unit: %d.%02d',ExpName,TrackNum,UnitNum))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Verify UNITSdata/unit analyses are all done ahead of time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~loadBOOL
	%%%% Load unit structure for this unit
	UnitFileName=sprintf('unit.%d.%02d.mat',TrackNum,UnitNum);
	eval(['ddd=dir(''' fullfile(unitdata_dir,UnitFileName) ''');'])
	% If UNITSdata file does not exist, load create from DataList, ow/ load it
	if isempty(ddd)
		unit=DataList.Units{TrackNum,UnitNum};
		eval(['save ''' fullfile(unitdata_dir,UnitFileName) ''' unit'])
	else
		eval(['load ''' fullfile(unitdata_dir,UnitFileName) ''''])
	end

	% If EHINvNreBFi_simFF analysis is not completed, run here (this will also
	% check EHINvNreBFi analysis and run if needed!)
	if ~isfield(unit,'EHvN_reBF_simFF')
		UnitAnal_EHvNrBF_simFF(ExpDate,UnitName,0);
		eval(['load ''' fullfile(unitdata_dir,UnitFileName) ''''])
	end
end

% Make sure TC is verfified (i.e., Q10 known)
if isempty(unit.Info.Q10)
	UnitVerify_TC(ExpDate,UnitName);
	eval(['load ''' fullfile(unitdata_dir,UnitFileName) ''''])
else
	UnitVerify_TC(ExpDate,UnitName,1);  % JUST PLOT
end
set(gcf,'Name',sprintf('TC for Unit: %s',UnitName),'NumberTitle','off')
set(gcf,'Units','norm','pos',[-0.00078125 0.74707 0.220313 0.201172],'Resize','off')

if ~loadBOOL
	% Make sure SR is estimated
	if isempty(unit.Info.SR_sps)
		UnitCalc_SR(ExpDate,UnitName);
		eval(['load ''' fullfile(unitdata_dir,UnitFileName) ''''])
	end

	%%%% Get CalibPic
	CalibPic=unique(DataList.CALIB.CalibFile_ToUse(findPics('*',[1,1])));
	if length(CalibPic)~=1
		error('CALIB Pic not determined for this unit - SEE DataList')
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Show EHrlfs for this unit
EHrlf_piclist=findPics('EHrlv',[TrackNum UnitNum]);
% quick_EHrlfs(EHrlf_piclist,CalibPic)
plot_EHrlfs(EHrlf_piclist,CalibPic)

EHrlf_FIG=gcf;
set(EHrlf_FIG,'Name',sprintf('EHrlfs for Unit: %s',UnitName))
set(EHrlf_FIG,'NumberTitle','off')
YLIMITS_EHrlf=ylim;
OLDtitle=get(get(gca,'Title'),'String');
title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s', ...
	ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,OLDtitle), ...
	'units','norm')

% Label L_EH - tone level for rest of data
EHINrlf_piclist=findPics('EHINrlv',[TrackNum UnitNum]);
if ~isempty(EHINrlf_piclist)
	x=loadPic(EHINrlf_piclist(1));
	VOWELlevel_dBSPL=x.Stimuli.Condition.Level_dBSPL;
	plot(VOWELlevel_dBSPL*ones(2,1),[0 1000],'k:')
	text(VOWELlevel_dBSPL,0,'L_{EH}','HorizontalAlignment','center','VerticalAlignment','bottom')
	text(.95,.25,sprintf('Vowel Level = %.f dB SPL',VOWELlevel_dBSPL),'HorizontalAlignment','right','units','norm')
end

set(EHrlf_FIG,'units','norm','pos',[-0.0008    0.4043    0.2188    0.2588],'Resize','off')
clear x

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Show EHINrlfs for this unit
% quick_EHINrlfs(EHINrlf_piclist,CalibPic)
dBAtt_2_SNR = plot_EHINrlfs(EHINrlf_piclist,CalibPic);

EHINrlf_FIG=gcf;
set(EHINrlf_FIG,'Name',sprintf('EHINrlfs for Unit: %s',UnitName))
set(EHINrlf_FIG,'NumberTitle','off')
YLIMITS_EHINrlf=ylim;
OLDtitle=get(get(gca,'Title'),'String');
title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s', ...
	ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,OLDtitle), ...
	'units','norm')

% Label A_N - noise Atten for rest of data
EHvNreBFi_piclist=findPics('EHvNrBFi',[TrackNum UnitNum]);
if ~isempty(EHvNreBFi_piclist)
	x=loadPic(EHvNreBFi_piclist(1));
	SNR_dB=x.Stimuli.Condition.NoiseAttens_dB(3)+dBAtt_2_SNR;
	plot(SNR_dB*ones(2,1),[0 1000],'k:')
	plot(SNR_dB*ones(2,1)-10,[0 1000],'k:')
	plot(SNR_dB*ones(2,1)+10,[0 1000],'k:')
	text(SNR_dB,0,'SNR_{N}','HorizontalAlignment','center','VerticalAlignment','bottom')
	text(.95,.25,sprintf('Signal-to-Noise Ratio = %.f dB',SNR_dB),'HorizontalAlignment','right','units','norm')
end

set(EHINrlf_FIG,'units','norm','pos',[-0.0008    0.0684    0.2188    0.2588],'Resize','off')
ymax=max([YLIMITS_EHrlf(2) YLIMITS_EHINrlf(2)]);
set(0,'CurrentFigure',EHrlf_FIG)
ylim([0 ymax])
set(0,'CurrentFigure',EHINrlf_FIG)
ylim([0 ymax])

if isempty(EHvNreBFi_piclist)
	return;
end
clear x


if ~loadBOOL
	%%% Hardcode for NOW
	HarmonicsIND=1;
	PolarityIND=1;

	%%%% Find number of features to plot (tone, F1, T1, ...)
	%%%% Find all levels and BFs to plot
	NUMcols=4;
	NUMrows=2;
	Nattens_dB=[]; BFsTEMP_kHz=[];
	if isfield(unit,'EHvN_reBF_simFF')
		EHfeats=fieldnames(unit.EHvN_reBF);
		inds=find(~strcmp(EHfeats,'interleaved'))';
		for FeatIND=inds   % eliminate 'interleaved' field
			FeatINDs(FeatIND)=find(strcmp(FeaturesText,EHfeats{FeatIND}));
		end
		FeatINDs=FeatINDs(find(FeatINDs~=0));

		F0min=Inf;
		for FeatIND=FeatINDs
			eval(['yTEMP=unit.EHvN_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
			if ~isempty(yTEMP)

				Nattens_dB=union(Nattens_dB,yTEMP.Nattens_dB);
				if FeatIND==FeatINDs(1)
					FeatureLevels_dB=yTEMP.FeatureLevels_dB;
				else
					if sum(FeatureLevels_dB(~isnan(FeatureLevels_dB))-yTEMP.FeatureLevels_dB(~isnan(yTEMP.FeatureLevels_dB)))
						error('FeatureLevels_dB do not match across Features for this unit');
					end
				end
				BFsTEMP_kHz=union(BFsTEMP_kHz,yTEMP.BFs_kHz);
				% Find minimum F0 for PERhist XMAX
				for i=1:length(yTEMP.FeatureFreqs_Hz)
					if ~isempty(yTEMP.FeatureFreqs_Hz{i})
						if yTEMP.FeatureFreqs_Hz{i}(1)<F0min
							F0min=yTEMP.FeatureFreqs_Hz{i}(1);
						end
					end
				end
			end
		end
	end
	lowBF=min(BFsTEMP_kHz);
	highBF=max(BFsTEMP_kHz);
	clear BFsTEMP_kHz;
	TFiltWidth=1;   % What is a good number here?? is 1 OK, ow, you get major smoothing for low F0, and not much smoothing for high F0s

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%% DO ALL CALCS (BEFORE PLOTTING), e.g., PERhists, DFTs, SCCs, ...
	%%%%   - runs through all BFs, levels and saves ALL calcs prior to PLOTTING (allows amart plotting based on ALL data)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	BFs_kHz=cell(NUMrows,length(Nattens_dB));
	PERhists=cell(NUMrows,length(Nattens_dB));
	PERhists_Smoothed=cell(NUMrows,length(Nattens_dB));
	PERhistXs_sec=cell(NUMrows,length(Nattens_dB));  % for plotting
	DFTs=cell(NUMrows,length(Nattens_dB));
	DFTfreqs_Hz=cell(NUMrows,length(Nattens_dB));
	Nsps=cell(NUMrows,length(Nattens_dB));
	Rates=cell(NUMrows,length(Nattens_dB));
	Synchs=cell(NUMrows,length(Nattens_dB));
	Phases=cell(NUMrows,length(Nattens_dB));
	PERhistsMAX=0;
	PERhistsYCHANS=0;
	DFTsMAX=0;
	SMP_rate=cell(1,length(Nattens_dB));
	for ATTind=1:length(Nattens_dB)
		SMP_rate{ATTind}=NaN*ones(1,length(FeaturesText));
	end
	ALSRs=cell(NUMrows,length(Nattens_dB));
	SMP_alsr=cell(1,length(Nattens_dB));
	for ATTind=1:length(Nattens_dB)
		SMP_alsr{ATTind}=NaN*ones(1,length(FeaturesText));
	end

	if doSCC
		%%%% SCC variables and params
		% Changed 16Feb2005 for ARO2005
		numSCCs=0; %later set to max #of SCCs
		% SCC_octOFFSET=0.25; parameter of the offset between BF and other AN fiber

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%% 12/31/05 Tried going after PO, by allowing SCCs between any 2
		%% channels
		% ASSUME OFFSET1 is below OFFSET2
		SCC_octOFFSET1=NaN; %previously -0.05; % parameter of the offset between lower BF and Nominal BF
		SCC_octOFFSET2=NaN; %previously 0.05; % parameter of the offset between higher BF and Nominal BF
        
		if 	(~isnan(SCC_octOFFSET1) && ~isnan(SCC_octOFFSET2)) && SCC_octOFFSET1>SCC_octOFFSET2
			error('SCC OFFSET 1 > OFFSET2')
		end
		disp(sprintf('   *** SCC_octOFFSET1 = %.3f',SCC_octOFFSET1))
		disp(sprintf('   *** SCC_octOFFSET2 = %.3f',SCC_octOFFSET2))

		clear paramsIN
		paramsIN.SCC.StartTime_sec=.02;  % Take 20-400(scaled to higher BF TimeFact) ms as stimulus window
		paramsIN.SCC.EndTime_sec=.400; % scaled for each BF_Hz later
	%	disp(sprintf('   * SCC window: %.3f - %.3f sec',paramsIN.SCC.StartTime_sec,paramsIN.SCC.EndTime_sec))
	
		paramsIN.SCC.DELAYbinwidth_sec=50e-6;  % 50e-6 is what Joris used
		%paramsIN.SCC.Duration_sec=paramsIN.SCC.EndTime_sec-paramsIN.SCC.StartTime_sec;

		NSCCs=cell(NUMrows,length(Nattens_dB));
        NSCCs_sps=cell(NUMrows,length(Nattens_dB));
		NSCC_delays_usec=cell(NUMrows,length(Nattens_dB));
		NSCC_BFs_kHz=cell(NUMrows,length(Nattens_dB));
		NSCC_avgrates=cell(NUMrows,length(Nattens_dB));
		NSCC_nsps=cell(NUMrows,length(Nattens_dB));
		NSCC_CDs_usec=cell(NUMrows,length(Nattens_dB));
		NSCC_peaks=cell(NUMrows,length(Nattens_dB));
		NSCC_0delay=cell(NUMrows,length(Nattens_dB));
        NSCC_Rho=cell(NUMrows,length(Nattens_dB));
		NSCC_ARBdelay=cell(NUMrows,length(Nattens_dB));
		SCCsMAX=0;
        NSACs=cell(NUMrows,length(Nattens_dB));
        NSACs_sps=cell(NUMrows,length(Nattens_dB));
		NSAC_delays_usec=cell(NUMrows,length(Nattens_dB));
        NSAC_BFs_kHz=cell(NUMrows,length(Nattens_dB));
        NSAC_avgrates=cell(NUMrows,length(Nattens_dB));
        NSAC_nsps=cell(NUMrows,length(Nattens_dB));
		NSAC_CDs_usec=cell(NUMrows,length(Nattens_dB));
		NSAC_peaks=cell(NUMrows,length(Nattens_dB));
	end
	
	for ATTEN=Nattens_dB
		% beep
		% disp('***** HARD CODED FOR ONLY 1 (highest) ATTEN *****')
		% for ATTEN=Nattens_dB(end)
		ROWind=0;

		%%%%%%%%%%%%%%%%%%%% EH_reBF Calcs
		if isfield(unit,'EHvN_reBF_simFF')
			for FeatIND=FeatINDs
				ROWind=ROWind+1;
				eval(['yTEMP=unit.EHvN_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
				if ~isempty(yTEMP)
					%%%% EH_reBF plots
					ATTind=find(yTEMP.Nattens_dB==ATTEN);
					PERhists{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
					PERhistXs_sec{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));

					%%%% Decide which BFs needed for SCCs
					[y,BF_INDEX]=min(abs(yTEMP.BFs_kHz-unit.Info.BF_kHz));  % Finds index of BF from unit.Tone_reBF_simFF.BFs_kHz
					if doSCC
						SCC_allBFinds=[]; % Lists all BFinds needed for SCCs

						% 12/31/05 - added offfset1 and 2
						% OLD XXXSCC is between BF+SCC_octOFFSET and BF-SCC_octOFFSET octaves
						SCCind=1;% index of SCC to calculate
						%yTEMP is already sorted in descending order of frequencies.
                        BFind_min = length(yTEMP.BFs_kHz); %BF index for smallest BF
                        BFind_max = 1; %BF index for largest BF
                        if ~isnan(SCC_octOFFSET1)
    						[y,BFind_min]=min(abs(yTEMP.BFs_kHz-unit.Info.BF_kHz*2^SCC_octOFFSET1));
                        end
                        if ~isnan(SCC_octOFFSET2)
    						[y,BFind_max]=min(abs(yTEMP.BFs_kHz-unit.Info.BF_kHz*2^SCC_octOFFSET2));  % ASSUMES BFind2<BFind1
                        end

						if ~isnan(SCC_octOFFSET1) && ~isnan(SCC_octOFFSET2)...
                        && (abs(log2(yTEMP.BFs_kHz(BFind_max)/yTEMP.BFs_kHz(BFind_min))-(SCC_octOFFSET2-SCC_octOFFSET1))>0.03)
							beep
							disp('*** WARNING ***: The two BFs used for the SCC (BF+SCC_octOFFset2 & BF+SCC_octOFFset1) are more than 0.03 octaves different than the desired distance')
                        end
                        
                        for BFind1 = BFind_min:-1:BFind_max
                            for BFind2 = (BFind1-1):-1:BFind_max
        						NSCC_BFinds{SCCind}=[BFind1 BFind2];%BFind1 should be > BFind2 for BF1 to be < BF2
                				SCC_allBFinds=[SCC_allBFinds NSCC_BFinds{SCCind}];
                    			% Tally all BFs needed. Will be redundant if SCC_octOFFSETs are both set to NaN
                				SCC_allBFinds=unique(SCC_allBFinds);                                
                                SCCind = SCCind+1;
                            end
						end
						if numSCCs~=0 && numSCCs~=length(NSCC_BFinds)
							fprintf('warning: #SCCs is not constant across Features. previously %d, now %d. Taking the bigger one...',numSCCs,length(NSCC_BFinds))
						end
						numSCCs=max([numSCCs,length(NSCC_BFinds)]);
						
						SCC_allSpikeTrains=cell(size(yTEMP.BFs_kHz));  % Store Spike Trains (driven spikes), but only those we need for computing SCCs later
                        NSACs{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
                        NSACs_sps{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
                        NSAC_delays_usec{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
                        NSAC_BFs_kHz{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
                        NSAC_avgrates{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
                        NSAC_nsps{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
                        NSAC_CDs_usec{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
                        NSAC_peaks{ROWind,ATTind}=cell(size(yTEMP.BFs_kHz));
					end
					
					for BFind=1:length(yTEMP.BFs_kHz)
						if ~isempty(yTEMP.picNums{ATTind,BFind})

							PIC=concatPICS_NOHR(yTEMP.picNums{ATTind,BFind},yTEMP.excludeLines{ATTind,BFind});
							% Shift spikes and frequencies to simulate shifted-BF neuron with stimulus at nominal-BF
							PIC=simFF_PICshift(PIC);
							PIC=calcSynchRate_PERhist(PIC);  % Calculates PERIOD histogram as well

							BFs_kHz{ROWind,ATTind}(BFind)=yTEMP.BFs_kHz(BFind);
							PERhists{ROWind,ATTind}{BFind}=PIC.PERhist.PERhist;
							PERhistXs_sec{ROWind,ATTind}{BFind}=PIC.PERhist.PERhist_X_sec;

							% Filter PERhists with Triangular Filter: filter 3 reps, take middle rep to avoid edge effects and keep periodic
							N=length(PERhists{ROWind,ATTind}{BFind});
							SmoothedPERhist=trifilt(repmat(PERhists{ROWind,ATTind}{BFind},1,3),TFiltWidth);
							PERhists_Smoothed{ROWind,ATTind}{BFind}=SmoothedPERhist(N+1:2*N);
							% Determine Maximum of ALL plotted PERhists (i.e., post-Smoothing)
							if max(PERhists_Smoothed{ROWind,ATTind}{BFind})>PERhistsMAX
								PERhistsMAX=max(PERhists_Smoothed{ROWind,ATTind}{BFind});
							end

							% Save DFTs as well of PERhists
							DFTs{ROWind,ATTind}{BFind}=PIC.SynchRate_PERhist.SynchRate_PERhist;
							DFTfreqs_Hz{ROWind,ATTind}{BFind}=PIC.SynchRate_PERhist.FFTfreqs;
							% Determine Maximum of ALL plotted DFTs
							if max(abs(DFTs{ROWind,ATTind}{BFind}))>DFTsMAX
								DFTsMAX=max(abs(DFTs{ROWind,ATTind}{BFind}));
							end

							Nsps{ROWind,ATTind}(BFind)=PIC.PERhist.NumDrivenSpikes;
							Rates{ROWind,ATTind}(BFind)=PIC.SynchRate_PERhist.SynchRate_PERhist(1);
							if PIC.SynchRate_PERhist.FeatureRaySig(FeatIND)
								Synchs{ROWind,ATTind}(BFind)=PIC.SynchRate_PERhist.FeatureSynchs(FeatIND);
								Phases{ROWind,ATTind}(BFind)=PIC.SynchRate_PERhist.FeaturePhases(FeatIND);
							else
								Synchs{ROWind,ATTind}(BFind)=NaN;
								Phases{ROWind,ATTind}(BFind)=NaN;
							end

							if doSCC
								%%%% Save SpikeTrains for this BF if it is used for SCCs
								SCCind=find(SCC_allBFinds==BFind);
								if ~isempty(SCCind)
                                    FreqFact = yTEMP.BFs_kHz(BFind) / unit.Info.BF_kHz;
                                    myEndTime_sec = paramsIN.SCC.EndTime_sec / FreqFact;
                                    myDuration_sec = myEndTime_sec-paramsIN.SCC.StartTime_sec;
                                %    fprintf('   * SAC window: %.3f - %.3f sec for freqfact: %.3f\n',paramsIN.SCC.StartTime_sec,myEndTime_sec,FreqFact)
									SCC_allSpikeTrains{BFind}=getDrivenSpikeTrains(PIC.x.spikes{1},[],[paramsIN.SCC.StartTime_sec myEndTime_sec]);
                                    %%%%%%%%%%%%%%%%%%%%%%%%%
                                    % calculate SAC, CD, Peak
                                    %%%%%%%%%%%%%%%%%%%%%%%%%
                                    disp(sprintf('Feature: %s; SNR: %.f dB  --  Computing SAC at BF %d ........', ...
                                        FeaturesText{FeatIND},Nattens_dB(ATTind)+dBAtt_2_SNR,BFind))
                                    [NSACs{ROWind,ATTind}{BFind},NSAC_delays_usec{ROWind,ATTind}{BFind},NSAC_avgrates{ROWind,ATTind}{BFind},NSAC_nsps{ROWind,ATTind}{BFind}] ...
                                        = ShufAutoCorr(SCC_allSpikeTrains{BFind},paramsIN.SCC.DELAYbinwidth_sec,myDuration_sec);
                                    NSACs_sps{ROWind,ATTind}{BFind}=NSACs{ROWind,ATTind}{BFind}*...
                                        paramsIN.SCC.DELAYbinwidth_sec*...
                                        NSAC_avgrates{ROWind,ATTind}{BFind}^2/...
                                        FreqFact^2;
                                    F0per_us=1/yTEMP.FeatureFreqs_Hz{1}(1)*1e6;
                                    [NSAC_CDs_usec{ROWind,ATTind}{BFind},NSAC_peaks{ROWind,ATTind}{BFind}] =...
                                        calcCD(NSACs{ROWind,ATTind}{BFind},NSAC_delays_usec{ROWind,ATTind}{BFind},F0per_us);
                                    NSAC_BFs_kHz{ROWind,ATTind}{BFind}=yTEMP.BFs_kHz(BFind);
                                end
							end

						else
							BFs_kHz{ROWind,ATTind}(BFind)=yTEMP.BFs_kHz(BFind);
							Nsps{ROWind,ATTind}(BFind)=NaN;
							Rates{ROWind,ATTind}(BFind)=NaN;
							Synchs{ROWind,ATTind}(BFind)=NaN;
							Phases{ROWind,ATTind}(BFind)=NaN;

							PERhists{ROWind,ATTind}{BFind}=[];
							PERhistXs_sec{ROWind,ATTind}{BFind}=[];
							DFTs{ROWind,ATTind}{BFind}=[];
							DFTfreqs_Hz{ROWind,ATTind}{BFind}=[];

							%%%% Warn that no SpikeTrains for this BF if it is used for SCCs
							SCCind=find(SCC_allBFinds==BFind);
							if ~isempty(SCCind)
								%                            uiwait(warndlg(sprintf('SCC_allSpikeTrains{SCCind} is set to EMPTY because no data for this BF!\n\n   Feature: %s; ATTEN=%.f dB SPL, BFind=%d', ...
								%                               FeaturesText{FeatIND},Nattens_dB(ATTind),BFind),'SCC WARNING'))
								fprintf('SCC_allSpikeTrains{SCCind} is set to EMPTY because no data for this BF!\n   Feature: %s; SNR=%.f dB, BFind=%d', ...
									FeaturesText{FeatIND},Nattens_dB(ATTind)+dBAtt_2_SNR,BFind);
							end
						end
					end % BFinds

					%%%%%%%%%%%%%%%%
					% Calculate ALSR data
					%%%%%%%%%%%%%%%%
					if ~isempty(DFTfreqs_Hz{ROWind,ATTind})
						ALSR_OCTrange=0.28;  % Slight slop for slight mismatches in sampling rates
						ALSRinds=find((yTEMP.BFs_kHz>=unit.Info.BF_kHz*2^-ALSR_OCTrange)&(yTEMP.BFs_kHz<=unit.Info.BF_kHz*2^ALSR_OCTrange));
						disp(sprintf('--- ALSR_OCTrange = +- %.2f octs [Channnels %d - %d]',ALSR_OCTrange,min(ALSRinds),max(ALSRinds)))
						SynchRatesTEMP=NaN*ones(1,length(yTEMP.BFs_kHz));
						for BFind=ALSRinds
							[y,DFT_INDEX]=min(abs(DFTfreqs_Hz{ROWind,ATTind}{BFind}-unit.Info.BF_kHz*1000));
							if ~isempty(DFT_INDEX)
								SynchRatesTEMP(BFind)=abs(DFTs{ROWind,ATTind}{BFind}(DFT_INDEX));
							end
						end
						ALSRs{ROWind,ATTind}=mean(SynchRatesTEMP(~isnan(SynchRatesTEMP)));
					else
						ALSRs{ROWind,ATTind}=NaN;
					end

					if doSCC

						%%%%%%%%%%%%%%%%
						% Compute SCCs
						%%%%%%%%%%%%%%%%
						NSCCs{ROWind,ATTind}=cell(size(NSCC_BFinds));
                        NSCCs_sps{ROWind,ATTind}=cell(size(NSCC_BFinds));
						NSCC_delays_usec{ROWind,ATTind}=cell(size(NSCC_BFinds));
						NSCC_avgrates{ROWind,ATTind}=cell(size(NSCC_BFinds));
						NSCC_nsps{ROWind,ATTind}=cell(size(NSCC_BFinds));
						NSCC_BFs_kHz{ROWind,ATTind}=cell(size(NSCC_BFinds));
						NSCC_CDs_usec{ROWind,ATTind}=cell(size(NSCC_BFinds));
						NSCC_peaks{ROWind,ATTind}=cell(size(NSCC_BFinds));
						NSCC_0delay{ROWind,ATTind}=cell(size(NSCC_BFinds));
                        NSCC_Rho{ROWind,ATTind}=cell(size(NSCC_BFinds));
						NSCC_ARBdelay{ROWind,ATTind}=cell(size(NSCC_BFinds));
                        
						for SCCind=1:length(NSCC_BFinds)  % index of SCC to calculate
							% Find SpikeTrains needed for this SCC
							emptySCC=0;
							for i=1:2
								SpikeTrains{i}=SCC_allSpikeTrains{NSCC_BFinds{SCCind}(i)};
								if isempty(SpikeTrains{i})
									emptySCC=1;
								end
							end
							if ~emptySCC
								disp(sprintf('Feature: %s; SNR: %.f dB  --  Computing SCC # %d between BFs %d and %d ........', ...
									FeaturesText{FeatIND},Nattens_dB(ATTind)+dBAtt_2_SNR,SCCind,NSCC_BFinds{SCCind}))
                                FreqFact =yTEMP.BFs_kHz(NSCC_BFinds{SCCind}(2))/unit.Info.BF_kHz;
                                myDuration_sec = paramsIN.SCC.EndTime_sec/FreqFact-paramsIN.SCC.StartTime_sec;
								[NSCCs{ROWind,ATTind}{SCCind},NSCC_delays_usec{ROWind,ATTind}{SCCind},NSCC_avgrates{ROWind,ATTind}{SCCind},NSCC_nsps{ROWind,ATTind}{SCCind}] ...
									= ShufCrossCorr(SpikeTrains,paramsIN.SCC.DELAYbinwidth_sec,myDuration_sec);

								%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
								%disp('   ********* Converting NSCC[0,1] to SCC_CD(sp/sec) by SCC_CD=NSCC*binwidth*rA*rB')
								%%% 12/31/05: TRY SCCs as CD_sp/sec instead of NSCC!!!
								NSCCbinwidth_sec=diff(NSCC_delays_usec{ROWind,ATTind}{SCCind}(1:2))*1e-6;
								% Convert NSCC to SCC_CD as SCC_CD(sp/sec)=NSCC*binwidth*rA*rB
								% Keep stored as NSCCs_sps for bookkeeping
								% NEED to scale avgrates to compensate for rate
								% bias due to shifting
								NSCCs_sps{ROWind,ATTind}{SCCind}=NSCCs{ROWind,ATTind}{SCCind}* ...
									NSCCbinwidth_sec * ...
									NSCC_avgrates{ROWind,ATTind}{SCCind}{1} * ...
									cell2mat(unit.EHvN_reBF_simFF.F1{HarmonicsIND,PolarityIND}.TimeFact(1,NSCC_BFinds{SCCind}(1))) * ...
									NSCC_avgrates{ROWind,ATTind}{SCCind}{2} * ...
									cell2mat(unit.EHvN_reBF_simFF.F1{HarmonicsIND,PolarityIND}.TimeFact(1,NSCC_BFinds{SCCind}(2)));

								% Determine Maximum of ALL plotted SCCs (i.e., post-Smoothing)
								if max(NSCCs{ROWind,ATTind}{SCCind})>SCCsMAX
									SCCsMAX=max(NSCCs{ROWind,ATTind}{SCCind});
								end
								NSCC_BFs_kHz{ROWind,ATTind}{SCCind}=[yTEMP.BFs_kHz(NSCC_BFinds{SCCind}(1)),yTEMP.BFs_kHz(NSCC_BFinds{SCCind}(2))];
								NSCC_0delay{ROWind,ATTind}{SCCind}=NSCCs{ROWind,ATTind}{SCCind}(find(NSCC_delays_usec{ROWind,ATTind}{SCCind}==0));
                                
                                F0per_us=1/yTEMP.FeatureFreqs_Hz{1}(1)*1e6;
                                [NSCC_CDs_usec{ROWind,ATTind}{SCCind},NSCC_peaks{ROWind,ATTind}{SCCind}] =...
                                    calcCD(NSCCs{ROWind,ATTind}{SCCind},NSCC_delays_usec{ROWind,ATTind}{SCCind},F0per_us);
								
                                %%%%%%%%%%%%%%%%%%%%%
                                % calculate rho
                                %%%%%%%%%%%%%%%%%%%%%
                                if ~isempty(NSCC_peaks{ROWind,ATTind}{SCCind})&&...
                                   ~isempty(NSAC_peaks{ROWind,ATTind}{NSCC_BFinds{SCCind}(1)})&&...
                                   ~isempty(NSAC_peaks{ROWind,ATTind}{NSCC_BFinds{SCCind}(2)})
                                    SCCpeak=max(NSCC_peaks{ROWind,ATTind}{SCCind});
                                    SACpeak1=max(NSAC_peaks{ROWind,ATTind}{NSCC_BFinds{SCCind}(1)});
                                    SACpeak2=max(NSAC_peaks{ROWind,ATTind}{NSCC_BFinds{SCCind}(2)});
                                    NSCC_Rho{ROWind,ATTind}{SCCind}=SCCpeak/sqrt(SACpeak1*SACpeak2);
                                else
                                    fprintf('Cannot compute NSCC_Rho. No peaks in Feat %s, SNR %.f dB...\n',...
                                        FeaturesText{FeatIND},Nattens_dB(ATTind)+dBAtt_2_SNR)
                                    if isempty(NSCC_peaks{ROWind,ATTind}{SCCind})
                                        fprintf('\tSCC #%d (BFs %d, %d)\n',SCCind,NSCC_BFinds{SCCind})
                                    end
                                    if isempty(NSAC_peaks{ROWind,ATTind}{NSCC_BFinds{SCCind}(1)})
                                        fprintf('\tSAC BF %d\n',NSCC_BFs_kHz{ROWind,ATTind}{SCCind}(1))
                                    end
                                    if isempty(NSAC_peaks{ROWind,ATTind}{NSCC_BFinds{SCCind}(2)})
                                        fprintf('\tSAC BF %d\n',NSCC_BFs_kHz{ROWind,ATTind}{SCCind}(2))
                                    end
                                    NSCC_Rho{ROWind,ATTind}{SCCind}=NaN;
                                end
							else  % No Data to compute SCCs
								F0per_us=1/yTEMP.FeatureFreqs_Hz{1}(1)*1e6;

								fprintf('Feature: %s; SNR: %.f dB  --  CAN''T compute SCC # %d between BFs %d and %d (MISSING DATA) ........', ...
									FeaturesText{FeatIND},Nattens_dB(ATTind)+dBAtt_2_SNR,SCCind,NSCC_BFinds{SCCind})
								NSCCs{ROWind,ATTind}{SCCind}=NaN*ones(1,3);
								NSCC_delays_usec{ROWind,ATTind}{SCCind}=[-F0per_us 0 F0per_us];
								NSCC_avgrates{ROWind,ATTind}{SCCind}=NaN;
								NSCC_nsps{ROWind,ATTind}{SCCind}=0;
								NSCC_BFs_kHz{ROWind,ATTind}{SCCind}=[yTEMP.BFs_kHz(NSCC_BFinds{SCCind}(1)),yTEMP.BFs_kHz(NSCC_BFinds{SCCind}(2))];
								NSCC_0delay{ROWind,ATTind}{SCCind}=NaN;
								NSCC_ARBdelay{ROWind,ATTind}{SCCind}=NaN;
								NSCC_CDs_usec{ROWind,ATTind}{SCCind}=NaN;
                                NSCC_Rho{ROWind,ATTind}{SCCind}=NaN;
								NSCC_peaks{ROWind,ATTind}{SCCind}=NaN;
							end

							%                   % TO COMPUTE
							%                   *NSCCs
							%                   *NSCC_delays_usec
							%                   *NSCC_BFs_kHz
							%                   *NSCC_avgrates
							%                   *NSCC_nsps
							%                   *NSCC_CDs_usec
							%                   *NSCC_peaks
							%                   *NSCC_0delay
							%                   *(LATER in SMP plot) NSCC_ARBdelay

							%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
							%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
							%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
							%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
							%%%%%%%%%%%%%%%% 2/5/05 TODO %%%%%%%%%%%%%%%%%%%%%%%%%%%
							% *1) Compute peak, CD (use 1/F0 to limit search?)
							% *2) Setup *NSCC and SCC plots,
							%         *and plot SCC and NSCC values
							% *3) Set up SMP plots
							% 3.5) Verify all calcs look OK, decide how to handle NSCC/SCC
							% 4) Start to looking at data to see effects!!!!
							%      - look for CNL
							%      - look for robust SCCs
							%              - !!! LOOKS LIKE D&G story holds, largest Cross-Corr is at troughs, drops at formants
							%      - DO WE NEED 2 SCCs, or just one BF+epsilon, BF-epsilon???  WOULD BE SIMPLER!!!
							%      - DEVELOP STORY

							%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
							%%%%%%%%%%%%%%%%%%%% TODO  2/2/05 %%%%%%%%%%%%%%%%%%%%%%%%%%%%
							% Compute these 2 SCCs for demo, and get all things working
							% TRY to setup general, simple implementation of these things
							% Then can start looking for real issues
							%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        end
					end

					%%%%%%%%%%%%%%%%
					% Store SMP data
					%%%%%%%%%%%%%%%%
					SMP_rate{ATTind}(FeatIND)=Rates{ROWind,ATTind}(BF_INDEX);
					SMP_alsr{ATTind}(FeatIND)=ALSRs{ROWind,ATTind};

					% Determine how many CHANNELS to plot
					if length(yTEMP.BFs_kHz)>PERhistsYCHANS
						PERhistsYCHANS=length(yTEMP.BFs_kHz);
					end
				end %End if data for this condition, plot
			end % End Feature
		end % If EHrBF data
	end % ATTENs

% save all SMP_NSCC_* data, now that numSCCs is known.
if doSCC
	fprintf('saving SMP_NSCC*... %d SCC pairs',numSCCs)
	SMP_NSCC_0delay=cell(numSCCs,length(Nattens_dB));
	SMP_NSCC_ARBdelay=cell(numSCCs,length(Nattens_dB));
	SMP_NSCC_CD=cell(numSCCs,length(Nattens_dB));
	SMP_NSCC_peak=cell(numSCCs,length(Nattens_dB));
	for i=1:numSCCs
		for ATTind=1:length(Nattens_dB)
			SMP_NSCC_0delay{i,ATTind}=NaN*ones(1,length(FeaturesText));
			SMP_NSCC_ARBdelay{i,ATTind}=NaN*ones(1,length(FeaturesText));
			SMP_NSCC_CD{i,ATTind}=NaN*ones(1,length(FeaturesText));
			SMP_NSCC_peak{i,ATTind}=NaN*ones(1,length(FeaturesText));
			ROWind=0;
			for FeatIND=FeatINDs
				ROWind=ROWind+1;
				SMP_NSCC_0delay{i,ATTind}(FeatIND)=NSCC_0delay{ROWind,ATTind}{i};
				SMP_NSCC_CD{i,ATTind}(FeatIND)=NSCC_CDs_usec{ROWind,ATTind}{i};
				SMP_NSCC_peak{i,ATTind}(FeatIND)=NSCC_peaks{ROWind,ATTind}{i};
			end
		end
	end
end

% SETUP SAVING ALL CALCS to speed up figure design
% 	saveBOOL=input('Do you want to save these calculations before plotting (0: no; [1]: yes)?? ');
	saveBOOL=1;
	if isempty(saveBOOL)
		saveBOOL=1;
	end
	if saveBOOL
		clear loadBOOL
		disp(sprintf('Saving ''UNITSdata/%s'' with all calculations!!',SAVECALCSfilename))
		eval(['save ''' fullfile(unitdata_dir,SAVECALCSfilename) ''''])
	end


end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO ALL PERhist PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Plot data
ATTENcolors={'b','r','g','k','c','y'};
FEATmarkers={'.','x','s','^','*','<','^','>'};
FIG.FontSize=8;

FeatureColors={'r','g'};
%%% Show multiple periods of tone PERhist
NperiodsTONE=5;
if isfield(unit,'EHvN_reBF_simFF')
	PERhist_XMAX=1/F0min*1000;  % take the PERhist_Xlims on vowels (in ms)
	XLIMITS_perhist=[0 PERhist_XMAX];
else
	% Need to find PERhist_XMAX by hand
	PERhist_XMAX=0;
	for ROWind=1:NUMrows
		for ATTind=1:length(Nattens_dB)
			for BFind=1:length(PERhistXs_sec{1,1})
				if max(PERhistXs_sec{ROWind,ATTind}{BFind})>PERhist_XMAX
					PERhist_XMAX=max(PERhistXs_sec{ROWind,ATTind}{BFind});
				end
			end
		end
	end
	PERhist_XMAX=PERhist_XMAX*1000; % in ms
	XLIMITS_perhist=[0 PERhist_XMAX*NperiodsTONE];
end
XLIMITS_rate=[0 300];
XLIMITS_synch=[0 1];
XLIMITS_phase=[-pi pi];
%% Find PERhist_YMAX
PERhistGAIN=2.0; % # of channels covered by max PERhist
PERhists_logCHwidth=log10(highBF/lowBF)/(PERhistsYCHANS-1);  % log10 channel width
PERhist_YMIN=lowBF;
PERhist_YMAX=10^((PERhistsYCHANS-1+PERhistGAIN)*PERhists_logCHwidth)*lowBF;    % sets an extra (GAIN-1) log channel widths
YLIMITS=[PERhist_YMIN PERhist_YMAX];  % Used for all plots
%% This  is ALL needed to get the right LOG Yticks!!
YLIMunit=10^floor(log10(lowBF));
YLIMS=floor(lowBF/YLIMunit)*YLIMunit*[1 100]; % Do two decades to be sure we get all the ticks
YTICKS=[YLIMS(1):YLIMunit:YLIMS(1)*10 YLIMS(1)*20:YLIMunit*10:YLIMS(end)];
BFoctCRIT=1/128;  % Chooses as BF channel is within 1/128 octave

% Setup parameters for title
if isempty(unit.Info.Threshold_dBSPL)
	unit.Info.Threshold_dBSPL=NaN;
end
if isempty(unit.Info.SR_sps)
	unit.Info.SR_sps=NaN;
end
if isempty(unit.Info.Q10)
	unit.Info.Q10=NaN;
end

for ATTEN=Nattens_dB
	% beep
	% disp('***** HARD CODED FOR ONLY 1 (highest) ATTEN *****')
	% for ATTEN=Nattens_dB(end)
	figure(max([2 round(ATTEN)])); clf
	set(gcf,'units','norm','pos',[0.2234    0.7119    0.4297    0.2344],'Resize','off')
	set(gcf,'vis','off')
	ROWind=0;

	%%%%%%%%%%%%%%%%%%%% EH_reBF Plots
	if isfield(unit,'EHvN_reBF_simFF')
		for FeatIND=FeatINDs
			ROWind=ROWind+1;
			eval(['yTEMP=unit.EHvN_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
			if ~isempty(yTEMP)
				%%%% EH_reBF plots
				ATTind=find(yTEMP.Nattens_dB==ATTEN);

				%%%% Spatio-Temporal Plots
				PLOTnum=(ROWind-1)*NUMcols+1;
				eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
				for BFind=1:length(BFs_kHz{ROWind,ATTind})
					if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,ATTind}/unit.Info.BF_kHz))<BFoctCRIT))
						LINEwidth=2;
					else
						LINEwidth=.5;
					end
					% This normalization plots each signal the same size on a log scale
					if ~isempty(PERhistXs_sec{ROWind,ATTind}{BFind})
						NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,ATTind}(BFind)/PERhistsMAX;
						semilogy(PERhistXs_sec{ROWind,ATTind}{BFind}*1000, ...
							PERhists_Smoothed{ROWind,ATTind}{BFind}*NormFact+BFs_kHz{ROWind,ATTind}(BFind), ...
							'LineWidth',LINEwidth)
						hold on
					end
				end
				xlabel('Time (ms)')
				ylabel('Effective Best Frequency (kHz)')
				if ROWind==1
					title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL, SNR = %.f dB,  Harm: %d, Polarity: %d', ...
						ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,FeaturesText{FeatIND}, ...
						yTEMP.levels_dBSPL,yTEMP.Nattens_dB(ATTind)+dBAtt_2_SNR,HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
				else
					title(sprintf('%s @ %.f dB SPL, SNR = %.f dB,  Harm: %d, Polarity: %d',FeaturesText{FeatIND}, ...
						yTEMP.levels_dBSPL,yTEMP.Nattens_dB(ATTind)+dBAtt_2_SNR,HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
				end
				xlim(XLIMITS_perhist)
				PLOThand=eval(['h' num2str(PLOTnum)]);
				set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
				ylim(YLIMITS)  % Same Ylimits for all plots
				%%%%%%%%%%%%%%%%%%%%%
				% Plot lines at all features
				for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
					if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
						semilogy(XLIMITS_perhist,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
						text(XLIMITS_perhist(2)*1.005,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000, ...
							sprintf('%s (%.1f)',FeaturesText{FeatINDPlot},yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000), ...
							'units','data','HorizontalAlignment','left','VerticalAlignment','middle','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
					end
					for BFind=1:length(BFs_kHz{ROWind,ATTind})
						if ~isempty(PERhistXs_sec{ROWind,ATTind}{BFind})
							if (FeatINDPlot<=FeatIND)
								if (FeatINDPlot>1)
									text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
										'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color',FeatureColors{-rem(FeatINDPlot,2)+2})
								else
									text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
										'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color','k')
								end
							end
						end
					end
				end
				hold off


				%%%% Rate Plot
				PLOTnum=(ROWind-1)*NUMcols+2;
				eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
				semilogy(Rates{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-')
				hold on
				semilogy(Nsps{ROWind,ATTind}/10,BFs_kHz{ROWind,ATTind},'m+','MarkerSize',4)
				semilogy(ALSRs{ROWind,ATTind},unit.Info.BF_kHz,'go','MarkerSize',6)
				semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
				xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]\nO: ALSR'),'FontSize',6)
				PLOThand=eval(['h' num2str(PLOTnum)]);
				xlim(XLIMITS_rate)
				set(PLOThand,'XDir','reverse')
				set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
				ylim(YLIMITS)  % Same Ylimits for all plots
				%%%%%%%%%%%%%%%%%%%%%
				% Plot lines at all features
				for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
					if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
						semilogy(XLIMITS_rate,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
					end
				end
				hold off

				%%%% Synch Plot
				PLOTnum=(ROWind-1)*NUMcols+3;
				eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
				semilogy(Synchs{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-')
				hold on
				semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
				xlabel(sprintf('Synch Coef (to %s)',FeaturesText{FeatIND}))
				PLOThand=eval(['h' num2str(PLOTnum)]);
				xlim(XLIMITS_synch)
				set(PLOThand,'XDir','reverse')
				set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
				set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
				ylim(YLIMITS)  % Same Ylimits for all plots
				%%%%%%%%%%%%%%%%%%%%%
				% Plot lines at all features
				for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
					if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
						semilogy(XLIMITS_synch,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
					end
				end
				hold off

				%%%% Phase Plot
				PLOTnum=(ROWind-1)*NUMcols+4;
				eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
				semilogy(Phases{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-')
				hold on
				semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
				xlabel(sprintf('Phase (cycles of %s)',FeaturesText{FeatIND}))
				PLOThand=eval(['h' num2str(PLOTnum)]);
				xlim(XLIMITS_phase)
				set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
				set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
				ylim(YLIMITS)  % Same Ylimits for all plots
				%%%%%%%%%%%%%%%%%%%%%
				% Plot lines at all features
				for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
					if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
						semilogy(XLIMITS_phase,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
					end
				end
				hold off

			end %End if data for this condition, plot
		end % End Feature
	end


	Xcorner=0.05;
	Xwidth1=.5;
	Xshift1=0.05;
	Xwidth2=.1;
	Xshift2=0.03;

	Ycorner=0.05;
	Yshift=0.07;
	Ywidth=(1-NUMrows*(Yshift+.01))/NUMrows;   %.26 for 3; .42 for 2

	TICKlength=0.02;

	if NUMrows>4
		set(h17,'Position',[Xcorner Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		set(h18,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h19,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h20,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>3
		set(h13,'Position',[Xcorner Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		set(h14,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h15,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h16,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>2
		set(h9,'Position',[Xcorner Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		set(h10,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h11,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h12,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>1
		set(h5,'Position',[Xcorner Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		set(h6,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h7,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h8,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	end

	set(h1,'Position',[Xcorner Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	set(h2,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h3,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h4,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])

	orient landscape
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2/13/05 TODO
% *1) plot 5 periods tone
% *2) Add all-ATTENs PERhist plot for tones
% *3) Take out DFT for tones
% *4) Update SCCs - which channels
% *5) Add SCCs for tones
% *5.25) Add extra figure with all ATTEN SCCs
% 5.5) Figure out how to show CNL is a benefit, by accounting for passive TW delay
% 6) Deal with passive TW delay, to show NSCCpeak goes up with ATTEN
% 7) Add figure to show CD(L) for tones


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% ADD EXTRA PERhist plot at the end with all ATTENs on top of one anothe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1000); clf
set(gcf,'units','norm','pos',[0.2234    0.7119    0.4297    0.2344],'Resize','off')
ROWind=0;
ALLlevelsTriFiltTONE=9;
ALLlevelsTriFilt=3;

ATTEN=max(Nattens_dB);

%%%%%%%%%%%%%%%%%%%% EH_reBF Plots
if isfield(unit,'EHvN_reBF_simFF')
	for FeatIND=FeatINDs
		ROWind=ROWind+1;
		eval(['yTEMP=unit.EHvN_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
		if ~isempty(yTEMP)
			%%%% EH_reBF plots
			ATTind=find(yTEMP.Nattens_dB==ATTEN);

			%%%% Spatio-Temporal Plots
			PLOTnum=(ROWind-1)*NUMcols+1;
			eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
			LEGtext='';
			for BFind=1:length(BFs_kHz{ROWind,ATTind})
				if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,ATTind}/unit.Info.BF_kHz))<BFoctCRIT))
					LINEwidth=2;
				else
					LINEwidth=.5;
				end
				% This normalization plots each signal the same size on a log scale
				if ~isempty(PERhistXs_sec{ROWind,ATTind}{BFind})
					NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,ATTind}(BFind)/PERhistsMAX;
					semilogy(PERhistXs_sec{ROWind,ATTind}{BFind}*1000, ...
						trifilt(PERhists_Smoothed{ROWind,ATTind}{BFind},ALLlevelsTriFilt)*NormFact+BFs_kHz{ROWind,ATTind}(BFind), ...
						'LineWidth',LINEwidth,'Color',ATTENcolors{ATTind})
					hold on
					if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,ATTind}/unit.Info.BF_kHz))<BFoctCRIT))
						LEGtext{length(LEGtext)+1}=sprintf('%.f dB',Nattens_dB(ATTind)+dBAtt_2_SNR);
					end
					for ATTind2=fliplr(find(Nattens_dB~=max(Nattens_dB)))
						if ~isempty(PERhistXs_sec{ROWind,ATTind2}{BFind})
							semilogy(PERhistXs_sec{ROWind,ATTind2}{BFind}*1000, ...
								trifilt(PERhists_Smoothed{ROWind,ATTind2}{BFind},ALLlevelsTriFilt)*NormFact+BFs_kHz{ROWind,ATTind2}(BFind), ...
								'LineWidth',LINEwidth,'Color',ATTENcolors{ATTind2})
							if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,ATTind}/unit.Info.BF_kHz))<BFoctCRIT))
								LEGtext{length(LEGtext)+1}=sprintf('%.f dB',Nattens_dB(ATTind2)+dBAtt_2_SNR);
							end
						end
					end
					if strcmp(FeaturesText{FeatIND},'F1')
						hleg1000=legend(LEGtext,1);
						set(hleg1000,'FontSize',2)%LOLbiss
						set(hleg1000,'pos',[0.4451    0.8913    0.0942    0.0473])
					end
				end
			end
			xlabel('Time (ms)')
			ylabel('Effective Best Frequency (kHz)')
			if ROWind==1
				title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL,   Harm: %d, Polarity: %d', ...
					ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,FeaturesText{FeatIND}, ...
					yTEMP.levels_dBSPL,HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
			else
				title(sprintf('%s @ %.f dB SPL,   Harm: %d, Polarity: %d',FeaturesText{FeatIND}, ...
					yTEMP.levels_dBSPL,HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
			end
			xlim(XLIMITS_perhist)
			PLOThand=eval(['h' num2str(PLOTnum)]);
			set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
			ylim(YLIMITS)  % Same Ylimits for all plots
			%%%%%%%%%%%%%%%%%%%%%
			% Plot lines at all features
			for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
				if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
					semilogy(XLIMITS_perhist,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
					text(XLIMITS_perhist(2)*1.005,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000, ...
						sprintf('%s (%.1f)',FeaturesText{FeatINDPlot},yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000), ...
						'units','data','HorizontalAlignment','left','VerticalAlignment','middle','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
				end
				for BFind=1:length(BFs_kHz{ROWind,ATTind})
					if ~isempty(PERhistXs_sec{ROWind,ATTind}{BFind})
						if (FeatINDPlot<=FeatIND)
							if (FeatINDPlot>1)
								text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
									'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color',FeatureColors{-rem(FeatINDPlot,2)+2})
							else
								text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
									'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color','k')
							end
						end
					end
				end
			end
			hold off


			%%%% Rate Plot
			PLOTnum=(ROWind-1)*NUMcols+2;
			eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
			semilogy(Rates{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-','Color',ATTENcolors{ATTind})
			hold on
			%                semilogy(Nsps{ROWind,ATTind}/10,BFs_kHz{ROWind,ATTind},'m+','MarkerSize',4,'Color',ATTENcolors{ATTind})
			semilogy(ALSRs{ROWind,ATTind},unit.Info.BF_kHz,'go','MarkerSize',6,'Color',ATTENcolors{ATTind})
			for ATTind2=fliplr(find(Nattens_dB~=max(Nattens_dB)))
				semilogy(Rates{ROWind,ATTind2},BFs_kHz{ROWind,ATTind2},'*-','Color',ATTENcolors{ATTind2})
				%                   semilogy(Nsps{ROWind,ATTind2}/10,BFs_kHz{ROWind,ATTind2},'m+','MarkerSize',4,'Color',ATTENcolors{ATTind2})
				semilogy(ALSRs{ROWind,ATTind2},unit.Info.BF_kHz,'go','MarkerSize',6,'Color',ATTENcolors{ATTind2})
			end
			semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
			%                xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]\nO: ALSR'),'FontSize',6)
			xlabel(sprintf('Rate (sp/sec)\nO: ALSR'),'FontSize',8)
			PLOThand=eval(['h' num2str(PLOTnum)]);
			xlim(XLIMITS_rate)
			set(PLOThand,'XDir','reverse')
			set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
			ylim(YLIMITS)  % Same Ylimits for all plots
			%%%%%%%%%%%%%%%%%%%%%
			% Plot lines at all features
			for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
				if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
					semilogy(XLIMITS_rate,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
				end
			end
			hold off

			%%%% Synch Plot
			PLOTnum=(ROWind-1)*NUMcols+3;
			eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
			semilogy(Synchs{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-','Color',ATTENcolors{ATTind})
			hold on
			for ATTind2=fliplr(find(Nattens_dB~=max(Nattens_dB)))
				semilogy(Synchs{ROWind,ATTind2},BFs_kHz{ROWind,ATTind2},'*-','Color',ATTENcolors{ATTind2})
			end
			semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
			xlabel(sprintf('Synch Coef (to %s)',FeaturesText{FeatIND}))
			PLOThand=eval(['h' num2str(PLOTnum)]);
			xlim(XLIMITS_synch)
			set(PLOThand,'XDir','reverse')
			set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
			set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
			ylim(YLIMITS)  % Same Ylimits for all plots
			%%%%%%%%%%%%%%%%%%%%%
			% Plot lines at all features
			for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
				if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
					semilogy(XLIMITS_synch,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
				end
			end
			hold off

			%%%% Phase Plot
			PLOTnum=(ROWind-1)*NUMcols+4;
			eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
			semilogy(Phases{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-','Color',ATTENcolors{ATTind})
			hold on
			for ATTind2=fliplr(find(Nattens_dB~=max(Nattens_dB)))
				semilogy(Phases{ROWind,ATTind2},BFs_kHz{ROWind,ATTind2},'*-','Color',ATTENcolors{ATTind2})
			end
			semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
			xlabel(sprintf('Phase (cycles of %s)',FeaturesText{FeatIND}))
			PLOThand=eval(['h' num2str(PLOTnum)]);
			xlim(XLIMITS_phase)
			set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
			set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
			ylim(YLIMITS)  % Same Ylimits for all plots
			%%%%%%%%%%%%%%%%%%%%%
			% Plot lines at all features
			for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
				if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
					semilogy(XLIMITS_phase,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
				end
			end
			hold off

		end %End if data for this condition, plot
	end % End Feature
end


Xcorner=0.05;
Xwidth1=.5;
Xshift1=0.05;
Xwidth2=.1;
Xshift2=0.03;

Ycorner=0.05;
Yshift=0.07;
Ywidth=(1-NUMrows*(Yshift+.01))/NUMrows;   %.26 for 3; .42 for 2

TICKlength=0.02;

if NUMrows>4
	set(h17,'Position',[Xcorner Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	set(h18,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h19,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h20,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
end

if NUMrows>3
	set(h13,'Position',[Xcorner Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	set(h14,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h15,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h16,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
end

if NUMrows>2
	set(h9,'Position',[Xcorner Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	set(h10,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h11,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h12,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
end

if NUMrows>1
	set(h5,'Position',[Xcorner Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	set(h6,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h7,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	set(h8,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
end

set(h1,'Position',[Xcorner Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
set(h2,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
set(h3,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
set(h4,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])

orient landscape


if isfield(unit,'EHvN_reBF_simFF')

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%% DO ALL DFT PLOTS
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	XLIMITS_dft=[0 10];

	for ATTEN=Nattens_dB
		% beep
		% disp('***** HARD CODED FOR ONLY 1 (highest) ATTEN *****')
		% for ATTEN=Nattens_dB(end)
		figure(round(ATTEN)+1); clf 		
		set(gcf,'units','norm','pos',[0.2234    0.3906    0.4297    0.2344],'Resize','off')
		set(gcf,'vis','off')
		ROWind=0;

		%%%%%%%%%%%%%%%%%%%% EH_reBF Plots
		if isfield(unit,'EHvN_reBF_simFF')
			for FeatIND=FeatINDs
				ROWind=ROWind+1;
				eval(['yTEMP=unit.EHvN_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
				if ~isempty(yTEMP)
					%%%% EH_reBF plots
					ATTind=find(yTEMP.Nattens_dB==ATTEN);

					%%%% Spatio-Temporal Plots
					PLOTnum=(ROWind-1)*NUMcols+1;
					eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
					for BFind=1:length(BFs_kHz{ROWind,ATTind})
						if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,ATTind}/unit.Info.BF_kHz))<BFoctCRIT))
							LINEwidth=2;
						else
							LINEwidth=.5;
						end
						% This normalization plots each signal the same size on a log scale
						if ~isempty(PERhistXs_sec{ROWind,ATTind}{BFind})
							NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,ATTind}(BFind)/DFTsMAX;
							%                         plot(DFTfreqs_Hz{ROWind,ATTind}{BFind}/1000, ...
							%                            abs(DFTs{ROWind,ATTind}{BFind})*NormFact+BFs_kHz{ROWind,ATTind}(BFind),'b-x', ...
							%                            'LineWidth',LINEwidth)
							semilogy(DFTfreqs_Hz{ROWind,ATTind}{BFind}/1000, ...
								abs(DFTs{ROWind,ATTind}{BFind})*NormFact+BFs_kHz{ROWind,ATTind}(BFind),'b-x', ...
								'LineWidth',LINEwidth)
							hold on
						end
					end
					%                   plot([1e-6 1e6],[1e-6 1e6],'k')
					semilogy(BFs_kHz{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'k')
					xlabel('Stimulus Frequency (kHz)')
					ylabel('Effective Best Frequency (kHz)')
					if ROWind==1
						title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL, SNR = %.f dB,  Harm: %d, Polarity: %d', ...
							ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,FeaturesText{FeatIND}, ...
							yTEMP.levels_dBSPL,yTEMP.Nattens_dB(ATTind)+dBAtt_2_SNR,HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
					else
						title(sprintf('%s @ %.f dB SPL, SNR = %.f dB,  Harm: %d, Polarity: %d',FeaturesText{FeatIND}, ...
							yTEMP.levels_dBSPL,yTEMP.Nattens_dB(ATTind)+dBAtt_2_SNR,HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
					end
					xlim(XLIMITS_dft)
					PLOThand=eval(['h' num2str(PLOTnum)]);
					set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
					ylim(YLIMITS)  % Same Ylimits for all plots
					%%%%%%%%%%%%%%%%%%%%%
					% Show BFs used for ALSR calculation
					ALSRxVEC=ones(size(ALSRinds))*XLIMITS_dft(2);
					ALSRyVEC=yTEMP.BFs_kHz(ALSRinds);
					semilogy(ALSRxVEC,ALSRyVEC,'ko-','LineWidth',3)
					%%%%%%%%%%%%%%%%%%%%%
					% Plot lines at all features
					for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
						if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
							semilogy(XLIMITS_dft,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
							text(XLIMITS_dft(2)*1.005,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000, ...
								sprintf('%s (%.1f)',FeaturesText{FeatINDPlot},yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000), ...
								'units','data','HorizontalAlignment','left','VerticalAlignment','middle','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
						end
						semilogy(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],YLIMITS,':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
						text(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000,YLIMITS(1)*1.0, ...
							sprintf('%s',FeaturesText{FeatINDPlot}),'units','data','HorizontalAlignment','center','VerticalAlignment','top', ...
							'Color',FeatureColors{-rem(FeatINDPlot,2)+2},'FontSize',6)
						%                      for BFind=1:length(BFs_kHz{ROWind,ATTind})
						%                         if ~isempty(PERhistXs_sec{ROWind,ATTind}{BFind})
						%                            if (FeatINDPlot<=FeatIND)
						%                               if (FeatINDPlot>1)
						%                                  text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
						%                                     'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color',FeatureColors{-rem(FeatINDPlot,2)+2})
						%                               else
						%                                  text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
						%                                     'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color','k')
						%                               end
						%                            end
						%                         end
						%                      end
					end
					hold off


					%%%% Rate Plot
					PLOTnum=(ROWind-1)*NUMcols+2;
					eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
					semilogy(Rates{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-')
					hold on
					semilogy(Nsps{ROWind,ATTind}/10,BFs_kHz{ROWind,ATTind},'m+','MarkerSize',4)
					semilogy(ALSRs{ROWind,ATTind},unit.Info.BF_kHz,'go','MarkerSize',6)
					semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
					xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]\nO: ALSR'))
					PLOThand=eval(['h' num2str(PLOTnum)]);
					xlim(XLIMITS_rate)
					set(PLOThand,'XDir','reverse')
					set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
					ylim(YLIMITS)  % Same Ylimits for all plots
					%%%%%%%%%%%%%%%%%%%%%
					% Plot lines at all features
					for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
						if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
							semilogy(XLIMITS_rate,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
						end
					end
					hold off

					%%%% Synch Plot
					PLOTnum=(ROWind-1)*NUMcols+3;
					eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
					semilogy(Synchs{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-')
					hold on
					semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
					xlabel(sprintf('Synch Coef (to %s)',FeaturesText{FeatIND}))
					PLOThand=eval(['h' num2str(PLOTnum)]);
					xlim(XLIMITS_synch)
					set(PLOThand,'XDir','reverse')
					set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
					set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
					ylim(YLIMITS)  % Same Ylimits for all plots
					%%%%%%%%%%%%%%%%%%%%%
					% Plot lines at all features
					for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
						if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
							semilogy(XLIMITS_synch,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
						end
					end
					hold off

					%%%% Phase Plot
					PLOTnum=(ROWind-1)*NUMcols+4;
					eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
					semilogy(Phases{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'*-')
					hold on
					semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
					xlabel(sprintf('Phase (cycles of %s)',FeaturesText{FeatIND}))
					PLOThand=eval(['h' num2str(PLOTnum)]);
					xlim(XLIMITS_phase)
					set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
					set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
					ylim(YLIMITS)  % Same Ylimits for all plots
					%%%%%%%%%%%%%%%%%%%%%
					% Plot lines at all features
					for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
						if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
							semilogy(XLIMITS_phase,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
						end
					end
					hold off

				end %End if data for this condition, plot
			end % End Feature
		end


		Xcorner=0.05;
		Xwidth1=.5;
		Xshift1=0.05;
		Xwidth2=.1;
		Xshift2=0.03;

		Ycorner=0.05;
		Yshift=0.07;
		Ywidth=(1-NUMrows*(Yshift+.01))/NUMrows;   %.26 for 3; .42 for 2

		TICKlength=0.02;

		if NUMrows>4
			set(h17,'Position',[Xcorner Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
			set(h18,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
			set(h19,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
			set(h20,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		end

		if NUMrows>3
			set(h13,'Position',[Xcorner Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
			set(h14,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
			set(h15,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
			set(h16,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		end

		if NUMrows>2
			set(h9,'Position',[Xcorner Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
			set(h10,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
			set(h11,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
			set(h12,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		end

		if NUMrows>1
			set(h5,'Position',[Xcorner Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
			set(h6,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
			set(h7,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
			set(h8,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		end

		set(h1,'Position',[Xcorner Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		set(h2,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h3,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		set(h4,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])

		orient landscape
	end



	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%% ADD EXTRA DFT PLOTS with ALL ATTENs
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	ATTEN=max(Nattens_dB);
	figure(1001); clf
	set(gcf,'units','norm','pos',[0.2234    0.3906    0.4297    0.2344],'Resize','off')
	ROWind=0;

	%%%%%%%%%%%%%%%%%%%% EH_reBF Plots
	if isfield(unit,'EHvN_reBF_simFF')
		for FeatIND=FeatINDs
			ROWind=ROWind+1;
			eval(['yTEMP=unit.EHvN_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
			if ~isempty(yTEMP)
				%%%% EH_reBF plots
				ATTind=find(yTEMP.Nattens_dB==ATTEN);

				%%%% Spatio-Temporal Plots
				PLOTnum=(ROWind-1)*NUMcols+1;
				eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
				LEGtext='';
				for BFind=1:length(BFs_kHz{ROWind,ATTind})
					if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,ATTind}/unit.Info.BF_kHz))<BFoctCRIT))
						LINEwidth=2;
					else
						LINEwidth=.5;
					end
					% This normalization plots each signal the same size on a log scale
					if ~isempty(PERhistXs_sec{ROWind,ATTind}{BFind})
						NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,ATTind}(BFind)/DFTsMAX;
						%                      plot(DFTfreqs_Hz{ROWind,ATTind}{BFind}/1000, ...
						%                         abs(DFTs{ROWind,ATTind}{BFind})*NormFact+BFs_kHz{ROWind,ATTind}(BFind),'-x', ...
						%                         'LineWidth',LINEwidth,'Color',ATTENcolors{ATTind})
						semilogy(DFTfreqs_Hz{ROWind,ATTind}{BFind}/1000, ...
							abs(DFTs{ROWind,ATTind}{BFind})*NormFact+BFs_kHz{ROWind,ATTind}(BFind),'-x', ...
							'LineWidth',LINEwidth,'Color',ATTENcolors{ATTind})
						hold on
						if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,ATTind}/unit.Info.BF_kHz))<BFoctCRIT))
							LEGtext{length(LEGtext)+1}=sprintf('%.f dB',Nattens_dB(ATTind)+dBAtt_2_SNR);
						end
						for ATTind2=fliplr(find(Nattens_dB~=max(Nattens_dB)))
							if ~isempty(PERhistXs_sec{ROWind,ATTind2}{BFind})
								%                            plot(DFTfreqs_Hz{ROWind,ATTind2}{BFind}/1000, ...
								%                               abs(DFTs{ROWind,ATTind2}{BFind})*NormFact+BFs_kHz{ROWind,ATTind2}(BFind),'-x', ...
								%                               'LineWidth',LINEwidth,'Color',ATTENcolors{ATTind2})
								semilogy(DFTfreqs_Hz{ROWind,ATTind2}{BFind}/1000, ...
									abs(DFTs{ROWind,ATTind2}{BFind})*NormFact+BFs_kHz{ROWind,ATTind2}(BFind),'-x', ...
									'LineWidth',LINEwidth,'Color',ATTENcolors{ATTind2})
								if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,ATTind}/unit.Info.BF_kHz))<BFoctCRIT))
									LEGtext{length(LEGtext)+1}=sprintf('%.f dB',Nattens_dB(ATTind2)+dBAtt_2_SNR);
								end
							end
						end
						if strcmp(FeaturesText{FeatIND},'F1')
							hleg1001=legend(LEGtext,1);
							set(hleg1001,'FontSize',8)
							set(hleg1001,'pos',[0.4451    0.8913    0.0942    0.0473])
						end
					end
				end
				%                plot([1e-6 1e6],[1e-6 1e6],'k')
				semilogy(BFs_kHz{ROWind,ATTind},BFs_kHz{ROWind,ATTind},'k')
				xlabel('Stimulus Frequency (kHz)')
				ylabel('Effective Best Frequency (kHz)')
				if ROWind==1
					title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL,   Harm: %d, Polarity: %d', ...
						ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,FeaturesText{FeatIND}, ...
						yTEMP.levels_dBSPL,HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
				else
					title(sprintf('%s @ %.f dB SPL,   Harm: %d, Polarity: %d',FeaturesText{FeatIND}, ...
						yTEMP.levels_dBSPL,HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
				end
				xlim(XLIMITS_dft)
				PLOThand=eval(['h' num2str(PLOTnum)]);
				set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
				ylim(YLIMITS)  % Same Ylimits for all plots
				%%%%%%%%%%%%%%%%%%%%%
				% Show BFs used for ALSR calculation
				ALSRxVEC=ones(size(ALSRinds))*XLIMITS_dft(2);
				ALSRyVEC=yTEMP.BFs_kHz(ALSRinds);
				semilogy(ALSRxVEC,ALSRyVEC,'ko-','LineWidth',3)
				%%%%%%%%%%%%%%%%%%%%%
				% Plot lines at all features
				for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
					if (yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000<=YLIMITS(2))
						semilogy(XLIMITS_dft,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
						text(XLIMITS_dft(2)*1.005,yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000, ...
							sprintf('%s (%.1f)',FeaturesText{FeatINDPlot},yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000), ...
							'units','data','HorizontalAlignment','left','VerticalAlignment','middle','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
					end
					semilogy(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000*[1 1],YLIMITS,':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
					text(yTEMP.FeatureFreqs_Hz{ATTind}(FeatINDPlot)/1000,YLIMITS(1)*1.0, ...
						sprintf('%s',FeaturesText{FeatINDPlot}),'units','data','HorizontalAlignment','center','VerticalAlignment','top', ...
						'Color',FeatureColors{-rem(FeatINDPlot,2)+2},'FontSize',6)
				end
				hold off


			end %End if data for this condition, plot
		end % End Feature
	end


	Xcorner=0.05;
	Xwidth1=.5;
	Xshift1=0.05;
	Xwidth2=.1;
	Xshift2=0.03;

	Ycorner=0.05;
	Yshift=0.07;
	Ywidth=(1-NUMrows*(Yshift+.01))/NUMrows;   %.26 for 3; .42 for 2

	TICKlength=0.02;

	if NUMrows>4
		set(h17,'Position',[Xcorner Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h18,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h19,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h20,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>3
		set(h13,'Position',[Xcorner Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h14,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h15,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h16,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>2
		set(h9,'Position',[Xcorner Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h10,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h11,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h12,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>1
		set(h5,'Position',[Xcorner Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h6,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h7,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
		%       set(h8,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	end

	set(h1,'Position',[Xcorner Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	%    set(h2,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	%    set(h3,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
	%    set(h4,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])

	orient landscape
end

if doSCC
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%% DO ALL SCC PLOTS
	%
	% 4/27/06 - Plot SCC on sp/sec scale, give up on POP plotting
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	XLIMITS_scc=[-PERhist_XMAX PERhist_XMAX];
	YLIMITS_scc=[0 8.2];
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%% EXTRA SCC PLOT WITH ALL ATTENS
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% 	XLIMITS_scc=4*[-1 1];
	%	ATTEN=max(Nattens_dB);
	ptcolor={'b','r','g','k','c','m','y'};

	figure(1002); clf
	set(gcf,'units','norm','pos',[0.2234    0.0693    0.4297    0.2344])%,'Resize','off'
	ROWind=0;
	%%%%%%%%%%%%%%%%%%%% EH_reBF Plots
%	if 0==1 %bypass this resource-heavy graph for debugging purpose
	if isfield(unit,'EHvN_reBF_simFF')
		for FeatIND=FeatINDs
			ROWind=ROWind+1;
			eval(['yTEMP=unit.EHvN_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
			if ~isempty(yTEMP)
                [SCCpos,SCCs_belowBF,SCCs_aboveBF,BFind,centerBF_kHz]=getSCCindsWithBF(unit.Info.BF_kHz,NSAC_BFs_kHz{ROWind,ATTind},NSCC_BFs_kHz{ROWind,ATTind});

                for ATTind=1:length(Nattens_dB)
                    LEGtext='';
                    PLOTnum=(ROWind-1)*length(Nattens_dB)+ATTind;
                    subplot(NUMrows,NUMcols,PLOTnum);
                    for SCCindind=1:size(SCCpos,1)
                        SCCind=SCCpos(SCCindind,1);
                        LINEwidth=.5;
						LINEstyle='-';
						if SCCindind>length(ptcolor)
							LINEstyle='--';
						end
                        if ~isempty(NSCCs{ROWind,ATTind}{SCCind})
                            %fprintf('in subfig %d, plotting feature %s, att %.0fdB, SCCind %d\n',PLOTnum,FeaturesText{FeatIND},Nattens_dB(ATTind),SCCind) 
							colorIND=mod(SCCindind,length(ptcolor));
							if colorIND==0
								colorIND=length(ptcolor);
							end
                            plot(NSCC_delays_usec{ROWind,ATTind}{SCCind}/1000, ...
                                NSCCs{ROWind,ATTind}{SCCind},'LineStyle',LINEstyle,'LineWidth',LINEwidth,'Color',ptcolor{colorIND})
                            hold on
                            LEGtext{length(LEGtext)+1}=sprintf('%.3fkHz vs. %.3fkHz',NSCC_BFs_kHz{ROWind,ATTind}{SCCind}(:));
						end
					end
					leg=legend(LEGtext);
					set(leg,'FontSize',8,'pos',[(ROWind-1)*0.2 0.5+(ROWind-1)*0.2 0.15+(ROWind-1)*0.2 0.3])
					xlabel('Delay (ms)')
					ylabel('[CoincDet] Rate (sp/sec)')
					title_part=sprintf('%s @ %.f dB SPL, ATT %.f dB',FeaturesText{FeatIND},yTEMP.levels_dBSPL,Nattens_dB(ATTind));
					if PLOTnum==1
						title([sprintf('Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f; Harm: %d, Polarity: %d\n', ...
							ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10...
							,HarmonicsIND,PolarityIND),title_part],'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
					else
						title(title_part,'units','norm','pos',[0 1 0],'HorizontalAlignment','left')
					end
					if PLOTnum==8
						xlim(XLIMITS_scc),ylim(YLIMITS_scc*1.75)
					else
						xlim(XLIMITS_scc),ylim(YLIMITS_scc)  % Same Ylimits for all plots except last one, hard-coded
					end
					PLOThand=eval(['h' num2str(PLOTnum)]);
					for SCCindind=1:size(SCCpos,1)
						SCCind=SCCpos(SCCindind,1);
						colorIND=mod(SCCindind,length(ptcolor));
						if colorIND==0
							colorIND=length(ptcolor);
						end
						plot(zeros(1,2),YLIMITS_scc,'k:','LineWidth',LINEwidth/2)
						plot(0,NSCC_0delay{ROWind,ATTind}{SCCind},'s','Color',ptcolor{colorIND})
						plot(NSCC_CDs_usec{ROWind,ATTind}{SCCind}/1000,NSCC_peaks{ROWind,ATTind}{SCCind}, ...
							'o','Color',ptcolor{colorIND})
					end
				end
				%%%%%%%%%%%%%%%%%%%%%
				% Plot lines at all features
				for FeatINDPlot=find(~strcmp(FeaturesText,'TN'))
					for SCCind=1:length(NSCCs{ROWind,ATTind})
						if ~isempty(NSCCs{ROWind,ATTind}{SCCind})
							if (FeatINDPlot<=FeatIND)
								if (FeatINDPlot>1)
									text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS_scc(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
										'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color',FeatureColors{-rem(FeatINDPlot,2)+2})
								else
									text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS_scc(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
										'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color','k')
								end
							end
						end
					end
				end
				hold off

			end %End if data for this condition, plot
		end % End Feature
	end
	%same data, now organized into cols=SCCinds, rows=Features, lines in
	%each panel=ATTENs, to see atten trend in each freq pair.
	figure(1021); clf
	set(gcf,'units','norm','pos',[0.2234    0.0693    0.4297    0.2344])%,'Resize','off'
	numCOLS=0;
	SCCpositions=cell(size(FeatINDs));
	if isfield(unit,'EHvN_reBF_simFF')
		ROWind=0;
		for FeatIND=FeatINDs %get the biggest # of BF pairs and make it numROWS
			ROWind=ROWind+1;
			numCOLS=max([numCOLS,length(NSAC_BFs_kHz{ROWind,ATTind})]);
		end
		ROWind=0;
		for FeatIND=FeatINDs
			eval(['yTEMP=unit.EHvN_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
			ROWind=ROWind+1;
			[SCCpos,SCCs_belowBF,SCCs_aboveBF,BFind,centerBF_kHz]=getSCCindsWithBF(unit.Info.BF_kHz,NSAC_BFs_kHz{ROWind,1},NSCC_BFs_kHz{ROWind,1});
			SCCpos=[SCCpos(1:size(SCCs_belowBF),:);BFind,0;SCCpos(size(SCCs_belowBF)+1:size(SCCpos),:)];
			for SCCindind=1:size(SCCpos,1)
				subplot(length(FeatINDs),numCOLS,(ROWind-1)*numCOLS+SCCindind)
				SCCind=SCCpos(SCCindind,1);
				if SCCpos(SCCindind,2)~=0
					BFpair=NSCC_BFs_kHz{ROWind,1}{SCCind};
				end
				LEGtext='';
				for ATTind=1:length(Nattens_dB)
					if SCCpos(SCCindind,2)==0
						plot(NSAC_delays_usec{ROWind,ATTind}{BFind}/1000,...
							NSACs{ROWind,ATTind}{BFind},'-','Color',ptcolor{ATTind})
						if NSAC_BFs_kHz{ROWind,ATTind}{BFind}~=NSAC_BFs_kHz{ROWind,1}{BFind}
							fprintf('warning: BF not const within ATT: %f | %f\n',NSAC_BFs_kHz{ROWind,1}{BFind},NSAC_BFs_kHz{ROWind,ATTind}{BFind})
						end
					else
						plot(NSCC_delays_usec{ROWind,ATTind}{SCCind}/1000, ...
							NSCCs{ROWind,ATTind}{SCCind},'-','Color',ptcolor{ATTind})
						if NSCC_BFs_kHz{ROWind,ATTind}{SCCind}~=BFpair
							fprintf('warning: BFpair not const within ATT: %f vs. %f | %f vs. %f\n',NSCC_BFs_kHz{ROWind,1}{SCCind},NSCC_BFs_kHz{ROWind,ATTind}{SCCind})
						end
					end
					hold on
					LEGtext{length(LEGtext)+1}=sprintf('ATT %.fdB',Nattens_dB(ATTind));
				end
				if SCCpos(SCCindind,2)==0
					title(sprintf('Feature %s\nfreq %.3fkHz NSAC',FeaturesText{FeatIND},NSAC_BFs_kHz{ROWind,1}{BFind}),'Color','r')
				else
					title(sprintf('Feature %s\nfreqs %.3fkHz vs. %.3fkHz',FeaturesText{FeatIND},NSCC_BFs_kHz{ROWind,1}{SCCind}(:)))
				end
				leg=legend(LEGtext);
				set(leg,'FontSize',8,'pos',[0 0.5 0.15 0.3])
				for ATTind=1:length(Nattens_dB)
					plot(zeros(1,2),YLIMITS_scc*1.6,'k:')
					if SCCpos(SCCindind,2)==0
						plot(NSAC_CDs_usec{ROWind,ATTind}{BFind}/1000,NSAC_peaks{ROWind,ATTind}{BFind}, ...
							'o','Color',ptcolor{ATTind})
					else
						plot(0,NSCC_0delay{ROWind,ATTind}{SCCind},'s','Color',ptcolor{ATTind})
						plot(NSCC_CDs_usec{ROWind,ATTind}{SCCind}/1000,NSCC_peaks{ROWind,ATTind}{SCCind}, ...
							'o','Color',ptcolor{ATTind})
					end
				end
				if FeatIND==3
					xlimfac=0.3;ylimfac=0.6;
				elseif FeatIND==4
					xlimfac=1.1;ylimfac=1.6;
				end
				yind=0;
				for myF=[5 4 3 1]%draw vertical lines at periods of F2 T1 F1 F0
					myX=1000/yTEMP.FeatureFreqs_Hz{1,1}(myF);
					plot(myX*ones(1,2),YLIMITS_scc*ylimfac,'k:')
					text(myX,YLIMITS_scc(2)*ylimfac-1-mod(yind,3)*0.5,sprintf('1/%s',FeaturesText{myF}),'HorizontalAlignment','center','VerticalAlignment','bottom')
					yind=yind+1;
				end
				xlabel('Delay (ms)'),ylabel('[CoincDet] Rate (sp/sec)')
				xlim(XLIMITS_scc*xlimfac),ylim(YLIMITS_scc*ylimfac)
			end
		end
	end

	Xcorner=0.05;
	Xwidth1=.5;
	Xshift1=0.05;
	Xwidth2=.1;
	Xshift2=0.03;

	Ycorner=0.05;
	Yshift=0.07;
	Ywidth=(1-NUMrows*(Yshift+.01))/NUMrows;   %.26 for 3; .42 for 2

	TICKlength=0.02;

	if NUMrows>4
		set(h17,'Position',[Xcorner Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>3
		set(h13,'Position',[Xcorner Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>2
		set(h9,'Position',[Xcorner Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	end

	if NUMrows>1
		set(h5,'Position',[Xcorner Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
	end

	set(h1,'Position',[Xcorner Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])

	orient landscape

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO SMP PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SMPlegFontSize=7;
FIGnum=1;
figure(FIGnum); clf
set(gcf,'units','norm','pos',[0.6570    0.0713    0.4391    0.8770],'Resize','off')

%%%%%%%%%%%%%%%%%%%%% CALCULATE SLOPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rate vs. Feature Level
SensitivitySlopes_rate=NaN+ones(size(Nattens_dB));
SensitivityIntercepts_rate=NaN+ones(size(Nattens_dB));
for ATTind=1:length(Nattens_dB)
	if sum(~isnan(SMP_rate{ATTind}))>1
		x=yTEMP.levels_dBSPL+FeatureLevels_dB(find(~isnan(SMP_rate{ATTind})));
		y=SMP_rate{ATTind}(find(~isnan(SMP_rate{ATTind})));
		[Cfit,MSE,fit]=fit1slope(x,y);
		SensitivitySlopes_rate(ATTind)=Cfit(1);
		SensitivityIntercepts_rate(ATTind)=Cfit(2);
	end
end

% ALSR vs. Feature Level
SensitivitySlopes_alsr=NaN+ones(size(Nattens_dB));
SensitivityIntercepts_alsr=NaN+ones(size(Nattens_dB));
for ATTind=1:length(Nattens_dB)
	if sum(~isnan(SMP_alsr{ATTind}))>1
		x=yTEMP.levels_dBSPL+FeatureLevels_dB(find(~isnan(SMP_alsr{ATTind})));
		y=SMP_alsr{ATTind}(find(~isnan(SMP_alsr{ATTind})));
		[Cfit,MSE,fit]=fit1slope(x,y);
		SensitivitySlopes_alsr(ATTind)=Cfit(1);
		SensitivityIntercepts_alsr(ATTind)=Cfit(2);
	end
end

if doSCC
	% NSCC_CD(1) vs. Feature Level
	SensitivitySlopes_nsccCD{1}=NaN+ones(size(Nattens_dB));
	SensitivityIntercepts_nsccCD{1}=NaN+ones(size(Nattens_dB));
	for ATTind=1:length(Nattens_dB)
		if sum(~isnan(SMP_NSCC_CD{1,ATTind}))>1
			x=yTEMP.levels_dBSPL+FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{1,ATTind})));
			y=SMP_NSCC_CD{1,ATTind}(find(~isnan(SMP_NSCC_CD{1,ATTind})));
			[Cfit,MSE,fit]=fit1slope(x,y);
			SensitivitySlopes_nsccCD{1}(ATTind)=Cfit(1);
			SensitivityIntercepts_nsccCD{1}(ATTind)=Cfit(2);
		end
	end

	% NSCC_0delay(1) vs. Feature Level
	SensitivitySlopes_nscc0{1}=NaN+ones(size(Nattens_dB));
	SensitivityIntercepts_nscc0{1}=NaN+ones(size(Nattens_dB));
	for ATTind=1:length(Nattens_dB)
		if sum(~isnan(SMP_NSCC_0delay{1,ATTind}))>1
			x=yTEMP.levels_dBSPL+FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{1,ATTind})));
			y=SMP_NSCC_0delay{1,ATTind}(find(~isnan(SMP_NSCC_0delay{1,ATTind})));
			[Cfit,MSE,fit]=fit1slope(x,y);
			SensitivitySlopes_nscc0{1}(ATTind)=Cfit(1);
			SensitivityIntercepts_nscc0{1}(ATTind)=Cfit(2);
		end
	end

	% NSCC_peak(1) vs. Feature Level
	SensitivitySlopes_nsccPEAK{1}=NaN+ones(size(Nattens_dB));
	SensitivityIntercepts_nsccPEAK{1}=NaN+ones(size(Nattens_dB));
	for ATTind=1:length(Nattens_dB)
		if sum(~isnan(SMP_NSCC_peak{1,ATTind}))>1
			x=yTEMP.levels_dBSPL+FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{1,ATTind})));
			y=SMP_NSCC_peak{1,ATTind}(find(~isnan(SMP_NSCC_peak{1,ATTind})));
			[Cfit,MSE,fit]=fit1slope(x,y);
			SensitivitySlopes_nsccPEAK{1}(ATTind)=Cfit(1);
			SensitivityIntercepts_nsccPEAK{1}(ATTind)=Cfit(2);
		end
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Rate-FeatureLevels for each OAL
subplot(511)
LEGtext='';
for ATTind=1:length(Nattens_dB)
	%% Plot fitted lines
	if ~isnan(SensitivitySlopes_rate(ATTind))
		xdata=[min(FeatureLevels_dB(find(~isnan(SMP_rate{ATTind})))+yTEMP.levels_dBSPL) max(FeatureLevels_dB(find(~isnan(SMP_rate{ATTind})))+yTEMP.levels_dBSPL)];
		ydata=SensitivitySlopes_rate(ATTind)*xdata+SensitivityIntercepts_rate(ATTind);
		plot(xdata,ydata,'Marker','none','Color',ATTENcolors{ATTind},'LineStyle','-')
		hold on
		LEGtext{length(LEGtext)+1}=sprintf('%.f dB (%.2f)',Nattens_dB(ATTind)+dBAtt_2_SNR,SensitivitySlopes_rate(ATTind)); %% sp/sec/dB
	end
end
for ATTind=1:length(Nattens_dB)
	for FeatIND=FeatINDs
		if ~isnan(SMP_rate{ATTind}(FeatIND))
			plot(yTEMP.levels_dBSPL+FeatureLevels_dB(FeatIND),SMP_rate{ATTind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',ATTENcolors{ATTind},'LineStyle','none')
			hold on
		end
	end
end
YLIMITS_SMPrate=[0 300];
XLIMITS_SMPrate=[0 100];
ylim(YLIMITS_SMPrate)  % Fixed ordinate for all plots
xlim(XLIMITS_SMPrate)
%%%%%%%%%%%%%%%%%%%%%
% Home-made Feature Symbol Legend
%%%%%%%%%%%%%%%%%%%%%
LEGXleft=.8; LEGYbottom=0.15; LEGYstep=0.1; LEGXsymbOFFset=0.05;
FeatNum=0;
for FeatIND=fliplr(FeatINDs)
	FeatNum=FeatNum+1;
	plot(XLIMITS_SMPrate(1)+diff(XLIMITS_SMPrate)*(LEGXleft),YLIMITS_SMPrate(1)+diff(YLIMITS_SMPrate)*(LEGYbottom+(FeatNum-1)*LEGYstep),FEATmarkers{FeatIND}, ...
		'Color','k','MarkerSize',6)
	text(LEGXleft+LEGXsymbOFFset,LEGYbottom+(FeatNum-1)*LEGYstep,FeaturesText{FeatIND},'Units','norm','FontSize',10)
end
ylabel('Rate (sp/sec)')
xlabel('Feature Level (dB SPL)')
hleg=legend(LEGtext,1);
set(hleg,'FontSize',SMPlegFontSize)
hold off
set(gca,'FontSize',FIG.FontSize)
title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n', ...
	ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10), ...
	'units','norm')


%%%% ALSR-FeatureLevels for each OAL
subplot(512)
LEGtext='';
for ATTind=1:length(Nattens_dB)
	%% Plot fitted lines
	if ~isnan(SensitivitySlopes_alsr(ATTind))
		xdata=[min(FeatureLevels_dB(find(~isnan(SMP_alsr{ATTind})))+yTEMP.levels_dBSPL) max(FeatureLevels_dB(find(~isnan(SMP_alsr{ATTind})))+yTEMP.levels_dBSPL)];
		ydata=SensitivitySlopes_alsr(ATTind)*xdata+SensitivityIntercepts_alsr(ATTind);
		plot(xdata,ydata,'Marker','none','Color',ATTENcolors{ATTind},'LineStyle','-')
		hold on
		LEGtext{length(LEGtext)+1}=sprintf('%.f dB (%.2f)',Nattens_dB(ATTind)+dBAtt_2_SNR,SensitivitySlopes_alsr(ATTind));  % sp/sec/dB
	end
end
for ATTind=1:length(Nattens_dB)
	for FeatIND=FeatINDs
		if ~isnan(SMP_alsr{ATTind}(FeatIND))
			plot(yTEMP.levels_dBSPL+FeatureLevels_dB(FeatIND),SMP_alsr{ATTind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',ATTENcolors{ATTind},'LineStyle','none')
			hold on
		end
	end
end
YLIMITS_SMPalsr=[0 300];
XLIMITS_SMPalsr=XLIMITS_SMPrate;
ylim(YLIMITS_SMPalsr)  % Fixed ordinate for all plots
xlim(XLIMITS_SMPalsr)
ylabel('ALSR (sp/sec)')
xlabel('Feature Level (dB SPL)')
hleg=legend(LEGtext,1);
set(hleg,'FontSize',SMPlegFontSize)
hold off
set(gca,'FontSize',FIG.FontSize)

if doSCC
	%%%% NSCC_0delay-FeatureLevels for each OAL
	subplot(515)
	LEGtext='';
	for ATTind=1:length(Nattens_dB)
		%% Plot fitted lines
		if ~isnan(SensitivitySlopes_nscc0{1}(ATTind))
			xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{1,ATTind})))+yTEMP.levels_dBSPL) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{1,ATTind})))+yTEMP.levels_dBSPL)];
			ydata=SensitivitySlopes_nscc0{1}(ATTind)*xdata+SensitivityIntercepts_nscc0{1}(ATTind);
			plot(xdata,ydata,'Marker','none','Color',ATTENcolors{ATTind},'LineStyle','-')
			hold on
			LEGtext{length(LEGtext)+1}=sprintf('%.f dB (%.3f)',Nattens_dB(ATTind)+dBAtt_2_SNR,SensitivitySlopes_nscc0{1}(ATTind));  % sp/sec/dB
		end
	end
	for ATTind=1:length(Nattens_dB)
		for FeatIND=FeatINDs
			if ~isnan(SMP_NSCC_0delay{1,ATTind}(FeatIND))
				plot(yTEMP.levels_dBSPL+FeatureLevels_dB(FeatIND),SMP_NSCC_0delay{1,ATTind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',ATTENcolors{ATTind},'LineStyle','none')
				hold on
			end
		end
	end
	YLIMITS_SMPnscc0=[0 5];
	XLIMITS_SMPnscc0=XLIMITS_SMPrate;
	ylim(YLIMITS_SMPnscc0)  % Fixed ordinate for all plots
	xlim(XLIMITS_SMPnscc0)
	ylabel('SCC[CoincDet (sp/sec)] (at 0 delay)')
	title(sprintf('SCC1: BF+%.2f octaves re BF+%.2f octaves',SCC_octOFFSET2,SCC_octOFFSET1),'color','red')
	xlabel('Feature Level (dB SPL)')
	hleg=legend(LEGtext,1);
	set(hleg,'FontSize',SMPlegFontSize)
	hold off
	set(gca,'FontSize',FIG.FontSize)


	%%%% NSCC_peak-FeatureLevels for each OAL
	%%%% [This is the Deng and Geisler Analysis!!!]
	subplot(513)
	LEGtext='';
	for ATTind=1:length(Nattens_dB)
		%% Plot fitted lines
		if ~isnan(SensitivitySlopes_nsccPEAK{1}(ATTind))
			xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{1,ATTind})))+yTEMP.levels_dBSPL) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{1,ATTind})))+yTEMP.levels_dBSPL)];
			ydata=SensitivitySlopes_nsccPEAK{1}(ATTind)*xdata+SensitivityIntercepts_nsccPEAK{1}(ATTind);
			plot(xdata,ydata,'Marker','none','Color',ATTENcolors{ATTind},'LineStyle','-')
			hold on
			LEGtext{length(LEGtext)+1}=sprintf('%.f dB (%.3f)',Nattens_dB(ATTind)+dBAtt_2_SNR,SensitivitySlopes_nsccPEAK{1}(ATTind));  % sp/sec/dB SCC_CD
		end
	end
	for ATTind=1:length(Nattens_dB)
		for FeatIND=FeatINDs
			if ~isnan(SMP_NSCC_peak{1,ATTind}(FeatIND))
				plot(yTEMP.levels_dBSPL+FeatureLevels_dB(FeatIND),SMP_NSCC_peak{1,ATTind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',ATTENcolors{ATTind},'LineStyle','none')
				hold on
			end
		end
	end
	YLIMITS_SMPnsccPEAK=[0 10];
	XLIMITS_SMPnsccPEAK=XLIMITS_SMPrate;
	ylim(YLIMITS_SMPnsccPEAK)  % Fixed ordinate for all plots
	xlim(XLIMITS_SMPnsccPEAK)
	ylabel(sprintf('Peak SCC [CoincDet (sp/sec)] (at CD)\n [Deng and Geisler 1987]'))
	xlabel('Feature Level (dB SPL)')
	hleg=legend(LEGtext,1);
	set(hleg,'FontSize',SMPlegFontSize)
	hold off
	set(gca,'FontSize',FIG.FontSize)


	%%%% NSCC_CD-FeatureLevels for each OAL
	subplot(514)
	LEGtext='';
	for ATTind=1:length(Nattens_dB)
		%% Plot fitted lines
		if ~isnan(SensitivitySlopes_nsccCD{1}(ATTind))
			xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{1,ATTind})))+yTEMP.levels_dBSPL)  ...
				max(FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{1,ATTind})))+yTEMP.levels_dBSPL)];
			ydata=SensitivitySlopes_nsccCD{1}(ATTind)*xdata+SensitivityIntercepts_nsccCD{1}(ATTind);
			plot(xdata,ydata/1000,'Marker','none','Color',ATTENcolors{ATTind},'LineStyle','-')
			hold on
			%          LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f usec/dB)',Nattens_dB(ATTind)+dBAtt_2_SNR,SensitivitySlopes_nsccCD{1}(ATTind));
		end
	end
	for ATTind=1:length(Nattens_dB)
		for FeatIND=FeatINDs
			if ~isnan(SMP_NSCC_CD{1,ATTind}(FeatIND))
				plot(yTEMP.levels_dBSPL+FeatureLevels_dB(FeatIND),SMP_NSCC_CD{1,ATTind}(FeatIND)/1000, ...
					'Marker',FEATmarkers{FeatIND},'Color',ATTENcolors{ATTind},'LineStyle','none')
				hold on
			end
		end
	end
	YLIMITS_SMPnsccCD=1*[-1 1];
	XLIMITS_SMPnsccCD=XLIMITS_SMPrate;
	ylim(YLIMITS_SMPnsccCD)  % Fixed ordinate for all plots
	xlim(XLIMITS_SMPnsccCD)
	plot(XLIMITS_SMPnsccCD,zeros(1,2),'k:')
	ylabel(sprintf('Characteristic Delay\nof SCC (msec)'))
	xlabel('Feature Level (dB SPL)')
	%    hleg=legend(LEGtext,1);
	%    set(hleg,'FontSize',SMPlegFontSize)
	hold off
	set(gca,'FontSize',FIG.FontSize)
	
	%%%%%%%%%%%%%% Interactive Section to pick delays to try SMP on

	INTERACTyes=0; %bypassed for debugging simplicity
	if ~INTERACTyes
		disp('INTERACTIVE DELAY ANALYSIS SHUT OFF FOR NOW!!!')  % When turn back on, change subplots back to 61x from 51x
	end
	ARBdelay_msec=NaN;

	while INTERACTyes

		beep
		disp('CONVERT INTERACTICE ARBITRARY DELAY TO SCC_CD units')

		%%%%%%%%%%%%%%% ADD INTERACTIVE STUFF HERE

		temp=input('Enter arbitrary delay to compute SMP (in msec) [Return to quit]: ');
		if isempty(temp)
			INTERACTyes=0;
		else
			ARBdelay_msec=temp;

			for ATTEN=Nattens_dB
				ROWind=0;

				%%%%%%%%%%%%%%%%%%%% EH_reBF Calcs
				if isfield(unit,'EHvN_reBF_simFF')
					ATTind=find(Nattens_dB==ATTEN);
					for FeatIND=FeatINDs
						ROWind=ROWind+1;

						for SCCind=1:length(NSCC_BFinds)  % index of SCC to calculate
							if ~isempty(NSCCs{ROWind,ATTind})
								[yy,ABRdelayIND]=min(abs(NSCC_delays_usec{ROWind,ATTind}{SCCind}-ARBdelay_msec*1000));
								NSCC_ARBdelay{ROWind,ATTind}{SCCind}=NSCCs{ROWind,ATTind}{SCCind}(ABRdelayIND);
							else  % No Data to compute SCCs
								NSCC_ARBdelay{ROWind,ATTind}{SCCind}=NaN;
							end

							%%%%%%%%%%%%%%%%
							% Store SMP data
							%%%%%%%%%%%%%%%%
							SMP_NSCC_ARBdelay{SCCind,ATTind}(FeatIND)=NSCC_ARBdelay{ROWind,ATTind}{i};

						end %End if data for this condition, plot
					end % End Feature
				end % If EHrBF data
			end % Levels

			% NSCC_ARBdelay(1) vs. Feature Level
			SensitivitySlopes_nsccARB{1}=NaN+ones(size(Nattens_dB));
			SensitivityIntercepts_nsccARB{1}=NaN+ones(size(Nattens_dB));
			for ATTind=1:length(Nattens_dB)
				if sum(~isnan(SMP_NSCC_ARBdelay{1,ATTind}))>1
					x=yTEMP.levels_dBSPL+FeatureLevels_dB(find(~isnan(SMP_NSCC_ARBdelay{1,ATTind})));
					y=SMP_NSCC_ARBdelay{1,ATTind}(find(~isnan(SMP_NSCC_ARBdelay{1,ATTind})));
					[Cfit,MSE,fit]=fit1slope(x,y);
					SensitivitySlopes_nsccARB{1}(ATTind)=Cfit(1);
					SensitivityIntercepts_nsccARB{1}(ATTind)=Cfit(2);
				end
			end

			%%%% NSCC_ARBdelay-FeatureLevels for each OAL
			figure(FIGnum)
			subplot(616)
			LEGtext='';
			for ATTind=1:length(Nattens_dB)
				%% Plot fitted lines
				if ~isnan(SensitivitySlopes_nsccARB{1}(ATTind))
					xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_ARBdelay{1,ATTind})))+yTEMP.levels_dBSPL) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_ARBdelay{1,ATTind})))+yTEMP.levels_dBSPL)];
					ydata=SensitivitySlopes_nsccARB{1}(ATTind)*xdata+SensitivityIntercepts_nsccARB{1}(ATTind);
					plot(xdata,ydata,'Marker','none','Color',ATTENcolors{ATTind},'LineStyle','-')
					hold on
					LEGtext{length(LEGtext)+1}=sprintf('%.f dB (%.3f)',Nattens_dB(ATTind)+dBAtt_2_SNR,SensitivitySlopes_nsccARB{1}(ATTind));  % 1/dB
				end
			end
			for ATTind=1:length(Nattens_dB)
				for FeatIND=FeatINDs
					if ~isnan(SMP_NSCC_ARBdelay{1,ATTind}(FeatIND))
						plot(yTEMP.levels_dBSPL+FeatureLevels_dB(FeatIND),SMP_NSCC_ARBdelay{1,ATTind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',ATTENcolors{ATTind},'LineStyle','none')
						hold on
					end
				end
			end
			YLIMITS_SMPnsccARB=YLIMITS_SMPnscc0;
			XLIMITS_SMPnsccARB=XLIMITS_SMPnscc0;
			ylim(YLIMITS_SMPnsccARB)  % Fixed ordinate for all plots
			xlim(XLIMITS_SMPnsccARB)
			ylabel(sprintf('SCC (at delay = %.2f msec)',ARBdelay_msec))
			title(sprintf('SCC1: BF+%.2f octaves re BF+%.2f octaves',SCC_octOFFSET2,SCC_octOFFSET1),'color','red')
			xlabel('Feature Level (dB SPL)')
			hleg=legend(LEGtext,1);
			set(hleg,'FontSize',SMPlegFontSize)
			hold off
			set(gca,'FontSize',FIG.FontSize)
		end


	end % While
end
orient tall
%% END SMP figure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot all Rhos and CDs in bubbles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1003);
panel=0;
ROWind=0;
for FeatIND=FeatINDs
    ROWind=ROWind+1;
    eval(['myFeatures=unit.EHvN_reBF_simFF.',FeaturesText{FeatIND},'{1,1}.FeatureFreqs_Hz{1,1};']);
    for ATTind=1:length(Nattens_dB)
        panel=panel+1;
        xymin=min(cell2mat(NSAC_BFs_kHz{ROWind,ATTind}));
        xymax=max(cell2mat(NSAC_BFs_kHz{ROWind,ATTind}));
        xyhem=(xymax/xymin)^(0.1);%allowance around xy
        xyrange=[xymin xymax];

		data2plot=zeros(length(NSCC_BFs_kHz{ROWind,ATTind}),4);
        for SCCind=1:length(NSCC_BFs_kHz{ROWind,ATTind})
            data2plot(SCCind,:)=[NSCC_BFs_kHz{ROWind,ATTind}{SCCind},...
            NSCC_Rho{ROWind,ATTind}{SCCind},NSCC_peaks{ROWind,ATTind}{SCCind}];
        end
		SAC2plot=zeros(length(NSAC_BFs_kHz{ROWind,ATTind}),2);
		for BFind=1:length(NSAC_BFs_kHz{ROWind,ATTind})
			SAC2plot(BFind,:)=[NSAC_BFs_kHz{ROWind,ATTind}{BFind},NSAC_peaks{ROWind,ATTind}{BFind}];
		end
		dotSizeFac=20;
		subplot(length(FeatINDs)*2,length(Nattens_dB),panel)
        scatter(data2plot(:,1),data2plot(:,2),data2plot(:,3).^2*dotSizeFac,'k','filled'), hold on
        scatter(SAC2plot(:,1),SAC2plot(:,1),dotSizeFac,'k','filled'), hold on
        xlim(xyrange),ylim(xyrange)
		
		dotSizeFac=0.75;
		subplot(length(FeatINDs)*2,length(Nattens_dB),panel+length(FeatINDs)*length(Nattens_dB))
        scatter(data2plot(:,1),data2plot(:,2),data2plot(:,4).^2*dotSizeFac,'r','filled'), hold on
        scatter(SAC2plot(:,1),SAC2plot(:,1),SAC2plot(:,2).^2*dotSizeFac,'r','filled')		
        xlim(xyrange),ylim(xyrange)

		%draw indicators at features
		subplot(length(FeatINDs)*2,length(Nattens_dB),panel)
		title('Rho')
		scatter(myFeatures(FeatIND)/1000,myFeatures(FeatIND)/1000,'b'), hold on;
		text(myFeatures(FeatIND)/1000,myFeatures(FeatIND)/1000,FeaturesText{FeatIND},'color','b','HorizontalAlignment','left','VerticalAlignment','top');
		if FeatIND==4
			scatter(myFeatures(5)/1000,myFeatures(5)/1000,'b'), hold on;
			text(myFeatures(5)/1000,myFeatures(5)/1000,FeaturesText{5},'color','b','HorizontalAlignment','left','VerticalAlignment','top');
		end
        set(gca,'XScale','log','YScale','log')
        axis equal

		subplot(length(FeatINDs)*2,length(Nattens_dB),panel+length(FeatINDs)*length(Nattens_dB))
		title('Peak')
		scatter(myFeatures(FeatIND)/1000,myFeatures(FeatIND)/1000,'b'), hold on;
		text(myFeatures(FeatIND)/1000,myFeatures(FeatIND)/1000,FeaturesText{FeatIND},'color','b','HorizontalAlignment','left','VerticalAlignment','top');
		if FeatIND==4
			scatter(myFeatures(5)/1000,myFeatures(5)/1000,'b'), hold on;
			text(myFeatures(5)/1000,myFeatures(5)/1000,FeaturesText{5},'color','b','HorizontalAlignment','left','VerticalAlignment','top');
		end
        set(gca,'XScale','log','YScale','log')
        axis equal
		
		if ATTind==1
			subplot(length(FeatINDs)*2,length(Nattens_dB),panel)
            ylabel(sprintf('Feature %s',FeaturesText{FeatIND}))
			subplot(length(FeatINDs)*2,length(Nattens_dB),panel+length(FeatINDs)*length(Nattens_dB))
            ylabel(sprintf('Feature %s',FeaturesText{FeatIND}))
        end
        if ROWind==2
            xlabel(sprintf('ATT %.0fdB',Nattens_dB(ATTind)))
		end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot CD, PEAK, and Rho wrt |BF difference|
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1004);
ROWind=0;
LEGtext=cell(1,length(Nattens_dB));
for FeatIND=FeatINDs
    ROWind=ROWind+1;
    for ATTind=1:length(Nattens_dB)
        data2plot=zeros(length(NSCC_BFs_kHz{ROWind,ATTind}),4);
        for SCCind=1:length(NSCC_BFs_kHz{ROWind,ATTind})
            data2plot(SCCind,1)=log2(max(NSCC_BFs_kHz{ROWind,ATTind}{SCCind})/min(NSCC_BFs_kHz{ROWind,ATTind}{SCCind}));
            data2plot(SCCind,2)=NSCC_CDs_usec{ROWind,ATTind}{SCCind};
            data2plot(SCCind,3)=NSCC_peaks{ROWind,ATTind}{SCCind};
            data2plot(SCCind,4)=NSCC_Rho{ROWind,ATTind}{SCCind};
		end
		for BFind=1:length(NSAC_BFs_kHz{ROWind,ATTind})
            data2plot(SCCind,1)=0;
            data2plot(SCCind,2)=NSAC_CDs_usec{ROWind,ATTind}{BFind};
            data2plot(SCCind,3)=NSAC_peaks{ROWind,ATTind}{BFind};
            data2plot(SCCind,4)=1;
		end
        data2plot=sortrows(data2plot);
        ptstyle='x';
        subplot(3,length(FeatINDs),ROWind)
		plot(data2plot(:,1),data2plot(:,2),'LineStyle',ptstyle,'color',ptcolor{ATTind}), hold on
        subplot(3,length(FeatINDs),length(FeatINDs)+ROWind)
		plot(data2plot(:,1),data2plot(:,3),'LineStyle',ptstyle,'color',ptcolor{ATTind}), hold on
        subplot(3,length(FeatINDs),2*length(FeatINDs)+ROWind)
		plot(data2plot(:,1),data2plot(:,4),'LineStyle',ptstyle,'color',ptcolor{ATTind}), hold on
        LEGtext{ATTind}=sprintf('atten %.0f',Nattens_dB(ATTind));
	end
	subplot(3,length(FeatINDs),ROWind), title(FeaturesText{FeatIND})
	subplot(3,length(FeatINDs),2*length(FeatINDs)+ROWind), xlabel('octave difference in frequency')
end
subplot(3,length(FeatINDs),1), ylabel('CD (ms)')
subplot(3,length(FeatINDs),length(FeatINDs)+1), ylabel('Peak')
subplot(3,length(FeatINDs),2*length(FeatINDs)+1), ylabel('Rho')
subplot(3,length(FeatINDs),4),legend(LEGtext,'FontSize',6,'location','northeast');
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot CD, PEAK, and Rho only for BF pairs including BF@Feature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1005);
plotfield=0;
COLind=0;
xlimits=NaN*ones(length(FeatINDs),2);
ylimits=NaN*ones(3,2);%rows=graphs, left col=min, right col=max;
BFs=NaN*ones(1,length(FeatINDs));
data2plot=cell(length(FeatINDs),length(Nattens_dB));
d2p_NSACind=zeros(length(FeatINDs),1);
altCD=cell(length(FeatINDs),1);
for FeatIND=FeatINDs
    COLind=COLind+1;
    LEGtext=cell(length(Nattens_dB),1);
    for ATTind=1:length(Nattens_dB)
        plotfield=plotfield+1;
        %find all BF pairs including unit.Info.BF_kHz
        
        BFprev=BFs(COLind);
        [SCCpos,SCCs_belowBF,SCCs_aboveBF,BFind,BFs(COLind)]=getSCCindsWithBF(unit.Info.BF_kHz,NSAC_BFs_kHz{COLind,ATTind},NSCC_BFs_kHz{COLind,ATTind});
        
        if ~isnan(BFprev)&&BFs(COLind)~=BFprev
            fprintf('Warning: BFind is not constant within Feature %s: now %.3f, prev %.3f',FeaturesText{FeatIND},BFs(COLind),BFprev)
		end
		
		data2plot{COLind,ATTind}=zeros(size(SCCpos,1),4);
        for SCCposind=1:size(SCCpos,1)
            data2plot{COLind,ATTind}(SCCposind,:)=[...
                log2(NSCC_BFs_kHz{COLind,ATTind}{SCCpos(SCCposind,1)}(3-SCCpos(SCCposind,2))/BFs(COLind)),... 
                NSCC_CDs_usec{COLind,ATTind}{SCCpos(SCCposind,1)}/1000,...
                NSCC_peaks{COLind,ATTind}{SCCpos(SCCposind,1)},...
                NSCC_Rho{COLind,ATTind}{SCCpos(SCCposind,1)}];
		end
		%insert a line representing [BFind,BFind] i.e. SAC data.
        data2plot{COLind,ATTind}=[data2plot{COLind,ATTind}(1:length(SCCs_belowBF),:);...
            0,NSAC_CDs_usec{COLind,ATTind}{BFind}/1000,NSAC_peaks{COLind,ATTind}{BFind},1;...
            data2plot{COLind,ATTind}(length(SCCs_belowBF)+1:size(data2plot{COLind,ATTind},1),:)];
		if d2p_NSACind(COLind)~=0 && d2p_NSACind(COLind)~=length(SCCs_belowBF)+1
			fprintf('Warining: index of central freq is not constant within Feature %s: %d %d',FeaturesText{FeatIND},d2p_NSACind(COLind),length(SCCs_belowBF)+1)
		else
			d2p_NSACind(COLind)=length(SCCs_belowBF)+1;
		end
        %get vertical limits of graph windows
        xlimits(COLind,:)=[min([data2plot{COLind,ATTind}(:,1);xlimits(COLind,1)]),max([data2plot{COLind,ATTind}(:,1);xlimits(COLind,2)])];
        ylimits=[min([data2plot{COLind,ATTind}(:,2);ylimits(1,1)]),max([data2plot{COLind,ATTind}(:,2);ylimits(1,2)]);...
            min([data2plot{COLind,ATTind}(:,3);ylimits(2,1)]),max([data2plot{COLind,ATTind}(:,3);ylimits(2,2)]);...
            min([data2plot{COLind,ATTind}(:,4);ylimits(3,1)]),max([data2plot{COLind,ATTind}(:,4);ylimits(3,2)])];
		
		subplot(3,length(FeatINDs),0*length(FeatINDs)+COLind)
        plot(data2plot{COLind,ATTind}(:,1),data2plot{COLind,ATTind}(:,2),['-',ptcolor{ATTind}]), hold on
        if COLind==1
            ylabel('CD (msec)')
        end
        title(sprintf('feature %s',FeaturesText{FeatIND}))

        subplot(3,length(FeatINDs),1*length(FeatINDs)+COLind)
        plot(data2plot{COLind,ATTind}(:,1),data2plot{COLind,ATTind}(:,3),['-',ptcolor{ATTind}]), hold on
        if COLind==1
            ylabel('PEAKS (no unit)')
        end
        
        subplot(3,length(FeatINDs),2*length(FeatINDs)+COLind)
        plot(data2plot{COLind,ATTind}(:,1),data2plot{COLind,ATTind}(:,4),['-',ptcolor{ATTind}]), hold on
        if COLind==1
            ylabel('Rho (no unit)')
        end
        xlabel('octave difference')
        LEGtext{ATTind}=sprintf('att: %ddB',Nattens_dB(ATTind));
    end
    subplot(3,length(FeatINDs),3), leg=legend(LEGtext);
    set(leg,'Location','northeast','FontSize',6)    
end
%draw additional guidelines, indicators
COLind=0;
for FeatIND=FeatINDs
    COLind=COLind+1;
    eval(['myFeatures_kHz=unit.EHvN_reBF_simFF.',FeaturesText{FeatIND},'{1,1}.FeatureFreqs_Hz{1,1}/1000;']);
    %horizontal lines @ periods, on CD panels
	myFs=[3 4 5];
    subplot(3,length(FeatINDs),COLind)
    plot(xlimits(COLind,:),[0 0],':','color',[.5 .5 .5]), hold on
    for myF=myFs
        myY_msec=1/myFeatures_kHz(myF);
        plot(xlimits(COLind,:),myY_msec*ones(1,2),':','color',[.5 .5 .5]), hold on
        text(xlimits(COLind,1),myY_msec,sprintf('1/%s',FeaturesText{myF}),'HorizontalAlignment','right','VerticalAlignment','middle')
        ylimits(1,:)=[min([myY_msec-0.1;ylimits(1,1)]),max([myY_msec+0.1;ylimits(1,2)])];		
	end
	%"alternative CDs" - calculated CD - {1 or 2} periods of {F1, T1, F2}.
	%{}=decided by observation, hard-coded.
	if COLind==1
		altCD{COLind}=[data2plot{1,1}(1,1:2);...
			data2plot{1,1}(2,1),data2plot{1,1}(2,2)-1/myFeatures_kHz(3);...
			data2plot{1,1}(3:7,1:2);...
			data2plot{1,4}(8,1:2);...
			data2plot{1,1}(9,1),data2plot{1,1}(9,2)-1/myFeatures_kHz(3);...
			data2plot{1,4}(10,1),data2plot{1,4}(10,2)-1/myFeatures_kHz(3)];
	else
		altCD{COLind}=[data2plot{2,4}(1:7,1:2);...
			data2plot{2,4}(8,1),data2plot{2,4}(8,2)-1/myFeatures_kHz(5);...
			data2plot{2,4}(9,1),data2plot{2,4}(9,2)-1/myFeatures_kHz(5);...
			data2plot{2,4}(10,1:2)];
	end
	plot(altCD{COLind}(:,1),altCD{COLind}(:,2),'--k')
	
    for ROWind=0:2
        subplot(3,length(FeatINDs),ROWind*length(FeatINDs)+COLind)
        if COLind==1
            myFs=[3 4];%F1 T1, hard code for now
        elseif COLind==2
            myFs=[4 5];%F1 T1 F2, hard code for now
        end
        for myF=myFs
            myX=log2(myFeatures_kHz(myF)/BFs(COLind));
            plot(myX*ones(1,2),ylimits(ROWind+1,:),':','color',[.5 .5 .5]), hold on
            text(myX,ylimits(ROWind+1,1),FeaturesText{myF},'HorizontalAlignment','center','VerticalAlignment','bottom')
            xlim(xlimits(COLind,:)), ylim(ylimits(ROWind+1,:))
        end        
    end
end

figure(1051)
COLind=0;
for FeatIND=FeatINDs
	COLind=COLind+1;
	subplot(3,length(FeatINDs),COLind)
	plot(altCD{COLind}(1:d2p_NSACind(COLind),1).*(-1),altCD{COLind}(1:d2p_NSACind(COLind),2),'--k'), hold on
	plot(altCD{COLind}(d2p_NSACind(COLind):end,1),altCD{COLind}(d2p_NSACind(COLind):end,2),'-k'), hold on
	if COLind==1
		ylabel('CD (msec)')
	end
	xlim([0,xlimits(COLind,2)]), ylim(ylimits(1,:))
	for ATTind=1:length(Nattens_dB)
		subplot(3,length(FeatINDs),length(FeatINDs)+COLind)
		plot(data2plot{COLind,ATTind}(1:d2p_NSACind(COLind),1).*(-1),data2plot{COLind,ATTind}(1:d2p_NSACind(COLind),3),'--','color',ptcolor{ATTind}), hold on
		plot(data2plot{COLind,ATTind}(d2p_NSACind(COLind):end,1),data2plot{COLind,ATTind}(d2p_NSACind(COLind):end,3),'-','color',ptcolor{ATTind}), hold on
		if COLind==1
			ylabel('PEAKS (no unit)')
		end
		xlim([0,xlimits(COLind,2)]), ylim(ylimits(2,:))
		subplot(3,length(FeatINDs),2*length(FeatINDs)+COLind)
		plot(data2plot{COLind,ATTind}(1:d2p_NSACind(COLind),1).*(-1),data2plot{COLind,ATTind}(1:d2p_NSACind(COLind),4),'--','color',ptcolor{ATTind}), hold on
		plot(data2plot{COLind,ATTind}(d2p_NSACind(COLind):end,1),data2plot{COLind,ATTind}(d2p_NSACind(COLind):end,4),'-','color',ptcolor{ATTind}), hold on
		if COLind==1
			ylabel('Rho (no unit)')
		end
		xlim([0,xlimits(COLind,2)]), ylim(ylimits(3,:))
	end
	subplot(3,length(FeatINDs),COLind),title(sprintf('feature %s',FeaturesText{FeatIND}))
	subplot(3,length(FeatINDs),2*length(FeatINDs)+COLind),xlabel('octave difference')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO SUMMARY SMP PLOT versus Natten
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SMPlegFontSize=7;
FIGnum=2000;
figure(FIGnum); clf
set(gcf,'units','norm','pos',[0.4227    0.0654    0.2422    0.3555],'Resize','off')

NOnoiseIND=find(Nattens_dB==120);
noiseINDs=setdiff(1:length(Nattens_dB),NOnoiseIND);
LOWnoiseIND=find(Nattens_dB==max(Nattens_dB(noiseINDs)));
xmax=Nattens_dB(LOWnoiseIND)+dBAtt_2_SNR+15; xmin=min(Nattens_dB(noiseINDs)+dBAtt_2_SNR);
ymin=0; ymax=6;
yminFACT=-.4; ymaxFACT=1.7;

% RATE
subplot(311)
plot(Nattens_dB(noiseINDs)+dBAtt_2_SNR,SensitivitySlopes_rate(noiseINDs),'b-x')
xlim([xmin-2 xmax+2])
hold on
plot(xmax,SensitivitySlopes_rate(NOnoiseIND),'ro')
plot([xmax Nattens_dB(LOWnoiseIND)+dBAtt_2_SNR],SensitivitySlopes_rate([NOnoiseIND LOWnoiseIND]),'r--')
plot([xmin-2 xmax+2],[0 0],'k:')
hold off
% ylim([ymin ymax])
ylim([yminFACT ymaxFACT]*SensitivitySlopes_rate(NOnoiseIND))
text(xmax,yminFACT*SensitivitySlopes_rate(NOnoiseIND),'IQ','units','data','HorizontalAlignment','center','VerticalAlignment','bottom','color','red')
title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\nRATE', ...
	ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10), ...
	'units','norm')
% title('RATE')
ylabel('SMP Slope (sp/sec/dB)')
% xlabel('Noise Attenuation (dB)')
set(gca,'XDir','reverse')

% ALSR
subplot(312)
plot(Nattens_dB(noiseINDs)+dBAtt_2_SNR,SensitivitySlopes_alsr(noiseINDs),'b-x')
xlim([xmin-2 xmax+2])
hold on
plot(xmax,SensitivitySlopes_alsr(NOnoiseIND),'ro')
plot([xmax Nattens_dB(LOWnoiseIND)+dBAtt_2_SNR],SensitivitySlopes_alsr([NOnoiseIND LOWnoiseIND]),'r--')
plot([xmin-2 xmax+2],[0 0],'k:')
hold off
if SensitivitySlopes_alsr(NOnoiseIND)>0
	ylim([yminFACT ymaxFACT]*SensitivitySlopes_alsr(NOnoiseIND))
else
	ylim([SensitivitySlopes_alsr(NOnoiseIND) 4])
end
text(xmax,yminFACT*SensitivitySlopes_alsr(NOnoiseIND),'IQ','units','data','HorizontalAlignment','center','VerticalAlignment','bottom','color','red')
title('ALSR')
ylabel('SMP Slope (sp/sec/dB)')
% xlabel('Noise Attenuation (dB)')
set(gca,'XDir','reverse')

if doSCC
	% Deng and Geisler 1987
	% yminDG=-6e-1; ymaxDG=0;
	subplot(313)
	plot(Nattens_dB(noiseINDs)+dBAtt_2_SNR,SensitivitySlopes_nsccPEAK{1}(noiseINDs),'b-x')
	xlim([xmin-2 xmax+2])
	hold on
	plot(xmax,SensitivitySlopes_nsccPEAK{1}(NOnoiseIND),'ro')
	plot([xmax Nattens_dB(LOWnoiseIND)+dBAtt_2_SNR],SensitivitySlopes_nsccPEAK{1}([NOnoiseIND LOWnoiseIND]),'r--')
	plot([xmin-2 xmax+2],[0 0],'k:')
	hold off
	if ~isnan(SensitivitySlopes_nsccPEAK{1}(NOnoiseIND))
		if SensitivitySlopes_nsccPEAK{1}(NOnoiseIND)>0
			ylim([yminFACT ymaxFACT]*SensitivitySlopes_nsccPEAK{1}(NOnoiseIND))
		else
			ylim([ymaxFACT yminFACT]*SensitivitySlopes_nsccPEAK{1}(NOnoiseIND))
		end
	end
	text(xmax,ymaxFACT*SensitivitySlopes_nsccPEAK{1}(NOnoiseIND),'IQ','units','data','HorizontalAlignment','center','VerticalAlignment','bottom','color','red')
	title('Peak Cross-BF Coincidence Detection - DENG AND GEISLER 1987')
	ylabel('SMP Slope (sp/sec/dB)')
	xlabel('SNR (dB)')
	set(gca,'XDir','reverse')
end

orient tall

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unlock all figures
figlist=get(0,'Children');
for FIGind=figlist
	set(FIGind,'Resize','on')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print all important figures
if PRINTyes
	figPRINTlist=[14 100 101 1000 1002 1 2000];
% 	figPRINTlist=[101 1000 1002 1 2000];
	for FIGind=figPRINTlist
		print(FIGind,'-PChesapeake')
% 		print(FIGind,'-PChoptank')
	end
% 	figure(1001)  % DFT figure won't print right for some reason???
% 	print -P'Adobe PDF'
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Turn off saved PICS feature
SavedPICS=[]; SavedPICnums=[];
SavedPICSuse=0;

% % For ARO2005: ANmodel figure
% save SMP_FIG

return;
