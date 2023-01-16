% MBW simulation to assess the calibration errors in the EcoMedics system
% that has become a problem
% 9/27/2021
% GK Prisk

%Simplifying assumptions
% 2 compartments
% NO deadspace
% Instananeaous inspiration
% Respiratory rate fixed
%100 points in an expiration

% First off get some basic numbers into the simulation

  % We're going to need some deadsape
  %But this is the alveolar concentration, we want mixed expired so we'll
 %make life simple and just assume 30% deadsapce (which contains 0% N2), so
 %we'll take 70% of the alveolar mean
 %Sn3 = P3slope/(MeanN2*0.7)*1000;
 DSP= VX('Fractional Deadspace ',0.3);
 NonDSP=1-DSP;
 
 
FRC = VX('FRC in mL ',2500);
TV = VX('TV in mL ',1000);

% For modeil purposes I need to handle the deadsapce which is explictly not
% in the model, so I'll just artifically inflate FRC and TV 

%FRC=FRC/NonDSP;
%TV=TV/NonDSP;

RR = VX('Respiratory rate (BPM) ',12);
N2Air = VX('N2 percentage in air ',78);
N2End = VX('N2 percentage for end of test ',1);
InspN2 = 0;
InspCO2=0;
ExpireCO2 =5;
MeanN2=N2Air;
%and set up the 2 compartments
PctFRC1 = VX('Percentage of FRC to compartment 1 (the low SV compartment)',50);
FRC1=FRC * PctFRC1/100;
FRC2=FRC - FRC1;
PctTV1 = VX('Percentage of TV to compartment 1 (the low SV compartment) ',50);
TV1 = TV * PctTV1/100;
TV2 = TV - TV1;
SV1 = TV1/FRC1;
SV2 = TV2/FRC2;
N21 = N2Air;
N22 = N2Air;
for i=1:100
    longN2(i)=N2Air; % Need this later
    longCO2(i)=ExpireCO2;
    longO2(i)=100-N2Air-ExpireCO2;
    longbadO2(i)=longO2(i); %set up as equal for now
    longbadN2(i)=longN2(i);
end;

 
% Sequencing
%
% In order to get a P3 slope we need sequencing so we'll set up a
% sequencing parameter.  
% Assumptions are that the low SV unit empies late.  BY definition this is
% compartment #1. The seq parameter isa number between 0 (none) and 50.
% A value of (say) 10 means that at end expiration the flow from
% compartment 1 is 60 percent and at the beginning of expiration 40
% percent. It's a linear function over the course of the expiration
SeqParam = VX('Sequencing -- [0,50] ',0);
for i=1:100
    Seq(i)=0.5 + (SeqParam*2/100) *((i-50)/100);
end;
% plot(Seq);
% So now we use the Seq array to build the flow arrays for each comp.
for i=1:100
    Flow1(i) = (TV1/100) * Seq(i)*2;
    Flow2(i) = TV/100 - Flow1(i);
end;
%plot(Flow1);
%hold on;
%plot(Flow2);
%and we'll need an expired volume singnal for later fitting
ExpVol(1)=0;
for i=2:100
    ExpVol(i) = ExpVol(i-1) + (Flow1(i)+Flow2(i));
end

% All set up so now we want to do a series of breaths 
% We will simulate until we reach below quarter the N2End parameter just to
% ensure that we have enough data later.
breath=1;
while MeanN2 > (N2End)
% So now do a breath
% Instantaneous inspiration;
N21 = N21 / (1+SV1);
N22 = N22 / (1+SV2);

% And add the inspired data
for i=1:100
    longN2=[longN2,InspN2];
    longCO2=[longCO2,InspCO2];
    longO2=[longO2,(100-InspN2-InspCO2)];
    longbadN2=[longbadN2,InspN2];
    longbadO2=[longbadO2,(100-InspN2-InspCO2)]; %nothing bad in inspiration
end;
%That's got the new compartmetn N2 values;
% and now a 100 point expiration
for i=1:100
    ExpN2(i) = (N21 * Flow1(i) + N22 * Flow2(i))/10;
    ExpCO2(i) = ExpireCO2;
    ExpO2(i) = 100-ExpN2(i)-ExpCO2(i);
end;
% plot(ExpN2);
% hold on;

% And analyze that breath
 %perform linear fit to the breath and extract params
 P3fit=fit(transpose(ExpVol), transpose(ExpN2),'poly1');
 P3slope =P3fit.p1;
 P3int=P3fit.p2;
 MeanN2=mean(ExpN2);

 BxBN2(breath)=MeanN2*NonDSP;
 BxBSlope(breath)=P3slope*1000;
 BxBSn3(breath)=BxBSlope(breath)/BxBN2(breath);
 % So now we have Sn3 for the breath based on the good data!
 %
 %
 % N2 ERROR SECTION &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
 %
