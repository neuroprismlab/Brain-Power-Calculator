function Params = setparams()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% User-defined parameters for running NBS with design matrix via command line
%
% Can define all numerical arguments as numeric or string types
% (Original NBS designed to parse string data)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NBS toolbox
% if true, will update paths using system and paths in setpaths.m
% if false, will use the paths defined below
Params.system_dependent_paths=0;
Params.save_directory = './power_calculator_results/';
Params.data_dir = '/Users/f.cravogomes/Desktop/Cloned Repos/NBS_Calculator/data/s_hcp_fc_noble_tasks.mat';
Params.gt_data_dir = '/Users/f.cravogomes/Desktop/Cloned Repos/NBS_Calculator/power_calculator_results/ground_truth/';
Params.gt_origin = 'power_calculator';

% If recalculate is equal to 1 - recalculate
Params.recalculate = 0;

% Directories
Params.nbs_dir = './NBS1.2';
Params.other_scripts_dir='./NBS_benchmarking/support_scripts/';


%HPC data for now - need to fix directory %% FIX THIS

Params.task1='WM';         % 'EMOTION' | 'GAMBLING' | 'LANGUAGE' | 'MOTOR' | 'RELATIONAL' | 'SOCIAL' | 'WM' | 'REST'
                    % use any for TPR and 'REST' for FPR
Params.task_gt='WM'; % for ground truth (can use truncated, e.g., 'REST_176frames')
Params.task2='REST';       % 2nd task for FPR or TPR contrast (set 'REST2' for FPR)
Params.subIDs_suffix='_subIDs.txt';        % see naming convention
Params.data_type_suffix='_GSR_matrix.txt'; % see naming convention 


% Model: 2D matrix
% for testing, get from NBS toolbox "SchizophreniaExample" dir
Params.design_matrix_file = './NBS1.2/SchizophreniaExample/designMatrix.mat';
Params.contrast = [-1,1];
Params.exchange = [];

%%% Model %%%
%Params.do_TPR=1;
%Params.use_both_tasks=1; % for a paired-sample test
%Params.paired_design=1; % currently required if using a paired design

%%% Trimmed Scans %%%
% Specify whether to use resting runs for task2 which have been trimmed to match each task's scan duration
% (in no. frames for single encoding direction; cf. https://protocols.humanconnectome.org/HCP/3T/imaging-protocols.html)
% Note: all scans were acquired with the same TR
Params.use_trimmed_rest=0; % default = 0
Params.n_frames.EMOTION=176;
Params.n_frames.GAMBLING=253;
Params.n_frames.LANGUAGE=316;
Params.n_frames.MOTOR=284;
Params.n_frames.RELATIONAL=232;
Params.n_frames.SOCIAL=274;
Params.n_frames.WM=405;
Params.n_frames.REST=1200;
Params.n_frames.REST2=1200;

%%% Resampling parameters %%%
Params.n_workers = 10; % num parallel workers for parfor, best if # workers = # cores
Params.parallel = 1; % run stuff sequentially or in parallel
Params.mapping_category = 'subnetwork'; % for cNBS
Params.n_repetitions = 500;  % 500 recommended
Params.n_subs_subset = 40;   % 40 | 80 | 120

%% List of subjects per subset
Params.list_of_nsubset = {20, 40, 80, 120}; % To change this, add more when necessary
Params.list_of_nsubset = {40}; % Redefined because I need a base with all 40 first
                    % size of subset is full group size (N=n*2 for two sample t-test or N=n for one-sample)


% Edge groups -- required for cNBS and Omnibus cNBS
% file contains n_nodes x n_nodes edge matrix mask with nonzeros as follows: 1=subnetwork 1, 2=subnetwork 2, etc.
% for testing, get a map from this NBS_benchmarking toolbox "NBS_addon" dir
Params.edge_groups_file ='./NBS_benchmarking/NBS_addon/SchizophreniaExample/Example_74node_map.mat'; 

% NBS parameters
Params.nbs_method = 'Run NBS';       % 'Run NBS' (all procedures except edge-level) | 'Run Parametric Edge-Level Correction' | 'Run FDR' (nonparametric edge-level FDR correction)
% not needed anymore
% Params.nbs_test_stat = 't-test';     % 't-test' | 'one-sample' | 'F-test'
                            % Current model (see above design matrix) only designed for t-test
Params.n_perms = 1000;               % recommend n_perms=5000 to appreciably reduce uncertainty of p-value estimation (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Randomise/Theory)
Params.n_perms_gt = 1000;
Params.tthresh_first_level = 3.1;    % t=3.1 corresponds with p=0.005-0.001 (DOF=10-1000)
                            % Only used if cluster_stat_type='Size'
Params.pthresh_second_level = 0.05;  % FWER or FDR rate
Params.cluster_stat_type = 'Size';   
Params.all_cluster_stat_types = {'Parametric_Bonferroni', 'Parametric_FDR', 'Size', 'TFCE', ...
    'Constrained', 'Constrained_FWER', 'Omnibus'};
Params.stat_type_gt = 'Size';

% cluster_stat_type (should be renamed stat_type) is required for all inference procedures except nonparametric edge-level
% 'Parametric_Bonferroni' (edge-level + FWER correction; must set nbs_method=Run Parametric Edge-Level Correction)
% 'Parametric_FDR' (edge+FDR; nbs_method=Run Parametric Edge-Level Correction)
% 'Size' (cluster+FWER; nbs_method='Run NBS')
% 'TFCE' (cluster+FWER; nbs_method='Run NBS')
% 'Constrained' (predefined network+FDR; nbs_method='Run NBS')
% 'Constrained_FWER' (predefined network+FWER; nbs_method='Run NBS')
% 'Omnibus' (whole-brain; nbs_method='Run NBS')
% 'SEA' (under construction) (predefined network; nbs_method='Run NBS') -
% No SEA
Params.cluster_size_type = 'Extent'; % 'Intensity' | 'Extent'
                            % Only used if cluster_stat_type='Size'
Params.all_omnibus_types = {'Multidimensional_cNBS'};
Params.omnibus_type = 'Multidimensional_cNBS'; 
% 'Threshold_Positive' | 'Threshold_Both_Dir' | 'Average_Positive' | 'Average_Both_Dir' | 'Multidimensional_cNBS' | 'Multidimensional_all_edges' 
                            % Only used if cluster_stat_type='Omnibus'
Params.omnibus_type_gt='Threshold_Positive';
Params.use_preaveraged_constrained = 0; % 1 | 0
                            % Only used for cNBS and Omnibus cNBS
                 
%%%%% DEVELOPERS ONLY %%%%%
% Use a small subset of permutations for faster development -- inappropriate for inference

Params.testing = false;
Params.test_n_perms = '100';
Params.test_n_repetitions = 1;
Params.test_n_workers = 10;

end
