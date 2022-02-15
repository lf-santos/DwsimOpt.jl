%% ------------------------------------------------------------------------
% Coded by Lucas Francisco dos Santos, PhD candidate at State University of
% Maringá, under supervision of prof. Mauro A. S. S. Ravagnani.
%
% This is an implementation of black-box constrained optimization uses
% kriging, artificial neural network, or Supported Vector Machine (SVM) to 
% model the feasible region, and kriging as a surrogate of the objective 
% function.

%% PROBLEM DEFINITION -----------------------------------------------------
% clearvars;
global flag_problem;
flag_problem = 'smr';  %'smr' -> SMR;
                        %'smr_2exp' -> SMR 2exp
                        %'smr_3exp' -> SMR 3exp
                        %'DexpMR' -> Dual-expander-MR;
                        %'c3mr' -> C3MR;
                        %'dmr' -> DMR;
                        %'shcb' -> shcb test function

opt_mode = 'std';       %'mo' = multi objective
                        %'std'= standard optimization mode
global std_obj;
std_obj = 'work';       %'work' or 'ua'

if strcmp(flag_problem,'smr_2exp')
    UUAA = [0.295 0.30:0.02:0.60]; %smr_2exp
    UUAA = linspace(0.29,0.66,18); UUAA=UUAA(2:end-1);
    UUAA = linspace(0.2904,0.5914,18); UUAA=UUAA(2:end-1); %TESTEEEEEE
%     UUAA = 0.295; %smr_2exp
elseif strcmp(flag_problem,'c3mr')
    UUAA = [0.26 0.265 0.27:0.01:0.4];    %c3mr
    UUAA = linspace(0.254,0.449,18); UUAA=UUAA(2:end-1);
    UUAA = linspace(0.254,0.4433,18); UUAA=UUAA(2:end-1);
    UUAA = linspace(0.25247,0.4321,18); UUAA=UUAA(2:end-1);
%     UUAA = 0.26;    %c3mr
elseif strcmp(flag_problem,'prico_2exp')
    UUAA = linspace(0.2796,0.4144,18); UUAA=UUAA(2:end-1);
    UUAA = linspace(0.2796,0.4064,18); UUAA=UUAA(2:end-1); %-36C
    UUAA = linspace(0.28,0.4064,18); UUAA=UUAA(2:end-1); %-24C
%     UUAA = 0.2843; %qyyum 2020
else
    UUAA = 1;
