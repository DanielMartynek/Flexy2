%% Laborka 19.10.2023

addpath(genpath('./'));
Ts = 0.025;
Port = 'COM3'; % Port number can vary on different machines
graceful_shutdown_opt = 1;


%% Command window/script examples

% Flexy Air can be controlled directly from command window or script.
% If control is automated, it should be controlled by some sort
% of timer to ensure real-time behavior.

% Create instance of Flexy Air
flexy_air = FlexyAir(Port); % define port manually


% To learn about other commands, run 'help FlexyAir'
flexy_air.setFanSpeedPerc(55)
pause(1)

% Preallocationg for measurement
nMeasurements=200;
t=zeros(1,nMeasurements);
u=ones(1,nMeasurements)*55;
y=zeros(1,nMeasurements);

% Input signal setup
u(20:200)=57;
% u(20:50)=58;

% Measurement loop
tic
for i=1:nMeasurements
    flexy_air.setFanSpeedPerc(u(i))
    y(i)=flexy_air.getSensor1DistanceMm();
    t(i)=toc;
    pause(0.05);
end

% Save measurements
U=timeseries(t,u,"Input");
Y=timeseries(t,y,"Output");
%% RENAME ME
% (nebo to můžete ukládat nějak chytřeji, ať se to nepřepisuje a dá se v tom vyznat)
save("RENAME_ME","U","Y",'-mat')

flexy_air.setFanSpeedPerc(0);
% Properly close the connection to Flexy Air
flexy_air.close();

% Plotting
figure
subplot(211)
plot(U)
ylabel("U [%]")

subplot(212)
plot(Y)
xlabel("t")
ylabel("Height [mm]")