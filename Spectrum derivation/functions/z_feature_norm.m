function output_spec = z_feature_norm(input_spec,b,a)
    [num_freq_bin,num_mic] = size(input_spec);
    
    data_proc = zeros(num_freq_bin,num_mic);
    for mic_idx = 1:1:num_mic
        data_tmp = input_spec(:,mic_idx);

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
    output_spec = data_proc;
end

