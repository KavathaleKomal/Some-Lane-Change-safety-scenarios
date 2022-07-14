%% Clean workspace and close all
clear all
close all
clc
%% Constraint for parameter

KK = 0;
c=200;
deg_to_rad=pi/180;
LaneWidth = 3.66;
TruckWidth = 3.05;
WheelBase = 5.79;
SRR = 18;
s=(LaneWidth-TruckWidth)/2;
b=c+s+LaneWidth;

Str_Ang_Rate=[];
x_speed=[];
y_TTC=[];
z_FHTI=[];
for SteerAngRate_EV_Comp = 310 : 10 : 360
    Speed = [];
    TimeDur = [];
    DataTTC = [];
    AAy=[];
    for EgoVehicleSpeed = 40 : 5 : 130
        
Vx_EV = EgoVehicleSpeed/3.6;
wheel_angle=SteerAngRate_EV_Comp/SRR;
wheel_ang_rad=0.0174533*wheel_angle;
deg_to_rad=pi/180;
ang_C_deg=90-wheel_angle;
ang_B_deg=180-(asind(b*sind(ang_C_deg)/c));
ang_A_deg=180-ang_C_deg-ang_B_deg;
ang_B_rad=ang_B_deg*deg_to_rad;
ang_A_rad=ang_A_deg*deg_to_rad;
ang_C_rad=ang_C_deg*deg_to_rad;

a=(c*sin(ang_A_rad))/sin(ang_C_rad);
      
        Ay = -Vx_EV^2 * tand(SteerAngRate_EV_Comp/SRR)/WheelBase;
        AyComp = Vx_EV^2 * tand(SteerAngRate_EV_Comp/SRR)/WheelBase;
        % Saturation: If acceleration is more than 1g. Need to saturate
        if abs(AyComp) > 9.81
            AyComp = sign(AyComp)*9.81;
        else
            AyComp = AyComp;
        end
        dT = 0.01;                                      % Sample time
        VelY = 0;
        DistCovered = 0;
        K = 0;
 %% TTC computation
        Flag = false;
        while(Flag == false)
            VelY = VelY + dT * Ay;
            DistCovered = DistCovered + dT*VelY;
            K = K + 1;
            if (abs(DistCovered) >= a)
                Flag = true;
            end
        end
        TTC = K * dT;
        %% Dist covered during response time
        for ijk = TTC : -dT : 0.001
            
        IC = 0;
        VelY = 0;
        DistCovered = 0;
        Flag = false;
        C = 0;
        %% FHTI calculation
        for i = 0 : dT : ijk
            VelY = VelY + dT * Ay;
            DistCovered = DistCovered + dT*VelY;
        end
        DistCovered1 = abs(DistCovered);
 %% 
 
        Flag = false;
        N = 0;
        Pev_VelY = VelY;
        DistCovered = 0;
        while(Flag == false)
            
            VelY = VelY + dT * AyComp;
            DistCovered = DistCovered + dT*VelY;
            if sign(VelY) ~= sign(Pev_VelY)
                Flag = true;
            end
            N = N + 1;
        end
        
        DistCovered2 = abs(DistCovered);
        TotalDist = DistCovered1 + DistCovered2;
        if abs(TotalDist) < (a-0.05)
            break;
        end
        end
        Speed = [Speed EgoVehicleSpeed];
        TimeDur = [TimeDur ijk];
        DataTTC = [DataTTC TTC];
        AAy=[AAy Ay];
        Str_Ang_Rate=[Str_Ang_Rate SteerAngRate_EV_Comp];
    end
    
    x_speed=[x_speed Speed]; 
    y_TTC=[y_TTC DataTTC];
    z_FHTI=[z_FHTI TimeDur];
    KK = KK + 1; 
    SSSS(KK,:) = Speed;
    TTTT(KK,:) = TimeDur;
    TTCC(KK,:) = DataTTC;
    AAAY(KK,:) = AAy;
end
%% Plots
figure(1)
plot(SSSS(1,:),TTTT(1,:),'b');
hold on;
grid on;
plot(SSSS(2,:),TTTT(2,:),'r');
plot(SSSS(3,:),TTTT(3,:),'c');
plot(SSSS(4,:),TTTT(4,:),'m');
plot(SSSS(5,:),TTTT(5,:),'k');
plot(SSSS(6,:),TTTT(6,:),'g');

legend('SteerR 310 (in dg/s)','SteerR 320','SteerR 330','SteerR 340','SteerR 350','SteerR 360','Location','Best');
xlabel('EV Velocity in KMPH');
ylabel('Fault Handling Time Interval in sec');

f=gcf;
saveas(f,'Redvehstability_w_rollover_24_1_FHTI.jpg');

figure(2)
plot(SSSS(1,:),TTCC(1,:),'b');
hold on;
grid on;
plot(SSSS(2,:),TTCC(2,:),'r');
plot(SSSS(3,:),TTCC(3,:),'c');
plot(SSSS(4,:),TTCC(4,:),'m');
plot(SSSS(5,:),TTCC(5,:),'k');
plot(SSSS(6,:),TTCC(6,:),'g');

legend('SteerR 310 (in dg/s)','SteerR 320','SteerR 330','SteerR 340','SteerR 350','SteerR 360','Location','Best');
xlabel('EV Velocity in KMPH');
ylabel('Time-to-collision in sec');

f=gcf;
saveas(f,'Redvehstability_w_rollover_24_1_TTC.jpg');

%% excel write
Str_Ang_Rate=Str_Ang_Rate';
x_speed=x_speed';
y_TTC=y_TTC';
z_FHTI=z_FHTI';
data={'Str_ang_rate','Vehicle_Speed','TTC','FHTI'};
xlswrite('Functional_Safety_Scenarios',data,'Redvehstability_w_rollover_24_1','A1');
xlswrite('Functional_Safety_Scenarios',Str_Ang_Rate,'Redvehstability_w_rollover_24_1','A2');
xlswrite('Functional_Safety_Scenarios',x_speed,'Redvehstability_w_rollover_24_1','B2');
xlswrite('Functional_Safety_Scenarios',y_TTC,'Redvehstability_w_rollover_24_1','C2');
xlswrite('Functional_Safety_Scenarios',z_FHTI,'Redvehstability_w_rollover_24_1','D2');


folder = pwd;
excelFileName = 'Functional_Safety_Scenarios.xls';
fullFileName = fullfile(folder, excelFileName);
objExcel = actxserver('Excel.Application');
objExcel.Visible = true;
ExcelWorkbook = objExcel.Workbooks.Open(fullFileName);
oSheet = objExcel.ActiveSheet;
imageFolder = fileparts(which('Redvehstability_w_rollover_24_1_TTC.jpg'));
imageFullFileName = fullfile(imageFolder, 'Redvehstability_w_rollover_24_1_TTC.jpg');
Shapes = oSheet.Shapes;
Shapes.AddPicture(imageFullFileName, 0, 1, 400, 20, 400, 300);

imageFolder1 = fileparts(which('Redvehstability_w_rollover_24_1_FHTI.jpg'));
imageFullFileName1 = fullfile(imageFolder, 'Redvehstability_w_rollover_24_1_FHTI.jpg');
Shapes.AddPicture(imageFullFileName1, 0, 1, 850, 20, 400, 300);

objExcel.DisplayAlerts = false;
ExcelWorkbook.SaveAs(fullFileName);
ExcelWorkbook.Close(false);
objExcel.Quit; 