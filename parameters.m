

clear; close all; clc;

%% 1) Parameters
c  = 3e8;              % speed of light (m/s)
fs = 50e6;             % sampling frequency (Hz)
Ts = 1/fs;

d_real = 1200;         % target range (m)  (change as you like)
alpha  = 0.6;          % attenuation factor (0..1) (simple model)

Tobs = 80e-6;          % observation window (s) must be long enough for echo
t = 0:Ts:Tobs-Ts;
N = numel(t);

% Gaussian pulse parameters
t0    = 8e-6;          % pulse center time (s)
sigma = 0.35e-6;       % pulse width (s) (smaller => wider bandwidth)
s = exp(-((t - t0).^2) / (2*sigma^2));
s = s / max(abs(s));   % normalize peak to 1

%% 2) Target delay (time-of-flight)
tau = 2*d_real/c;                   % round-trip delay (s)
Ndelay = round(tau * fs);           % delay in samples

% Build delayed echo (truncate if needed)
echo = zeros(1,N);
if Ndelay < N
    echo( (Ndelay+1):end ) = alpha * s( 1:(end-Ndelay) );
else
    warning("Delay is outside observation window. Increase Tobs or reduce d_real.");
end

%% 3) SNR scenarios
SNR_dB_list = [20 10 0 -5];

% Pre-allocate results
d_est_list = zeros(size(SNR_dB_list));
tau_est_list = zeros(size(SNR_dB_list));
err_list = zeros(size(SNR_dB_list));

%% 4) Matched filtering via cross-correlation
% Using xcorr(r, s): peak location corresponds to delay.
% lags are in samples.

figure('Name','Signals (Tx and Clean Echo)','Color','w');
subplot(2,1,1);
plot(t*1e6, s, 'LineWidth', 1.4); grid on;
xlabel('Time (\mus)'); ylabel('Amplitude');
title('Transmitted Gaussian Pulse s(t)');

subplot(2,1,2);
plot(t*1e6, echo, 'LineWidth', 1.4); grid on;
xlabel('Time (\mus)'); ylabel('Amplitude');
title(sprintf('Clean Received Echo (No Noise), d_{real}=%.1f m, \\tau=%.2f \\mus', d_real, tau*1e6));

% Loop SNR cases
for k = 1:numel(SNR_dB_list)
    SNR_dB = SNR_dB_list(k);

    % Add AWGN with desired SNR relative to signal power of echo
    Ps = mean(echo.^2);
    SNR_lin = 10^(SNR_dB/10);
    Pn = Ps / SNR_lin;
    noise = sqrt(Pn) * randn(1,N);

    r = echo + noise;

    % Cross-correlation
    [Rrs, lags] = xcorr(r, s);

    % Find peak
    [~, idx] = max(abs(Rrs));
    lag_hat = lags(idx);                 % samples
    tau_hat = lag_hat / fs;              % seconds

    % Convert to distance
    d_est = (c * tau_hat) / 2;

    % Save results
    d_est_list(k) = d_est;
    tau_est_list(k) = tau_hat;
    err_list(k) = abs(d_real - d_est);

    % Plots per SNR
    figure('Name',sprintf('SNR = %d dB', SNR_dB),'Color','w');

    subplot(2,1,1);
    plot(t*1e6, r, 'LineWidth', 1.2); grid on;
    xlabel('Time (\mus)'); ylabel('Amplitude');
    title(sprintf('Received Signal r(t) with AWGN (SNR = %d dB)', SNR_dB));

    subplot(2,1,2);
    plot(lags/fs*1e6, abs(Rrs), 'LineWidth', 1.2); grid on;
    xlabel('Lag (\mus)'); ylabel('|R_{rs}(\tau)|');
    title(sprintf('Cross-correlation |R_{rs}| (Peak at \\tau_{est}=%.2f \\mus => d_{est}=%.1f m)', tau_hat*1e6, d_est));

    xline(tau*1e6, '--', 'True \tau', 'LineWidth', 1.2);
    xline(tau_hat*1e6, '-',  'Estimated \tau', 'LineWidth', 1.2);
end

%% 5) Summary table + error plot
T = table(SNR_dB_list(:), tau_est_list(:)*1e6, d_est_list(:), err_list(:), ...
    'VariableNames', {'SNR_dB','tau_est_us','d_est_m','abs_error_m'});

disp('==== Results ====');
disp(T);

figure('Name','Range Estimation Error vs SNR','Color','w');
plot(SNR_dB_list, err_list, 'o-','LineWidth',1.4); grid on;
xlabel('SNR (dB)'); ylabel('Absolute Range Error |d_{real}-d_{est}| (m)');
title('Error vs SNR');

%% 6) (Optional) Range resolution estimate from bandwidth (rough)
% For a Gaussian pulse, bandwidth depends on sigma. A rough proxy:
% time std = sigma => approximate one-sided bandwidth ~ 1/(2*pi*sigma)
% This is not exact, but gives intuition.

B_approx = 1/(2*pi*sigma);    % Hz (rough)
deltaR = c/(2*B_approx);      % m
fprintf('Approx bandwidth ~ %.2f MHz -> Range resolution ~ %.2f m (rough)\n', B_approx/1e6, deltaR);