function perm_data = generate_permutation_for_repetition(GLM, STATS)
%% generate_permutation_for_repetition
% Generates permutation data for one repetition.
%
% Inputs:
% - GLM: Fitted GLM structure.
% - RP: Config struct with fields n_var, n_perms, edge_groups, and mask.
%
% Outputs:
% - perm_data: Struct with fields:
%       permuted_data: Matrix (n_var x n_perms) of edge stats.
%       permuted_network_data: Matrix of network stats per permutation.
%
% Workflow:
% 1. For each permutation, permute GLM signal and compute edge stats using NBSglm_smn.
% 2. Unflatten edge stats and compute network averages.
% 3. Store results in perm_data.
%
% Author: Fabricio Cravo | Date: March 2025

    permuted_data = zeros(STATS.n_var, STATS.n_perms); % Prelocate double
    permuted_network_data = zeros(numel(unique(STATS.edge_groups)) - 1, STATS.n_perms);
    
    flat_edge_stats = flat_matrix(STATS.edge_groups, STATS.mask);

    for i = 1:STATS.n_perms
        % Generate permuted data
        permuted_GL = GLM;
        permuted_GL.y = permute_signal(GLM);  % Apply permutation
        permutation_edge_stats = GLM_fit(permuted_GL);
        
        % Store permutation
        permuted_data(:, i) = permutation_edge_stats;

        % Compute and store network-level statistics
        network_stat = get_network_average(permutation_edge_stats, flat_edge_stats);
        permuted_network_data(:, i) = network_stat;
    end
    
    % Return as struct
    perm_data.permuted_data = permuted_data;
    perm_data.permuted_network_data = permuted_network_data;

end