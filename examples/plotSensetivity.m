%% Objective Function -> Sensitivity Analysis
x_c3mr_energyopt = [2.5234   40.7939   89.8308   55.5049  238.6822  301.4141  -37.0000 -122.1633];
x_c3mr_uaopt = [13.4173     81.2659     65.6213     37.2365    125.0000    750.0000    -37.0000   -133.8992];
x_c3mr_test = [2.8014   41.2836   91.0720   54.5242  245.4715  303.3915  -37.0000 -121.6634];
x_paper_new = x_base;
f_name = 'fobj_composite';
for ii=4
I = ii;
% xx = linspace(D_space(1,I),D_space(2,I),11);
xx = linspace(x_paper_new(I)*0.9,x_paper_new(I)*1.5,11);
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
hold on
plot(xx,yy_hat,'g.-')
xlabel((sprintf('x_%d',I))); ylabel('Work consumption (kW)');
figure;
plot(xx,cc,'b.-')
hold on
plot(xx,cc_hat,'g.-')
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
%% Derivative -> Sensitivity Analysis
global f_name;
f_name = fobj;
% xx = 220:10:520;
dy = zeros(size(xx));
dc = zeros(size(xx));
h=1e1;
for i=1:length(xx)
    [tmp,tmp2,tmp3,tmp4] = derivativeCalc([x_paper_new(1:I-1) xx(i) x_paper_new(I+1:end)],h);
    dy(i) = tmp2(1);
    dc(i) = tmp4(1);
end
figure;
plot(xx(1:end-1),dy(1:end-1),'r.-')
xlabel('Mass flow rate of Nitrogen [kg/h]'); ylabel('df/dx');
title(sprintf('Finite diference with h=%1.0e',h));
figure;
plot(xx(1:end-1),dc(1:end-1),'b.-')
title(sprintf('Finite diference with h=%1.0e',h));
xlabel('Mass flow rate of Nitrogen [kg/h]'); ylabel('dc/dx');
