function flexy_air_fun(block)

setup(block);

%endfunction

function setup(block)
global lastDelay;
global lastNoise;
global lastWeight;
lastDelay = 0;
lastNoise = 0;
lastWeight = 0;
% Register number of ports
block.NumInputPorts  = 4;
block.NumOutputPorts = 5;

% Setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;

block.InputPort(1).Dimensions        = 1;   % fan speed
block.InputPort(2).Dimensions        = 1;   % delay samples
block.InputPort(3).Dimensions        = 1;   % art. noise
block.InputPort(4).Dimensions        = 1;   % filt. weight
block.OutputPort(1).Dimensions        = 1;  % sensor 1
block.OutputPort(2).Dimensions        = 1;  % sensor 2
block.OutputPort(3).Dimensions        = 1;  % left knob
block.OutputPort(4).Dimensions        = 1;  % right knob
block.OutputPort(5).Dimensions        = 1;  % terminal input

% Register parameters
block.NumDialogPrms     = 3;
block.DialogPrmsTunable = {'Nontunable', ...
                           'Nontunable', ...
                           'Nontunable'
                          };

block.SampleTimes = [block.DialogPrm(1).Data 0];

block.SimStateCompliance = 'DefaultSimState';

block.RegBlockMethod('SetInputPortSamplingMode',@SetInputPortSamplingMode);
block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
block.RegBlockMethod('InitializeConditions', @InitializeConditions);
block.RegBlockMethod('Start', @Start);
block.RegBlockMethod('Outputs', @Outputs);     % Required
block.RegBlockMethod('Update', @Update);
block.RegBlockMethod('Derivatives', @Derivatives);
block.RegBlockMethod('Terminate', @Terminate); % Required

%end setup

function SetInputPortSamplingMode(block, idx, fd)
  block.InputPort(idx).SamplingMode = fd;
  block.OutputPort(1).SamplingMode = fd;
  block.OutputPort(2).SamplingMode = fd;
  block.OutputPort(3).SamplingMode = fd;
  block.OutputPort(4).SamplingMode = fd;
  block.OutputPort(5).SamplingMode = fd;

function DoPostPropSetup(block)
    if block.SampleTimes(1) == 0
        throw(MSLException(block.BlockHandle,'Dicrete sampling time required'));
    end

function InitializeConditions(block)
    block.OutputPort(1).Data = 0;
    block.OutputPort(2).Data = 0;
    block.OutputPort(3).Data = 0;
    block.OutputPort(4).Data = 0;

%end InitializeConditions

function Start(block)
global flexy_air_instance;

    flexy_air_instance = FlexyAir(block.DialogPrm(2).Data);
    pause(3); % we must wait for MCU to initialize
    flexy_air_instance.setVerboseModeOnOff(0); %debugging
    flexy_air_instance.setInternalSamplingFreq(round(1/block.DialogPrm(1).Data));
    if(block.DialogPrm(3).Data)
        flexy_air_instance.setGracefulShutdown(block.DialogPrm(3).Data);
    end
    
%endfunction

function Outputs(block)
global flexy_air_instance;
global lastDelay;
global lastNoise;
global lastWeight;
last_delay = lastDelay;
delay = block.InputPort(2).Data;
if(last_delay~=delay)
    flexy_air_instance.setDelaySamples(delay);
end
lastDelay = delay;
last_noise = lastNoise;
noise = block.InputPort(3).Data;
if(last_noise~=noise)
    flexy_air_instance.setArtificialNoise(noise);
end
lastNoise = noise;
last_weight = lastWeight;
weight = block.InputPort(4).Data;
if(last_weight~=weight)
    flexy_air_instance.setFilter(weight);
end
lastWeight = weight;
flexy_air_instance.setFanSpeedPerc(block.InputPort(1).Data);

block.OutputPort(1).Data = flexy_air_instance.getSensor1DistanceMm();
block.OutputPort(2).Data = flexy_air_instance.getSensor2DistanceMm();
block.OutputPort(3).Data = flexy_air_instance.getUserInputLPerc();
block.OutputPort(4).Data = flexy_air_instance.getUserInputRPerc();
block.OutputPort(5).Data = flexy_air_instance.getTerminalInputPerc();
%end Outputs

function Update(block)

%end Update

function Derivatives(block)

%end Derivatives

function Terminate(block)
    global flexy_air_instance;
    flexy_air_instance.off();
    flexy_air_instance.close();
    
 %end Terminate

