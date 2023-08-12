%% Notes
% Not changing dailyMultiplier from code because confusion with npts inside
% loadshapes.

%%
clear;clc;

DSSObj = actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0)
    disp('Unable to start the OpenDSS Engine');
    return
end

DSSText = DSSObj.Text; % Used for all text interfacing from matlab to opendss
DSSCircuit = DSSObj.ActiveCircuit; % active circuit
DSSText.Command=strcat('Compile (',pwd,'\MasterIEEE13.dss)');% Path where Master and its associated files are stored.
DSSText.Command='batchedit load..* Vmin=0.8'; % Set Vmin so that load model property will remain same
DSSTransformers=DSSCircuit.Transformers;
%DSSText.Command='Batchedit regcontrol..* Enabled=no'; % uncomment for tap change as per user's choice
DSSText.Command='batchedit load..* daily=PQmult'; % Loadshape
DSSText.Command='New EnergyMeter.Main Line.650632 1';% Energy meter
dailyMultiplier = 1; % Don't change!
nt=24*dailyMultiplier;
TimeArray=1:nt;
%% Uncomment following for Tap chang as per user choice (manually)
% Xtap=[15	7	6	6	6	7	8	9	11	12	13	14	14	14	14	14	14	14	14	14	14	14	13	12
% 10	5	4	4	4	4	5	6	7	8	8	9	9	9	9	9	9	9	9	9	9	9	9	9
% 15	6	5	5	5	6	7	9	10	12	13	13	14	14	14	14	14	14	14	14	14	14	13	12 ];
% Reg1Tap=Xtap(1,:)-5;
% Reg2Tap=Xtap(2,:)-5;
% Reg3Tap=Xtap(3,:)-5;
% Vreg1=1+0.00625*Reg1Tap;
% Vreg2=1+0.00625*Reg2Tap;
% Vreg3=1+0.00625*Reg3Tap;

%% Main loop
DSSText.Command=strcat('set mode=daily stepsize=', getStepSize(dailyMultiplier),' number=1');
DSSText.Command='set hour=0'; % Start at second 0 of hour 0
for i=1:nt
    DSSText.Command='get hour';
    hour=DSSText.Result;

    % Uncomment following for change in Tap Positions of Regulator as per user choice
    % DSSText.command = ['Transformer.Reg1.Tap=',num2str(Vreg1(i))];
    % DSSText.command = ['Transformer.Reg2.Tap=',num2str(Vreg2(i))];
    % DSSText.command = ['Transformer.Reg3.Tap=',num2str(Vreg3(i))];
    DSSText.Command='Solve';
    SystemLosses(i,:)=(DSSCircuit.Losses)/1000; % Will Give you Distribution System Losses in kWs and kVArs

    % Line Losses
    LineLosses(i,:)=DSSCircuit.Linelosses;

    % Transformer Losses
    TranLosses(i,:)=SystemLosses(i,:)-LineLosses(i,:);
    
    % Voltage Magnitude in p.u. for 24-hours can be obtained in this way
    V1pu(i,:)=DSSCircuit.AllNodeVmagPUByPhase(1);
    V2pu(i,:)=DSSCircuit.AllNodeVmagPUByPhase(2);
    V3pu(i,:)=DSSCircuit.AllNodeVmagPUByPhase(3);
    DSSText.Command = '? Transformer.Reg1.Taps';
    Reg1=str2num(DSSText.Result); 
    Vreg1S(i,:)=Reg1(2);% Secondary winding voltage of Reg1 in 24-hr
    DSSText.Command = '? Transformer.Reg2.Taps';
    Reg2=str2num(DSSText.Result);
    Vreg2S(i,:)=Reg2(2);% Secondary winding voltage of Reg2 in 24-hr
    DSSText.Command = '? Transformer.Reg3.Taps';
    Reg3=str2num(DSSText.Result); 
    Vreg3S(i,:)=Reg3(2);% Secondary winding voltage of Reg3 in 24-hr
    DSSText.Command='Export Meter'; % A MasterIEEE13_EXP_METERS.CSV file will be saved in same path
end

%% Data processing
EM=csvread('MasterIEEE13_EXP_METERS.CSV',1,4);
SubkWh=EM(:,1);
SubkVArh=EM(:,2);

% TODO: Get kW info using these formula dynamically
% Only use these 4 lines when dailyMultiplier is 1
if dailyMultiplier == 1
    SubkW24=[SubkWh(TimeArray(1)); SubkWh(TimeArray(2):TimeArray(end))-SubkWh(TimeArray(1):TimeArray(nt-1))];
    SubkVAr24=[SubkVArh(TimeArray(1)); SubkVArh(TimeArray(2):TimeArray(end))-SubkVArh(TimeArray(1):TimeArray(nt-1))];
    SubkVA24=abs(SubkW24+sqrt(-1)*SubkVAr24);
    SubstationkWkVArandkVA24=[SubkW24 SubkVAr24 SubkVA24];
end

delete(strcat(pwd,'\MasterIEEE13_EXP_METERS.CSV'))
% Here SubkW24 SubkVAr24 and SubkVA24 are substation kWs, kVArs, and kVAs for 24 hours period
clearvars -except SystemLosses LineLosses SubkW24 SubkVAr24 SubkVA24 V1pu V2pu V3pu Vreg1S Vreg2S Vreg3S


