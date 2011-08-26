function UnitPlot_EHrBF_simFF(ExpDate,UnitName)
% File: UnitPlot_EHrBF_simFF.m
% Modified Date: 07Jan2005: incorporated EHrBFi interleaving here
% Date: 28Sep2004 (M. Heinz) (Modified from UnitPlot_EHrBF.m)
% For: NOHR Experiments
% Usage: UnitPlot_EHrBF_simFF(ExpDate,UnitName)
%
% ExpDate: e.g., '070804' (converted later)
% UnitName: '3.07' (converted later)
%
% Plots EH_reBF_simFF data for a given experiment and unit.  Loads 'UNITSdata/unit.T.U.mat' file.
% UnitAnal_EHrBF_simFF.m performs the relevant analysis.
%

global NOHR_dir NOHR_ExpList
global FeaturesText FormsAtHarmonicsText InvertPolarityText
   
%%%% Verify in passed parameters if needed
if ~exist('ExpDate','var')
   ExpDate=0;
%%% HARD CODE FOR NOW
ExpDate='070804'
   while ~ischar(ExpDate)
      ExpDate=input('Enter Experiment Date (e.g., ''070804''): ');
   end
end
if ~exist('UnitName','var')
   UnitName=0;
%%% HARD CODE FOR NOW
UnitName='3.35'
   while ~ischar(UnitName)
      UnitName=input('Enter Unit Name (e.g., ''3.07''): ');
   end
end

%%%% Find the full Experiment Name 
ExpDateText=strcat('20',ExpDate(end-1:end),'_',ExpDate(1:2),'_',ExpDate(3:4));
for i=1:length(NOHR_ExpList)
   if ~isempty(strfind(NOHR_ExpList{i},ExpDateText))
      ExpName=NOHR_ExpList{i};
      break;
   end
end
if ~exist('ExpName','var')
   disp(sprintf('***ERROR***:  Experiment: %s not found\n   Experiment List:',ExpDate))
   disp(strvcat(NOHR_ExpList))
   beep
   break
end

%%%% Parse out the Track and Unit Number 
TrackNum=str2num(UnitName(1:strfind(UnitName,'.')-1));
UnitNum=str2num(UnitName(strfind(UnitName,'.')+1:end));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data_dir=fullfile(NOHR_dir,'ExpData');
anal_dir=fullfile(NOHR_dir,'Data Analysis');
stim_dir=fullfile(NOHR_dir,'Stimuli');

