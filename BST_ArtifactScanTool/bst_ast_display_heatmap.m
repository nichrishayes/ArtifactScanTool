% CREATE HEATMAP %
function h = bst_ast_display_heatmap(heatmap_data, mapMax, mapMin, title, bad_channels_to_be_removed, output_channel_names, all_condition_labels, heatmap_blocker, remove_trial_thresh, sort_type)
    %if heatmap_blocker == 1, do not block channels
    %if heatmap_blocker == 2, do block channels
    %if heatmap_blocker == 3, do block channels, but not trials
    %if heatmap_blocker == 4, do block channels, and block trials
    
    % bring in actual MEG labels %
    meg_labels_v1 = char(output_channel_names);
    % keep just the numbers dropping the 'MEG' %
    meg_labels_v1 = str2num(meg_labels_v1(:,4:end))';
    
    % get the actual MEG labels that are bad %
    meg_bad_labels_v1 = char(output_channel_names(bad_channels_to_be_removed));
    meg_bad_labels_v1 = str2num(meg_bad_labels_v1(:,4:end))';
    
    % make a copy of just the data %
    filter_data_condition_sorted = heatmap_data(:,2:end);
    
    % make a copy of just the trial labels %
    trial_labels_v1 = heatmap_data(:,1);
    
    % get mean/median/mad for each column(channel), last row is the value %
    if contains(sort_type, "mean") | contains(sort_type, "manual")
        meg_labels_v1(end+1,:) = mean(filter_data_condition_sorted, 1);
        filter_data_condition_sorted(end+1, :) = mean(filter_data_condition_sorted, 1);
        
    elseif contains(sort_type, "median")
        meg_labels_v1(end+1,:) = median(filter_data_condition_sorted, 1);
        filter_data_condition_sorted(end+1, :) = median(filter_data_condition_sorted, 1);
        
    elseif contains(sort_type, "var")
        meg_labels_v1(end+1,:) = mad(filter_data_condition_sorted, 1, 1);
        filter_data_condition_sorted(end+1, :) = mad(filter_data_condition_sorted, 1, 1);
        
    end
    
    % flip the matrix - channels are now rows, trials are now columns %
    filter_data_condition_sorted = transpose(filter_data_condition_sorted);
    meg_labels_v1 = transpose(meg_labels_v1);
    
    % sort the rows(channels) by the means/medians/vars %
    filter_data_condition_sorted = sortrows(filter_data_condition_sorted, size(filter_data_condition_sorted,2), 'descend');
    meg_labels_v2 = sortrows(meg_labels_v1, size(meg_labels_v1,2), 'descend');
    
    % flip the matrix - channels are back to columns, trials are back to
    % rows, and drop the channel means/medians/vars
    filter_data_condition_sorted = transpose(filter_data_condition_sorted(:,1:end-1));
    meg_labels_v2 = meg_labels_v2(:,1);
    
    % get max for each row(trial), last column is the max
    trial_labels_v1(:,end+1) = max(filter_data_condition_sorted, [], 2);
    filter_data_condition_sorted(:, end+1) = max(filter_data_condition_sorted, [], 2);
    
    % sort the rows(trials) by the max trial values in the last column%
    filter_data_condition_sorted = sortrows(filter_data_condition_sorted, size(filter_data_condition_sorted,2));
    [trial_labels_v2, trial_labels_indeces_v2] = sortrows(trial_labels_v1, size(trial_labels_v1,2));

    % flip the matrix - channels are back to rows, trials are back to
    % columns, and drop the trial max values
    filter_data_condition_sorted = transpose(filter_data_condition_sorted(:,1:end-1));
    trial_labels_v2 = transpose(trial_labels_v2(:,1));
    trial_labels_indeces_v2 = transpose(trial_labels_indeces_v2);
    
    
    
    % create a copy for visualizing the raw data %
    % use _v2 for raw display of channels and trials %
    filter_data_Condition_heatmap_raw = filter_data_condition_sorted;
    
    % create a second version for plotting with bad channels removed %
    filter_data_Condition_heatmap_channels_blocked = filter_data_Condition_heatmap_raw;
    
    % If there are bad channels, let's mark them out with the highest possible value %
    if size(meg_bad_labels_v1,2) > 0
        % get row indeces of bad channels %
        bad_channel_rows_v1 = find(ismember(meg_labels_v2, meg_bad_labels_v1)==1, size(meg_bad_labels_v1,2));
        
        % insert max value in all bad channels %
        filter_data_Condition_heatmap_channels_blocked(bad_channel_rows_v1,:) = repmat(...
                                            max(filter_data_Condition_heatmap_channels_blocked,[],'all'),...
                                            size(bad_channel_rows_v1,1),size(filter_data_Condition_heatmap_channels_blocked,2));
        
        % get mean/median/var again for each row(channel), last row is the value %
        if contains(sort_type, "mean") | contains(sort_type, "manual")
            meg_labels_v2(:,end+1) = mean(filter_data_Condition_heatmap_channels_blocked, 2);
            filter_data_Condition_heatmap_channels_blocked(:, end+1) = mean(filter_data_Condition_heatmap_channels_blocked, 2);
        elseif contains(sort_type, "median")
            meg_labels_v2(:,end+1) = median(filter_data_Condition_heatmap_channels_blocked, 2);
            filter_data_Condition_heatmap_channels_blocked(:, end+1) = median(filter_data_Condition_heatmap_channels_blocked, 2);
        elseif contains(sort_type, "var")
            meg_labels_v2(:,end+1) = mad(filter_data_Condition_heatmap_channels_blocked, 1, 2);
            filter_data_Condition_heatmap_channels_blocked(:, end+1) = mad(filter_data_Condition_heatmap_channels_blocked, 1, 2);
        end
        
        
        % sort the rows(channels) by the means/medians/vars %
        % store the new version of channel labels %
        meg_labels_v3 = sortrows(meg_labels_v2, size(meg_labels_v2,2), 'descend');
        filter_data_Condition_heatmap_channels_blocked = sortrows(filter_data_Condition_heatmap_channels_blocked, ...
                                                        size(filter_data_Condition_heatmap_channels_blocked,2), 'descend');
        
        
        % drop the means/median/vars, indeces, and labels %meg_labels_v2 
        meg_labels_v3 = meg_labels_v3(:,1);
        filter_data_Condition_heatmap_channels_blocked = filter_data_Condition_heatmap_channels_blocked(:,1:end-1);
        
        
        
        % heatmap with channels blocked should use meg_labels_v3 and
        % trials_v2
        % use the second version - dropping the blocked out channels - for plotting with bad trials %
        filter_data_Condition_heatmap_trials_blocked = filter_data_Condition_heatmap_channels_blocked(...
                                                        ~ismember(meg_labels_v3, meg_bad_labels_v1),:);
                                                    
                                                    
        % flip the matrix - channels are back to columns, trials are back to
        % rows
        trial_labels_v3 = transpose(trial_labels_v2);
        trial_labels_indeces_v3 = transpose(trial_labels_indeces_v2);
        filter_data_Condition_heatmap_trials_blocked = transpose(filter_data_Condition_heatmap_trials_blocked);
        % get max for each row(trial), last column is the max
        trial_labels_v3(:, end+1) = max(filter_data_Condition_heatmap_trials_blocked, [], 2);
        trial_labels_indeces_v3(:, end+1) = max(filter_data_Condition_heatmap_trials_blocked, [], 2);
        filter_data_Condition_heatmap_trials_blocked(:, end+1) = max(filter_data_Condition_heatmap_trials_blocked, [], 2);
        
        % sort the rows(trials) by the NEW max trial values in the last column %
        trial_labels_v3 = sortrows(trial_labels_v3, size(trial_labels_v3,2));
        trial_labels_indeces_v3 = sortrows(trial_labels_indeces_v3, size(trial_labels_indeces_v3,2));
        filter_data_Condition_heatmap_trials_blocked = sortrows(filter_data_Condition_heatmap_trials_blocked, size(filter_data_Condition_heatmap_trials_blocked,2));
        
        % flip the matrix - channels are back to rows, trials are back to
        % columns, and keep the max
        % values (these are now the last row)
        filter_data_Condition_heatmap_trials_blocked = transpose(filter_data_Condition_heatmap_trials_blocked);
        trial_labels_v3 = transpose(trial_labels_v3(:, 1));
        trial_labels_indeces_v3 = transpose(trial_labels_indeces_v3(:, 1));
        
        % the rest of trial data setup occurs only if the trial threshold is
        % greater than 0 %
        
    % else there are not bad channels to be marked out
    else
        filter_data_Condition_heatmap_trials_blocked = filter_data_Condition_heatmap_channels_blocked;
        
        % get max for each column(trial), last row is the max
        filter_data_Condition_heatmap_trials_blocked(end+1, :) = max(filter_data_Condition_heatmap_trials_blocked, [], 1);
        
        
        %set which channels to use
        meg_labels_v3 = meg_labels_v2(:,1);
        trial_labels_indeces_v3 = trial_labels_indeces_v2;
        trial_labels_v3 = trial_labels_v2;
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
        
        % re add bad channels to top rows %
        filter_data_Condition_heatmap_trials_blocked = [filter_data_Condition_heatmap_channels_blocked(ismember(meg_labels_v3, meg_bad_labels_v1),:); filter_data_Condition_heatmap_trials_blocked];
        
    else
        % re add bad channels to top rows, also dropping trial max from last row %
        filter_data_Condition_heatmap_trials_blocked = [filter_data_Condition_heatmap_channels_blocked(ismember(meg_labels_v3, meg_bad_labels_v1),:); filter_data_Condition_heatmap_trials_blocked(1:end-1,:)];
    
    end
    
    % plot raw data without channels or trials blocked %
    if heatmap_blocker == 1
        
        h = heatmap(filter_data_Condition_heatmap_raw,...
        'ColorLimits', [round(mapMin) round(mapMax)], 'Title', sprintf("%s Raw", title), ...
        'YLabel', 'Sensors', 'XLabel','Trials', 'GridVisible','off', 'Colormap', jet);
        h.YData = cellstr(num2str(meg_labels_v2(:,1)));
        trial_labels_v3 = {};
        for trial=1:size(trial_labels_v2,2)
            trial_labels_v3{1,trial} = sprintf('%d_%s', ...
                sum(trial_labels_v2(1,trial_labels_indeces_v2 < trial_labels_indeces_v2(1,trial)) == trial_labels_v2(1,trial)), ...
                char(all_condition_labels(trial_labels_v2(1,trial),1)));
        end
        h.XData = transpose(trial_labels_v3);
    % plot data with bad channels blocked, bad trials unblocked
    elseif heatmap_blocker == 2
        h = heatmap(filter_data_Condition_heatmap_channels_blocked,...
        'ColorLimits', [round(mapMin) round(mapMax)], 'Title', sprintf("%s Channels Removed", title), 'YLabel', 'Sensors', 'XLabel','Trials', 'GridVisible','off', 'Colormap', jet);

        h.YData = cellstr(num2str(meg_labels_v3));
        trial_labels_v4 = {};
        for trial=1:size(trial_labels_v2,2)
            trial_labels_v4{1,trial} = sprintf('%d_%s', ...
                sum(trial_labels_v2(1,trial_labels_indeces_v3 < trial_labels_indeces_v3(1,trial)) == trial_labels_v2(1,trial)), ...
                char(all_condition_labels(trial_labels_v2(1,trial),1)));
        end
        h.XData = transpose(trial_labels_v4);
    % identical to if it's 2 currently, just a different heatmap_blocker
    % number since it's coming from the trial exclusion stage. Channels
    % blocked, trials not yet blocked
    elseif heatmap_blocker == 3
        h = heatmap(filter_data_Condition_heatmap_channels_blocked,... 
        'ColorLimits', [round(mapMin) round(mapMax)], 'Title', sprintf("%s Channels Removed", title), 'YLabel', 'Sensors', 'XLabel','Trials', 'GridVisible','off', 'Colormap', jet);
        h.YData = cellstr(num2str(meg_labels_v3));
        trial_labels_v4 = {};
        for trial=1:size(trial_labels_v2,2)
            trial_labels_v4{1,trial} = sprintf('%d_%s', ...
                sum(trial_labels_v2(1,trial_labels_indeces_v3 < trial_labels_indeces_v3(1,trial)) == trial_labels_v2(1,trial)), ...
                char(all_condition_labels(trial_labels_v2(1,trial),1)));
        end
        h.XData = transpose(trial_labels_v4);
    % plot data from all conditions with bad channels removed and bad
    % trials removed
    elseif heatmap_blocker == 4
        h = heatmap(filter_data_Condition_heatmap_trials_blocked,...
        'ColorLimits', [round(mapMin) round(mapMax)], 'Title', sprintf("%s Trials Removed", title), 'YLabel', 'Sensors', 'XLabel','Trials', 'GridVisible','off', 'Colormap', jet);
        h.YData = cellstr(num2str(meg_labels_v3));
        trial_labels_v4 = {};
        for trial=1:size(trial_labels_v2,2)
            trial_labels_v4{1,trial} = sprintf('%d_%s', ...
                sum(trial_labels_v2(1,trial_labels_indeces_v3 < trial_labels_indeces_v3(1,trial)) == trial_labels_v2(1,trial)), ...
                char(all_condition_labels(trial_labels_v2(1,trial),1)));
        end
        h.XData = transpose(trial_labels_v4);
    end
      

end