% At this point it's a good opportunity to do the calibration fuck-up from
% EcoMedics.  So we'll bugger up the O2 data and the N2 data for the
% expired gases.
%
% The effect is one of the influnce of CO2 on the O2 channel which then
% screws up the N2 chanell as that's subtracted!

% We'll define the N2 error based on Figure 3 from Wyler et al (JAP 2021)
%Fitting a quadratice function to the 5% error data is an excellent fit so
%we'll simply use that as the error function.  The next three lines are the
%terms for the quadratic of the form     val(x) = p1*x^2 + p2*x + p3
% where the value of x is the N2 concentration in %.
p1 = -0.0001293;
p2 = 0.0004785;
p3 = 0.9767;


for i=1:100
    N2error(i)= (p1*ExpN2(i)*ExpN2(i)) + (p2*ExpN2(i)) + p3;
   % N2error(i)=0;
    ExpbadN2(i)=ExpN2(i) + N2error(i);
    ExpbadO2(i)= 100-ExpCO2(i)-ExpbadN2(i);
end;

%plot(N2error);
%pause;

% END OF THE N2 ERROR DEFINITION &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

%figure;plot(ExpN2);hold on;plot(ExpbadN2);pause;
error(breath)=mean(N2error);
% Analyze the breath (this is a bad one)
 Pfit=fit(transpose(ExpVol), transpose(ExpbadN2),'poly1');
 Pslope =Pfit.p1;
 Pint=Pfit.p2;
 MeanbadN2=mean(ExpbadN2);
   %But this is the alveolar concentration, we want mixed expired so we'll
 %make life simple and just assume 30% deadsapce (which contains 0% N2), so
 %we'll take 70% of the alveolar mean
 %Sn3bad = Pslope/(MeanbadN2*0.1)*1000;
 BxBbadN2(breath)=MeanbadN2*NonDSP;
 BxBbadSlope(breath)=P3slope*1000;
 BxBbadSn3(breath)=BxBbadSlope(breath)/BxBbadN2(breath);;
 

% Generate arrays
% We're going to need the O2 and CO2 data for allow us to simulate 
%the EcoMedics sensor fuck up
longN2=[longN2,ExpN2];
longCO2=[longCO2, ExpCO2];
longO2=[longO2, ExpO2];
longbadN2=[longbadN2,ExpbadN2];
longbadO2=[longbadO2,ExpbadO2];
breath=breath+1;
end
%clean up
breath=breath-1;

% Add in some Phase 3 slope to simulate Sacin
% Rather than do thorugh a long convoluted process of making up some model,
% for now I'm just going to add in a fized amount of slope to the SN3 arrar
% since the effect of DCDI is mostly first breath and remains pretty static
% thereafter.


Snadded = VX('Value of Sn1 due to DCDI (defines Sacin, normal value ~0.05)',0.05);
BxBSn3=BxBSn3 + Snadded;

BxBbadSn3=BxBbadSn3+ Snadded;


%% plot the actual and error riddled N2 profiles  -- OPTIONAL
figure;
plot(longN2);
hold on;
plot(longbadN2);
title('[N2]');
%
%% plot breath by breath expired N2 (the normalization signal) OPTIONAL
figure;
plot(BxBN2);
hold on;
plot(BxBbadN2,'+');
title('Breath-by-breath Expired [N2] (+ = with error)');

%% plot the P3 slope BxB -- OPTIONAL
figure;
plot(BxBSlope);
hold on;
plot(BxBbadSlope,'+');
title('Breath-by-breath P3 slope (+ = with error)');
%% plot the normalized P3 slopes OPTIONAL
figure;
plot(BxBSn3);
hold on;
plot(BxBbadSn3,'+');
title('Breath-by-breath Normalized P3 slope (+ = with error)');

%% Now we should do the Scond and Sacin and other calculations
%Get cumulative expired volumes
cumvol(1)=TV;
cumN2(1)=TV*BxBN2(1)/100;
cumbadN2(1)=TV*BxBbadN2(1)/100;
for i=2:breath
    cumvol(i)=cumvol(i-1)+TV;
    cumN2(i)=cumN2(i-1)+(TV*BxBN2(i)/100);
    cumbadN2(i)=cumbadN2(i-1)+(TV*BxBbadN2(i)/100);
end
% Now need to find where to stop the washout.
for i=1:breath
    if (BxBN2(i) > N2End)
        goodstop =i;
    end
        if (BxBbadN2(i) > N2End)
        badstop =i;
    end
end

% So there's a bit of jiggery-pokery going on here
%Becasue there is no deadapce in the model per se the expired N2 had to be 
%reduced by the non-deadspace fraction that was defined.  As a consequence,
% the cumulative expired N2 is too small which leads to a reduced FRC calculation.
% This is a direct result of the choce made not to include the deadspace.
% So to fix that I'll DISPLAY a FRC value that is elevated by the non-deadspace
% fraction.


