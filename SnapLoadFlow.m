clear all;
clc;
DSSObj = actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0),
disp('Unable to start the OpenDSS Engine');
return
end
DSSText = DSSObj.Text; % Used for all text interfacing from matlab to opendss
DSSCircuit = DSSObj.ActiveCircuit; % active circuit
% Write Path where Master and its associated files are stored and compile as per following command
DSSText.Command='Compile (C:\Users\Admin\Desktop\SaturdayExample\ToUpload\MasterIEEE13.dss)';
DSSText.Command='batchedit load..* Vmin=0.8'; % Set Vmin lower so that load model property will remain same
DSSTransformers=DSSCircuit.Transformers;
 %% SnapShot Mode (To Run for Peak Load Only)
DSSText.Command='set mode=snap';
DSSText.Command='solve';

DSSText.Command='Show current'; 
DSSText.Command='Show losses';
DSSText.Command='Show Taps';
DSSText.Command='Show Voltage';
SystemLosses=(DSSCircuit.Losses)/1000; % Will Give you Distribution System Losses in kWs and kVArs
%% Line Losses
LineLosses=DSSCircuit.Linelosses;
%% Transformer Losses

TranLosses=SystemLosses-LineLosses; %Will give us losses of all transformer in distribution network (if no storage)


%% Voltage Magnitude for each phase in p.u. can be obtained in this way
V1pu=DSSCircuit.AllNodeVmagPUByPhase(1); % For A-phase
V2pu=DSSCircuit.AllNodeVmagPUByPhase(2); % For B-phase
V3pu=DSSCircuit.AllNodeVmagPUByPhase(3); % For C-phase


