function fs_final = z_get_spec_final(rx_trace_list)
    %%
    params_folder = './params/';
    settings_folder = './settings/';
    raw_data_dir = './rx_sig/';
      
    config = load([settings_folder,'config.mat']).config;
    setting_params = load([settings_folder,'settings.mat']).setting;
    signal_config = load([params_folder,'signal.mat']).signal;
    proc_params = load([params_folder,'proc.mat']).proc_params;

    %% extract parameters
    Fs = signal_config.Fs;
    BW = signal_config.BW;
    Fc = signal_config.Fc;
    N_BC = signal_config.N_BC;
    T_chirp = signal_config.T_chirp;
    BC_ALL = signal_config.BC_ALL;
    N_cycles = signal_config.N_cycle;

    NUM_MIC_ARRAY = setting_params.array;
    NUM_MIC = setting_params.mic;

    windowlength = proc_params.wl;
    step_len = proc_params.sl;
    noverlap = proc_params.nl;
    nfft = proc_params.nfft;
    cell_len = proc_params.cl;

    %%
    cell_count = 0;
    s_cell = cell(length(rx_trace_list)*length(BC_ALL),cell_len);
    for rx_trace_idx = rx_trace_list
        for N_BC = BC_ALL
            cell_count = cell_count + 1;
            
            audio_speed = proc_params.audio_speed;
            delay_v = z_freq_to_time(BW,N_BC,T_chirp,Fs);
            dist_v = delay_v * audio_speed / 2;

            dist_max_idx = find(dist_v > config.dist_max, 1);
            
            dist_min_idx = find(dist_v <= config.dist_min);
            dist_min_idx = dist_min_idx(end);
            
            N_depth = length(config.Depth_all);
            spec_mat_wbgn = zeros(dist_max_idx-dist_min_idx,NUM_MIC_ARRAY*NUM_MIC, N_cycles);
            spec_mat_depth = zeros(dist_max_idx-dist_min_idx,NUM_MIC_ARRAY*NUM_MIC, N_depth);
            
            %% get rx
            for rx_idx = 1:1:NUM_MIC_ARRAY
                [data,Fs] = audioread([raw_data_dir,'test_rx',num2str(rx_idx),'_tr',num2str(rx_trace_idx),'.wav']);
                if rx_idx == 2      % second array is arranged inversely
                    data = fliplr(data);
                end

                for mic_idx = 1:1:NUM_MIC
                    rx_pb_t = data(:,mic_idx);
                    
                    fprintf('tr_idx: %d | rx_idx: %d | mic_idx: %d\n', rx_trace_idx, rx_idx, mic_idx)
                    %%
                    t_rx = [0:length(rx_pb_t)-1]'*1/Fs;

                    I_cos = cos(2*pi*Fc*t_rx);
                    Q_sin = sin(2*pi*Fc*t_rx);

                    I_bb_t = rx_pb_t .* I_cos;
                    Q_bb_t = rx_pb_t .* Q_sin;

                    I_bb_t_lpf = lowpass(I_bb_t,BW/2,Fs);
                    Q_bb_t_lpf = lowpass(Q_bb_t,BW/2,Fs);

                    rx_bb_t = I_bb_t_lpf - 1i*Q_bb_t_lpf;
                    
                    %% sync
                    L = proc_params.edl;
                    S = length(rx_bb_t);
                    ratio_vec = zeros(1,1);
                    for win_head = 1:1:S
                        win_A_head = win_head;
                        win_A_tail = win_A_head+L-1;
                        win_B_head = win_A_head+L;
                        win_B_tail = win_B_head+L-1;
                        if win_B_tail > S
                            break;
                        end

                        win_A = rx_bb_t(win_A_head:win_A_tail);
                        win_B = rx_bb_t(win_B_head:win_B_tail);

                        ratio_vec(win_head,1) = win_B' * win_B / (win_A' * win_A);
                    end

                    [~,I] = max(ratio_vec);
                    range_Len = proc_params.rl;
                    I_to_test = [I+L-range_Len:I+L+range_Len];

                    % subplot(2,4,1)
                    % plot(abs(rx_bb_t));
                    % ylabel('r(x) amplitude');
                    % xlabel('sample index');
                    % subplot(2,4,5)
                    % plot(ratio_vec);
                    % ylabel('power ratio');
                    % xlabel('sample index');

                    % step 2: de-chirp, check DC power
