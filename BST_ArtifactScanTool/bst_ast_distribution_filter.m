% FILTER TRIALS BASED ON DISTRIBUTION CUTOFFS %
function [filtered_combined_data, filtered_combined_data_cutoff_logical] = bst_ast_distribution_filter(max_amp_range_all_trials, trialAmpHighCutoff, ...
    max_grad_range_all_trials, trialGradHighCutoff, all_amp_data_bad_chnls_removed)
    
    % Take out any trials with low signal - min amplitude value across all
    % channels for each trial < 64
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    low_sig_range_all_channels_min = min(all_amp_data_bad_chnls_removed(3:end,2:end), [], 2);
    low_sig_range_all_channels_min_logical = low_sig_range_all_channels_min <= 40;
    
    % Take out any trials beyond cutoffs %
    filtered_amp_data_cutoff_logical = max_amp_range_all_trials > trialAmpHighCutoff;
    filtered_grad_data_cutoff_logical = max_grad_range_all_trials > trialGradHighCutoff;
    
    % Combine to-be removed trials from low sig and cutoff criteria %
    filtered_combined_data_cutoff_logical = or(or(filtered_amp_data_cutoff_logical,filtered_grad_data_cutoff_logical), ...
                                            low_sig_range_all_channels_min_logical);
    
    % Removed epochs from dataset %
    filtered_combined_data = all_amp_data_bad_chnls_removed(3:end,:);
    filtered_combined_data = filtered_combined_data(~filtered_combined_data_cutoff_logical,:);
end