clear;
close all

filename = 'Rx_file'

Device = 'nanoSHARC micArray16 UAC2.0'
Rx_duration = 5
Fs = 48000
NumCh = 16

deviceReader = audioDeviceReader('Device', Device,...
    'SampleRate',Fs,...
    'NumChannels',NumCh,...
    'OutputDataType','double',...
    'BitDepth','24-bit integer');
setup(deviceReader)

fileWriter = dsp.AudioFileWriter([filename,'.wav'],'FileFormat','WAV','DataType','double',...
    'SampleRate',Fs);

disp('Recording starts now');

tic
while toc < Rx_duration
    acquireAudio = deviceReader();
    fileWriter(acquireAudio);
end

disp('Record complete')

release(deviceReader)
release(fileWriter)

%%
[data,Fs] = audioread([filename,'.wav']);

for i = 1:NumCh
    plot(data(:,i));
    ylim([-0.2 0.2])
    title(['i: ', num2str(i)]);
    
   waitforbuttonpress()
%    drawnow()
end