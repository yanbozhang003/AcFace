function audioRecorder(varargin)

    p = inputParser;
    addParameter(p, 'filename', 'Rx_file', @ischar);
    addParameter(p, 'Device', 'nanoSHARC micArray16 UAC2.0', @ischar);
    addParameter(p, 'Rx_duration', 5, @isnumeric);
    addParameter(p, 'Fs', 48000, @isnumeric);
    addParameter(p, 'NumCh', 16, @isnumeric);
    
    parse(p, varargin{:});
    
    filename = p.Results.filename;
    Device = p.Results.Device;
    Rx_duration = p.Results.Rx_duration;
    Fs = p.Results.Fs;
    NumCh = p.Results.NumCh;
    
    close all;
    
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
    
    [data,~] = audioread([filename,'.wav']);
    
    for i = 1:NumCh
        plot(data(:,i));
        ylim([-0.2 0.2])
        title(['i: ', num2str(i)]);
        
       waitforbuttonpress()
    end

end

