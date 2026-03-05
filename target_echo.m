%% Target Echo Simulation

run("transmitted_signal.m")

N = length(t);
Ndelay = round(tau*fs);

echo = zeros(1,N);

echo(Ndelay+1:end) = alpha*s(1:end-Ndelay);

figure
plot(t*1e6,echo,'LineWidth',1.5)
grid on

xlabel('Time (μs)')
ylabel('Amplitude')

title('Clean Received Echo')