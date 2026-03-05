%% Add Noise

run("target_echo.m")

SNR_dB = 10;

Ps = mean(echo.^2);
SNR = 10^(SNR_dB/10);

Pn = Ps/SNR;

noise = sqrt(Pn)*randn(size(echo));

r = echo + noise;

figure
plot(t*1e6,r)
grid on

xlabel('Time (μs)')
ylabel('Amplitude')

title(['Received Signal with Noise SNR = ' num2str(SNR_dB) ' dB'])