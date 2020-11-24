% REMOVE BAD CHANNELS - MIXED METHOD %
function [channel_amp_data_Cutoff_logical, channel_grad_data_Cutoff_logical, low_sig_range_all_channels_val_logical] = ...
    bst_ast_remove_bad_channels_mixed_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold, method)
    
    if method == "mix mean"
        % VARIABILITY METHOD %
        [channel_amp_data_CombinedCutoff_logical_var, channel_grad_data_CombinedCutoff_logical_var, low_sig_range_all_channels_val_logical_var] = ...
        bst_ast_remove_bad_channels_variability_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold);
        
        %call the consistency method with mean
        % CONSISTENCY METHOD %
        [channel_amp_data_HighCutoff_logical_cons, channel_grad_data_HighCutoff_logical_cons, low_sig_range_all_channels_val_logical_cons] = ...
        bst_ast_remove_bad_channels_consistency_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold, "mean");
        
        % MIXED METHOD %
        channel_amp_data_Cutoff_logical = or(channel_amp_data_CombinedCutoff_logical_var, channel_amp_data_HighCutoff_logical_cons);
        channel_grad_data_Cutoff_logical = or(channel_grad_data_CombinedCutoff_logical_var, channel_grad_data_HighCutoff_logical_cons);
        low_sig_range_all_channels_val_logical = or(low_sig_range_all_channels_val_logical_var, low_sig_range_all_channels_val_logical_cons);
    
    elseif method == "mix median"
        % VARIABILITY METHOD %
        [channel_amp_data_CombinedCutoff_logical_var, channel_grad_data_CombinedCutoff_logical_var, low_sig_range_all_channels_val_logical_var] = ...
        bst_ast_remove_bad_channels_variability_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold);
        
        %call the consistency method with mean
        % CONSISTENCY METHOD %
        [channel_amp_data_HighCutoff_logical_cons, channel_grad_data_HighCutoff_logical_cons, low_sig_range_all_channels_val_logical_cons] = ...
        bst_ast_remove_bad_channels_consistency_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold, "median");
        
        % MIXED METHOD %
        channel_amp_data_Cutoff_logical = or(channel_amp_data_CombinedCutoff_logical_var, channel_amp_data_HighCutoff_logical_cons);
        channel_grad_data_Cutoff_logical = or(channel_grad_data_CombinedCutoff_logical_var, channel_grad_data_HighCutoff_logical_cons);
        low_sig_range_all_channels_val_logical = or(low_sig_range_all_channels_val_logical_var, low_sig_range_all_channels_val_logical_cons);
    end
    
end