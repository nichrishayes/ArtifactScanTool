% REMOVE BAD CHANNELS - LOW SIGNAL Formula %
function low_sig_range_all_channels_val_logical = bst_ast_remove_bad_channels_low_signal(all_amp_data)

    %take out any channels with low signal more than 10% of the trials
    low_sig_range_all_channels_val = all_amp_data(3:end,2:end) <= 40;
    low_sig_range_all_channels_val = sum(low_sig_range_all_channels_val,1);
    low_sig_range_all_channels_val = (low_sig_range_all_channels_val / size(all_amp_data(3:end,2:end),1));
    low_sig_range_all_channels_val_logical = low_sig_range_all_channels_val > 0.10;

end