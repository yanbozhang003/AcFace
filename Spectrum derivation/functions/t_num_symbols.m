clear;
close all

[data,Fs] = audioread('./tx/tx_BC0_16s.wav');

BW = 12e3;
Fc = Fs/2-BW/2;
T_chirp = 50e-3;

N_BC = 3;

[sig_bb,sig_pb] = z_get_sig(Fs,BW,Fc,N_BC,T_chirp,'N');

symbol_cnt = 0;
L_triangle = T_chirp*2*Fs;
L_padding = 12000;
N_triangle = 122;
for triangle_i = 1:1:N_triangle
    head_idx = (triangle_i-1)*L_triangle+1 + L_padding;
    
    N_symbol = (N_BC+2)*L_triangle/2;
    
    tail_idx = head_idx + N_symbol - 1;
    
    if tail_idx <= length(data)
        symbol_cnt = symbol_cnt + 1;
    else
        break
    end
end
symbol_cnt