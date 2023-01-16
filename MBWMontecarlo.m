% MBW MonteCarlo
% GKP 10/11/2021
% Calls the MBwerr function repeatedly


%function [DisplayFRC,DisplaybadFRC,LCI,LCIbad,Scond,Scondbad,Sacin,Sacinbad]...
%    = MBWerr(FRC,PctFRC1,TV,PctTV1,SeqParam,Snadded);


% INPUTS
%FRC: in mL
%PctFRC1: Percentage of FRC in compartment 1
% TV: in mL
%PctTV1:Percentage of TV in compartment 1
%SeqParam: Sequencing parameter in percent, see definitionin code below
%Snadded: Norm P3 slope on breath 1 (surrogate for Sacin) see below

% OUTPUTS
%DisplayFRC,: Calcualted correct value of FRC
%DisplaybadFRC: Calcualted value of FRC with the EcoMedics error
%LCI: Calcualted correct value of LCI
%LCIbad: Calcualted value of LCI with the EcoMedics error
%Scond:Calcualted correct value of Scond
%Scondbad,Calcualted value of Scond with the EcoMedics error
%Sacin: Calcualted correct value of Sacin
%Sacinbad: Calcualted value of Sacin with the EcoMedics error
%% Test case
[a,b,c,d,e,f,g,h] = MBWerr(3000,51,999,45,40,0.06);


%%

% We're going to need random numers
NumSim = 100;

% Simlate variation in the TV contribution
for ii=1:NumSim
    FRCvalue = 4000 + (rand-0.5)*4000; % 2000- 6000 ml
     TV1value = 50 - rand*30;   % Up to 30% TV variation
    FRC1value = 50 + rand*10;  % up to 10% FRC variation
    Seqvalue = 0 + rand*7.5;     % Sequencing up to 15%
    Sn1value = 0+ rand*0.1;     %Sn1 

    [FRC(ii),FRCbad(ii),LCI(ii),LCIbad(ii),Scond(ii),Scondbad(ii),Sacin(ii),Sacinbad(ii)] = ...
        MBWerr(FRCvalue,FRC1value,1000,TV1value,Seqvalue,Sn1value);
end

%%
BAplot2(Scond,Scondbad,'Scond');
mean(Scond)
std(Scond)

mean(Scondbad)
BAplot2(Sacin,Sacinbad,'Sacin');
mean(Sacin)
std(Sacin)
mean(Sacinbad)

%%
%Do the BA plots;
load('allgroups.mat');
BAplot2over(FRC,FRCbad,'FRC',FRCC*1000,FRCU*1000);
% and oveplot the individual groups
load('health.mat');
BAontop(FRCC*1000,FRCU*1000,'*g');
load('asthma.mat');
BAontop(FRCC*1000,FRCU*1000,'*b');
load('smokers.mat');
BAontop(FRCC*1000,FRCU*1000,'*r');
%%
load('allgroups.mat');
BAplot2over(LCI,LCIbad,'LCI',LCIC,LCIU);
% and oveplot the individual groups
load('health.mat');
BAontop(LCIC,LCIU,'*g');
load('asthma.mat');
BAontop(LCIC,LCIU,'*b');
load('smokers.mat');
BAontop(LCIC,LCIU,'*r');
%%
load('allgroups.mat');
BAplot2over(Scond,Scondbad,'Scond',ScondC,ScondU);
% and oveplot the individual groups
load('health.mat');
BAontop(ScondC,ScondU,'*g');
load('asthma.mat');
BAontop(ScondC,ScondU,'*b');
load('smokers.mat');
BAontop(ScondC,ScondU,'*r');
%%
load('allgroups.mat');
BAplot2over(Sacin,Sacinbad,'Sacin',SacinC,SacinU);
% and oveplot the individual groups
load('health.mat');
BAontop(SacinC,SacinU,'*g');
load('asthma.mat');
BAontop(SacinC,SacinU,'*b');
load('smokers.mat');
BAontop(SacinC,SacinU,'*r');


