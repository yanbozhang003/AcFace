function s_cell = z_get_spec(raw_data_dir,rx_trace_list,BC_ALL,Fs,BW,Fc,T_chirp,N_cycles,NUM_MIC_ARRAY,NUM_MIC,bgn_root)
    windowlength = 32*8;
    step_len = 32;
    noverlap = windowlength-step_len;
    nfft = 32*8;

    s_cell = cell(length(rx_trace_list)*length(BC_ALL),3);

    cell_count = 0;
    for rx_trace_idx = rx_trace_list
        for N_BC = BC_ALL
            N_BC
            cell_count = cell_count + 1;
            
            audio_speed = 340;
            delay_v = z_freq_to_time(BW,N_BC,T_chirp,Fs);
            dist_v = delay_v * audio_speed / 2;

            dist_max = 0.35;
            dist_max_idx = find(dist_v > dist_max, 1);
            
            dist_min = 0.1;
            dist_min_idx = find(dist_v <= dist_min);
            dist_min_idx = dist_min_idx(end);
            
            spec_mat_nobgn = zeros(dist_max_idx-dist_min_idx,NUM_MIC_ARRAY*NUM_MIC, N_cycles);
            spec_mat = zeros(dist_max_idx-dist_min_idx,NUM_MIC_ARRAY*NUM_MIC, N_cycles);
            
            %% get rx
            for rx_idx = 1:1:NUM_MIC_ARRAY
                [data,Fs] = audioread([raw_data_dir,'test_rx',num2str(rx_idx),'_tr',num2str(rx_trace_idx),'.wav']);
                if rx_idx == 2      % second array is arranged inversely
                    data = fliplr(data);
                end

                for mic_idx = 1:1:NUM_MIC
                    fprintf('tr_idx: %d | rx_idx: %d | mic_idx: %d\n', rx_trace_idx, rx_idx, mic_idx)

                    rx_pb_t = data(:,mic_idx);

                    rx_pb_t = highpass(rx_pb_t,12e3,Fs);        % avoid environment noise
                    %% demodulate
                    t_rx = [0:length(rx_pb_t)-1]'*1/Fs;

                    I_cos = cos(2*pi*Fc*t_rx);
                    Q_sin = sin(2*pi*Fc*t_rx);

                    I_bb_t = rx_pb_t .* I_cos;
                    Q_bb_t = rx_pb_t .* Q_sin;

                    I_bb_t_lpf = lowpass(I_bb_t,BW/2,Fs);
                    Q_bb_t_lpf = lowpass(Q_bb_t,BW/2,Fs);

                    rx_bb_t = I_bb_t_lpf - 1i*Q_bb_t_lpf;
                    
                    %% sync
                    % step 1: energy detection
                    L = 64;
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
                    range_Len = 32;
                    I_to_test = [I+L-range_Len:I+L+range_Len];

%                     subplot(2,4,1)
%                     plot(abs(rx_bb_t));
%                     ylabel('r(x) amplitude');
%                     xlabel('sample index');
%                     subplot(2,4,5)
%                     plot(ratio_vec);
%                     ylabel('power ratio');
%                     xlabel('sample index');

                    % step 2: de-chirp, check DC power
%                     dechirp_exp_t = z_get_dechirp(N_BC,upchirp_exp_t,downchirp_exp_t);
                    [dechirp_exp_t,~] = z_get_sig(Fs,BW,Fc,N_BC,T_chirp,'Y');
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
                    chirp_head = I_to_test(max_I)

                    rx_bb_t_by_frame = z_frame_segment(rx_bb_t,chirp_head,N_cycles,N_BC,T_chirp*Fs);

                    %% get multipath
                    N_sig = L_symbol;
                    CIR_v = zeros(N_sig/2+1,N_cycles);
                    for tri_i = 1:1:1
                        rx_bb_t_tmp = rx_bb_t_by_frame(:,tri_i);

                        rx_IF = rx_bb_t_tmp .* dechirp_exp_t;
                        rx_IF_f = fftshift(fft(rx_IF)/length(rx_IF));
%                         rx_IF_f = flip(rx_IF_f(1:length(rx_IF)/2+1));
%                         rx_IF_f = fft(rx_IF)/length(rx_IF);

                        plot(abs(rx_IF_f));
                        hold on

%                         CIR_v(:,tri_i) = flip(rx_IF_f(1:length(rx_IF)/2+1));
                    end
                    
                    %% remove bgn
                    bgn_tr = N_BC + 2;
                    if N_BC == 3
                        bgn_tr = 4;
                    end
                    
                    bgn = load(['bgn/bgn_tr',num2str(bgn_tr),'_rx',num2str(rx_idx),...
                        '_mic',num2str(mic_idx),'.mat']);
                    
                    CIR_v_nobgn = abs(CIR_v) - abs(bgn.CIR_v(:,1:N_cycles));

                    spec_mat_nobgn(:,(rx_idx-1)*4+mic_idx,:) = CIR_v_nobgn(dist_min_idx+1:dist_max_idx,:);
                    spec_mat(:,(rx_idx-1)*4+mic_idx,:) = abs(CIR_v(dist_min_idx+1:dist_max_idx,:));
%                     
%                     %% plot
%                     CIR_vec = abs(CIR_v)';
%                     CIR_vec_bgn = abs(bgn.CIR_v)';
%                     CIR_vec_nobgn = abs(CIR_v_nobgn)';
% 
%                     FlattenedData = CIR_vec(:)'; 
%                     MappedFlattened = mapminmax(FlattenedData, 0, 1);
%                     MappedData = reshape(MappedFlattened, size(CIR_vec)); %
% 
%                     x = (1:N_cycles)*(L_symbol)*1/Fs;
%                     y = dist_v;
% 
%                     subplot(2,4,[2 6])
%                     image(x,y(1:dist_max_idx),MappedData(:,1:dist_max_idx)'*255)
%                     xlabel('time (s)');
%                     ylabel('moving distance (cm)');
%                     colormap('jet')
%                     colorbar()
% 
%                     FlattenedData = CIR_vec_bgn(:)'; 
%                     MappedFlattened = mapminmax(FlattenedData, 0, 1);
%                     MappedData = reshape(MappedFlattened, size(CIR_vec_bgn)); %
% 
%                     x = (1:N_cycles)*(L_symbol)*1/Fs;
%                     y = dist_v;
% 
%                     subplot(2,4,[3 7])
%                     image(x,y(1:dist_max_idx),MappedData(:,1:dist_max_idx)'*255)
%                     xlabel('time (s)');
%                     ylabel('moving distance (cm)');
%                     colormap('jet')
%                     colorbar()
% 
%                     FlattenedData = CIR_vec_nobgn(:)'; 
%                     MappedFlattened = mapminmax(FlattenedData, 0, 1);
%                     MappedData = reshape(MappedFlattened, size(CIR_vec_nobgn)); %
% 
%                     x = (1:N_cycles)*(L_symbol)*1/Fs;
%                     y = dist_v;
% 
%                     subplot(2,4,[4 8])
%                     image(x,y(1:dist_max_idx),MappedData(:,1:dist_max_idx)'*255)
%                     xlabel('time (s)');
%                     ylabel('moving distance (cm)');
%                     colormap('jet')
%                     colorbar()
% 
% %                     drawnow()
%                     waitforbuttonpress()
                    
                end
            end

            s_cell{cell_count,1} = num2str(rx_trace_idx);
            s_cell{cell_count,2} = num2str(N_BC);
            s_cell{cell_count,3} = spec_mat;
        end
    end
    
end