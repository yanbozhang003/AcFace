clear;
close all

% root_dir = 'C:\Users\Yanbo Zhang\OneDrive - Nanyang Technological University\work\faceRec\code\python\audioFaceID-master-RDnet-domain\data\AudioFace\raw_20211124\';
root_dir = 'D:\Onedrive\OneDrive - Nanyang Technological University\work\faceRec\code\python\audioFaceID-master-RDnet-domain\data\AudioFace\raw_20211124\';

N_BC = 3;
USER = 'jansen';
train = 'training';
domain = 1;

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

for mat_idx = 1:1:100
    load([dir_to_use,num2str(mat_idx),'.mat']);
    data = spec_data;
    
    %% plot
    mat_idx
    
    x = 1:1:16;
    y = delay_v * BW/T_chirp;
    y = y(dist_min_idx+1:dist_max_idx);
    
    data_plot = data';
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