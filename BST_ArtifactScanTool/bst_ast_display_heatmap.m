% CREATE HEATMAP %
function h = bst_ast_display_heatmap(heatmap_data, mapMax, mapMin, title, bad_channels_to_be_removed, output_channel_names, all_condition_labels, heatmap_blocker, remove_trial_thresh, sort_type)
    %if heatmap_blocker == 1, do not block channels
    %if heatmap_blocker == 2, do block channels
    %if heatmap_blocker == 3, do block channels, but not trials
    %if heatmap_blocker == 4, do block channels, and block trials
    
    % bring in actual MEG labels, and drop the MEG converting to numbers %
    meg_labels_v1 = str2num(char(extractAfter(output_channel_names, "MEG")))';
    
    % get the actual MEG labels that are bad %
    meg_bad_labels_v1 = meg_labels_v1(bad_channels_to_be_removed);
    
    % make a copy of just the data %
    filter_data_condition_sorted = heatmap_data(:,2:end);
    
    % make a copy of just the trial labels %
    trial_labels_v1 = heatmap_data(:,1);
    
    % get mean/median/mad for each column(channel), last row is the value %
    if contains(sort_type, "mean") | contains(sort_type, "manual")
        filter_data_condition_sorted(end+1, :) = mean(filter_data_condition_sorted, 1);
        
    elseif contains(sort_type, "median")
        filter_data_condition_sorted(end+1, :) = median(filter_data_condition_sorted, 1);
        
    elseif contains(sort_type, "var")
        filter_data_condition_sorted(end+1, :) = mad(filter_data_condition_sorted, 1, 1);
        
    end
    
    % flip the matrix - channels are now rows, trials are now columns %
    filter_data_condition_sorted = transpose(filter_data_condition_sorted);
    
    % sort the rows(channels) by the means/medians/vars %
    [filter_data_condition_sorted, meg_labels_v1_sort] = sortrows(filter_data_condition_sorted, size(filter_data_condition_sorted,2), 'descend');
    
    % flip the matrix - channels are back to columns, trials are back to
    % rows, and drop the channel means/medians/vars
    filter_data_condition_sorted = transpose(filter_data_condition_sorted(:,1:end-1));
    
    % get max for each row(trial)(across all channels), last column is the max
    filter_data_condition_sorted(:, end+1) = max(filter_data_condition_sorted, [], 2);
    
    % sort the rows(trials) by the max trial values in the last column%
    [filter_data_condition_sorted, trial_labels_v1_sorted] = sortrows(filter_data_condition_sorted, size(filter_data_condition_sorted,2));

    % flip the matrix - channels are back to rows, trials are back to
    % columns, and drop the trial max values
    filter_data_condition_sorted = transpose(filter_data_condition_sorted(:,1:end-1));
    trial_labels_v1_sorted = transpose(trial_labels_v1_sorted);
    
    
    % create a copy for visualizing the raw data %
    % use _v2 for raw display of channels and trials %
    filter_data_Condition_heatmap_raw = filter_data_condition_sorted;
    
    % create a second version for plotting with bad channels removed %
    filter_data_Condition_heatmap_channels_blocked = filter_data_Condition_heatmap_raw;
    
    % If there are bad channels, let's mark them out with the highest possible value %
    if size(meg_bad_labels_v1,2) > 0
        % get row indeces of bad channels %
        meg_labels_v2 = meg_labels_v1(meg_labels_v1_sort)';
        trial_labels_v2 = trial_labels_v1(trial_labels_v1_sorted)';
        
        % find bad channel rows to fill with max value
        bad_channel_rows_v1 = find(ismember(meg_labels_v2, meg_bad_labels_v1), size(meg_bad_labels_v1,2));
        good_channel_rows_v1 = find(~ismember(meg_labels_v2, meg_bad_labels_v1), size(meg_labels_v2,1)-size(meg_bad_labels_v1,2));
        
        % insert max value in all bad channels %
        filter_data_Condition_heatmap_channels_blocked(bad_channel_rows_v1,:) = repmat(...
                                            max(filter_data_Condition_heatmap_channels_blocked,[],'all'),...
                                            size(bad_channel_rows_v1,1),size(filter_data_Condition_heatmap_channels_blocked,2));
        
        % heatmap with channels blocked should also use _v2 for channel and
        % trial labels
        % use the version - blocked out channels dropped - for plotting with bad trials %
        filter_data_Condition_heatmap_trials_blocked = filter_data_Condition_heatmap_channels_blocked(good_channel_rows_v1,:);
                                                    
        % flip the matrix - channels are back to columns, trials are back to
        % rows
        filter_data_Condition_heatmap_trials_blocked = transpose(filter_data_Condition_heatmap_trials_blocked);
        
        % get max for each row(trial), last column is the max
        filter_data_Condition_heatmap_trials_blocked(:, end+1) = max(filter_data_Condition_heatmap_trials_blocked, [], 2);
        
        % sort the rows(trials) by the NEW max trial values in the last column %
        [filter_data_Condition_heatmap_trials_blocked,trial_labels_v2_sorted] = sortrows(filter_data_Condition_heatmap_trials_blocked, size(filter_data_Condition_heatmap_trials_blocked,2));
        
        % flip the matrix - channels are back to rows, trials are back to
        % columns, and keep the max values (these are now the last row)
        filter_data_Condition_heatmap_trials_blocked = transpose(filter_data_Condition_heatmap_trials_blocked);
        % the rest of trial data setup occurs only if the trial threshold is
        % greater than 0 %
        
        % heatmap with channels blocked AND trials blocked should use _v3 for channel and
        % trial labels
        trial_labels_v3 = trial_labels_v2(trial_labels_v2_sorted);
        
    % else there are not bad channels to be marked out
    else
        % get row indeces of bad channels %
        meg_labels_v2 = meg_labels_v1(meg_labels_v1_sort)';
        trial_labels_v2 = trial_labels_v1(trial_labels_v1_sorted)';
        
        filter_data_Condition_heatmap_trials_blocked = filter_data_Condition_heatmap_channels_blocked;
        
        % get max for each column(trial), last row is the max
        filter_data_Condition_heatmap_trials_blocked(end+1, :) = max(filter_data_Condition_heatmap_trials_blocked, [], 1);
        
        trial_labels_v3 = trial_labels_v2;
        trial_labels_v2_sorted = trial_labels_v1_sorted;
    end
        
        

    % get a logical for where the max values are greater than the trial max
    % threshold, then find the column numbers for exclusion
    if (remove_trial_thresh > 0) & (sum(filter_data_Condition_heatmap_trials_blocked(end, :) > remove_trial_thresh) > 0)
        % column numbers for exclusion
        bad_trial_columns_v1 = find(filter_data_Condition_heatmap_trials_blocked(end, :)...
            > remove_trial_thresh, sum(filter_data_Condition_heatmap_trials_blocked(end, :) > remove_trial_thresh));
        
        % drop the trial max values from the last row %
        filter_data_Condition_heatmap_trials_blocked = filter_data_Condition_heatmap_trials_blocked(1:end-1, :);
        % fill trial columns identified as bad with max value %
        filter_data_Condition_heatmap_trials_blocked(:,bad_trial_columns_v1) = repmat(max(filter_data_Condition_heatmap_trials_blocked,[],'all'),...
            size(filter_data_Condition_heatmap_trials_blocked,1), size(bad_trial_columns_v1,2));
        
        if exist('bad_channel_rows_v1','var')
            % re add bad channels to top rows %
            filter_data_Condition_heatmap_trials_blocked = [filter_data_Condition_heatmap_channels_blocked(bad_channel_rows_v1,:); filter_data_Condition_heatmap_trials_blocked];
        end
            
            
    else
        if exist('bad_channel_rows_v1','var')
            % re add bad channels to top rows, also dropping trial max from last row %
            filter_data_Condition_heatmap_trials_blocked = [filter_data_Condition_heatmap_channels_blocked(bad_channel_rows_v1,:); filter_data_Condition_heatmap_trials_blocked(1:end-1,:)];
        else
            filter_data_Condition_heatmap_trials_blocked = filter_data_Condition_heatmap_trials_blocked(1:end-1,:);
        end
    end
    
    % plot raw data without channels or trials blocked %
    if heatmap_blocker == 1
        
        h = heatmap(filter_data_Condition_heatmap_raw,...
        'ColorLimits', [round(mapMin) round(mapMax)], 'Title', sprintf("%s Raw", title), ...
        'YLabel', 'Sensors', 'XLabel','Trials', 'GridVisible','off', 'Colormap', jet);
        h.YData = cellstr(num2str(meg_labels_v2(:,1)));
        label_looper = 1:size(trial_labels_v2,2);
        trial_labels_v4 = arrayfun(@(SSS) sprintf('%d_%s', ...
                sum(trial_labels_v2(trial_labels_v1_sorted < trial_labels_v1_sorted(SSS)) == trial_labels_v2(SSS)), ...
                all_condition_labels{trial_labels_v2(SSS)}), label_looper, 'UniformOutput', false);
            
        h.XData = transpose(trial_labels_v4);
    % plot data with bad channels blocked, bad trials unblocked
    elseif (heatmap_blocker == 2) | (heatmap_blocker == 3)
        h = heatmap(filter_data_Condition_heatmap_channels_blocked,...
        'ColorLimits', [round(mapMin) round(mapMax)], 'Title', sprintf("%s Channels Removed", title), 'YLabel', 'Sensors', 'XLabel','Trials', 'GridVisible','off', 'Colormap', jet);
        h.YData = cellstr(num2str(meg_labels_v2));
        label_looper = 1:size(trial_labels_v2,2);
        trial_labels_v4 = arrayfun(@(SSS) sprintf('%d_%s', ...
                sum(trial_labels_v2(trial_labels_v1_sorted < trial_labels_v1_sorted(SSS)) == trial_labels_v2(SSS)), ...
                all_condition_labels{trial_labels_v2(SSS)}), label_looper, 'UniformOutput', false);
        h.XData = transpose(trial_labels_v4);
    elseif heatmap_blocker == 4
        h = heatmap(filter_data_Condition_heatmap_trials_blocked,...
        'ColorLimits', [round(mapMin) round(mapMax)], 'Title', sprintf("%s Trials Removed", title), 'YLabel', 'Sensors', 'XLabel','Trials', 'GridVisible','off', 'Colormap', jet);
        h.YData = cellstr(num2str(meg_labels_v2));
        label_looper = 1:size(trial_labels_v3,2);
        trial_labels_v4 = arrayfun(@(SSS) sprintf('%d_%s', ...
                sum(trial_labels_v3(trial_labels_v2_sorted < trial_labels_v2_sorted(SSS)) == trial_labels_v3(SSS)), ...
                all_condition_labels{trial_labels_v3(SSS)}), label_looper, 'UniformOutput', false);
        h.XData = transpose(trial_labels_v4);
    end
      

end