%                     dechirp_exp_t = z_get_dechirp(N_BC,upchirp_exp_t,downchirp_exp_t);
                    [dechirp_exp_t,~] = z_get_sig(signal_config,'Y');
                    L_symbol = length(dechirp_exp_t);
                    
%                     figure()
%                     spectrogram(dechirp_exp_t,windowlength,noverlap,nfft,Fs,'yaxis')

                    DC_volt_vec = zeros(length(I_to_test),1);
                    for head_candidate_i = 1:1:length(I_to_test)
                        head_candidate = I_to_test(head_candidate_i);

                        rx_bb_tmp = rx_bb_t(head_candidate:head_candidate+L_symbol-1);

                        rx_IF = rx_bb_tmp .* dechirp_exp_t;

                        rx_IF_f_volt_tmp = abs(fftshift(fft(rx_IF)) / L_symbol);

                        DC_volt_vec(head_candidate_i) = rx_IF_f_volt_tmp(L_symbol/2+1);
                    end
%                     figure()
%                     plot(I_to_test,DC_volt_vec)

                    [~,max_I] = max(DC_volt_vec);
                    chirp_head = I_to_test(max_I);

                    rx_bb_t_by_frame = z_frame_segment(rx_bb_t,chirp_head,N_cycles,N_BC,T_chirp*Fs);

                    %% get multipath
                    N_sig = L_symbol;
                    cir_v = zeros(N_sig/2+1,N_cycles);
                    Depth_v = config.Depth_all;
                    for depth_i = 1:N_depth
                        for tri_i = 1:1:N_cycles
                            rx_bb_t_tmp = rx_bb_t_by_frame(:,tri_i);
                            rx_bb_t_tmp = delayseq(rx_bb_t_tmp,Depth_v(depth_i)*2/340e2,Fs);
    
                            rx_IF = rx_bb_t_tmp .* dechirp_exp_t;
                            rx_IF_f = fftshift(fft(rx_IF)/length(rx_IF));
    
    %                         plot(dist_v,abs(rx_IF_f));
    %                         hold on
    
                            cir_v(:,tri_i) = flip(rx_IF_f(1:length(rx_IF)/2+1));
                        end
                        spec_mat_wbgn(:,(rx_idx-1)*4+mic_idx,:) = abs(cir_v(dist_min_idx+1:dist_max_idx,:));
                        spec_mat_depth(:,(rx_idx-1)*4+mic_idx,depth_i) = mean(spec_mat_wbgn(:,(rx_idx-1)*4+mic_idx,:),3);
                    end
                end
            end

            s_cell{cell_count,1} = num2str(rx_trace_idx);
            s_cell{cell_count,2} = num2str(N_BC);
            s_cell{cell_count,3} = spec_mat_wbgn;
        end
    end

    %% define 3D positions
    % define microphone location
    array_length = setting_params.array_length;
    mic_dist = array_length/(setting_params.mic-1);
    
    mic_position_mat = setting_params.mic_positions;
    mic_position_vec = reshape(mic_position_mat,3,[]);
    
    % define speaker location
    speaker_position = setting_params.speaker_positon;             % [x,y,z]
    
    % map each entry of facial spec to a location
    faceArrayDist = config.distance_cm;     % CHANGE HERE for different distance
    Depth = config.Depth_all;
    
    % the coordinate is [z,x,y]
    [x_vec,y_vec,z_vec] = z_get_dims(config,faceArrayDist,Depth);
    %%
    if strcmp(config.pfm,'average')
        config.num_micNearest = 3;
    elseif strcmp(config.pfm,'model')
        config.num_micNearest = 2;
    end
    

    %%
    trace_str = ['tr',num2str(rx_trace_list(1))];
    cir_mat_all = spec_mat_depth - proc_params.bgn.(trace_str);
    res_str = ['R',num2str(config.resolution)];
    cir_m = proc_params.cir_m.(trace_str).(res_str);
    
    %%
    fs_final = zeros(length(x_vec),length(z_vec),length(y_vec));
    [num_x,num_z,num_y] = size(fs_final);

    signal_bandwidth = proc_params.fmcw_bw * 1e3;
    acoustic_speed = proc_params.audio_speed * 1e2;

    signal_resolution = acoustic_speed / signal_bandwidth;       %unit: cm
    detect_range = proc_params.fmcw_range;         % can support 50cm max distance
    cir_ref = 0:signal_resolution:detect_range*2;

    cir_mat_all = permute(cir_mat_all,[2,1,3]);
    [cir_mat_row,cir_mat_col,cir_mat_dep] = size(cir_mat_all);

    cir_mat_log = cell(cir_mat_row,cir_mat_col,cir_mat_dep);
    cir_mat_log_length = zeros(cir_mat_row,cir_mat_col,cir_mat_dep);
    cube_mat_log = cell(num_x,num_z,num_y);

    for y_i = 1:num_y
        cube_counter = 0;
        cir_mat = squeeze(cir_mat_all(:,:,y_i));
        facial_spec = zeros(length(x_vec),length(z_vec));

        for z_i = 1:num_z
            for x_i = 1:num_x
                cube_counter = cube_counter+1;

                cube_location = [x_vec(x_i),y_vec(1),z_vec(z_i)];
