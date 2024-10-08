clear;
close all

%% load configurations, parameters, functions
function_folder = './functions/';
addpath(function_folder)

settings_folder = './settings/';
[config,setting] = z_load_config(settings_folder);

MASK_ALL = config.mask;
DISTANCE_ALL = config.distance;
USER_ALL = config.user_all;
NUM_MIC_ARRAY = setting.array;
NUM_MIC = setting.mic;

%% get spectrum
rx_trace_list = 1:16;           % CHANGE here for your traces

facial_spec_all = z_get_spec_final(rx_trace_list);

%% plot spectrum
plt_filter = fspecial('gaussian',[10,10],2);
left_location = 250:399:1048;
for depth_i = 1:3
    facial_spec_plt = squeeze(facial_spec_all(:,:,depth_i))';
    
    if config.resolution ~= 2
        facial_spec_plt = expandMatrixNonUniform(facial_spec_plt,[151,126]);
    end
    
    facial_spec_plt = facial_spec_plt / max(max(facial_spec_plt));
    max_value1 = max(max(imfilter(facial_spec_plt*255,plt_filter)));
    mat_plt = imfilter(facial_spec_plt*255,plt_filter)/max_value1*255;
    
    figure('Position',[left_location(depth_i) 50 410 500/25*30])
    imagesc(mat_plt(11:end-10,11:end-10));
    colormap('jet')
end
