% REMOVE BAD CHANNELS - CONSISTENCY METHOD Formula %
function [channel_amp_data_HighCutoff_logical, channel_grad_data_HighCutoff_logical, low_sig_range_all_channels_val_logical] = ...
    bst_ast_remove_bad_channels_consistency_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold, method)

    
    % get channels to be removed due to low signal %
    low_sig_range_all_channels_val_logical = bst_ast_remove_bad_channels_low_signal(all_amp_data);
    
    if method == "mean"
        % get the mean (across trials) amplitude and gradient for each
        % channel %
        m_amp_range_all_channels = mean(all_amp_data(3:end,2:end),1);
        m_grad_range_all_channels = mean(all_grad_data(3:end,2:end),1);

        % create a statistical cutoff for channel medians %
        channelAmpHighCutoff = mean(m_amp_range_all_channels)+(chanAmpDevThreshold*std(m_amp_range_all_channels));
        channelGradHighCutoff = mean(m_grad_range_all_channels)+(chanGradDevThreshold*std(m_grad_range_all_channels));
    elseif method == "median"
        % get the median (across trials) amplitude and gradient for each
        % channel %
        m_amp_range_all_channels = median(all_amp_data(3:end,2:end),1);
        m_grad_range_all_channels = median(all_grad_data(3:end,2:end),1);

        % create a statistical cutoff for channel medians %
        channelAmpHighCutoff = median(m_amp_range_all_channels)+(chanAmpDevThreshold*mad(m_amp_range_all_channels,1));
        channelGradHighCutoff = median(m_grad_range_all_channels)+(chanGradDevThreshold*mad(m_grad_range_all_channels,1));
    end
    
    % determine which channels meet criteria for exclusion for both amplitude and gradient %
    channel_amp_data_HighCutoff_logical = m_amp_range_all_channels > channelAmpHighCutoff;
    
    channel_grad_data_HighCutoff_logical = m_grad_range_all_channels > channelGradHighCutoff;
end