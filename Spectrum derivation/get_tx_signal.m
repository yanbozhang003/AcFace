clear;
close all

%% get signal
Fs = 48e3;
BW = 12e3;
T_chirp = 50e-3;
T_triangle = 2*T_chirp;
N_chirp = T_chirp*Fs;
N_triangle = T_triangle*Fs;
A = 1;

t_chirp = [0:N_chirp-1]'*1/Fs;

upchirp_exp_t = A*exp(1i*2*pi*((-BW/2)*t_chirp+(1/2)*(BW/T_chirp)*t_chirp.^2));
downchirp_exp_t = A*exp(1i*2*pi*((BW/2)*t_chirp-(1/2)*(BW/T_chirp)*t_chirp.^2));

triangle_exp_t = [upchirp_exp_t;downchirp_exp_t];

windowlength = 32*8;
step_len = 32;
noverlap = windowlength-step_len;
nfft = 32*8;

% figure()
% spectrogram(triangle_exp_t,windowlength,noverlap,nfft,Fs,'yaxis')

N_BC = 0;
tx_sig = z_attach_BC(N_BC, upchirp_exp_t, downchirp_exp_t);

% tx_sig = lowpass(tx_sig,BW/16,Fs);

% figure()
% spectrogram(tx_sig,windowlength,noverlap,nfft,Fs,'yaxis')

Fc = (Fs-BW)/2;
N_sig = (2+N_BC)*N_chirp;
t_sig = [0:N_sig-1]'*1/Fs;
carrier_t = A*exp(1i*2*pi*Fc*t_sig);
tx_sig_up = tx_sig .* carrier_t;

% figure()
% spectrogram(tx_sig_up,windowlength,noverlap,nfft,Fs,'yaxis')

tx_sig = real(tx_sig_up);

figure()
spectrogram(tx_sig,windowlength,noverlap,nfft,Fs,'yaxis')

%% repeat pattern

triangle_bp_real_t = tx_sig;

N_cycle = 122;
N_GI = 0;

amp_v = ones(N_cycle,1);

tx_sig = [];
for i = 1:1:length(amp_v)
    tx_sig = [tx_sig; amp_v(i)*triangle_bp_real_t; zeros(N_GI,1)];
end

tx_sig = [0.001*cos(2*pi*(Fc-BW/2)*[0:N_chirp*5-1]'*1/Fs);
    tx_sig];    % spk always miss the first upchirp
tx_sig = 0.8 * tx_sig / max(abs(tx_sig));

figure()
t_sig = [0:length(tx_sig)-1]'*1/Fs;
plot(t_sig,tx_sig);

figure()
spectrogram(tx_sig,windowlength,noverlap,nfft,Fs,'yaxis')

total_time = ceil(t_sig(end))+3;

audiowrite(['tx\tx_BC',num2str(N_BC),'_',num2str(total_time),'s.wav'],tx_sig,Fs);

