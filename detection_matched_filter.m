%% Target Detection using Matched Filter

run("add_noise.m")

[R,lags] = xcorr(r,s);

[~,idx] = max(abs(R));

lag_est = lags(idx);

tau_est = lag_est/fs;

d_est = c*tau_est/2;

figure
plot(lags/fs*1e6,abs(R),'LineWidth',1.5)
grid on

xlabel('Lag (μs)')
ylabel('|R|')

title('Cross Correlation')

disp("Estimated Distance (m):")
disp(d_est)