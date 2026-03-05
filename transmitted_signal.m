%% Transmitted Signal

run("parameters.m")

t0 = 8e-6;          % pulse center
sigma = 0.35e-6;    % pulse width

s = exp(-((t - t0).^2)/(2*sigma^2));
s = s/max(abs(s));

figure
plot(t*1e6,s,'LineWidth',1.5)
grid on

xlabel('Time (μs)')
ylabel('Amplitude')

title('Transmitted Gaussian Pulse')