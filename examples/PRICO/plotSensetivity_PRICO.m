%% Objective Function -> Sensitivity Analysis
x_c3mr_energyopt = [2.5234   40.7939   89.8308   55.5049  238.6822  301.4141  -37.0000 -122.1633];
x_c3mr_uaopt = [13.4173     81.2659     65.6213     37.2365    125.0000    750.0000    -37.0000   -133.8992];
x_c3mr_test = [2.8014   41.2836   91.0720   54.5242  245.4715  303.3915  -37.0000 -121.6634];
x_paper_new = x_base;
xxx0 = [46.002 79.260 78.937 286.194 0 418.138 631.781];
xxx=[56.693 80.857 96.876 270.473 0 509.07 706.486];
x_paper_new = xxx;
f_name = 'fobj_composite';
for ii=[1:4 6 7]
I = ii;
% xx = linspace(D_space(1,I),D_space(2,I),11);
xx = linspace(x_paper_new(I)*0.9,x_paper_new(I)*1.1,11);
yy = zeros(size(xx));
cc = zeros(length(xx),10);
yy_hat = zeros(size(xx));
cc_hat = zeros(length(xx),10);
global f_name;
for i=1:length(xx)
    [tmp1,tmp2]=feval(f_name,([x_paper_new(1:I-1) xx(i) x_paper_new(I+1:end)]));
    yy(i) = tmp1;
%     yy_hat(i) = predictor([x_paper_new(1:I-1) xx(i) x_paper_new(I+1:end)], kriging_model);
    cc(i,:) = tmp2;
%     for j=1:20
%         cc_hat(i,j) = predictor([x_paper_new(1:I-1) xx(i) x_paper_new(I+1:end)], kriging_model_c(j));
%     end
end
figure;
plot(xx,yy,'r.-')
% hold on
% plot(xx,yy_hat,'g.-')
xlabel((sprintf('x_%d',I))); ylabel('Work consumption (kW)');
figure;
plot(xx,cc,'b.-')
% hold on
% plot(xx,cc_hat,'g.-')
title('MITA discretized');
xlabel(sprintf('x_%d',I)); ylabel('Minimum temperature approach (°C)');
figure;
plot(xx,[max(cc(:,1:10),[],2), max(cc(:,11:end),[],2)]','b.-')
title('MITA without discretizing');
xlabel(sprintf('x_%d',I)); ylabel('Minimum temperature approach (°C)');
% figure;
% plot(xx,yy_hat,'r.-')
% xlabel((sprintf('x_%d',I))); ylabel('Work consumption (kW)');
% figure;
% plot(xx,cc_hat,'b.-')
% title('MITA discretized');
% xlabel(sprintf('x_%d',I)); ylabel('Minimum temperature approach (°C)');
end
