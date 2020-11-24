% REMOVE BAD CHANNELS - MANUAL METHOD %
function [all_amp_data_bad_chnls_removed, all_grad_data_bad_chnls_removed] = bst_ast_manual_remove_bad_channels(all_amp_data, all_grad_data, channel_labels, bad_channels_to_be_removed)
    channels_removed_combined_logical = ismember(channel_labels,bad_channels_to_be_removed);

    % send back data with bad channels filtered out %
    all_amp_data_bad_chnls_temp = all_amp_data(:,2:end);
    all_amp_data_bad_chnls_removed = [all_amp_data(:,1), all_amp_data_bad_chnls_temp(:,~channels_removed_combined_logical)];
    all_grad_data_bad_chnls_temp = all_grad_data(:,2:end);
    all_grad_data_bad_chnls_removed = [all_grad_data(:,1), all_grad_data_bad_chnls_temp(:,~channels_removed_combined_logical)];
end