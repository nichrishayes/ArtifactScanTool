% REMOVE BAD CHANNELS - Display %
function channel_exclusion_table = bst_ast_remove_bad_channels_display(channel_amp_data_Cutoff_logical, channel_grad_data_Cutoff_logical, low_sig_range_all_channels_val_logical,output_channel_names)


    %Prepare the bad channels for display
    channels_removed_amp_display_labels = transpose(string(output_channel_names(channel_amp_data_Cutoff_logical)));
    channels_removed_amp_low_sig_display_labels = transpose(string(output_channel_names(low_sig_range_all_channels_val_logical)));
    channels_removed_grad_display_labels = transpose(string(output_channel_names(channel_grad_data_Cutoff_logical)));
    channels_removed_combined_display_labels = transpose(string(output_channel_names(or(or(channel_amp_data_Cutoff_logical, ...
                                                channel_grad_data_Cutoff_logical), low_sig_range_all_channels_val_logical))));

    % fill lesser sized matrices to match combined %
    channels_removed_amp_display_labels(size(channels_removed_amp_display_labels,1)+1:size(channels_removed_combined_display_labels,1),1) = "-";
    channels_removed_amp_low_sig_display_labels(size(channels_removed_amp_low_sig_display_labels,1)+1:size(channels_removed_combined_display_labels,1),1) = "-";
    channels_removed_grad_display_labels(size(channels_removed_grad_display_labels,1)+1:size(channels_removed_combined_display_labels,1),1) = "-";
   
    
    channel_exclusion_type = {'Amplitude','Gradient','Low_Signal','Combined'};
    %channel_exclusion_table = table(cellstr(channels_removed_amp_display_labels),cellstr(channels_removed_amp_low_sig_display_labels),...
    %                            cellstr(channels_removed_grad_display_labels), cellstr(channels_removed_combined_display_labels), 'VariableNames', channel_exclusion_type);
    channel_exclusion_table = vertcat(channel_exclusion_type, horzcat(cellstr(channels_removed_amp_display_labels), cellstr(channels_removed_grad_display_labels),...
                                cellstr(channels_removed_amp_low_sig_display_labels), cellstr(channels_removed_combined_display_labels)));

    
end