end
iteracaao = 1;
if strcmp(opt_mode,'std'), UUAA=1; end
%%
% for iteracaao = 1:length(UUAA) %only for multiObj
close all;
clc
format long
% path2main = pwd();
path2main = 'C:\Users\lfsfr\Documents\Doutorado\kriging_LNG';
path2gams_src = [path2main '\src\gams_src'];
% cd(path2main)
path2sim = ['C:\Users\lfsfr\Desktop\DwsimOpt.jl\examples\PRICO'];
addpath([path2main '\src']);
addpath([path2main '\src\test_fs\']);
addpath([path2main '\src\gams_src']);
addpath([path2main '\src\mlp_src']);
addpath([path2main '\data\']);

%% FLAGS ------------------------------------------------------------------
tStart = tic;
global UAmax
UAmax = UUAA(iteracaao);
UAbase= 0.2796;
global multiFactorUA;
multiFactorUA = 100;
source_multiFactorUA = 100;
flag_constraint_surrogate = 'kriging';      % 'kriging' -> kriging;
                                        % 'svm' -> support vector machine;
                                        % 'ann' -> 1-hidden-layer percepton
                                        % 'nnkr' -> neural network kriging residual
if strcmp(opt_mode,'mo'), insertGoodData = true; else, insertGoodData=false; end
new_testing = true;        % false if import from path2data
import_theta = false;
plotCrossVal = false;
% path2data = [path2sim flag_problem '\2021-4-30-11-27-90Result_0.22771_time=15.848_qk=10']; %SMR_3exp_noVLmix_compCurves
path2data = [path2sim flag_problem '\2021-5-4-10-5-80Result_0.23828_time_13.9521_qk_10']; %C3MR
% path2data = [path2sim flag_problem '\2021-4-30-10-30-80Result_0.22607_time=5.7693_qk=10']; %SMR_2exp_noVLmix_compCurves
% path2data = [path2sim flag_problem '\2021-4-28-9-17-70Result_0.25734_time=4.1578_qk=10']; %SMR_1exp_noVLmix_compCurves
% path2data = [path2sim flag_problem '\2021-6-1-9-57-80Result_0.2263_time_6.8233_UAmax_0.8']; %SMR_2exp_noVLmix_compCurves MO
% path2data = [path2sim flag_problem '\2021-6-2-8-44-80Result_0.21957_time_10.7739_UAmax_0.06']; %C3MR MO
path2data = [path2sim flag_problem '\2021-6-24-16-17-80Result_0.47378_UAbest_0.059682_time_14.2018_UAmax_0.06']; %SMR_2exp MO com UA*10, D_space mo2
path2data = [path2sim flag_problem '\2021-6-30-18-31-80Result_0.1973_Wbest_0.29497_time_5.4802_Wmax_0.295']; %SMR_2exp MO com UA*10, D_space mo2
% path2data = [path2sim flag_problem '\2021-6-30-9-17-160Result_0.19618_Wbest_0.29497_time_26.3197_Wmax_0.295']; %SMR_2exp MO com UA*10, D_space mo2
% path2data = [path2sim flag_problem '\2021-6-30-14-0-240Result_0.18357_Wbest_0.29496_time_29.3606_Wmax_0.295']; %SMR_2exp MO com UA*10, D_space mo2
path2data = [path2sim flag_problem '\2021-7-1-8-45-80Result_0.19682_Wbest_0.29496_time_4.9498_Wmax_0.295']; %SMR_2exp MO com UA*10, D_space mo2

path2data = [path2sim flag_problem '\2021-7-2-10-1-80Result_0.11213_Wbest_0.25997_time_10.1276_Wmax_0.26']; %C3MR MO com UA*100
% path2data = [path2sim flag_problem '\2021-7-2-13-26-80Result_0.10833_Wbest_0.25997_time_8.1798_Wmax_0.26']; %C3MR MO com UA*100
path2data = [path2sim flag_problem '\2021-7-6-10-7-80Result_0.11278_Wbest_0.25994_time_54.6406_Wmax_0.26']; %C3MR MO com UA*100
if iteracaao == 1
    flag_start_with_data = 0;   % 1 -> start with X, Y, C data
                                % 0 -> sample X from LHS  
else
    flag_start_with_data = 1;
    path2data = folder;
    UAbase = UUAA(iteracaao-1);
end
flag_use_gams = 1;          % 1 for GAMS and 0 for PSO
flag_cacq = 'fhat_st_ghat';      %'pfi' for probability of feasible improvement
                            %'lcb_pen' for penalized lower confidence bound
                            %'sim_pen' for penalized simulation
                            %'fhat_st_ghat' for kriging predictor only ->rápido
                            %'fhat_st_nnkr' for nnkr ->rápido
                            %'lcb_st_ghat'
dim_NN = 32;                % if 'nnkr' or 'ann'
flag_corr_kriging = '2';    % NOT '2', only if flag_use_gams=0 (PSO solver)
                            %'pj' for -theta_j * d_ij^theta_{j+1}
                            %'p'  for -theta_j * d_ij^theta_{n+1}
                            %'2'  for -theta_j * d_ij^2
flag_local = 'none';        %'nm' for Nelder-Mead -> standard
                            %'kriging' for local kriging
                            %'none' for no local search
flag_append_local = 0;
sampling_FF = false;
c_cut = 80;      %corte dos dados | C > c_cut
c_corta = true;    %remove bad sampled points
c_localsearch_trashold = 0.1;     %corte dos dados | C > c_cut
refitKriging = false;           % refit kriging durante a otimização?
refitKrigingEver = true;           % refit kriging durante a otimização?
lh_div_lh0 = 10;
% o PSO está sem chute inicial no 'InitialSwarm'
% flag_start_with_data = 1;
% path2data = 'C:\Users\lfsfr\Documents\Doutorado\kriging_LNG\sim\c3mr\2021-7-23-9-28-80Result_0.25423_time_9.3342_Khan2015';
%% PARAMETERS -------------------------------------------------------------
global f_name;
if strcmp(opt_mode, 'std')
    f_name = 'fobj_composite';              % normal optimization
elseif strcmp(opt_mode, 'mo')
    f_name = 'fMobj_composite';              % multi objective optimization
elseif strcmp(opt_mode, 'ro')
    f_name = 'fobj_composite_uncertain';    % para deterministic SO
end
f_pen_name = 'fobj_pen_generic';
% uncertain parameters
global i_mc;
global mean_mNG;
global std_mNG;
i_mc = 3;      % number of Monte Carlo simulations;
mean_mNG = 1;
std_mNG = 0.25;
% number of constraints
global qk;
qk = 10;  %number of kriging per MSHE
global pltng;   %plota o perfil de temperatura dos trocadores de calor
pltng = false;
global q;%tem que ser n_s * qk
nMSHE = 3;
if strcmp(flag_problem,'smr')
    q=qk;
    n=7;
elseif (strcmp(flag_problem,'smr_3exp'))
    q=3*qk;
    n=9;
elseif (strcmp(flag_problem,'dmr'))
    q=3*qk;
    n=15;
elseif strcmp(flag_problem,'smr_4exp')
    q=4*qk;
    n=10;
else
    q=2*qk;
    n=8;
end   
% number of initial design points
p = 10*n;
% testing points
test_samp = 0; %100
% maximum kriging iterations
M = p+10*n;
% number of kriging-assisted optimization iterations
max_ite = M - p - test_samp;
FEval_local_max = 1000;
FEval_max = FEval_local_max;
% exploration-exploitation trade-off coefficient 
global kappa;
kappa = 5;
global kappa_c;
kappa_c = 0; %positivo é otimista e negativo pessimista
is_plot = 0;
global gamultiobj_flag;
gamultiobj_flag = false;
global D_space;
if strcmp(flag_problem,'smr')
    % X = [100*m_N2, 100*m_C1, 100*m_C2, 100*m_C3, 100*m_iC5, P1,0.1*P8, T10, T10-T11];
    n = 8;
%     D_space =     [17.5, 30, 55,  40, 85,   200, 200, -157;
%                    52.5, 90, 165,  120, 255, 600, 600, -149.2]; %50%base
%     D_space = [10, 30,  70,  35, 110, 300, 300, -155;
%                70, 70, 140,  100, 190, 550, 550, -149.2]; %paper 
%     D_space = [10, 30,  70,  35, 110, 300, 300, -155;
%                70, 70, 140,  100, 190, 550, 550, -149.2]; %paper melhor
    D_space =     [10,  20,  25,  30,   45, 100, 100, -160;
                   70, 140, 175,  210, 315, 700, 700,  -149.2]; %75%base noVLmix
%     D_space =     [11.1, 35.8,52.3,  41.6, 64.2, 109, 180, -160;
%                    70,   123,  173,  210,   302, 590, 646,  -149.2]; %from parallel plot (C<0, Y<0.35) -> com PR s/ LK
    D_space =     [16.5,  31.6,  61.2,  40.8, 77.5, 116, 215,  -160;
                   70,     120,  170.5, 204,   308, 676, 692,  -149.2];%from parallel plot (C<0.3, Y<0.35) -> com PR s/ LK e 3 exp
    D_space =     [10,  23,  25,  30.3, 47.4, 100, 137,  -160;
                   70,  140, 175, 210,  313,  689, 700,  -149.2];%from parallel plot (C<1) -> com PR s/ LK e 3 exp
    x_base =      [40 80 100 120 180 400 400 -149.2];
    x_base_noVLmix = [35     70    110     100   200    300    400   -150];
    x_top_old =       [35.4760     52.7116     89.8656    100.4860    170.6438    396.8409    398.5311   -151.9426];
    x_top =       [14.9935     42.1148     84.1338     82.8097    175.7963    189.2336    315.2522   -150.0870];
    x_pso = [29.6399     52.2820    102.0326     87.3347    161.9471    340.8886    418.9266   -151.8471];
    x_paper=      [33.04       50.68       119.8       62.58       167.8       386.9         369         -153.485];
    x_paper_det = [33.6866     58.0010    106.2375     84.7538    162.8216    402.5940    369.5800   -150.6647];
    x_santos =    [31.27       48.11      95.26        70.16      140.2       362.7       496.9       -151.3];   
    x_qyyum =     [20.24       48.20      73.65        89.25      145.5       240         390         -150.6];
    x_ali =       [32.95       52         95           68.9       141.5       370         512.5         -149.5];  % perhaps P1=350?
    x_pham2017 =  [26.6        48.5       79.5         71         150         222         444.       -149.2];     % report P9!! Which is 4390
    x_pham2016 =  [29.5        68.0       152.3        235.6      0           405         548.3       -149.2];
    x_best_lng100 = [24.2473     53.0218    110.8747     74.4828    195.7097    280.4501    253.0318   -150.2036];
    x_base_new = [25    60   100   120   180   250   400];        %for fobj_composite
    D_space = [8.2500   19.8000   33.0000   39.6000   59.4000   82.5000  132.0000;
               41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000];%[0.33*x_base_new; 1.66*x_base_new];
    D_space = [0   19.8000   33.0000   39.6000   59.4000   82.5000  132.0000;
               41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000];%[0.33*x_base_new; 1.66*x_base_new]; mN2_lo = 0;
    D_space = [0   19.8000   33.0000   39.6000   59.4000   110.0  132.0000;
               41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000];%[0.33*x_base_new; 1.66*x_base_new]; mN2_lo = 0; Plo=110
    x_base_new2 = [25    60   100   120   180   300   400];        %for fobj_composite
%     D_space = [0        19.8000   33.0000   39.6000   59.4000   99.000    132.0000;
%                41.5000   99.6000  166.0000  199.2000  298.8000  498.0000  664.0000];%[0.33*x_base_new2; 1.66*x_base_new2]; mN2_lo = 0;
    n=7;
%     n = 9;
% %     D_space = [20, 30, 40,  70, 40, 70,   250, 250, -157;
% %                70, 90, 150,  150, 150, 150, 550, 550, -149.2]; %paper
%     D_space =     [25,  40,  55,  55,   55,  85, 200, 200, -157;
%                    75, 120, 165,  165, 165, 255, 600, 600, -149.2]; %50%base
%     xx = [50 80 110 110 110 170 400 400 -153.1];
%     x_top = [41.1009     67.5051    161.5219     79.1359   0 218.0034   304.6308    248.9343   -148.8431];
%     x_paper=[33.04      50.68       119.8       62.58      0 167.8      386.9         369         -153.485];
%     x_qyyum = [20.24     48.20      73.65        89.25     0 145.5      250         390         -149.2];
    x_top_new = [11.2599   38.9387   80.1987   79.9159  181.6733  154.5772  279.7806];
    x_paper = [11.3641     39.1711     79.2663     81.0916    180.1114    156.1560    284.2230];
    x_paper_new = [14.2881     41.6702     85.8570     81.7281    180.5192    182.3108    294.3735];
elseif strcmp(flag_problem,'smr_2exp')
    % X = [100*m_N2, 100*m_C1, 100*m_C2, 100*m_C3, 100*m_iC5, P1, 0.1*P8, T10_mid, T10];
    n = 8;
% %     D_space =     [15, 35, 60,  60, 75,   200, 200,  -105, -157;
% %                    45, 105, 180,  180, 225, 600, 600, -35, -149.2]; %50%base
% %     D_space =     [7.5, 17.5, 32.5,  32.5, 42.5, 85, 116.25, -119, -200;
% %                    52.5, 122.5, 227.5,  227.5, 297.5, 595, 813.75, -17, -149.2]; %75%base
% %     D_space =     [10, 30, 50,  35, 90, 100, 155, -115, -170;
% %                    55, 90, 205, 230, 290, 590, 800, -20, -149.2]; %using parallel analysis otimista
% %     D_space =     [10, 37, 56,  64, 102, 119, 156, -77, -160,;
% %                    50, 76, 155, 168, 280, 431, 779, -0, -149.2]; %using parallel analysis conservador
% %     D_space =     [10,  30,  50,  40,   95, 100, 150, -105, -160;
% %                    70, 120, 175,  200, 315, 700, 700, -15,  -149.2]; %75%base3exp using parallel C<0.3 e y<0.35
%     D_space =     [10,  20,  25,  30,   45, 100, 100, -105, -160;
%                    70, 140, 175,  210, 315, 700, 700, -15,  -149.2]; %75%base3exp para parallel [0.25*x_base_3exp;1.75*x_base_3exp]
% %     D_space =     [14.7, 22.7, 38.3,  32.8, 52.2, 109, 126, -105, -160;
% %                    67.3, 109,  174.3,  203, 306,  695, 698, -15,  -149.2]; %75%base_3sep using parallel C<0.3 e y<0.35
%     D_space =     [10, 21.4, 25.8, 30.0, 50.5, 100, 126, -105, -155;
%                    70, 140,  174.9,  210,  314, 695, 698, -15,  -149.2]; %75%base_3sep using parallel C<1
% %     D_space =     [13, 37, 56,  64, 102, 119, 156, -77;
% %                    50, 76, 155, 168, 280, 431, 779, -20]; n=8; %using parallel analysis conservador tentativa sem T10_2
% %     D_space =     [20, 50,  80, 100, 160, 250, 250, -30, -153;
% %                    60, 90, 120, 140, 200, 450, 450, -10, -149.2]; % facilitado para xternal_eqtn
%     D_space =     [5,  30,  100, 100, 160, 250, 250, -30;
%                    45, 70,  140, 140, 200, 450, 450, -10]; n=8;
%     D_space =     [10, 25, 80, 70, 130, 150, 150, -40;
%                    60, 80, 140,140,220, 600, 600, -10]; %75%base_3sep using parallel C<1
%     D_space =     [10, 21.4, 25.8, 30.0, 50.5, 100, 126, -105;
%                    70, 140,  174.9,  210,  314, 695, 698, -15]; %75%base_3sep using parallel C<1
%     D_space =     [5,  30,  100, 100, 160, 250, 250, -30, -153;
%                    45, 70,  140, 140, 200, 450, 450, -10, -149.2]; % facilitado para xternal_eqtn x_base=[25     50    120     120    180    350    350  -20  -150]
%     D_space =     [4,   08,  10,  12,   18,  40,  40, -114, -160;
%                    76, 152, 190,  228, 342, 760, 760,  -6,  -149.2]; %[0.1*x_base_3exp;1.9*x_base_3exp]
%     D_space =     [4,   08,  10,  12,   18,  40,  40, -114, -160;
%                    76, 152, 190,  228, 342, 760, 760,  -6,  -149.2]; %90%base3exp para parallel C<1 [0.1*x_base_3exp;1.9*x_base_3exp]
    if strcmp(opt_mode, 'std')
        x_top = [10.8912     34.9796    102.8085     86.1379    194.2167    199.9624    228.5447    -58.1139   -150.7825];  %SMR_2EXP
        x_top_new = [14.6732     43.6871     93.8622    120.7712    178.0652    266.3164    249.6317    -24.5641];
        x_pso = [29.9835     46.0568    122.0269     82.1551    147.2914    470.4322    480.6143    -25.6974   -150.6633];
        x_base_top =      [25     50    100     100  150    300    400  -70  -150]; %from gams tests
        x_base_new = [25    60   100   120   180   250   400 -50];        %for fobj_composite
        D_space = [8.2500   19.8000   33.0000   39.6000   59.4000   82.5000  132.0000   -83
                   41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000  -16.5];%[0.33*x_base_new; 1.66*x_base_new];
        D_space = [0        19.8000   33.0000   39.6000   59.4000   82.5000  132.0000   -83
                   41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000  -16.5];%[0.33*x_base_new; 1.66*x_base_new]; mN2_lo = 0;
        D_space = [0        19.8000   33.0000   39.6000   59.4000   110  132.0000   -83
                   41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000  -16.5];%[0.33*x_base_new; 1.66*x_base_new]; mN2_lo = 0;
        x_base_new2 = [25    60   100   120   180   300   400 -50];        %for fobj_composite
    %     D_space = [0        19.8000   33.0000   39.6000   59.4000   99.0000  132.0000   -83
    %                41.5000   99.6000  166.0000  199.2000  298.8000  498.0000 664.0000  -16.5];%[0.33*x_base_new2; 1.66*x_base_new2]; mN2_lo = 0;
        x_base =      [30     70    120     120    150    400    400   -70  -150];
        x_base_actual = [31.5 72.73 130 130 172 339 465 -68.1 -153];
        x_base_actual_round = [30 70 130 130 170 340 465 -68 -153];
        x_base_3exp =      [40 80 100 120 180 400 400 -60 -149.2];
        x_top_old = [25.6980     54.3240    117.1324    129.2794    178.8317    397.5482    276.8535    -16.7212   -151.7373];
        x_top_gams_ext = [23.3632   51.2924  112.6567  125.5067  177.1018  370.0810  278.8870  -17.2856 -151.2961]; %after NM
        x_trava_CC = [23.1348   50.4927  115.4710  123.0451  180.3916  362.9026  268.1200  -20.4095];
        x_paper = [14.4632     41.8793     95.6350    113.6488    176.3968    261.6836    259.1653    -25.8495];
        x_paper_new = [15.8213     44.2570     95.3324    119.8335    173.5494    282.7767    265.9824    -24.3056];
    elseif strcmp(opt_mode,'mo')
        %MULTI-OBJETIVO COM BASE EM KHAN ET AL. 2015
        x_base_mo = [25    80   100   120   180   300   400 -40];        %for fobj_composite MO -> KHAN ET AL. 2015
        D_space = [0        26.4   33.0000   39.6000   59.4000   82.5000  132.0000   -66.4
                   41.5000  132.8  166.0000  199.2000  298.8000  415.0000  664.0000  -13.2];%D_space=[0.33*x_base_mo; 1.66*x_base_mo]; D_space(1,1)=0; D_space(:,end)=[-66.4;-13.2];
        D_space = [         0   40.0000   50.0000   60.0000   90.0000  150.0000  200.0000  -60.0000
                      37.5000  120.0000  150.0000  180.0000  270.0000  450.0000  600.0000  -20.0000];%D_space=[0.5*x_base_mo; 1.5*x_base_mo]; D_space(1,1)=0; D_space(:,end)=[-60;-20];
        x_base_mo2=[    25    70   100   110   180   250   500   -40]; %D_space=[0.5*x_base_mo2; 1.5*x_base_mo2]; D_space(1,1)=0; D_space(:,end)=[-60;-20]; %considerar pois soluções na borda de x2 e x4
        D_space = [   12.5000   35.0000   50.0000   55.0000   90.0000  125.0000  200.0000  -60.0000
                      37.5000  105.0000  150.0000  165.0000  270.0000  375.0000  600.0000  -20.0000];%D_space=[0.5*x_base_mo2; 1.5*x_base_mo2]; D_space(1,1)=0; D_space(:,end)=[-60;-20]; %considerar pois soluções na borda de x2 e x4
        D_space = [       0   23.1000   33.0000   36.3000   59.4000  120.0000  132.0000  -66.4000
                    41.5000  116.2000  166.0000  182.6000  298.8000  415.0000  664.0000  -13.2000];%
        D_space=[0.5*x_base_mo2; 1.5*x_base_mo2];D_space(1,1)=0;D_space(1,6)=max(120,D_space(1,6));tmp=D_space(:,end);D_space(:,end)=[tmp(2);tmp(1)];
    %     D_space = [       0   17.5000   25.0000   27.5000   45.0000   120      100.0000  -70.0000
    %                 43.7500  122.5000  175.0000  192.5000  315.0000  437.5000  700.0000  -10.0000];%D_space=[0.25*x_base_mo2; 1.75*x_base_mo2];D_space(1,1)=0;D_space(1,6)=120;tmp=D_space(:,end);D_space(:,end)=[tmp(2);tmp(1)];
    %     x_base_mo3 = [    20    60   100   100   200   250   500   -40];
    %     D_space=[0.7*x_base_mo3; 1.3*x_base_mo3];D_space(1,1)=0;D_space(1,6)=max(120,D_space(1,6));tmp=D_space(:,end);D_space(:,end)=[tmp(2);tmp(1)];
    end
elseif strcmp(flag_problem, 'prico_2exp')
    x_base=[    25    70   90   90   70  90   250   500];
    x_qyyum2020 = [22.1 45.25 94.2 96 65.25 82.25 247 408];
%     D_space=[0.5*x_base; 1.5*x_base];D_space(1,1)=0;D_space(1,6)=max(120,D_space(1,6));tmp=D_space(:,end);D_space(:,end)=[tmp(2);tmp(1)];
    D_space = [ 15   30   70   80   50   60  150  350
                28   55  115  125   80  100  350  550];%
    x_uabest = [26.2034     55.0000    99.7575      83.2237     80.0000     65.8517    150.0000    550.0000];
    x_wbest36 = [24.1266     43.3574     94.7601     80.0000     65.3938     71.3926    261.4022    497.9936];
    x_wbest24 = [24.2631     43.4381     95.0371     80.0000     64.5014     71.0819    263.0072    504.7563];
    x_wbest24_09999 = [24.5575   43.6872   94.5822   82.6007   59.4954   71.1541  267.5610  521.6901]; %0.9999 vap frac in stream 1_L
    x_tradeoff_l2 = [18.7074     41.3170     88.7790     80.0146     62.3503     68.3769    205.8248    548.5966];
    x_tradeoff_l1 = [15.0000     42.4399     80.8982     89.0433     57.7480     68.7114    172.1448    550.0000];
elseif strcmp(flag_problem,'smr_3exp')
    % X = [100*m_N2, 100*m_C1, 100*m_C2, 100*m_C3, 100*m_iC5, P1, 0.1*P8, T10_mid, T10];
    n = 9;
%     D_space =     [20,  40,  40,  60,   80, 200, 200, -70, -120, -157;
%                    60, 120, 120,  180, 240, 600, 600, -30,  -70, -149.2]; %50%base
    D_space =     [10,  20,  25,  30,   45, 100, 100, -70, -120, -157;
                   70, 140, 175,  210, 315, 700, 700, -10,  -70, -149.2]; %75%base para parallel [0.25*x_base;1.75*x_base]
    D_space =     [8,  16,  20,  24,   36, 80, 80,   -60, -120, -157;
                   72, 144, 180,  216, 324, 720, 720, 10,  -60, -149.2]; %75%base para parallel [0.2*x_base;1.8*x_base]
    D_space =     [4,  8,   10,  12,   18, 40, 40,   -60, -120, -157;
                   76, 152, 190, 228, 342, 760, 760, 10,  -60, -149.2]; %75%base para parallel [0.1*x_base;1.9*x_base]
%     D_space =     [10.3,  51.6,  46.8,  65.0, 123, 224, 240, -63.6, -116,   -157;
%                    63.7,  126,    170,  182,  296, 665, 593, -30.9,  -91.4, -149.2]; %using parallel analysis conservador
%     D_space =     [8,  51.6,  46.8,  65.0, 123, 224, 240, -63.6, -120,   -157;
%                    63.7,  126,    170,  182,  296, 665, 593, -30.9,  -91.4, -149.2]; %using parallel analysis conservador modificado pelo uso
%     D_space =     [9,   49.6,  88,  54.6, 145,  224, 240,   -63,  -120,     -157;
%                    59.1, 128, 174,   208, 311,  679, 700, -11.1, -72.3, -149.2]; %using parallel analysis C<0.0 && Y<0.35
    D_space =     [10,  23.4, 26, 34.2, 54,  100, 153  -68, -120, -157;
                   70,   140,175,  210, 315, 679, 700, -10,  -70, -149.2]; %using parallel analysis C<1 -> PR & 3sep
%     D_space =     [8.2,  30.7, 21.4,  27,  49, 80,  112, -60, -120, -157;
%                    72,   144,   180,  215, 323, 720, 720, 9,  -60, -149.2]; %using parallel analysis C<1 && Y<10.35 -> PR & 3sep, 0.8x_base
%     D_space =     [4.1,  36.3, 14.7,  13.7, 61, 47,  152, -60, -120, -157;
%                    76,   152,   190,  228, 342, 746, 760, 9,  -60, -149.2]; %using parallel analysis C<1 && Y<10.35 -> PR & 3sep, 0.9x_base
    D_space =     [10,  23.4, 26, 34.2, 54,  100, 153  -68, -120;
                   70,   140,175,  210, 315, 679, 700, -10,  -70];n=9; %using parallel analysis C<1 -> PR & 3sep
    x_base_new = [25    60   100   120   180   250   400 -50 -110];        %for fobj_composite
    D_space = [8.2500   19.8000   33.0000   39.6000   59.4000   82.5000  132.0000  -80          -130
               41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000  -16.5000    -80.1];%[0.33*x_base_new; 1.66*x_base_new];
    D_space = [6.2500   15   25.0000   30.000   45.000   62.5000  100.0000  -80          -130
               43.7500  105  175.0000  210.000  315.000  437.500  700.0000  -16.5000    -80.1];%[0.25*x_base_new; 1.75*x_base_new];
    D_space = [0        19.8000   33.0000   39.6000   59.4000   82.5000  132.0000  -80          -130
               41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000  -16.5000    -80.1];%[0.33*x_base_new; 1.66*x_base_new]; mN2_lo = 0;
    D_space = [0        19.8000   33.0000   39.6000   59.4000   110.0000  132.0000  -80          -130
               41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000  -16.5000    -80.1];%[0.33*x_base_new; 1.66*x_base_new]; mN2_lo = 0; Psuc_lo=110;
    x_base_new2 = [25    60   100   120   180   300   400 -50 -110];        %for fobj_composite
%     D_space = [0         19.8000   33.0000   39.6000   59.4000   99.0000  132.0000   -80          -130
%                41.5000   99.6000  166.0000  199.2000  298.8000  498.0000  664.0000  -16.5000    -80.1];%[0.33*x_base_new; 1.66*x_base_new]; mN2_lo = 0;
    x_base =      [40 80 100 120 180 400 400 -50 -110 -149.2];
    x_pso = [14.6598     57.9185    116.4532    100.0511    170.8735    394.6417    343.4674    -20.2944    -98.3767   -154.9634];
    x_top = [10.1591   53.4740  118.7757   85.8325  165.7784  411.2663  397.5507  -26.3876 -111.5097 -151.1554];
    x_top_old = [9.9306     53.4205    119.8172     85.0274    166.7713    408.4791    393.1472    -27.2893   -112.5707   -150.8389];
    x_paper = [4.4631     44.8990    100.1160     83.3052    161.5336    298.3454    361.7456    -30.4926   -120.4218];
    x_paper_new =[4.6634     45.1171    100.3938     83.3254    160.9075    302.2217    365.4304    -30.0808   -120.1990];
elseif strcmp(flag_problem,'smr_4exp')
    % X = [100*m_N2, 100*m_C1, 100*m_C2, 100*m_C3, 100*m_iC5, P1, 0.1*P8, T10, T10_2, T10_3, T10_4];
    n = 11;
%     D_space =     [10,  20,  25,  30,   45, 100, 100, -50, -100, -149.2,   -157;
%                    70, 140, 175,  210, 315, 700, 700,   0,  -50,   -100, -149.2]; %75%base para parallel [0.25*x_base;1.75*x_base]
%     D_space =     [13.2, 76.1, 45.4, 68,  153, 317, 260, -44, -96.2, -145, -157;
%                    68.5, 136,  170,  203, 295, 690, 678,  -0, -53.5, -112, -149.2]; %using parallel analysis C<0.5 && Y<0.35 -> PR & 3sep
    D_space =     [11.8, 34,  44,  35.7, 105, 103, 135, -48, -97.8, -149, -157;
                     70, 140, 174,  210, 314, 690, 700,  -0, -51.3, -101, -149.2]; %using parallel analysis C<1 && Y<10.35 -> PR & 3sep
%     D_space =     [8, 34,  44,  35.7, 105, 103, 135, -48, -97.8, -149;
%                   70, 140, 174,  210, 314, 690, 700,  -0, -51.3, -101]; n=10;%using parallel analysis C<1 && Y<10.35 -> PR & 3sep
    x_base =      [40 80 100 120 180 400 400 -30 -90 -130 -149.2];
    x_base_new = [25    60   100   120   180   250   400 -20 -83 -120]; n=10;       %for fobj_composite
    D_space = [8.2500   19.8000   33.0000   39.6000   59.4000   82.5000  132.0000  -70         -100    -130;
               41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000  -6.6000    -70.1   -100];%[0.33*x_base_new; 1.66*x_base_new];
    D_space = [0        19.8000   33.0000   39.6000   59.4000   82.5000  132.0000  -70         -100    -130;
               41.5000   99.6000  166.0000  199.2000  298.8000  415.0000  664.0000  -6.6000    -70.1   -100];%[0.33*x_base_new; 1.66*x_base_new];
    x_base_new2 = [25    60   100   120   180   300   400 -25 -86 -125];
%     D_space = [0        19.8000   33.0000   39.6000   59.4000   99.0000  132.0000  -55         -105    -130;
%                41.5000   99.6000  166.0000  199.2000  298.8000  498.0000  664.0000  -8.2500    -55.1   -105.1];%[0.33*x_base_new2; 1.66*x_base_new2];
elseif strcmp(flag_problem,'DexpMR')
    n = 8;
    % D_space = [10, 30, 70,  35, 110, 300, 300, -160;
    %            70, 70, 140,  100, 250, 550, 550, -145]; %Qyyum
    D_space = [10,    30,    70,    35,   110,    300,   300,    -155;
               70,    70,   140,    100,   190,   600,   550,    -130]; %hard enough
    % D_space = [10,    10,    10,    10,   10,       300,   300,    -155;
    %                 150,    150,   150,    150,   200,   600,   550,    -130]; %haarrdd
    x_paper = [29.0756     54.5709    114.7526     78.5541    141.5268    540.2366    416.9757   -142.4643];
    x_santos = [36.94    47.22      107.4        68.06      143.1       482.9       478.5      -141.5];
    x_qyyum = [7         47.8       51.1         181.9      0           260         789      -145];   % Png = 64.8 bar 
%     x_qyyum = [4.6       43.7       57.6         173.6      0           169         807.7    -144.1];   % Png = 50 bar
elseif strcmp(flag_problem,'c3mr')
    % X = [C_N2, C_C1, C_C2, C_C3, C_iC4, C_iC5, m_MR, Pi_MR, Pf_MR, Pi_C3, Pf_C3, T_MCHE];
%     n = 12;
%     D_space = [10,  10,  10,   10,  10,  10,  1, 2.5, 40, 1, 10, -140;
%                100, 100, 100,  100, 100, 100, 3, 3.5, 60, 2, 15, -130];
%     x_test = [4.58 26.11 42.24 27.07 0 0 1.964 3.3 50 1.3 13.98 -133.4];
%     x_top = [4.58 26.11 42.24 27.07 0 0 1.964 3.3*0.875 50 1.3 13.98 -133.4];
    % c3mr_linde_statoil_completo
%     n = 8;
%     D_space = [1,  10,  10,   10,  10,  1, 2.5, 40;
%                100, 100, 100,  100, 100, 3, 3.5, 60];
%     x_top = [9.5 53, 83, 52.6, 0, 1.981, 3.3, 51];
%     x_test = [30, 75, 95, 70, 0, (0.3+0.75+.95+.7), 2.5, 55];
%     f_name = [f_name '_c3mr'];

    % c3mr_linde_statoil_completo sem ADJ OLD
%     n = 15;
%     D_space = [1,  10,  10,   10,  10,  1, 2.5, 40;
%                100, 100, 100,  100, 100, 3, 3.5, 60];
%     x_top = [9.5 53, 83, 52.6, 1.981, 3.3, 51, 22.4, 4, -14, -33.34, 0.8823, 0.6802, 0.519];
%     x_test = [30, 75, 95, 70, 0, (0.3+0.75+.95+.7), 2.5, 55];
%     f_name = [f_name '_c3mr'];
    
    % c3mr_linde_statoil_completo sem ADJ
    % X = [C_N2, C_C1, C_C2, C_C3,m_MR, Pi_MR, Pf_MR, Pf_C3, Tlng1, Tlng2, Tlng3, Tlng4, T_saidaLNG100, T_saidaLNG101, Pi_C3];
    n = 14;
    D_space = [5,   40,   70,    40,   1.5, 2.5, 40, 20, 3, -15, -35, -133, -160, 136;
               15,  60,   90,    60,   2.5, 4.5, 60, 25, 6, -10, -31, -123, -140, 142];
    x_top = [9.5, 53, 83, 52.6, 1.981, 3.3, 51, 22.4, 4, -14, -33.34, -126, -149.6, 137.3];
    x_test = [30, 75, 95, 70, 0, (0.3+0.75+.95+.7), 2.5, 55];
%     f_name = 'fobj_c3mr_noAdj';
%     f_pen_name = ['fobj_pen_c3mr_noAdj'];
    
    % c3mr_matheus
    n = 11;
    D_space = [10   30  50  20  300     300     15   0    -15      -37     -145;
               30   80  130 80  500     600     20   5    -10      -25     -130];
    x_base = [16.65 51.35 91.06 47.74 379.9 522.8 22.83 2.812 -17.48 -36.83 -131.6];
    n = 8;
    D_space = [10   30  50  20  200     200     -37     -145;
               30   80  130 80  600     600     -0     -130]; % tentativa sem T HE_i
    x_base = [16.65 51.35 91.06 47.74 379.9 522.8 -36.83 -131.6];
%     f_name = 'fobj_mat';
%     f_pen_name = 'fobj_pen_mat';
    D_space = [10   40  100  40  300     300     -37     -130;
               30   60  120  60  400     400     -33     -120]; % tentativa sem T HE_i -> para GAMS, APAGAR DPS, SE QUISER
    x_base = [15 50 120  60  350 350 -35 -125];     %melhorar espaço de busca
    D_space = [ 5   37.5000   90.0000   45.0000  262.5000  262.5000  -37  -130
               25   62.5000  150.0000   75.0000  437.5000  437.5000  -33  -120];
    D_space = [ 5   30   80   40  200  200  -37  -130
               25   70  160   80  500  500  -25  -100]; %10 ou 20 a mais e menos q x_base
    D_space = [ 0   30   80   40  200  200  -37  -130
               35   70  160   80  500  500  -25  -100]; %10 ou 20 a mais e menos q x_base <- melhorar isso
%     f_name = 'fobj';
%     f_pen_name = 'fobj_pen';

    %PAPER PRES21:
    x_base = [20 60 100 60 250 400 -35 -125];
    D_space = [ 0   19.8   33   19.8  82.5  132  -37   -135
               33.2   99.6  166   99.6  415  664  -30  -115]; %[0.33x_base; 1.66x_base] mN2->0; 
    n=8;
    x_paper = [1.4816     39.4799     82.0467     58.7720    215.3497    317.4669    -37.0000   -126.4039];
    x_khan2015 = [9     51.3     83.0000     53.2    335    502.5    -33.34   -130];
    x_qyyum2020= [8     44.9     84.30000     56.9    275    434.3    -33.42   -129];
    x_qyyum2020_mod= [7.3     44.83     84.25     56.85    275    434.3    -33.34   -130];
    x_ga = [20.4238     55.1145    117.0760     73.4227    351.7711    408.8738    -33.4123   -118.1588];
    x_pso = [13.1210     55.1991    103.2910     58.3507    369.5115    426.0610    -32.0705   -118.9206];

    % multi-obj
    %primabudi et al. 2019
    x_primabudi = [301.8*3600/570240*7.2 301.8*3600/570240*24.8 301.8*3600/570240*33.2 301.8*3600/570240*34.7 290 486 -33.15 -130];
    x_primabudi_best = [285.8*3600/570240*10.2 285.8*3600/570240*12.1 285.8*3600/570240*51.4 285.8*3600/570240*29.2 250 483 -33.15 -130];
    x_base = [20 60 100 60 250 500 -35 -125];
    D_space=[0.8*x_base; 1.2*x_base];D_space(1,6)=max(120,D_space(1,6)); D_space(:,7)=[-37; -30]; tmp=D_space(:,end);D_space(:,end)=[-135; -115];
    x_trava_sim = [5.8057   47.5478   94.4396   57.3676  295.9072  367.9054  -36.7112 -122.0042];
    x_trava_sim2 = [2.7125905372014   49.8897632087702   91.6671183876117   42.9595836579260   237.0538777111056   423.7111762441605  -36.5248568458752  -119.9127126050160];
    x_trava_sim3 = [7.2965   45.9510   94.4120   47.1200  296.8900  370.2700  -37.0000 -120.2700];
elseif strcmp(flag_problem, 'dmr')
    x_base = [0 60 130 180 230 282.8 266.0 -30 -100 60 50 20 0 300 300];
    D_space = [ 0   19.8 42.9   59.4  75.9  93.32 87.78 -10 -70  19.8 16.5 6.6   0 99  99;
               30   99.6 215.8 298.8 381.8  469.5 441.6 -40 -130 99.6 83   33.2 30 498 498]; %[0.33x_base; 1.66x_base] mN2->0; 
    n=15;
elseif strcmp(flag_problem, 'shcb')
    n=2;
    D_space = [-2, -1; 2, 1];
    optimum = -0.937214065198000;
    x_opt =[0.249574771645935
      -0.725349549702491]';
    f_name = 'shcb_st_ellipsoides';
    is_plot = 1;
end


if strcmp(flag_problem,'smr'), true_optimum = 0.234932;
elseif strcmp(flag_problem,'DexpMR'), true_optimum = 0.19724; 
elseif strcmp(flag_problem,'c3mr'), true_optimum = 0.2306; end
true_optimizer =[];
% q = 10;

%% Input para HYSYS
if (strcmp(flag_problem,'shcb')==0)
global MyObject;
global MySimCase;
global MyOperations; 
global MyStreams;
global MyMSHE;
global pen;
global MySolver;
pen = 1;
global dtmin;
dtmin = 3.01;
global feasAccept;
feasAccept = 1-3/dtmin;
% UAmax = UAmax - feasAccept;
global T_LNG_max;

T_LNG_max = -157;
global vap_LNG_max;
vap_LNG_max = 0.0801;
global P_LNG_min;
P_LNG_min = 101.325;
global T1_min;
T1_min = 0;
global penalty;
penalty = 0;
global f_fail;
f_fail = pen;

%%%%% Getting Hysys Objects %%%%%
MyObject = actxserver('Hysys.Application');
aplicacao= ['prico.hsc']; 
MySimCase = MyObject.SimulationCases.Open([path2sim '\' aplicacao]);
% hyCase = MyObject.ActiveDocument;
MySimCase.Visible = true;
MySimCase.Activate()
MyOperations = MySimCase.Flowsheet.Operations;
MyStreams = MySimCase.Flowsheet.Streams;
try MyMSHE = get(MyOperations,'Item', 'LNG-100'); catch, MyMSHE=1; end
MySolver = MyObject.ActiveDocument.Solver;             
end

x_base = [40.31 46.9 92.55 287.8 0 130 480]