function [sig_bb,sig_pb] = z_get_sig(signal_config,dechirp_str)

    Fs = signal_config.Fs;
    BW = signal_config.BW;
    Fc = signal_config.Fc;
    N_BC = signal_config.N_BC;
    T_chirp = signal_config.T_chirp;
    
    T_triangle = 2*T_chirp;
    N_chirp = T_chirp*Fs;
    A = 1;

    t_chirp = [0:N_chirp-1]'*1/Fs;

    upchirp_exp_t = A*exp(1i*2*pi*((-BW/2)*t_chirp+(1/2)*(BW/T_chirp)*t_chirp.^2));
    downchirp_exp_t = A*exp(1i*2*pi*((BW/2)*t_chirp-(1/2)*(BW/T_chirp)*t_chirp.^2));
    
    if strcmp(dechirp_str,'N')
        triangle_bb = z_attach_BC(N_BC, upchirp_exp_t, downchirp_exp_t);
    else
        triangle_bb = z_get_dechirp(N_BC, upchirp_exp_t, downchirp_exp_t);
    end

    N_sig = (2+N_BC)*N_chirp;
    t_sig = [0:N_sig-1]'*1/Fs;
    carrier_t = A*exp(1i*2*pi*Fc*t_sig);
    triangle_pb = triangle_bb .* carrier_t;
    
%     windowlength = 32*8;
%     step_len = 32;
%     noverlap = windowlength-step_len;
%     nfft = 32*8;
%     
%     figure()
%     spectrogram(triangle_bb,windowlength,noverlap,nfft,Fs,'yaxis')
%     
%     figure()
%     spectrogram(triangle_pb,windowlength,noverlap,nfft,Fs,'yaxis')
    
    sig_bb = triangle_bb;
    sig_pb = triangle_pb;
end

