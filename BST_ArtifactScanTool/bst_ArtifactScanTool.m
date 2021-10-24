% bst_ArtifactScanTool: Remove bad channels and trials. 
%
% USAGE:  bst_ArtifactScanTool(x, y, z)
%
% INPUT: output_channel_names, output_gradients, output_low_sig,
%       output_p2p, output_trial_fnames, output_trial_labels, 
%       path_to_database, subjid
%       
%
% OUTPUT: output_channel_names_keep, output_channel_names_remove, 
%       output_trial_labels_keep, output_trial_labels_remove, 
%       output_trial_fnames_keep, output_trial_fnames_remove,
%       logFileTableCSV
%
%
%
% DESCRIPTION: 
%         Received Artifact Estimates from bst_ArtifactRejection.m for 
%         every trial in your Brainstorm project database. It enables 
%         channel exclusion either manually or apply one of several 
%         simple statistical methods. Notably, channels with and average 
%         signal under 64 fT/cm automatically rejected. This software 
%         provides continuous heatmap graphing of the trial x channel noise
%         estimate. At the trial level, the software provides an 
%         individually-determined, statistical cutoff for both amplitude 
%         and gradient, in addition to a manual option. A distribution of 
%         trialwise amplitude and gradient estimates are included. This 
%         tool then calculates the the number of total and accepted trials 
%         for each condition included. Data is then returned to 
%         OrganizeBrainstormTrials.m for exclusion in the Brainstorm 
%         project database.
%    
% WARNING: 
%
%
% NOTE: MATLAB R2018b or later

% @=============================================================================
% This function is a wrapper to the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF NEBRASKA MEDICAL CENTER AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
% =============================================================================@
%
% Authors: Nicholas Christopher-Hayes, Alex I Wiesman
% Co-Authors: Brandon Lew
% Institutional Affiliation: University of Nebraska Medical Center



function [output_channel_names_keep, ...
    output_channel_names_remove, ...
    output_trial_labels_keep, ....
    output_trial_labels_remove,...
    output_trial_fnames_keep,...
    output_trial_fnames_remove] = bst_ArtifactScanTool(...
                                    output_p2p,...
                                    output_gradients,...
                                    output_trial_labels,...
                                    output_channel_names,...
                                    output_trial_fnames,...
                                    sensor_type,...
                                    subID,...
                                    log_path)
%

% load('ArtScanTesting.mat');
% subID = 'sub-001';

% sensor_type = "MEG GRAD";

display_text_sub = sprintf('Subject: %s\n\n',subID);

% Check to confirm there is artifact estimated data %
if isempty(output_p2p) | isempty(output_gradients)...
        | isempty(output_trial_labels)...
        | isempty(output_channel_names) | isempty(output_trial_fnames)
    error('Data not received. Ending');
end

% Setup condition labels and indeces %
all_condition_labels = unique(output_trial_labels);

% Generate numerical pairs for conditions %
all_condition_number_pairs = zeros(size(output_trial_labels,1),1);
for cond=1:size(all_condition_labels)
    all_condition_number_pairs(ismember(output_trial_labels, all_condition_labels{cond}),1) = cond;
end

% Create bad channel annotation row of 0's (nothing is bad within this tool,
% but perhaps defined as such previously), and channel labels to go along %
bad_channels = zeros(1,size(output_channel_names,2));
channel_labels = 1:size(output_channel_names,2);

% Store amplitude and gradient data in separate variables - and linearly
% transform for display purposes (data appears to be in/around nano-picotesla) %
all_amp_data = output_p2p*10000000000000;
all_grad_data = output_gradients*10000000000000;


% Build combined matrices : 1 is the asci values for letters i(condition index)%
all_amp_data = [55573,channel_labels;55573,bad_channels;all_condition_number_pairs,all_amp_data];
all_grad_data = [55573,channel_labels;55573,bad_channels;all_condition_number_pairs,all_grad_data];


% This begins the overarching cycle of this two step process: 1)remove bad
% channels, 2) remove bad trials %

