% FlexyAir: Constructs an object for Flexy Air device
%
% my_flexy = FlexyAir('PORT') creates an object instance that 
% represents a Flexy Air device. The PORT is mandatory parameter in 
% Linux or Mac, in Windows optional.
% To determine a PORT number, see device manager in Windows or
% /dev/* location on Linux/Mac.
%
% Possible names for PORT files on Linux/Mac:
%        
%       /dev/ttyACMx    (x - is usually 0)
%       /dev/ttyUSBx    (x - is usually 0)
%       /dev/tty.usbserial-x    (x - is a character string)
%
% If device ports are missing, see these tutorials for help with driver installation:
%        https://learn.sparkfun.com/tutorials/how-to-install-ftdi-drivers/linux
%        https://learn.sparkfun.com/tutorials/how-to-install-ftdi-drivers/mac
%
% Example:
%      
%        my_flexy_air_win = FlexyAir(); % with COM port autodetection (Win only)
%        my_flexy_air_win = FlexyAir('COM10');
%        my_flexy_air_linux = FlexyAir('/dev/ttyACM0');
%
% FlexyAir class contains the following public methods:
%       
%        .setFanSpeedPerc (see <a href="matlab:help FlexyAir.setFanSpeedPerc">FlexyAir.setFanSpeedPerc</a>)
%        .setInternalSamplingFreq (see <a href="matlab:help FlexyAir.setInternalSamplingFreq">FlexyAir.setInternalSamplingFreq</a>)
%        .setArtificialNoise (see <a href="matlab:help FlexyAir.setArtificialNoise">FlexyAir.setArtificialNoise</a>)
%        .setDelaySamples (see <a href="matlab:help FlexyAir.setDelaySamples">FlexyAir.setDelaySamples</a>)
%        .setFilter (see <a href="matlab:help FlexyAir.setFilter">FlexyAir.setFilter</a>)
%        .setDisplayStateOnOff (see <a href="matlab:help FlexyAir.setDisplayStateOnOff">FlexyAir.setDisplayStateOnOff</a>)
%        .dataFlowOnOff (see <a href="matlab:help FlexyAir.dataFlowOnOff">FlexyAir.dataFlowOnOff</a>)
%        .setVerboseModeOnOff (see <a href="matlab:help FlexyAir.setVerboseModeOnOff">FlexyAir.setVerboseModeOnOff</a>)
%        .setGracefulShutdown (see <a href="matlab:help FlexyAir.setGracefulShutdown">FlexyAir.setGracefulShutdown</a>)
%        .getUserInputLPerc (see <a href="matlab:help FlexyAir.getUserInputLPerc">FlexyAir.getUserInputLPerc</a>)
%        .getUserInputRPerc (see <a href="matlab:help FlexyAir.getUserInputRPerc">FlexyAir.getUserInputRPerc</a>)
%        .getSensor1DistanceMm (see <a href="matlab:help FlexyAir.getSensor1DistanceMm">FlexyAir.getSensor1DistanceMm</a>)
%        .getSensor2DistanceMm (see <a href="matlab:help FlexyAir.getSensor2DistanceMm">FlexyAir.getSensor2DistanceMm</a>)
%        .getSensor1DistanceCm (see <a href="matlab:help FlexyAir.getSensor1DistanceCm">FlexyAir.getSensor1DistanceCm</a>)
%        .getSensor2DistanceCm (see <a href="matlab:help FlexyAir.getSensor2DistanceCm">FlexyAir.getSensor2DistanceCm</a>)
%        .getTerminalInputPerc (see <a href="matlab:help FlexyAir.getTerminalInputPerc">FlexyAir.getTerminalInputPerc</a>)
%        .off (see <a href="matlab:help FlexyAir.off">FlexyAir.off</a>)
%        .close (see <a href="matlab:help FlexyAir.close">FlexyAir.close</a>)
%
% Description of each method can be displayed using
%
%        help FlexyAir.[method name]
%
% Brought to you by Optimal Control Labs, s.r.o. (www.ocl.sk).


classdef FlexyAir < handle
  
   properties(SetAccess=public)
        SerialObj                   % stores active serial object
        LastIncommingMessage        % last message from experiment
        VerboseMode
        DataFlow
        Data
        Version
        GracefulShutdown
   end
    
   properties(SetAccess=public)
        SerialPort                  % COM port
   end
   
   properties(Constant)
        COM_BAUD_RATE = 115200      % fixed baud rate for usb-serial
   end
   
   methods(Access=public)
        
       function obj = FlexyAir(varargin)
            % FlexyAir constructor method
            if(length(varargin)==1)
               port = varargin{1};
               obj.SerialPort = port;
            elseif(isempty(varargin))
               obj.findComPort();
            else
               error('Too many input arguments.'); 
            end
            obj.VerboseMode = 0;
            obj.GracefulShutdown = 0;
            obj.configureSerialPort();
            obj.dataFlowOnOff(1);
            obj.DataFlow = 1;
       end
       
       function setFanSpeedPerc(obj,speed)
           % FlexyAir.setFanSpeedPerc(SPEED) sets the speed of the fan on
           % a FlexyAir device. SPEED is in percentage [0-100] of maximum
           % achievable fan speed.
            if(speed>100)
                speed = 100;
            elseif(speed<0)
                speed = 0;
            end
            speedInt = round(speed*2.55);
            obj.sendCommand('F',speedInt);
       end
       
       function setInternalSamplingFreq(obj,freq)
            % FlexyAir.setInternalSamplingFreq(FREQ) sets the frequency [in Hz] of
            % data update rate from FlexyAir [min: 5, max: 255]
            if(freq>255)
                freq = 255;
            elseif(freq<5)
                freq = 5;
            end
            obj.sendCommand('S',round(freq));
       end
       
       function dataFlowOnOff(obj,opt)
            % FlexyAir.dataFlowOnOff(OPT) for binary value OPT (0-off,
            % 1-on) turns off/on the background serial
            % communication between FlexyAir and MATLAB
            if(opt==1)
                obj.sendCommand('P',round(opt));
                obj.DataFlow = 1;
            elseif(opt==0)
                obj.sendCommand('P',round(opt));
                obj.DataFlow = 0;
            else
               warning('FlexyWarning:UnexpectedValueWarning','dataFlowOnOff function expects logical value (either 0 or 1)'); 
            end
       end
       
       function setVerboseModeOnOff(obj,opt)
            % FlexyAir.setVerboseModeOnOff(OPT) for binary value OPT (0-off,
            % 1-on) turns off/on the console output of background serial
            % communication between FlexyAir and MATLAB
          	if(opt==1)
                obj.VerboseMode = 1;
            elseif(opt==0)
                obj.VerboseMode = 0;
            else
               warning('FlexyWarning:UnexpectedValueWarning','setVerboseModeOnOff function expects logical value (either 0 or 1)'); 
            end  
       end
       
       function setArtificialNoise(obj, mag)
           % FlexyAir.setArtificialNoise(MAG) adds randomly distributed artificial noise
           % to the measurements. Noise magnitude MAG is units of [%] of signal range[0-100%].
           % Minimum value 0 represents no artificaial noise (SNR=Inf) and
           % maximum value of 25 represents 25% of noise in signal range (SNR=4);
           mag = round(mag*10);
           if(mag>250)
               warning('FlexyWarning:UnexpectedValueWarning','setArtificialNoise function expects values between 0 and 25 - value is being ignored');
           elseif(mag<0)
               warning('FlexyWarning:UnexpectedValueWarning','setArtificialNoise function expects values between 0 and 25 - value is being ignored');
           else
               obj.sendCommand('N',mag);
           end
       end
       
       function setFilter(obj, weight)
           % FlexyAir.setFilter(W) initializes a an exponential smoothing
           % filter: y(k) = (1-W)*x(k)+W*x(k-1), where W is a weighting
           % factor between current and previous measurement.
           % Examples:
           %    W = 0       No smoothing (just current measurements)
           %    W = 0.1     Minor smoothing
           %    W = 0.5     Mediate smoothing
           %    W = 0.9     Heavy smoothing
           %    W = 1       Current measurements are lost (this setting is not useful at all)       
           weight = round(weight*100);
           if(weight>100)
               warning('FlexyWarning:UnexpectedValueWarning','setFilter function expects values between 0 and 1 - value is being ignored');
           elseif(weight<0)
               warning('FlexyWarning:UnexpectedValueWarning','setFilter function expects values between 0 and 1 - value is being ignored');
           else
               obj.sendCommand('L',weight);
           end
       end
       
       function setDelaySamples(obj, n)
           % FlexyAir.DelaySamples(N) introduces an atrificial measurement 
           % delay of N samples of internal sampling frequency. 
           % For value of N = 0, no delay is present. Maximum value of N is
           % 100 samples.
           %
           % see also: .setInternalSamplingFreq (see <a href="matlab:help FlexyAir.setInternalSamplingFreq">FlexyAir.setInternalSamplingFreq</a>)
           if(n>100)
               warning('FlexyWarning:UnexpectedValueWarning','setDelaySamples function expects values between 0 and 100 - value is being ignored');
           elseif(n<0)
               warning('FlexyWarning:UnexpectedValueWarning','setDelaySamples function expects values between 0 and 100 - value is being ignored');
           else
               obj.sendCommand('D',n);
           end
       end
       
       function setDisplayStateOnOff(obj, opt)
           % FlexyAir.setDisplayStateOnOff(OPT) for binary value OPT (0-off,
           % 1-on) turns off/on the display of the device
            if(opt==1 || opt==0)
            	obj.sendCommand('Y', opt);
            else
            	warning('FlexyWarning:UnexpectedValueWarning','setDisplayStateOnOff function expects logical value (either 0 or 1)'); 
            end
       end
       
       function out = getUserInputLPerc(obj)
            % FlexyAir.getUserInputLPerc() returns the signal from left user input 
            % (potentiometer) in percent
            out = obj.Data.UserInputLPerc;
       end
       
       function out = getUserInputRPerc(obj)
            % FlexyAir.getUserInputRPerc() returns the signal from right user input 
            % (potentiometer) in percent
            out = obj.Data.UserInputRPerc;
       end
       
       function out = getTerminalInputPerc(obj)
            % FlexyAir.getTerminalInputPerc() returns the voltage level 
            % (in percent of 0-5V) of a signal connected to input terminal AI 
            out = obj.Data.TerminalInputPerc;
       end
       
       function out = getSensor1DistanceMm(obj)
            % FlexyAir.getSensor1DistanceMm() returns a distance of object 
            % from the ToF sensor 1 (in millimeters) 
            out = obj.Data.Sensor1Distance;
       end
       
       function out = getSensor2DistanceMm(obj)
            % FlexyAir.getSensor2DistanceMm() returns a distance of object 
            % from the ToF sensor 2 (in millimeters) 
            out = obj.Data.Sensor2Distance;
       end
       
       function out = getSensor1DistanceCm(obj)
            % FlexyAir.getSensor1DistanceCm() returns a distance of object 
            % from the ToF sensor 1 (in centimeters) 
            out = obj.Data.Sensor1Distance/10;
       end
       
       function out = getSensor2DistanceCm(obj)
            % FlexyAir.getSensor2DistanceCm() returns a distance of object 
            % from the ToF sensor 2 (in centimeters) 
            out = obj.Data.Sensor2Distance/10;
       end
       
       function off(obj)
            % FlexyAir.off() turns off the fan
            obj.setFanSpeedPerc(0);
       end
       
       function close(obj)
            % FlexyAir.close() closes the active connection
            obj.off();
            obj.serialClose();
       end
       
       function setPort(obj, port)
            obj.ComPort = port;
       end
       
       function setGracefulShutdown(obj, opt)
           % FlexyAir.setGracefulShutdown(OPT) for binary value OPT (0-off,
           % 1-on) sets the power down of device's sensors after
           % the connection is closed. It is recommended to use this command with OPT=1
           % for Simulink-based control.
           if(opt==1 || opt==0)
            	obj.GracefulShutdown = opt;
           else
            	warning('FlexyWarning:UnexpectedValueWarning','setDisplayStateOnOff function expects logical value (either 0 or 1)'); 
           end       
       end
       
   end
   
   
   methods(Access=private)
       
       function sendCommand(obj, command, value)
            obj.SerialObj.writeline(['<' command ':' num2str(value) '>'])
       end
       
       function findComPort(obj)
            vdate = version('-date');
            release_year = str2double(vdate(end-3:end));
            if(ispc&&release_year>=2017)
                ports = seriallist;
            	disp('Searching COM ports ...')
            	for i=1:length(ports)
                	warning('off','all');
                	ser = serialport(ports{i}, obj.COM_BAUD_RATE, ...
                                   'TimeOut', 0.1, ...
                                   'ByteOrder', 'little-endian', ...
                                   'DataBits', 8, ...
                                   'StopBits', 1, ...
                                   'Parity', 'none', ...
                                   'FlowControl', 'none' ...
                                   );
                    configureTerminator(ser,'CR/LF');
                    pause(2);
                    ser.writeline('<V:1>');
                    pause(0.1);
                    message = readline(ser);
                    warning('on','all')
                    [~,ver] = strtok(message,':');
                    ver = char(ver);
                    obj.Version = ver(2:end-1);
                    obj.SerialPort = ports{i};
                    if(~isempty(obj.Version))
                        disp([obj.Version ' found on port ' ports{i}]);
                        delete(ser);
                        break;
                    end
                    delete(ser);
                end
                if(isempty(obj.Version))
                    error('No FlexyAir device found.');
                end
            else
                error('Specification of com. port is required. See <a href="matlab:help FlexyAir">help FlexyAir</a> for more information.')
            end
       end
           
       function readData(obj, serial_obj, ~)
            % Parsing function for incomming messages
            message = readline(serial_obj);
            [~,data] = strtok(char(message),':');
            [d1,d2345] = strtok(data,',');
            [d2,d345] = strtok(d2345,',');
            [d3,d45] = strtok(d345,',');
            [d4,d5] = strtok(d45,',');
            obj.Data.UserInputLPerc = str2double(d1(2:end));
            obj.Data.UserInputRPerc = str2double(d2(1:end));
            obj.Data.Sensor1Distance = str2double(d3(1:end));
            obj.Data.Sensor2Distance = str2double(d4(1:end));
            obj.Data.TerminalInputPerc = str2double(d5(1:end-1));
            if(obj.VerboseMode)
                disp(message);
            end
            obj.LastIncommingMessage = message;
       end
       
       function configureSerialPort(obj)
            obj.SerialObj = serialport(obj.SerialPort, obj.COM_BAUD_RATE, ...
                                   'TimeOut', 10, ...
                                   'ByteOrder', "little-endian", ...
                                   'DataBits', 8, ...
                                   'StopBits', 1, ...
                                   'Parity', "none", ...
                                   'FlowControl', "none" ...
                                   );
            configureTerminator(obj.SerialObj, 'CR/LF');
            flush(obj.SerialObj);
            configureCallback(obj.SerialObj,"terminator",@obj.readData);
            pause(2);
       end
       
       function serialClose(obj)
            % Closes serial connection
            if obj.GracefulShutdown
                obj.sendCommand('X',1);
            end
            delete(obj.SerialObj);
       end
        
    end
    
end