%% Laborka 11.10.2023

% Make sure the containing directory of this file (including subdirectories) 
% is in the MATLAB path. Or run the following line.
addpath(genpath('./'));

% Define sampling time.
% This parameter defines a time interval used for sampling of Simulink
% model execution, communication, and internal sampling of Flexy Air.
% Maximum Ts is 0.2 (5Hz sampli ng).
Ts = 0.025; % Minimum recommended Ts is 0.025s (40Hz sampling)

% Define COM port.
% Communication port assigned to Arduino UNO microcontroller by OS. 
% In Windows the format is COMX, where X is a number of port 
% (can be found in Device Manager).
% In Linux and OSX, this should be replaced by path to the serial 
% communication file located in \dev\ directory. In Linux, this is
% usually \dev\ttyACM0.
Port = 'COM3'; % Port number can vary on different machines

% Gracefull shutdown allows to power down distance sensors before
% their re-initiation. This can prevent occasional failure to initialize
% them (should be set to 1 for Simulink usage).
% Default value is 0 (no grafecul shutdown). 
graceful_shutdown_opt = 1;


%% Command window/script examples

% Flexy Air can be controlled directly from command window or script.
% If control is automated, it should be controlled by some sort
% of timer to ensure real-time behavior.

% Create instance of Flexy Air
flexy_air = FlexyAir(Port); % define port manually
pause(1);

% To learn about other commands, run 'help FlexyAir'

while (true)
    flexy_air.setFanSpeedPerc(flexy_air.getUserInputLPerc());
    pause(1)
end

% Properly close the connection to Flexy Air
flexy_air.close();