calcFRC = cumN2(goodstop)/(N2Air-BxBN2(goodstop))*100;
DisplayFRC=calcFRC/NonDSP;
%crap=VX('FRC (correct value)',calcFRC);
crap=VX('FRC (correct value)',DisplayFRC);
calcbadFRC = cumbadN2(badstop)/(N2Air-BxBbadN2(badstop))*100;
DisplaybadFRC=calcbadFRC/NonDSP;

%crap=VX('FRC (EcoMedics value)',calcbadFRC);
crap=VX('FRC (EcoMedics value)',DisplaybadFRC);
crap=VX('Percent Error relative to correct', ((calcbadFRC-calcFRC)/calcFRC)*100);

% Now go after the LCI
LCI=cumvol(goodstop)/calcFRC;
LCIbad=cumvol(badstop)/calcbadFRC;
crap=VX('LCI (correct value)',LCI);
crap=VX('LCI (EcoMedics value)',LCIbad);
crap=VX('Percent Error relative to correct', ((LCIbad-LCI)/LCI)*100);

% Scond calculated over 1.5 to 6 TO's
%Find the turnover points to start and stop
Turnover=cumvol/calcFRC;
Turnoverbad=cumvol/calcbadFRC;

% Now need to find where the TO limits are.
% these are the points immediateyl BEFORE the 1.5 and 6.0 points
TOstop=VX('What turnover to stop at ',6);
for i=1:breath
    if (Turnover(i) <1.5)
        good15 =i;
    end
    if (Turnoverbad(i) <1.5)
        bad15 =i;
    end
    if (Turnover(i) <TOstop)
        good60 =i;
    end
    if (Turnoverbad(i) <TOstop)
        bad60 =i;
    end
end
% Having found the stop and start points, make arrays for the Scond fit

for i=good15+1 : good60
    xfit(i-good15)=Turnover(i);
    yfit(i-good15)=BxBSn3(i);
end;
%
%plot the normalized P3 slopes as a function of turnover
figure;
plot(Turnover,BxBSn3);
%
hold on;
%plot(Turnoverbad,BxBbadSn3,'o');
title('Normalized P3 slope as function of Turnover (+ = with error)');
%
% add turnover limits to plot
yy(1)= max(BxBSn3);
yy(2)=0;
xx(1)=Turnover(good15+1);
xx(2)=Turnover(good15+1);
plot(xx,yy);
%
xx(1)=Turnover(good60);
xx(2)=Turnover(good60);
plot(xx,yy);
%
xx(1)=Turnoverbad(bad15+1);
xx(2)=Turnoverbad(bad15+1);
plot(xx,yy);
plot(xx,yy,'*');
xx(1)=Turnoverbad(bad60);
xx(2)=Turnoverbad(bad60);
plot(xx,yy);
plot(xx,yy,'*');
%
%figure;
plot(xfit,yfit,'x');
 P3fit=fit(transpose(xfit), transpose(yfit),'poly1');
 P3slope =P3fit.p1;
 P3int=P3fit.p2;
 %and show the line
 fitted=P3slope*xfit+P3int;
 hold on;
 plot(xfit,fitted);
 Scond=P3slope;
 %
 % and now do it for the bad data as well
 for i=bad15+1 : bad60
    xbad(i-bad15)=Turnoverbad(i);
    ybad(i-bad15)=BxBbadSn3(i);
end;
%figure;
plot(xbad,ybad,'x');
 P3fit=fit(transpose(xbad), transpose(ybad),'poly1');
 P3slope =P3fit.p1;
 P3int=P3fit.p2;
 %and show the line
 fitted=P3slope*xbad+P3int;
 hold on;
 plot(xbad,fitted);
 Scondbad=P3slope;
 %
 crap=VX('Scond (correct value)',Scond);
crap=VX('Scond (EcoMedics value)',Scondbad);
crap=VX('Percent Error relative to correct', ((Scondbad-Scond)/Scond)*100);

%
 %And finally Sacin
 %That should be Sn3(1) less the Scond component at TO of first breath
 Sacin = BxBSn3(1)-Scond*Turnover(1);
 Sacinbad = BxBbadSn3(1)-Scondbad*Turnoverbad(1);
  crap=VX('Sacin (correct value)',Sacin);
crap=VX('Sacin (EcoMedics value)',Sacinbad);
crap=VX('Percent Error relative to correct', ((Sacinbad-Sacin)/Sacin)*100);
% and plot things
 yacin = BxBSn3(1)-Scond*Turnover(1);
 yacinbad = BxBbadSn3(1)-Scondbad*Turnoverbad(1);
 xacin = Turnover(1);
 xacinbad = Turnoverbad(1);
 plot(xacin,yacin,'O');
 plot(xacinbad,yacinbad,'X');


