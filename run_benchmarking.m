function run_benchmarking(RP, Y)
% Do NBS-based method benchmarking (cNBS, TFCE, etc)
%
% main outputs:
% edge_stats_all: mean and sd of edge_stats_all
% cluster_stats_all: mean and sd of cluster_stats_all
% pvals_all: total # positives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
% make sure config files in NBS_benchmarking are correct

% setparams_bench;
    
    %% This line is temporary for testing
    %disp('Temporary assigment still here')
    %RP.all_cluster_stat_types = {'#Parametric_Bonferroni', 'Parametric_FDR', 'Size', 'TFCE', ...
    %'#Constrained', 'Constrained_FWER', '#Omnibus'};
  
    % RP.list_of_nsubset = {40};

    for stat_id=1:length(RP.all_cluster_stat_types)
        RP.cluster_stat_type = RP.all_cluster_stat_types{stat_id};
        
        tic
        
        [RP.node_nets, RP.trilmask_net, RP.edge_groups] = ...
            extract_atlas_related_parameters(RP, Y);
        
        % If omnibus, we'll loop through all the specified omnibus types
        if ~strcmp(RP.cluster_stat_type, 'Omnibus')
            loop_omnibus_types = {NaN};
        else
            loop_omnibus_types = RP.all_omnibus_types;
        end
        
        for omnibus_id=1:length(loop_omnibus_types) 
            RP.omnibus_type = loop_omnibus_types{omnibus_id};
             
            if ~isnan(RP.omnibus_type)
                RP.omnibus_str = RP.omnibus_type;
            else 
                RP.omnibus_str = 'nobus'; 
            end
            
            for id_nsub_list=1:length(RP.list_of_nsubset)
                RP.n_subs_subset = RP.list_of_nsubset{id_nsub_list};

                %% Create_file_name
                [existence, output_dir] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
                                                                    RP.test_type, RP.cluster_stat_type, ...
                                                                    RP.omnibus_str, RP.n_subs_subset, ...
                                                                    RP.testing, RP.ground_truth);
                
                if existence && RP.recalculate == 0
                    fprintf('Skipping %s \n', output_dir)
                    continue 
                else
                    fprintf('Calculating %s \n', output_dir)
                end

                [UI, RP] = setup_benchmarking(RP);
    
                FWER = 0;
                FWER_neg = 0;

                    
                %% PREALOCATE SPACE FOR OUTPUT DATA
                edge_stats_all = zeros(RP.n_var, RP.n_repetitions);
                edge_stats_all_neg = zeros(RP.n_var, RP.n_repetitions);                    

                if contains(UI.statistic_type.ui,'Constrained') || strcmp(UI.statistic_type.ui,'SEA')
                  
                    % minus 1 in all - to not count "zero"
                    cluster_stats_all = zeros(length(unique(UI.edge_groups.ui)) - 1, 1, RP.n_repetitions); 
                    cluster_stats_all_neg = zeros(length(unique(UI.edge_groups.ui)) - 1, 1, RP.n_repetitions); 
                    
                    pvals_all=zeros(length(unique(UI.edge_groups.ui)) - 1, RP.n_repetitions);
                    pvals_all_neg=zeros(length(unique(UI.edge_groups.ui)) - 1, RP.n_repetitions); 
        
                elseif strcmp(UI.statistic_type.ui,'Omnibus')
        
                    if strcmp(UI.omnibus_type.ui,'Multidimensional_cNBS')
                        n_nulls = length(unique(UI.edge_groups.ui))-1;
                    else
                        n_nulls = 1;
                    end
        
                    cluster_stats_all=zeros(1, n_nulls, RP.n_repetitions);
                    cluster_stats_all_neg=zeros(1, n_nulls, RP.n_repetitions);
                    pvals_all=zeros(1, RP.n_repetitions);
                    pvals_all_neg=zeros(1, RP.n_repetitions);
        
                elseif contains(UI.statistic_type.ui,'Parametric')
        
                    cluster_stats_all=zeros(1,1, RP.n_repetitions);
                    cluster_stats_all_neg=zeros(1,1, RP.n_repetitions);
                    pvals_all=zeros(RP.n_nodes*(RP.n_nodes - 1)/2, RP.n_repetitions);
                    pvals_all_neg=zeros(RP.n_nodes*(RP.n_nodes - 1)/2, RP.n_repetitions); 
        
                else
                    
                    cluster_stats_all = zeros(RP.n_nodes, RP.n_nodes, RP.n_repetitions); 
                    cluster_stats_all_neg = zeros(RP.n_nodes, RP.n_nodes, RP.n_repetitions); 
                    pvals_all=zeros(RP.n_var, RP.n_repetitions);
                    pvals_all_neg=zeros(RP.n_var, RP.n_repetitions);
        
                end
                
                %% Sample rep ids
                ids_sampled = draw_repetition_ids(RP);               
             
                
                if RP.testing
                    fprintf('\n*** TESTING MODE ***\n\n')
                end
                
                % fprintf(['Starting benchmarking - ', RP.task1, '_v_', RP.task2, '::',
                % UI.statistic_type.ui, RP.omnibus_str, '.\n']);
               
                %% Run NBS repetitions
                
                % Be careful with this parfor commented lol
                parfor (i_rep=1: RP.n_repetitions)

                % Do not erase the comment bellow, it is used for debugging
                % when running not in parallel 