%                 cube_power = concatenatedSpec(x_i,z_i,y_i);
    
                distance_cube_speaker = sqrt(sum((cube_location - speaker_position).^2));
                distance_cube_mic = sqrt(sum((cube_location' - mic_position_vec).^2,1));
                path_length_vec = distance_cube_speaker + distance_cube_mic;
    
                [micDist_nearest,micIdx_nearest] = mink(path_length_vec,config.num_micNearest);

                % find cir bins
                cir_v_diff = abs(micDist_nearest - cir_ref');
                [Min_v,I_v] = min(cir_v_diff,[],1);

                % update cir_mat_log
                linearIndices = sub2ind(size(cir_mat_log), micIdx_nearest, I_v);

                % if any grid of cir_mat is 0, skip this cube
                if any(cir_mat(linearIndices) == 0)
%                     disp(cir_mat(linearIndices))
                    continue
                end

                % update cube_mat_log
                cir_mat_bin_index = sub2ind(size(cir_mat),micIdx_nearest,I_v);
                cube_mat_log{x_i,z_i,y_i}.list = cir_mat_bin_index;

                % update cir_mat_log
                for i_temp = 1:length(I_v)
                    if isempty(cir_mat_log{micIdx_nearest(i_temp),I_v(i_temp),y_i})
                        cir_mat_log{micIdx_nearest(i_temp),I_v(i_temp),y_i}.list = [];
                        cir_mat_log{micIdx_nearest(i_temp),I_v(i_temp),y_i}.list(1) = cube_counter;
                        cir_mat_log_length(micIdx_nearest(i_temp),I_v(i_temp),y_i) = cir_mat_log_length(micIdx_nearest(i_temp),I_v(i_temp),y_i)+1;
                    else
                        cir_mat_log{micIdx_nearest(i_temp),I_v(i_temp),y_i}.list(end+1) = cube_counter;
                        cir_mat_log_length(micIdx_nearest(i_temp),I_v(i_temp),y_i) = cir_mat_log_length(micIdx_nearest(i_temp),I_v(i_temp),y_i)+1;
                    end
                end
            end
        end

        cube_fill_record = zeros(1,2);          % (cube_indice, cube_power)
        cube_filled_count = 0;

        cir_mat_log_length_i = squeeze(cir_mat_log_length(:,:,y_i));
        cir_mat_log_i = cir_mat_log(:,:,y_i);
        cir_mat = squeeze(cir_mat_all(:,:,y_i));

        cir_mat_new = zeros(size(cir_mat));
        [log_rowIdx,log_colIdx] = find(cir_mat_log_length_i ~= 0);
        for cir_nonzero_i = 1:length(log_colIdx)
            row_i = log_rowIdx(cir_nonzero_i);
            col_i = log_colIdx(cir_nonzero_i);
            cir_new_temp = cir_mat(row_i,col_i) / cir_mat_log_length_i(row_i,col_i);
            cir_mat_new(row_i,col_i) = cir_new_temp;
        end

        while 1
            cir_mat_log_nonvalue = cir_mat_log_length_i;
            cir_mat_log_nonvalue(cir_mat_log_length_i <= 0) = NaN;
    
            % find smallest value in cir_mat_log
            minValue = min(cir_mat_log_nonvalue(:));
            isMinValue = cir_mat_log_nonvalue == minValue; 
            [rowIndices, colIndices] = find(isMinValue); 
    
            % find the corresponding cube in facial spec
            for i_tmp = 1:length(rowIndices)
                cir_mat_indice = [rowIndices(i_tmp),colIndices(i_tmp)];
                cubes_projected = cir_mat_log_i{cir_mat_indice(1),cir_mat_indice(2)}.list;
    
                for cube_i = 1:length(cubes_projected)
                    cube_indice = cubes_projected(cube_i);
    
                    if any(cube_fill_record(:,1)==cube_indice)
                        continue
                    end 
    
                    % find the other cir grids that is projected by this cube
                    cube_all_assoc_cir_grids_indices = get_assoc_indice(cube_indice, cir_mat_log_i);
                    [num_project_cube,~] = size(cube_all_assoc_cir_grids_indices);
    
                    % fill this cube
                    single_project_power = cir_mat(cir_mat_indice(1),cir_mat_indice(2)) / length(cubes_projected);
                    [cube_power, power_vec, cir_m] = get_cube_fed(single_project_power,cir_m,cir_mat_new,facial_spec,...
                                                        speaker_position,mic_position_vec,num_project_cube,cir_ref,...
                                                        config, proc_params, cube_indice,y_i,x_vec,y_vec,z_vec);
                    facial_spec(ind2sub([num_x,num_z],cube_indice)) = cube_power;
    
                    cube_filled_count = cube_filled_count + 1;
                    cube_fill_record(cube_filled_count,1) = cube_indice;
                    cube_fill_record(cube_filled_count,2) = cube_power;
    
                    % update the cir_mat and the log
                    for assoc_cir_grid_i = 1:num_project_cube
                        cir_mat(cube_all_assoc_cir_grids_indices(assoc_cir_grid_i,1),cube_all_assoc_cir_grids_indices(assoc_cir_grid_i,2)) = ...
                            cir_mat(cube_all_assoc_cir_grids_indices(assoc_cir_grid_i,1),cube_all_assoc_cir_grids_indices(assoc_cir_grid_i,2)) - single_project_power;
                        cir_mat_log_length_i(cube_all_assoc_cir_grids_indices(assoc_cir_grid_i,1),cube_all_assoc_cir_grids_indices(assoc_cir_grid_i,2)) = ...
                            cir_mat_log_length_i(cube_all_assoc_cir_grids_indices(assoc_cir_grid_i,1),cube_all_assoc_cir_grids_indices(assoc_cir_grid_i,2)) - 1;
                    end
                end
            end

            if all(all(cir_mat_log_length_i == 0))
                    break
            end
        end

        fs_final(:,:,y_i) = facial_spec;
    end
end

function ret_indice = get_assoc_indice(cube_indice, cir_log)
    [num_row, num_col] = size(cir_log);
    
    indice_count = 0;
    ret_indice = zeros(1,1);
    for row_i = 1:num_row
        for col_i = 1:num_col
            if isempty(cir_log{row_i,col_i})
                continue
            end

            cube_indice_list = cir_log{row_i,col_i}.list;
            
            if ismember(cube_indice, cube_indice_list)
                indice_count = indice_count + 1;
                ret_indice(indice_count,1) = row_i;
                ret_indice(indice_count,2) = col_i;
            end
        end
    end
end

function [cube_power,power_vec,cir_m] = get_cube_fed(single_project_power,cir_m,cir_mat_new,facial_spec,...
                                                        speaker_position,mic_position_vec,num_project_cube,cir_ref,...
                                                        config, proc_params, cube_indice,y_i,x_vec,y_vec,z_vec)

    [cube_row,cube_col] = ind2sub(size(facial_spec),cube_indice);

    cube_location = [x_vec(cube_row),y_vec(1),z_vec(cube_col)];
    distance_cube_speaker = sqrt(sum((cube_location - speaker_position).^2));
    distance_cube_mic = sqrt(sum((cube_location' - mic_position_vec).^2,1));

    path_length_vec = distance_cube_speaker + distance_cube_mic;        
    [micDist_nearest,micIdx_nearest] = mink(path_length_vec,config.num_micNearest);    
    cir_v_diff = abs(micDist_nearest - cir_ref');
    [Min_v,I_v] = min(cir_v_diff,[],1);

    power_vec = cir_mat_new(sub2ind(size(cir_mat_new), micIdx_nearest, I_v));
    if strcmp(config.pfm, 'average')
        if isempty(find(power_vec==0))
            cube_power = sum(abs(power_vec));
        else
            cube_power = 0;
        end       
    elseif strcmp(config.pfm, 'model')
        if num_project_cube < proc_params.cube_limit
            cube_power = single_project_power*num_project_cube;
        else
            cube_power = sum(cir_m(:,cube_indice,y_i));
        end  
    end
end
