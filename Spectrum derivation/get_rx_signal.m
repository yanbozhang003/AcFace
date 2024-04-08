clear;
close all

filename = 'Rx_file'

deviceReader = audioDeviceReader('Device','nanoSHARC micArray16 UAC2.0 ',...
    'SampleRate',48000,...
    'NumChannels',16,...
    'OutputDataType','double',...
    'BitDepth','24-bit integer');
setup(deviceReader)

fileWriter = dsp.AudioFileWriter([filename,'.wav'],'FileFormat','WAV','DataType','double',...
    'SampleRate',48000);

disp('Recording starts now');

tic
while toc < 5
    acquireAudio = deviceReader();
    fileWriter(acquireAudio);
end

disp('Record complete')

release(deviceReader)
release(fileWriter)

%%
[data,Fs] = audioread([filename,'.wav']);

for i = 1:16
    plot(data(:,i));
    ylim([-0.2 0.2])
    title(['i: ', num2str(i)]);
    
   waitforbuttonpress()
%    drawnow()
end