12:22 26.01.2023, Jan Kohout

1) connect to power supply (fan)
2) connect to USB
3) start runme.m
4) left button will set fan power

RESENI POTIZI
12:46 11.10.2023
- za detekci FlexyAir() (nebo manualne s vyberem portu) MUSI byt pause(1), kdyz se to pusti bez pauzy, spadne to na error:
Error using serialport (line 116)
Unable to connect to the serialport device at port 'COM4'. Verify that a device is connected to the
port, the port is not in use, and all serialport input arguments and parameter values are supported by
the device.

Error in FlexyAir/configureSerialPort (line 344)
            obj.SerialObj = serialport(obj.SerialPort, obj.COM_BAUD_RATE, ...

Error in FlexyAir (line 87)
            obj.configureSerialPort();

Error in runme (line 57)
flexy_air = FlexyAir('COM4'); % define port manually

- Pokud se nechce matlab pripojit, je mozne, ze visi komunikace, spustte "flexy_air.close()".
- Kdyz se pusti ten vetracek scriptem, tak si ji to odchyti a pak nemuze komunikovat Simulink. 