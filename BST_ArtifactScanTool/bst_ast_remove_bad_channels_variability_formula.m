% REMOVE BAD CHANNELS - VARIABILITY METHOD Formula %
function [channel_amp_data_CombinedCutoff_logical, channel_grad_data_CombinedCutoff_logical, low_sig_range_all_channels_val_logical] = ...
    bst_ast_remove_bad_channels_variability_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold)

    % get channels to be removed due to low signal %
    low_sig_range_all_channels_val_logical = bst_ast_remove_bad_channels_low_signal(all_amp_data);
    
    % get the MAD (across trials) amplitude and gradient for each
    % channel, then the median of those MAD's
    mad_amp_range_all_channels = mad(all_amp_data(3:end,2:end),1);
    median_mad_amp_range_all_channels = median(mad_amp_range_all_channels);
    mad_grad_range_all_channels = mad(all_grad_data(3:end,2:end),1);
    median_mad_grad_range_all_channels = median(mad_grad_range_all_channels);
    
    % create a statistical cutoff for channel MAD's %
    channelAmpLowCutoff = median_mad_amp_range_all_channels - (chanAmpDevThreshold*mad(mad_amp_range_all_channels,1));
    channelAmpHighCutoff = median_mad_amp_range_all_channels + (chanAmpDevThreshold*mad(mad_amp_range_all_channels,1));
    channelGradHighCutoff = median_mad_grad_range_all_channels + (chanGradDevThreshold*mad(mad_grad_range_all_channels,1));
    channelGradLowCutoff = median_mad_grad_range_all_channels - (chanGradDevThreshold*mad(mad_grad_range_all_channels,1));
    
    % determine which channels meet criteria for exclusion and sum trials per channel meeting exclusion %
    channel_amp_data_HighCutoff_logical = mad_amp_range_all_channels > channelAmpHighCutoff;
    channel_amp_data_LowCutoff_logical = mad_amp_range_all_channels < channelAmpLowCutoff;
    channel_amp_data_CombinedCutoff_logical = or(channel_amp_data_HighCutoff_logical, channel_amp_data_LowCutoff_logical);
    
    channel_grad_data_HighCutoff_logical = mad_grad_range_all_channels > channelGradHighCutoff;
    channel_grad_data_LowCutoff_logical = mad_grad_range_all_channels < channelGradLowCutoff;
    channel_grad_data_CombinedCutoff_logical = or(channel_grad_data_HighCutoff_logical, channel_grad_data_LowCutoff_logical);
    
end