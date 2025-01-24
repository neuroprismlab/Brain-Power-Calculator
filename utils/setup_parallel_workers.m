function setup_parallel_workers(flag, worker_number)
    % Setup parallel workers only if specified
    if flag
        % Get the local parallel cluster
        c = parcluster('local'); 
        
        % Limit workers to the maximum available
        if worker_number > c.NumWorkers
            fprintf('Specified %d workers but only %d available. Setting to max available.\n', ...
                worker_number, c.NumWorkers);
            worker_number = c.NumWorkers;
        end
        
        % Check the existing parallel pool
        current_pool = gcp('nocreate');
        if ~isempty(current_pool)
            % If the existing pool has a different number of workers, delete it
            if current_pool.NumWorkers ~= worker_number
                fprintf('Current pool has %d workers. Deleting it...\n', current_pool.NumWorkers);
                delete(current_pool);
            else
                fprintf('Parallel pool already running with %d workers.\n', current_pool.NumWorkers);
                return; % No need to recreate the pool
            end
        end

        % Create a new parallel pool
        fprintf('Starting parallel pool with %d workers...\n', worker_number);
        parpool(worker_number);
    end
end