user_input_cycle = {''};
while user_input_cycle{1} ~= "end"
    % By default, there is no low signal issues %
    lowSigWarning = 'False';

    % REMOVING CHANNELS %

    % Let's handle formatting the heatmap color bars for normative/
    % data-driven per subject %
    % Set the min and max heatmap values %
    
    if strcmp(sensor_type,'MEG GRAD')
        heatmap_fixed_vals = [1300, 200, 800, 100];
    elseif strcmp(sensor_type,'MEG MAG')
        heatmap_fixed_vals = [4000, 600, 2500, 300];
    else
        error('Currently only accepts GRADs or MAGs independently.');
    end
    
    
    amp_heatmap_max = median(median(all_amp_data(3:end,2:end),2))+(5*mad(median(all_amp_data(3:end,2:end),2),1));
    if amp_heatmap_max <= 200
        % this max is arbitrary based on experience with BESA software %
        amp_heatmap_max = heatmap_fixed_vals(1);
    end

    amp_heatmap_min = median(median(all_amp_data(3:end,2:end),2))-(5*mad(median(all_amp_data(3:end,2:end),2),1));
    if amp_heatmap_min < 0
        % this min is somewhat arbitrary, but also reasoned
        % we'd rather have a positive heatmap colorbar %
        amp_heatmap_min = 0;
    end

    grad_heatmap_max = median(median(all_grad_data(3:end,2:end),2))+(5*mad(median(all_grad_data(3:end,2:end),2),1));
    if grad_heatmap_max <= 100
        % this max is arbitrary based on experience with BESA software %
        grad_heatmap_max = heatmap_fixed_vals(3);
    end

    grad_heatmap_min = median(median(all_grad_data(3:end,2:end),2))-(5*mad(median(all_grad_data(3:end,2:end),2),1));
    if grad_heatmap_min < 0
        % this min is somewhat arbitrary, but also reasoned
        % we'd rather have a positive heatmap colorbar %
        grad_heatmap_min = 0;
    end
    

    display_text_channel = sprintf(['%s     ###      INFORMATION PROMPT      ###\nDecide which channels will be identified as bad.\n'...
        'Low signal channels will automatically be removed regardless of channel exclusion method.\n\n'], display_text_sub);

    % CONSISTENCY method #1: (Subject_channels_Mean) > (Group_Mean + 3*Group_STDEV) %
    display_text_channel_consistency_mean = sprintf('   ~~~ MEAN METHOD (DEFAULT) ~~~   \n\n');
    display_text_channel_consistency_mean = sprintf(['%s A Channel is flagged if:\n 1) It has a mean (amplitude & gradient) ' ...
    'X number of STDEVs beyond the mean for all channels\n\n'], display_text_channel_consistency_mean);

    % CONSISTENCY method #2: (Subject_channels_Median) > (Group_Median + 3*Group_MAD) %
    display_text_channel_consistency_median = sprintf('   ~~~ MEDIAN METHOD ~~~   \n\n');
    display_text_channel_consistency_median = sprintf(['%s A Channel is flagged if:\n 1) It has a median (amplitude & gradient) '...
        'X number of MADs beyond the median for all channels\n\n'], display_text_channel_consistency_median);

    % MIXED method #1: VARIABILITY OR CONSISTENCY method #1 %
    display_text_channel_mixed_mean = sprintf('   ~~~ MIXED MEAN METHOD ~~~   \n\n');
    display_text_channel_mixed_mean = sprintf(['%s A Channel is flagged if: \n1) It has a mean (amplitude & gradient) '...
        'X number of STDEVs beyond the mean for all channels\nOR\n2) It has a STDEV (amplitude & gradient) X number of STDEVs beyond the mean STDEV for all channels ###\n\n'], display_text_channel_mixed_mean);

    % MIXED method #2: VARIABILITY OR CONSISTENCY method #2 %
    display_text_channel_mixed_median = sprintf('   ~~~ MIXED MEDIAN METHOD ~~~   \n\n');
    display_text_channel_mixed_median = sprintf(['%s A Channel is flagged if: \n1) It has a median (amplitude & gradient) '...
        'X number of MADs beyond the median for all channels\nOR\n2) It has an MAD (amplitude & gradient) X number of MADs beyond the median MAD for all channels ###\n\n'], display_text_channel_mixed_median);

    % VARIABILITY method: (Subject_channels_MAD) > (Group_MAD_MEDIAN + 3*Group_MAD) %
    display_text_channel_variability = sprintf('   ~~~ VARIABILITY METHOD ~~~   \n\n');
    display_text_channel_variability = sprintf(['%s A Channel is flagged if:\n 1) It has an MAD (amplitude & gradient) '...
        'X number of MADs beyond the median MAD for all channels\n\n'], display_text_channel_variability);

    % original with prompt for variablility method
    %waitfor(msgbox(sprintf("%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n\nClick OK to proceed", display_text_channel, display_text_channel_consistency_mean, ...
     %   display_text_channel_consistency_median, display_text_channel_mixed_mean, display_text_channel_mixed_median, display_text_channel_variability),'Channel Exclusion Methods', 'replace'));

    % absent of variablility method in prompt
    waitfor(msgbox(sprintf("%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n\nClick OK to proceed", display_text_channel, display_text_channel_consistency_mean, ...
        display_text_channel_consistency_median),'Channel Exclusion Methods', 'replace'));

    diag_options.WindowStyle = 'normal';
    diag_options.Interpreter = 'tex';

    cons_method_1_version_counter = 1;
    cons_method_2_version_counter = 1;
    mix_method_1_version_counter = 1;
    mix_method_2_version_counter = 1;
    var_method_version_counter = 1;

    % Plot Sensor Array for Reference %
    meg_sensor_array_fig = figure('Name','MEG Sensor Array','NumberTitle','off', 'Position', [100 300 400 200]);
    %'Position', [1350 575 500 400]
    cfg = []; cfg.layout = 'neuromag306planar.lay'; layout = bst_ast_prepare_layout(cfg); bst_ast_plot_layout(layout);


    user_input_bad_channel_method = {''};
    while user_input_bad_channel_method{1} ~= "end"
        user_input_method = questdlg('Which channel exclusion method would you like to use?','CHANNEL EXCLUSION METHOD','MEAN','MEDIAN','MANUAL','MEAN');
        if strcmp(user_input_method,'MEAN') user_input_method = "mean"; elseif strcmp(user_input_method,'MEDIAN') user_input_method = "median"; ...
        elseif strcmp(user_input_method,'MANUAL') user_input_method = "manual"; end
        
        % force correct input %
        while user_input_method ~= "mean" && user_input_method ~= "median" && user_input_method ~= "manual"
            user_input_method = questdlg('Which channel exclusion method would you like to use?','CHANNEL EXCLUSION METHOD','MEAN','MEDIAN','MANUAL','MEAN');
            if strcmp(user_input_method,'MEAN') user_input_method = "mean"; elseif strcmp(user_input_method,'MEDIAN') user_input_method = "median"; ...
            elseif strcmp(user_input_method,'MANUAL') user_input_method = "manual"; end
        end

        chanAmpDevThreshold = 0;
        chanGradDevThreshold = 0;

        % Manual method %
        if user_input_method == "manual"
            ast_channel_selection_method = "mean";
            exclude_channels_indicator = questdlg('Do you want to skip channel exclusion?','Channel Exclusion Indicator','YES','NO','NO');
            if strcmp(exclude_channels_indicator,'YES') exclude_channels_indicator = "y"; elseif strcmp(exclude_channels_indicator,'NO') exclude_channels_indicator = "n"; end
                                    
            while exclude_channels_indicator ~= "n" & exclude_channels_indicator ~= "y"
                exclude_channels_indicator = questdlg('Do you want to skip channel exclusion?','Channel Exclusion Indicator','YES','NO','NO');
                if strcmp(exclude_channels_indicator,'YES') exclude_channels_indicator = "y"; elseif strcmp(exclude_channels_indicator,'NO') exclude_channels_indicator = "n"; end
            end
            
            if exclude_channels_indicator == "n"
                bad_channels_to_be_removed = inputdlg('Enter channel numbers separated by commas (e.g.   MEG2642,MEG2643)', ...
                                            'User-defined bad channels', 2, {'MEG2643'}, diag_options);

                bad_channels_to_be_removed = split(bad_channels_to_be_removed, ',');

                % force correct input %
                while ~ismember(bad_channels_to_be_removed,output_channel_names)
                    bad_channels_to_be_removed = inputdlg('Not all channels you entered exist, please try again.\n\nEnter channel numbers separated by commas (e.g.   MEG2643)', ...
                        'User-defined bad channels', 2, {'MEG2643'}, diag_options);
                end
                [~,bad_channels_to_be_removed] = ismember(bad_channels_to_be_removed,output_channel_names);
            else
                bad_channels_to_be_removed = [];
            end
            
            
            [all_amp_data_bad_chnls_removed, all_grad_data_bad_chnls_removed] = bst_ast_manual_remove_bad_channels(all_amp_data, all_grad_data, channel_labels, bad_channels_to_be_removed);

            msgbox_name = 'Progress Report: MANUAL METHOD';
            amp_fig_name = 'Amplitude_Heatmap_MANUAL_METHOD';
            grad_fig_name = 'Gradient_Heatmap_MANUAL_METHOD';
            
            display_text_channel_changed = sprintf('%sLow Signal Cutoff: %.1f\n\n', sprintf("%s\n%s", display_text_channel), 64);
            
            channel_amp_data_Cutoff_logical = logical(bad_channels);
            channel_grad_data_Cutoff_logical = logical(bad_channels);
            low_sig_range_all_channels_val_logical = logical(bad_channels);

            
        
        % else it's a statistical method %
        else
            chanDevThresholds = inputdlg({'Enter a new amplitude deviation cutoff: ', 'Enter a new gradient deviation cutoff: '}, 'Deviation cutoff', 2, {'4','8'}, diag_options);
            chanAmpDevThreshold = str2double(chanDevThresholds{1});
            chanGradDevThreshold = str2double(chanDevThresholds{2});
            % force correct input %
            while isnan(chanAmpDevThreshold) | isnan(chanGradDevThreshold)
                chanDevThresholds = inputdlg({'Enter a new amplitude deviation cutoff: ', 'Enter a new gradient deviation cutoff: '}, 'Deviation cutoff', 2, {'4','8'}, diag_options);
                chanAmpDevThreshold = str2double(chanDevThresholds{1});
                chanGradDevThreshold = str2double(chanDevThresholds{2});
            end
            
            
            % CONSISTENCY methods %
            if user_input_method == "mean" || user_input_method == "median"
                
                %determine bad channels
                [channel_amp_data_Cutoff_logical, channel_grad_data_Cutoff_logical, low_sig_range_all_channels_val_logical] = ...
                bst_ast_remove_bad_channels_consistency_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold, user_input_method);

                if sum(low_sig_range_all_channels_val_logical) > 0
                   warndlg(sprintf("WARNING: You have %.1f channels identified with low signal (i.e. low signal existed in more than 10%% of your trials). Best check yo data!", sum(low_sig_range_all_channels_val_logical)));
                   lowSigWarning = 'True';
                end

                if user_input_method == "mean"
                    ast_channel_selection_method = "mean";
                    
                    %collect text for display
                    display_text_channel_changed = sprintf('%sAmplitude deviation Cutoff: %.1f \nGradient deviation Cutoff: %.1f\nLow Signal Cutoff: %.1f\n\n', ...
                                                                          sprintf("%s\n%s", display_text_channel, display_text_channel_consistency_mean), chanAmpDevThreshold, chanGradDevThreshold, 64);
                                                                      
                    msgbox_name = 'Progress Report: MEAN METHOD';
                    amp_fig_name = sprintf('Amplitude_Heatmap_MEAN_METHOD_v%d', round(cons_method_1_version_counter));
                    grad_fig_name = sprintf('Gradient_Heatmap_MEAN_METHOD_v%d', round(cons_method_1_version_counter));

                    cons_method_1_version_counter = cons_method_1_version_counter+1;
                elseif user_input_method == "median"
                    ast_channel_selection_method = "median";
                                %collect text for display
                    display_text_channel_changed = sprintf('%sAmplitude deviation Cutoff: %.1f \nGradient deviation Cutoff: %.1f\nLow Signal Cutoff: %.1f\n\n', ...
                                                              sprintf("%s\n%s", display_text_channel, display_text_channel_consistency_median), chanAmpDevThreshold, chanGradDevThreshold, 64);
                                                          
                    msgbox_name = 'Progress Report: MEDIAN METHOD';
                    amp_fig_name = sprintf('Amplitude_Heatmap_MEDIAN_METHOD_v%d', round(cons_method_2_version_counter));
                    grad_fig_name = sprintf('Gradient_Heatmap_MEDIAN_METHOD_v%d', round(cons_method_2_version_counter));

                    cons_method_2_version_counter = cons_method_2_version_counter+1;
                end

                
            % MIXED methods %
            elseif user_input_method == "mix mean" || user_input_method == "mix median"

                %determine bad channels
                [channel_amp_data_Cutoff_logical, channel_grad_data_Cutoff_logical, low_sig_range_all_channels_val_logical] = ...
                bst_ast_remove_bad_channels_mixed_formula(all_amp_data, all_grad_data, chanAmpDevThreshold, chanGradDevThreshold, user_input_method);

                if sum(low_sig_range_all_channels_val_logical) > 0
                   warndlg(sprintf("WARNING: You have %.1f channels identified with low signal (i.e. low signal existed in more than 10%% of your trials). Best to check yo data!", sum(low_sig_range_all_channels_val_logical)));
                   lowSigWarning = 'True';
                end

                if user_input_method == "mix mean"
                    ast_channel_selection_method = "mean";
                    %collect text for display
                    display_text_channel_changed = sprintf('%sAmplitude deviation Cutoff: %.1f \nGradient deviation Cutoff: %.1f\nLow Signal Cutoff: %.1f\n\n', ...
                                                              sprintf("%s\n%s", display_text_channel, display_text_channel_mixed_mean), chanAmpDevThreshold, chanGradDevThreshold, 64);
                                                          
                    msgbox_name = 'Progress Report: MIXED MEAN METHOD';
                    amp_fig_name = sprintf('Amplitude_Heatmap_MIXED_MEAN_METHOD_v%d', round(mix_method_1_version_counter));
                    grad_fig_name = sprintf('Gradient_Heatmap_MIXED_MEAN_METHOD_v%d', round(mix_method_1_version_counter));

                    mix_method_1_version_counter = mix_method_1_version_counter+1;
                    
                elseif user_input_method == "mix median"
                    ast_channel_selection_method = "median";
                    %collect text for display
                    display_text_channel_changed = sprintf('%sAmplitude deviation Cutoff: %.1f \nGradient deviation Cutoff: %.1f\nLow Signal Cutoff: %.1f\n\n', ...
                                                              sprintf("%s\n%s", display_text_channel, display_text_channel_mixed_median), chanAmpDevThreshold, chanGradDevThreshold, 64);
                                                          
                    msgbox_name = 'Progress Report: MIXED MEDIAN METHOD';
                    amp_fig_name = sprintf('Amplitude_Heatmap_MIXED_MEDIAN_METHOD_v%d', round(mix_method_2_version_counter));
                    grad_fig_name = sprintf('Gradient_Heatmap_MIXED_MEDIAN_METHOD_v%d', round(mix_method_2_version_counter));

                    mix_method_2_version_counter = mix_method_2_version_counter+1;
                end

            % VAR method %
            elseif user_input_method == "var"
                ast_channel_selection_method = "var";

                %determine bad channels
                [channel_amp_data_Cutoff_logical, channel_grad_data_Cutoff_logical, low_sig_range_all_channels_val_logical] = ...
                remove_bad_channels_variability_formula(filter_amp_data_Condition, filter_grad_data_Condition, chanAmpDevThreshold, chanGradDevThreshold);

                if sum(low_sig_range_all_channels_val_logical) > 0
                   warndlg(sprintf("WARNING: You have %.1f channels identified with low signal (i.e. low signal existed in more than 10%% of your trials). Best to check yo data!", sum(low_sig_range_all_channels_val_logical)));
                   lowSigWarning = 'True';
                end


                %collect text for display
                display_text_channel_changed = sprintf('%sAmplitude deviation Cutoff: %.1f \nGradient deviation Cutoff: %.1f\nLow Signal Cutoff: %.1f\n\n', ...
                                                   sprintf("%s\n%s", display_text_channel, display_text_channel_variability), chanAmpDevThreshold, chanGradDevThreshold, 64);
                                                                      
                msgbox_name = 'Progress Report: VARIABILITY METHOD';
                amp_fig_name = sprintf('Amplitude_Heatmap_VARIABILITY_METHOD_v%d', round(var_method_version_counter));
                grad_fig_name = sprintf('Gradient_Heatmap_VARIABILITY_METHOD_v%d', round(var_method_version_counter));
                var_method_version_counter = var_method_version_counter+1;

            end
            
            %excute removal of bad channels
            [bad_channels_to_be_removed, all_amp_data_bad_chnls_removed, all_grad_data_bad_chnls_removed] = ...
            bst_ast_remove_bad_channels_execute(all_amp_data, all_grad_data, channel_amp_data_Cutoff_logical, low_sig_range_all_channels_val_logical, ...
            channel_grad_data_Cutoff_logical, channel_labels);
            
        end
        
        %gather bad channels table for display %
        display_bad_channel_table = bst_ast_remove_bad_channels_display(channel_amp_data_Cutoff_logical, ...
                                    channel_grad_data_Cutoff_logical, low_sig_range_all_channels_val_logical, output_channel_names);

        %create figure for table %
        display_bad_channel_table_fig = figure('Name', msgbox_name, 'NumberTitle','off', 'Position', [680 558 792 420]);

        %create text info for table figure
        display_bad_channel_table_text = annotation(display_bad_channel_table_fig, 'textbox', 'String', ...
                                            display_text_channel_changed, 'Units', 'pixels', 'Position', [20 20 300 400]);

        %create table for table figure
        display_bad_channel_table_item = uitable(display_bad_channel_table_fig, 'Data', ...
                                        display_bad_channel_table, 'ColumnEditable', true, 'ColumnWidth', 'auto', ...
                                        'Units', 'pixels', 'Position', ...
                                        [(display_bad_channel_table_text.Position(4)+display_bad_channel_table_text.Position(1))+15 ...
                                        display_bad_channel_table_text.Position(2) ...
                                        display_bad_channel_table_text.Position(3)+30 ...
                                        display_bad_channel_table_text.Position(4)]);
            


        figure('Name',amp_fig_name,'NumberTitle','off', 'Position', [150 300 400 200]);
        %[100 400 500 400]
        subplot(3,1,1);
        hMapAmpRawFixed = bst_ast_display_heatmap(all_amp_data(3:end,:), heatmap_fixed_vals(1), heatmap_fixed_vals(2), 'Amplitude Heatmap Fixed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 1, 0, ast_channel_selection_method);
        subplot(3,1,2);
        hMapAmpRawNormed = bst_ast_display_heatmap(all_amp_data(3:end,:), amp_heatmap_max, amp_heatmap_min, 'Amplitude Heatmap Normed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 1, 0, ast_channel_selection_method);
        subplot(3,1,3);
        hMapAmpBlockedNormed = bst_ast_display_heatmap(all_amp_data(3:end,:), amp_heatmap_max, amp_heatmap_min, 'Amplitude Heatmap Normed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 2, 0, ast_channel_selection_method);


        figure('Name',grad_fig_name,'NumberTitle','off', 'Position', [200 300 400 200]);
        %[1300 400 500 400]
        subplot(3,1,1);
        hMapGradRaw = bst_ast_display_heatmap(all_grad_data(3:end,:), heatmap_fixed_vals(3), heatmap_fixed_vals(4), 'Gradient Heatmap Fixed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 1, 0, ast_channel_selection_method);
        subplot(3,1,2);
        hMapGradRawNormed = bst_ast_display_heatmap(all_grad_data(3:end,:), grad_heatmap_max, grad_heatmap_min, 'Gradient Heatmap Normed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 1, 0, ast_channel_selection_method);
        subplot(3,1,3);
        hMapGradBlockedNormed = bst_ast_display_heatmap(all_grad_data(3:end,:), grad_heatmap_max, grad_heatmap_min, 'Gradient Heatmap Normed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 2, 0, ast_channel_selection_method);
        
        user_input_bad_channel_method = inputdlg(sprintf('To accept bad channels and proceed to trial exclusions, enter (end).\nTo revise channel exclusions, enter (rev)'), 'Channel Advance', 1, {'end'}, diag_options);
    end

    user_input_bad_channel_method = user_input_method;

    % Get the max (across channels) max amplitude and max gradient for each
    % trial %
    max_amp_range_all_trials = max(all_amp_data_bad_chnls_removed(3:end,2:end), [], 2);
    max_grad_range_all_trials = max(all_grad_data_bad_chnls_removed(3:end,2:end), [], 2);

    % proceed to determine amplitude and gradient thresholds %
    display_text_trial = sprintf(['%s###   INFORMATION PROMPT   ###\nDecide what your amplitude and gradient cutoffs will be.\n'...
        'Trials with low signal will automatically be removed regardless of trial exclusion method'], display_text_sub);
    waitfor(msgbox(sprintf("%s\n\n\nClick OK to proceed", display_text_trial),'TRIAL EXCLUSION THRESHOLDS', 'replace'));

    user_input_bad_trial_method = {''};
    while user_input_bad_trial_method{1} ~= "end"
        user_input_method = inputdlg(sprintf('Which trial exclusion method would you like to use?\n\nFor AUTO, enter (auto).\nFor manual entry, enter (manual).\n'), ...
            'TRIAL EXCLUSION METHOD', 1, {'auto'}, diag_options);
        % force correct input %
        while user_input_method ~= "auto" && user_input_method ~= "manual"
            user_input_method = inputdlg(sprintf('A valid option was not selected.\nWhich trial exclusion method would you like to use?\n\nFor AUTO, enter (auto).\nFor manual entry, enter (manual).\n'), ...
                'TRIAL EXCLUSION METHOD', 1, {'auto'}, diag_options);
        end

        if user_input_method == "auto"
            % calculate cutoffs based on user-defined MAD
            trialHighCutoffMAD = inputdlg('Enter a new deviation cutoff: ', 'Amplitude & Gradient MAD', 1, {'3'}, diag_options);
            trialHighCutoffMAD = str2double(trialHighCutoffMAD{1});
            while isnan(trialHighCutoffMAD)
                trialHighCutoffMAD = inputdlg('A valid value was not entered.\nEnter a new deviation cutoff: ', 'Amplitude & Gradient MAD', 1, {'3'}, diag_options);
                trialHighCutoffMAD = str2double(trialHighCutoffMAD{1});
            end
            % Creaate a high statistical cutoff for trials %
            trialAmpHighCutoff = median(max_amp_range_all_trials)+(trialHighCutoffMAD*mad(max_amp_range_all_trials,1));
            trialGradHighCutoff = median(max_grad_range_all_trials)+(trialHighCutoffMAD*mad(max_grad_range_all_trials,1));


        elseif user_input_method == "manual"
            trialHighCutoff = inputdlg({'Enter an amplitude cutoff value: ', 'Enter a gradient cutoff value: '}, 'Amplitude & Gradient Cutoffs', 1, {'1500', '700'}, diag_options);
            trialAmpHighCutoff = str2double(trialHighCutoff{1});
            trialGradHighCutoff = str2double(trialHighCutoff{2});
            while isnan(trialAmpHighCutoff) || isnan(trialGradHighCutoff)
                trialHighCutoff = inputdlg({'A valid value was not entered.\nEnter an amplitude cutoff value: ', 'Enter a gradient cutoff value: '}, 'Amplitude & Gradient Cutoffs', 1, ...
                    {'1500', '700'}, diag_options);
            trialAmpHighCutoff = str2double(trialHighCutoff{1});
            trialGradHighCutoff = str2double(trialHighCutoff{2});
            end

            trialHighCutoffMAD = '-';
            
        end

        amp_fig_name = 'Amplitude_Heatmap';
        grad_fig_name = 'Gradient_Heatmap';

        display_text_trial_change = sprintf('%s\nMAD: %.1f\nLow Signal Cutoff: %.1f\nAmplitude Cutoff: %.1f\nGradient Cutoff: %.1f\n\n', display_text_trial, ...
                    trialHighCutoffMAD, 64, round(trialAmpHighCutoff), round(trialGradHighCutoff));

        % filter data for trial trial counting by condition %
        [filtered_combined_data, filtered_combined_data_cutoff_logical] = bst_ast_distribution_filter(max_amp_range_all_trials, ...
                                                            trialAmpHighCutoff, max_grad_range_all_trials, trialGradHighCutoff, ...
                                                            all_amp_data_bad_chnls_removed);

        % Display accepted trials per condition %
        for j=1:size(all_condition_labels,1)
            all_condition_labels{j,2} = sum(all_amp_data_bad_chnls_removed(:,1) == j);
            all_condition_labels{j,3} = sum(filtered_combined_data(:,1) == j);
        end

        %create figure for table %
        display_bad_trial_table_fig = figure('Name', 'Progress Report: TRIAL EXCLUSION', 'NumberTitle','off', 'Position', [680 558 763 300]);

        %create text info for table figure
        display_bad_trial_table_text = annotation(display_bad_trial_table_fig, 'textbox', 'String', display_text_trial_change,...
                                    'Units', 'pixels', 'Position', [20 20 250 250]);

        %create table for table figure
        display_bad_trial_table_item = uitable(display_bad_trial_table_fig, 'Data', ...
                                        vertcat({'Condition_Label', 'Total_Trials', 'Accepted_Trials'}, all_condition_labels), 'ColumnEditable', true, 'ColumnWidth', {100 100 100 100},...
                                        'Units', 'pixels', 'Position', ...
                                        [(display_bad_trial_table_text.Position(4)+display_bad_trial_table_text.Position(1))+20 ...
                                        display_bad_trial_table_text.Position(2) ...
                                        display_bad_trial_table_text.Position(3)+200 ...
                                        display_bad_trial_table_text.Position(4)]);
                                    
                                    

        figure('Name',amp_fig_name,'NumberTitle','off', 'Position', [100 300 400 200]);
        %[100 400 500 400]
        subplot(3,1,1);
        hMapAmpRaw = bst_ast_display_heatmap(all_amp_data(3:end,:), 1300, 200, 'Amplitude Heatmap Fixed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 3, round(trialAmpHighCutoff), user_input_bad_channel_method);
        subplot(3,1,2);
        hMapAmpRawNormed = bst_ast_display_heatmap(all_amp_data(3:end,:), amp_heatmap_max, amp_heatmap_min, 'Amplitude Heatmap Normed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 3, round(trialAmpHighCutoff), user_input_bad_channel_method);
        subplot(3,1,3);
        hMapAmpBlockedNormed = bst_ast_display_heatmap(all_amp_data(3:end,:), amp_heatmap_max, amp_heatmap_min, 'Amplitude Heatmap Normed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 4, round(trialAmpHighCutoff), user_input_bad_channel_method);


        figure('Name',grad_fig_name,'NumberTitle','off', 'Position', [150 300 400 200]);
        %[1300 400 500 400]
        subplot(3,1,1);
        hMapGradRaw = bst_ast_display_heatmap(all_grad_data(3:end,:), 800, 100, 'Gradient Heatmap Fixed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 3, round(trialGradHighCutoff), user_input_bad_channel_method);
        subplot(3,1,2);
        hMapGradRawNormed = bst_ast_display_heatmap(all_grad_data(3:end,:), grad_heatmap_max, grad_heatmap_min, 'Gradient Heatmap Normed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 3, round(trialGradHighCutoff), user_input_bad_channel_method);
        subplot(3,1,3);
        hMapGradBlockedNormed = bst_ast_display_heatmap(all_grad_data(3:end,:), grad_heatmap_max, grad_heatmap_min, 'Gradient Heatmap Normed', bad_channels_to_be_removed, ...
                            output_channel_names, all_condition_labels, 4, round(trialGradHighCutoff), user_input_bad_channel_method);


        % Plot the average max amplitude and average max gradient for the specified
        %condition
        figure('Name','Distribution Plot','NumberTitle','off', 'Position', [200 300 400 200]);
        %[700 250 500 400]
        subplot(2,1,1);
        histAmpDist = histogram(max_amp_range_all_trials,'BinWidth',25,'FaceColor','b');
        lim = max(histAmpDist.Values)+1;
        hold on
        histAmpLimDist = histogram(repmat(trialAmpHighCutoff,lim,1),'FaceColor','k');
        legend('Max Amp Range');
        datacursormode on
        subplot(2,1,2);
        histGradDist = histogram(max_grad_range_all_trials,'BinWidth',5,'FaceColor','r');
        lim = max(histGradDist.Values)+1;
        hold on
        histGradLimDist = histogram(repmat(trialGradHighCutoff,lim,1),'FaceColor','k');
        legend('Max Grad Range');
        datacursormode on


        user_input_bad_trial_method = inputdlg(sprintf('To accept trial thresholds, enter (end).\nTo revise trial thresholds, enter (rev)'), 'Trial Advance', 1, {'end'}, diag_options);

    end

    user_input_bad_trial_method = user_input_method;
    user_input_cycle = inputdlg(sprintf('To accept Artifact Scan parameters, enter (end).\nTo restart, enter (res)'), 'Artifact Scan Complete', 1, {'end'}, diag_options);
end

% Process is complete, wait for user to request to proceed and store
% data %

waitfor(msgbox('Press OK to move on to the next subject database.','Advance to Next Subject','replace'))


% Send back channel labels to keep, channel labels to get rid of %
output_channel_names_keep = output_channel_names(~ismember(channel_labels,bad_channels_to_be_removed));
output_channel_names_remove = output_channel_names(ismember(channel_labels,bad_channels_to_be_removed));

% Send back trial blocks to keep, trial blocks to get rid of %
output_trial_labels_keep = output_trial_labels(~filtered_combined_data_cutoff_logical);
output_trial_labels_remove = output_trial_labels(filtered_combined_data_cutoff_logical);
output_trial_fnames_keep = output_trial_fnames(~filtered_combined_data_cutoff_logical);
output_trial_fnames_remove = output_trial_fnames(filtered_combined_data_cutoff_logical);

% Check for ssp ?? %%

%blinkStatus = 'not checked';
%cardiacStatus = 'not checked';
%icaStatus = 'not checked';

% Determine if blink and cardiac was completed %



% Save summary info to csv file %
% setup log file column headers %
logFile = {'parID' 'sensorType' 'lowSignalWarning' 'badChannelAmpMADThreshold' 'badChannelGradMADThreshold' 'badChannelMethod' 'badChannelLabels' 'trialMADThreshold' 'trialMethod' 'ampCutoff' 'gradCutoff'};

% add initial content %
logFile(size(logFile,1)+1,1:size(logFile,2)) = {subID 
sensor_type
lowSigWarning
chanAmpDevThreshold
chanGradDevThreshold
user_input_bad_channel_method 
sprintf("%s;",string(output_channel_names_remove)) 
trialHighCutoffMAD 
user_input_bad_trial_method 
trialAmpHighCutoff
trialGradHighCutoff};

% add condition labels to column headers - total trials %
logFile(1,size(logFile,2)+1:size(logFile,2)+size(transpose(all_condition_labels(:,1)),2)) = strcat('Total_Trials_', transpose(all_condition_labels(:,1)));
% add condition - total trial - counts under each condition label %
logFile(size(logFile,1),size(logFile,2)-size(transpose(all_condition_labels(:,1)),2)+1:size(logFile,2)) = transpose(all_condition_labels(:,2));
% add condition labels to column headers - accepted trials %
logFile(1,size(logFile,2)+1:size(logFile,2)+size(transpose(all_condition_labels(:,1)),2)) = strcat('Accepted_Trials_', transpose(all_condition_labels(:,1)));
% add condition - accepted trial - counts under each condition label %
logFile(size(logFile,1),size(logFile,2)-size(transpose(all_condition_labels(:,1)),2)+1:size(logFile,2)) = transpose(all_condition_labels(:,3));


% prepare the table and write to file %
logFileTable = cell2table(logFile(2:end,:),'VariableNames',logFile(1,:));
%directoryname = uigetdir('D:', 'Pick a csv log save directory');
writetable(logFileTable,fullfile(log_path, sprintf("%s_artifactScan_log.csv", subID)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
