%% primeiro roda o main até linkar o matlab com o hysys!
% MyStreams.Item('NG').PressureValue=6300
clc
tStart = tic;
global solver;
solver = 'PSO';     %'PSO' or 'GA'
% write data
dia=[];
clock_ = clock();
for i=1:length(clock_)-1
    dia = [dia num2str(clock_(i),'%4d-')];
end
folderold = [path2sim flag_problem '\' dia];
mkdir(folderold);   
pop = 2*n;%30;%
maxIte = 2*10-1;%100;%
global X;
global Y;
global C;
global ite;
X = zeros(pop*maxIte,n);
Y = zeros(pop*maxIte,1);
C = zeros(pop*maxIte,1);
ite = 0;
%     cacq = @(x)(fobj_pen(x));
cacq = @(x)(fobj_pen_generic(x,f_name));

%% rodar PSO
if strcmp(solver,'PSO')
    options = optimoptions('particleswarm','Display','iter',...
        'FunctionTolerance',1e-3,'MaxIterations',maxIte,'MaxTime',2*7200,...
        'MaxStallIterations',100,'SwarmSize',pop,'PlotFcn',@pswplotbestf);
    [x_best_pso, acq_value, exitflag, output] = particleswarm(cacq,n,D_space(1,:),D_space(2,:),options);
    x_best = x_best_pso;
    FEval = output.funccount;
end

%% rodar GA
if strcmp(solver, 'GA')
    options = optimoptions('ga','Display','iter',...
        'FunctionTolerance',1e-3,'MaxGenerations',maxIte,'MaxTime',2*7200,...
        'MaxStallGenerations',100,'PopulationSize',pop,'PlotFcn',@gaplotbestf);
    [x_sa,fval_sa,exitflag,output,population,scores] = ga(cacq, n, [],[], [],[], D_space(1,:),D_space(2,:), [], [], options);
    x_best = x_sa;
    FEval = output.funccount;
end
%% rodar GA
if strcmp(solver, 'NM')
    options = optimset('Display','iter','MaxIter',200,...
        'MaxFunEvals',pop*maxIte,'TolX',0.01,'TolFun',0.0005); % standard
    [opt,fopt,exitflag,output] = fminsearch_mod(cacq, x_base_new, options,0.2);
    x_best = opt;
    FEval = output.funcCount;
end

%% write results
[y_best, c] = feval('fobj',x_best)
writematrix(X,[folderold '\X.csv'])
writematrix(Y,[folderold '\Y.csv'])
writematrix(C,[folderold '\C.csv'])

tEnd = toc(tStart);
global qk;
if MyStreams.Item('NG').PressureValue==5000
    folder = [folderold solver num2str(FEval) '_Result_' num2str(y_best) '_time_' num2str(tEnd/60) '_qk_' num2str(qk) '_Png=50bar'];
elseif MyStreams.Item('NG').PressureValue==6300
    folder = [folderold solver num2str(FEval) '_Result_' num2str(y_best) '_time_' num2str(tEnd/60) '_qk_' num2str(qk) '_Png=63bar'];
else
    folder = [folderold solver num2str(FEval) '_Result_' num2str(y_best) '_time_' num2str(tEnd/60) '_qk_' num2str(qk) '_Khan2015'];
end
movefile(folderold,folder);
txt = [folder '\Output.txt'];
fileID = fopen(txt,'w');
fprintf(fileID,'fobj =\t%12.6f %\n',y_best);
fprintf(fileID,'\nc =\t');
fprintf(fileID,'%12.8f %12.8f\n',c);
fprintf(fileID,'\nX =\t');
fprintf(fileID,'%12.4f',x_best);
fprintf(fileID,'\n\nFEval =\t%d %\n',FEval);
fclose(fileID);

txt = [folder '\Input.txt'];
fileID = fopen(txt,'w');
fprintf(fileID,'min    	fobj(X)\ns.t.    dt>%01f\n		vfLNG<%1.3f',dtmin,vap_LNG_max);
fprintf(fileID,'\n\t\tdesign_space=');
fprintf(fileID,'\n\t\t%5.0f %5.0f',D_space);
fprintf(fileID,'\nSimulation:   %s',aplicacao);
fprintf(fileID,'\nFunçao objetivo:   %s','fobj_pen.m');
fclose(fileID);

cd(folder)
savefig('optProgress.fig');
saveas(gcf,'optProgress.png');
global pltng;
pltng = true;
[f,c] = feval(f_name, x_best)
pltng = false;
%% ploting
% if strcmp(solver,'GA')
ybest = zeros(maxIte,1);
i=1;
ybest(i)=min(Y((i-1)*pop+1:i*pop)+1000*max(0,C((i-1)*pop+1:i*pop,:))); 
for i=2:maxIte
    ybest(i)=min(ybest(i-1),min(Y((i-1)*pop+1:i*pop)+1000*max(0,C((i-1)*pop+1:i*pop,:)))); 
end
figure;
plot(ybest,'b.','MarkerSize',10)
xlabel('Iteration'); ylabel('Function Value');title(sprintf('Best Function Value: %7.6f',ybest(end)));
ax=gca();
ax.Box='off';
savefig('optProgressGA.fig');
saveas(gcf,'optProgressGA.png');
% end
