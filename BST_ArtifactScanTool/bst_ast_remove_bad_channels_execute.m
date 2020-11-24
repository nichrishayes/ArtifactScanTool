% REMOVE BAD CHANNELS - Execute %
function [bad_channels_to_be_removed, all_amp_data_bad_chnls_removed, all_grad_data_bad_chnls_removed] = ...
    bst_ast_remove_bad_channels_execute(all_amp_data, all_grad_data, channel_amp_data_CombinedCutoff_logical, low_sig_range_all_channels_val_logical, channel_grad_data_CombinedCutoff_logical, channel_labels)

    % create final bad channel logical %
    channels_removed_combined_logical = or(or(channel_amp_data_CombinedCutoff_logical, ...
                                                channel_grad_data_CombinedCutoff_logical), low_sig_range_all_channels_val_logical);
    
                                            
    % these are the channels to be removed %
    bad_channels_to_be_removed = channel_labels(:,channels_removed_combined_logical);
    
    [all_amp_data_bad_chnls_removed, all_grad_data_bad_chnls_removed] = bst_ast_manual_remove_bad_channels(all_amp_data, ...
                                                                        all_grad_data, channel_labels, bad_channels_to_be_removed);

end