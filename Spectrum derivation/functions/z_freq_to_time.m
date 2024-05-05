function time_v = z_freq_to_time(BW,N_BC,T_chirp,Fs)
    f_resolution = 1/(T_chirp*(N_BC+2));
    f_max = Fs/2;
    f_vec = 0:f_resolution:f_max;
    
    slope = BW/T_chirp;
    time_v = f_vec/slope;
end