% disp('Parof');  for i_rep = 1:RP.n_repetitions
                    
                    % Encapsulation of the most computationally intensive loop
                    [FWER_rep, edge_stats_all_rep, pvals_all_rep, cluster_stats_all_rep, ...
                     FWER_neg_rep, edge_stats_all_neg_rep, pvals_all_neg_rep, cluster_stats_all_neg_rep] = ...
                     pf_repetition_loop(i_rep, ids_sampled, RP, UI, RP.X_rep, Y);
        
                    FWER = FWER + FWER_rep;
                    FWER_neg = FWER_neg + FWER_neg_rep;
        
                    edge_stats_all(:,i_rep) = edge_stats_all_rep;
                    pvals_all(:,i_rep) = pvals_all_rep;
                    edge_stats_all_neg(:,i_rep) = edge_stats_all_neg_rep;
                    pvals_all_neg(:,i_rep) = pvals_all_neg_rep;
                    
                    if ~isempty(cluster_stats_all_rep) || ~isempty(cluster_stats_all_neg_rep)
                        cluster_stats_all(:,:,i_rep) = cluster_stats_all_rep;
                        cluster_stats_all_neg(:,:,i_rep) = cluster_stats_all_neg_rep;
                    end
           
                end
                
                if contains(UI.statistic_type.ui,'Constrained') || strcmp(UI.statistic_type.ui,'SEA') ...
                    || strcmp(UI.statistic_type.ui,'Omnibus')
                    cluster_stats_all = squeeze(cluster_stats_all);
                    cluster_stats_all_neg = squeeze(cluster_stats_all_neg);
                end
                
                run_time = toc;
                
                %% Save
                
                if false
                    if strcmp(UI.statistic_type.ui,'Size')
                        size_str = ['_',UI.size.ui];
                    else
                        size_str = '';
                    end
                    
                    if testing
                        test_str = '_testing';
                    else 
                        test_str='';
                    end
                    
                    if do_TPR 
                        TPR_str = '';
                    else 
                        TPR_str = '_shuffled_for_FPR'; 
                    end
                    
                    if use_both_tasks
                        condition_str = [rep_params.task1,'_v_',rep_params.task2];
                    else 
                        condition_str = rep_params.task1;
                    end
                end
            

                %output_filename = [output_dir,'results__',condition_str,TPR_str,'_', ...
                %                   UI.statistic_type.ui,size_str,omnibus_str,'_grsize', ...
                %                   num2str(rep_params.n_subs_subset),test_str,'_', datestr(now,'mmddyyyy_HHMM'),'.mat'];
                brain_data = add_brain_data_to_repetition_data('edge_stats_all', edge_stats_all, ...
                    'edge_stats_all_neg', edge_stats_all_neg, ...
                    'cluster_stats_all', cluster_stats_all, 'cluster_stats_all_neg', cluster_stats_all_neg, ...
                    'pvals_all', pvals_all, 'pvals_all_neg', pvals_all_neg, ...
                    'FWER', FWER, 'FWER_neg', FWER_neg);

                dummy_data_set_parts = strsplit(RP.data_set, '_');
                data_set_name = dummy_data_set_parts{1};
                data_set_map = dummy_data_set_parts{2};
                meta_data = add_meta_data_to_repetition_data('dataset', data_set_name, ...
                                                 'map', data_set_map, 'test', RP.test_type, ...
                                                 'test_components', strsplit(RP.test_name, '_'), ...
                                                 'omnibus', RP.omnibus_str, 'subject_number', RP.n_subs_subset, ...
                                                 'testing_code', RP.testing, 'test_type', RP.cluster_stat_type, ...
                                                 'rep_parameters', RP, 'date', datetime("today"), ...
                                                 'run_time', run_time);
                

                fprintf('###### Saving results in %s ######### \n', output_dir)
                save(output_dir, 'brain_data', 'meta_data');
        
            end
        end

    end

end