eval(['cd ''' fullfile(data_dir,ExpName) ''''])
disp(sprintf('Plotting (EHreBF_simFF) Experiment: ''%s''; Unit: %d.%02d',ExpName,TrackNum,UnitNum))

%%%% Load unit structure for this unit
UnitFileName=sprintf('unit.%d.%02d.mat',TrackNum,UnitNum);
eval(['ddd=dir(''' fullfile('UNITSdata',UnitFileName) ''');'])
% If UNITSdata file does not exist, run analysis
if isempty(ddd)
   UnitAnal_EHrBF_simFF(ExpDate,UnitName,0);
end
eval(['load ''' fullfile('UNITSdata',UnitFileName) ''''])

% Make sure there is EH_reBF data
if ~isfield(unit,'EH_reBF')
   disp(sprintf('*** No EH_reBF data for this unit!!!'))
   beep
   return;
end

% If EH_reBF_simFF analysis is not completed, run here
if ~isfield(unit,'EH_reBF_simFF')
   UnitAnal_EHrBF_simFF(ExpDate,UnitName,0);   
   eval(['load ''' fullfile('UNITSdata',UnitFileName) ''''])
end
         
%%%% Plot data
LEVELmarkers={'s','^','*'};
LEVELlines={'-','--',':'};
LEVELcolors={'b','r','g'};

FIG.FontSize=8;
if strcmp(unit.EH_reBF.interleaved,'yes')
   FIG.FontSize=6;
   XLIMITS=unit.Info.BF_kHz*[(2^-.25)*.99 (2^.25)/.99];
else
   FIG.FontSize=8;
   XLIMITS=unit.Info.BF_kHz*[(2^-1)*.99 (2^1)/.99];
end


%%% Separate Plot for each Condition
%%% Only plot Synch and Phase for Feature of interest (for now)
UnitFeats=fieldnames(unit.EH_reBF);
UnitFeats=UnitFeats(~strcmp(UnitFeats,'interleaved'));  %% 010705: M Heinz; takes out newly added "interleaved" field
clear FeatINDs
for FeatIND=1:length(UnitFeats)
   FeatINDs(FeatIND)=find(strcmp(FeaturesText,UnitFeats{FeatIND}));
end
 
for FeatIND=FeatINDs
   for HarmonicsIND=1:2
      for PolarityIND=1:2
         
         eval(['yTEMP=unit.EH_reBF_simFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
         if ~isempty(yTEMP)
            
            %%%% Take out (mark with NaNs) insignificant phase and synch values
            warning off % don't need to see "divide by zero" error over and over
            for LEVind=1:length(yTEMP.levels_dBSPL)
               for FREQind=1:length(yTEMP.BFs_kHz)
                  yTEMP.synch{LEVind,FREQind}=yTEMP.synch{LEVind,FREQind}.*yTEMP.RaySig{LEVind,FREQind}./yTEMP.RaySig{LEVind,FREQind};
                  yTEMP.phase{LEVind,FREQind}=yTEMP.phase{LEVind,FREQind}.*yTEMP.RaySig{LEVind,FREQind}./yTEMP.RaySig{LEVind,FREQind};
               end
            end
            warning on
            
            %%%% Later, Can choose feature to plot
            FEATtoPLOT=FeaturesText{FeatIND};
            FeatPlotIND=find(strcmp(FeaturesText,FEATtoPLOT));
            %             FeatPlotIND=4
             
            FIGnum=str2num(strcat(num2str(FeatIND),num2str(HarmonicsIND),num2str(PolarityIND)));
            
            rateSlopes=NaN+zeros(size(yTEMP.rate));
            synchSlopes=NaN+zeros(size(yTEMP.rate));
            phaseSlopes=NaN+zeros(size(yTEMP.rate));
            
            figure(FIGnum); clf
            set(gcf,'pos',[420   199   976   761])
            %%%% Rate
            subplot(321)
            clear LEGtext
            for LEVind=1:length(yTEMP.levels_dBSPL)
               semilogx(yTEMP.BFs_kHz,yTEMP.rate(LEVind,:),'Marker',LEVELmarkers{LEVind},'Color',LEVELcolors{LEVind},'LineStyle',LEVELlines{LEVind})
               hold on
               LEGtext{LEVind}=sprintf('%.f dB SPL',yTEMP.levels_dBSPL(LEVind));
            end
            semilogx(unit.Info.BF_kHz*ones(1,2),[0 1e6],'k:')
            %             ylim([0 ceil(max(max(yTEMP.rate))/50)*50])
            ylim([0 300])  % Fixed ordinate for all plots
            xlim(XLIMITS)
            set(gca,'XTick',fliplr(yTEMP.BFs_kHz))
            ylabel('Overall Rate (sp/sec)')
            ht1=title(sprintf('Exp: %s; Unit: %s [BF=%.4f kHz, Thr= %.f dB atten]\n[UnitPlot_EHreBF_SIMreFF]   Feature: %s (plotting: %s);    Formants at Harmonics: %s;    Invert Polarity: %s', ...
               unit.Info.ExpName,unit.Info.Unit,unit.Info.BF_kHz,unit.Info.Threshold_dBatten,FeaturesText{FeatIND}, ...
               FeaturesText{FeatPlotIND},upper(FormsAtHarmonicsText{HarmonicsIND}),upper(InvertPolarityText{PolarityIND})));
            set(ht1,'units','norm','Interpreter','none','pos',[1.2 1.0292 0])
            hold off
            set(gca,'FontSize',FIG.FontSize)
            
            %%%% Rate Change
            subplot(322)
            clear LEGtextSlope
            for LEVind=2:length(yTEMP.levels_dBSPL)
               rateSlopes(LEVind,:)=(yTEMP.rate(LEVind,:)-yTEMP.rate(LEVind-1,:))/diff(yTEMP.levels_dBSPL(LEVind-1:LEVind));
               semilogx(yTEMP.BFs_kHz,rateSlopes(LEVind,:),'Marker',LEVELmarkers{LEVind},'MarkerEdgeColor',LEVELcolors{LEVind}, ...
                  'Color',LEVELcolors{LEVind-1},'LineStyle',LEVELlines{LEVind})
               hold on
               LEGtextSlope{LEVind}=sprintf('%.f-%.f dB SPL',yTEMP.levels_dBSPL(LEVind-1),yTEMP.levels_dBSPL(LEVind));
            end
            semilogx(unit.Info.BF_kHz*ones(1,2),[-1e6 1e6],'k:')
            semilogx(unit.Info.BF_kHz*[.5 2],[0 0],'k-')
            ylabel('Rate Slope (sp/sec/dB)')
            % ylim([-1 1]*max(ceil(max(abs(rateSlopes))/.02)*.02))
            ymax_DeltaRate=10;  % 0 to 300 in 30 dB
            ylim([-1 1]*ymax_DeltaRate)
            xlim(XLIMITS)
            set(gca,'XTick',fliplr(yTEMP.BFs_kHz))
            hold off
            set(gca,'FontSize',FIG.FontSize)
            
            %%%% Synch
            subplot(323)
            synchTEMP=NaN+ones(size(yTEMP.synch));
            for LEVind=1:length(yTEMP.levels_dBSPL)
               for FREQind=1:length(yTEMP.BFs_kHz)
                  if ~isempty(yTEMP.synch{LEVind,FREQind})
                     synchTEMP(LEVind,FREQind)=yTEMP.synch{LEVind,FREQind}(FeatPlotIND);
                  end
               end
               semilogx(yTEMP.BFs_kHz,synchTEMP(LEVind,:),'Marker',LEVELmarkers{LEVind},'Color',LEVELcolors{LEVind},'LineStyle',LEVELlines{LEVind})
               hold on
            end
            if strcmp(unit.EH_reBF.interleaved,'yes')
               hleg=legend(LEGtext,1);
            else
               hleg=legend(LEGtext,4);
            end
            set(hleg,'FontSize',6)
            semilogx(unit.Info.BF_kHz*ones(1,2),[0 1],'k:')
            ylabel(sprintf('Synch (to %s)',FeaturesText{FeatPlotIND}))
            ylim([0 1])
            xlim(XLIMITS)
            set(gca,'XTick',fliplr(yTEMP.BFs_kHz))
            hold off
            set(gca,'FontSize',FIG.FontSize)
            
            %%%% Synch Change
            subplot(324)
            for LEVind=2:length(yTEMP.levels_dBSPL)
               synchSlopes(LEVind,:)=(synchTEMP(LEVind,:)-synchTEMP(LEVind-1,:))/diff(yTEMP.levels_dBSPL(LEVind-1:LEVind));
               semilogx(yTEMP.BFs_kHz,synchSlopes(LEVind,:),'Marker',LEVELmarkers{LEVind},'MarkerEdgeColor',LEVELcolors{LEVind},'Color',LEVELcolors{LEVind-1},'LineStyle',LEVELlines{LEVind})
               hold on
            end
            semilogx(unit.Info.BF_kHz*ones(1,2),[-1e6 1e6],'k:')
            semilogx(unit.Info.BF_kHz*[.5 2],[0 0],'k-')
            if strcmp(unit.EH_reBF.interleaved,'yes')
               hlegSlope=legend(LEGtextSlope{2:length(yTEMP.levels_dBSPL)},1);
            else
               hlegSlope=legend(LEGtextSlope{2:length(yTEMP.levels_dBSPL)},4);
            end
            set(hlegSlope,'FontSize',6)
            ylabel('Synch Slope (1/dB)')
            % ylim([-1 1]*max(ceil(max(abs(synchSlopes))/.02)*.02))
            ymax_DeltaSynch=1/30;  % 0 to 1 in 30 dB
            ylim([-1 1]*ymax_DeltaSynch)
            xlim(XLIMITS)
            set(gca,'XTick',fliplr(yTEMP.BFs_kHz))
            hold off
            set(gca,'FontSize',FIG.FontSize)
            
            %%%% Phase
            subplot(325)
            phaseTEMP=NaN+ones(size(yTEMP.phase));
            for LEVind=1:length(yTEMP.levels_dBSPL)
               for FREQind=1:length(yTEMP.BFs_kHz)
                  if ~isempty(yTEMP.phase{LEVind,FREQind})
                     phaseTEMP(LEVind,FREQind)=yTEMP.phase{LEVind,FREQind}(FeatPlotIND);
                  end
               end
               semilogx(yTEMP.BFs_kHz,phaseTEMP(LEVind,:),'Marker',LEVELmarkers{LEVind},'Color',LEVELcolors{LEVind},'LineStyle',LEVELlines{LEVind})
               hold on
            end
            semilogx(unit.Info.BF_kHz*ones(1,2),[-pi pi],'k:')
            ylabel(sprintf('Phase (to %s) (rad)',FeaturesText{FeatPlotIND}))
            xlabel('Effective Best Frequency (kHz)')
            ylim([-pi pi])
            xlim(XLIMITS)
            set(gca,'XTick',fliplr(yTEMP.BFs_kHz))
            hold off
            set(gca,'FontSize',FIG.FontSize)
            
            %%%% Phase Change
            subplot(326)
            for LEVind=2:length(yTEMP.levels_dBSPL)
               phaseLL=repmat(phaseTEMP(LEVind-1,:),3,1);
               phaseLL(2,:)=phaseLL(1,:)+2*pi;
               phaseLL(3,:)=phaseLL(3,:)-2*pi;
               phaseHL=repmat(phaseTEMP(LEVind,:),3,1);
               phaseDiffs=phaseHL-phaseLL;
               [phaseMinDiffs,phaseMinInds]=min(abs(phaseDiffs));
               for FREQind=1:length(yTEMP.BFs_kHz)
                  phaseSlopes(LEVind,FREQind)=phaseDiffs(phaseMinInds(FREQind),FREQind)/diff(yTEMP.levels_dBSPL(LEVind-1:LEVind));
               end
               semilogx(yTEMP.BFs_kHz,phaseSlopes(LEVind,:),'Marker',LEVELmarkers{LEVind},'MarkerEdgeColor',LEVELcolors{LEVind}, ...
                  'Color',LEVELcolors{LEVind-1},'LineStyle',LEVELlines{LEVind})
               hold on
            end
            semilogx(unit.Info.BF_kHz*ones(1,2),[-pi pi],'k:')
            semilogx(unit.Info.BF_kHz*[.5 2],[0 0],'k-')
            ylabel('Phase Slope (rad/dB)')
            xlabel('Effective Best Frequency (kHz)')
            % ylim([-1 1]*max(ceil(max(abs(phaseSlopes))/.02)*.02))  
            ymax_DeltaSynch=0.05;  % ~pi/2 in 30 dB
            ylim([-1 1]*ymax_DeltaSynch)
            xlim(XLIMITS)
            set(gca,'XTick',fliplr(yTEMP.BFs_kHz))
            hold off
            set(gca,'FontSize',FIG.FontSize)

            orient landscape
            
         end %End if data for this condition, plot
      end % End Polarity
   end % End Harmonics
end % End Feature

return;
