clear;
close all

root_dir = 'C:\Users\Yanbo Zhang\OneDrive - Nanyang Technological University\work\faceRec\code\python\audioFaceID-master-RDnet-domain\data\AudioFace\raw_20211124\';

N_BC = 1;
USER = 'yongcheng';
train = 'training';
domain = 3;

dir_to_use = [root_dir,'BC',num2str(N_BC),'\',train,'\',USER,'_domain',num2str(domain),'\'];

BW = 12e3;
T_chirp = 50e-3;
Fs = 48e3;
audio_speed = 340;
delay_v = z_freq_to_time(BW,N_BC,T_chirp,Fs);
dist_v = delay_v * audio_speed / 2;

dist_max = 0.35;
dist_max_idx = find(dist_v > dist_max, 1);

dist_min = 0.1;
dist_min_idx = find(dist_v <= dist_min);
dist_min_idx = dist_min_idx(end);

[b,a] = butter(4,12e3/(48e3/2),'low'); % 4-order Butterworth filter

for mat_idx = 1:1:100
    load([dir_to_use,num2str(mat_idx),'.mat']);
    
    if strcmp(train,'training')
        data = spec_train;
    else
        data = spec_test;
    end
    
    %% proc
    data = data(dist_min_idx+1:dist_max_idx,:);
    [num_freq_bin,num_mic] = size(data);
    
    data_proc = zeros(num_freq_bin,num_mic);
    for mic_idx = 1:1:num_mic
        data_tmp = data(:,mic_idx);

        data_tmp = filter(b,a,data_tmp);

        % remove negative value
        data_tmp(data_tmp<0) = 0;

        % normalization
        data_norm = data_tmp / max(abs(data_tmp));

        data_proc(:,mic_idx) = data_norm;
        
%         plot(data_norm)
%         mic_idx
%         waitforbuttonpress();
    end
    
    %% plot
    mat_idx
    
    x = 1:1:16;
    y = delay_v * BW/T_chirp;
    y = y(dist_min_idx+1:dist_max_idx);
    
    data_plot = data_proc';
    FlattenedData = data_plot(:)'; 
    MappedFlattened = mapminmax(FlattenedData, 0, 1);
    MappedData = reshape(MappedFlattened, size(data_plot)); %
    
    image(MappedData'*255)
    xlabel('Mic. index');
    ylabel('Frequency (Hz)');
    colormap('jet')
    colorbar()
    
    waitforbuttonpress();
end
