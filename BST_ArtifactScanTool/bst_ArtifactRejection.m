%PURPOSE:           1) Organize and compute descriptive metrics for single
%trial data from a set of Brainstorm subject directories
%                   2) Send these metrics to BST_ArtifactScanTool.m for GUI-based trial rejection
%                   3) Use resulting thresholds to mark new bad trials/channels
%
%
%AUTHORS:            Alex Wiesman, Nick Christopher-Hayes
%VERSION HISTORY:    07/23/2020  v1: First working version

%%select all parent directories to consider%%


function bst_ArtifactRejection
% Start brainstorm in background
%brainstorm nogui

raw_search_patt = 'notch_band';

disp_str = sprintf('Select the Brainstorm Database subject directories to run:');
waitfor(msgbox(sprintf("%s\n\nClick OK to proceed", disp_str),'Brainstorm: Subject Directories', 'replace'));

filedirs = uigetdir2;
filedirs = cellfun(@(SSS) dir(SSS), filedirs, 'UniformOutput', false);

%determine data type to processes
%user specification re: GRADS or MAGS
method = questdlg('What type of data to process?','Data Type','REST_blocks','TASK_trials','TASK_trials');
if contains(method,'block')
    data_type = 'block';
elseif contains(method,'trial')
    data_type = 'trial';
else
    error('Data Type Not Selected!');
end
% data_type = 'trial';

%user specification re: GRADS or MAGS
method = questdlg('What type of sensors?','Sensor Type','GRADs','MAGs','All','GRADs');
if strcmp(method,'GRADs')
    sensor_type = 'MEG GRAD';
elseif strcmp(method,'MAGs')
    sensor_type = 'MEG MAG';
elseif strcmp(method,'All')
    sensor_type = 'MEG';
else
    error('Sensor Type Not Selected!');
end
% sensor_type = 'MEG GRAD';

%user specification re: directory for writing CSV log files
log_path = uigetdir(pwd,'Please select destination directory for CSV log files.');

for d = 1:size(filedirs,2)
    % all trial.mat files for a directory %
    sub_data_mats = dir(fullfile(filedirs{d}(1).folder, sprintf('*%s*',raw_search_patt), sprintf('*%s*.mat',data_type)));
    subID = split(filedirs{d}(1).folder,'\');
    subID = subID{end};
    
    % collect subject channel file and load it
    channel_mat = dir(fullfile(filedirs{d}(1).folder, '*', '*channel*.mat'));
    
    if isempty(channel_mat) || size(channel_mat,1) > 1
        [channel_mat_f,channel_mat_p] = uigetfile('*.mat',sprintf('Select Brainstorm channel file for %s',subID), filedirs{d}(1).folder);
        channel_mat(1).folder = channel_mat_p;
        channel_mat(1).name = channel_mat_f;
    end
    channel_data = load(fullfile(channel_mat(1).folder, channel_mat(1).name));
    
    % build index of channels, and those that match sensor_type
    use_channel_ind = ismember({channel_data.Channel(:).Type},sensor_type);
    channel_names = {channel_data.Channel(:).Name};
    
    % consider selection here of unique directories with block/trial data
    %folders_selected = listdlg('PromptString','Please select folders to scan for artifacts.','SelectionMode','multiple','ListString',sub_folders);
    %folders_selected = sub_folders(folders_selected);
    %unique({sub_data_mats(:).folder})';
    
    % pull in all brainstudy.mat files that contain existing bad trials
    % for the data segments to be reviewed
    uniq_sub_data_mats = unique({sub_data_mats(:).folder})';
    bs_study_mats = cellfun(@dir, strcat(uniq_sub_data_mats, '/*brainstormstudy.mat'), 'UniformOutput', false);
    %cellfun(@(SSS) SSS.folder, bs_study_mats, 'UniformOutput', false)
    
    if ~any(cell2mat(cellfun(@(SSS) ~isempty(SSS), bs_study_mats, 'UniformOutput', false)))
        error('No Brainstorm study file(s) found for: %s\nCannot proceed!',sub_data_mats(d).folder)
    end
    
    % lets only work on those data mats with a brainstorm study mat and skip the
    % others
    fprintf('\nCombining the following for the ArtifactScanTool:\n');
    fprintf('%s\n',uniq_sub_data_mats{cell2mat(cellfun(@(SSS) ~isempty(SSS), bs_study_mats, 'UniformOutput', false))});
    fprintf('\nDropping the following due to missing brainstormstudy.mat files:\n');
    fprintf('%s\n',uniq_sub_data_mats{cell2mat(cellfun(@(SSS) isempty(SSS), bs_study_mats, 'UniformOutput', false))});
    
    % collapse down to only epochs within directories found to have a
    % brainstormstudy.mat file
    wbar = waitbar(.25,sprintf('Loading Epoch Data: %s',subID));
    
    sub_data_mats = sub_data_mats(ismember({sub_data_mats.folder},...
                uniq_sub_data_mats(cell2mat(cellfun(@(SSS) ~isempty(SSS), bs_study_mats, 'UniformOutput', false)))));
                                                
    
    
    % collapse down to only unique directories with brainstormstudy.mat
    % files
    uniq_sub_data_mats = uniq_sub_data_mats(cell2mat(cellfun(@(SSS) ~isempty(SSS), bs_study_mats, 'UniformOutput', false)));
    % collapse down to only brainstormstudy.mat files that exist
    bs_study_mats = bs_study_mats(cell2mat(cellfun(@(SSS) ~isempty(SSS), bs_study_mats, 'UniformOutput', false)));
    
    
    % now load existing bad trials from all brainstormstudy.mat files
    bs_study_mat_data = cellfun(@(SSS) load(fullfile(SSS.folder,SSS.name)), bs_study_mats, 'UniformOutput', false);
    prev_bad_trials = cellstr(char(cellfun(@(SSS) char(SSS.BadTrials), bs_study_mat_data, 'UniformOutput', false)))';
    
    %read in all data trials/blocks and compile
    trial_dat = cellfun(@load, fullfile({sub_data_mats.folder}, {sub_data_mats.name}), 'UniformOutput', false);
    trial_labels = cellfun(@(SSS) split(SSS.Comment), trial_dat, 'UniformOutput', false);
    
    trial_labels = vertcat(trial_labels{:})';
    trial_labels(contains(trial_labels, '('))=[];
    trial_fnames = {sub_data_mats.name};
    trial_fpaths = {sub_data_mats.folder};
    %build index of trials that match prev_bad_trials
    use_trial_ind = ~ismember(trial_fnames,prev_bad_trials);
    %this is what we'll use
    trial_dat_no_prev_bad=trial_dat(use_trial_ind);
    
    trial_dat_sizes = cellfun(@(SSS) size(SSS.F), trial_dat_no_prev_bad, 'UniformOutput', false);
    trial_dat_sizes = vertcat(trial_dat_sizes{:});
    
    
    

    if any(any(logical(diff(trial_dat_sizes)),2))
        warning('These epochs are different than the others for %s! Skipping!', subID);
        shortened_epochs = trial_fnames(logical([false;any(logical(diff(trial_dat_sizes)),2)]));
        fprintf('%s\n',shortened_epochs{:});
        delete(wbar);
        continue;
        %s_e_indicator = questdlg('Define shortened epochs for this subject as bad and proceed, or skip for review in Brainstorm?','Shortened Epochs','Bad','Skip','Bad');
%         if contains(s_e_indicator,'Bad')
%             %define as bad
%             prev_bad_trials = horzcat([prev_bad_trials shortened_epochs]);
%         elseif contains(s_e_indicator,'Skip')
%             continue;
%         else
%             error('Shortened epoch decision not made for: %s!', subID);
%         end
    end

    % check each trial file and exlude channels from use_channel_ind that are excluded from any trial
    % should this be ==0 or ==-1???
    use_channel_ind(1, any(cell2mat(cellfun(@(SSS) SSS.ChannelFlag, trial_dat_no_prev_bad, 'UniformOutput', false))==-1, 2)')=false;
    output_channel_flags = any(cell2mat(cellfun(@(SSS) SSS.ChannelFlag, trial_dat_no_prev_bad, 'UniformOutput', false))==-1, 2)';
    
    % add trial data to compiler
    %trial_dat_compiled = cellfun(@(SSS) SSS.F, trial_dat, 'UniformOutput', false);
    waitbar(.75,wbar,sprintf('Computing epoch data for ArtifactScanTool: %s',subID));
    
    for t=1:size(trial_dat_no_prev_bad,2)
        trial_dat_compiled(:,:,t)=trial_dat_no_prev_bad{t}.F;
    end
    
    
    % gradient resolution
    % first method doesn't seem accurate as it's calculating time
    % resolution and mulitplying, and may result
    % in unwanted resolution
    %time_res = (trial_dat.Time(1,2)-trial_dat.Time(1,1))*1000;
    
    % just set a fixed value instead
    gradient_res = 1;
    

    % create Artifact Estimation Data
    % max for each 
    maxes = squeeze(max(trial_dat_compiled,[],2));
    mins = squeeze(min(trial_dat_compiled,[],2));
    p2p = maxes-mins;
    [gradient_x,~,~] = gradient(trial_dat_compiled,gradient_res);
    gradients = squeeze(max(gradient_x,[],2));
    low_sig = p2p < 40e-15;

    % Prepare data for ArtifactScanTool
    output_p2p = p2p(use_channel_ind,:)';
    output_gradients = gradients(use_channel_ind,:)';
    output_low_sig = low_sig(use_channel_ind,:)';
    output_trial_labels = trial_labels(1,use_trial_ind)';
    output_channel_names = channel_names(use_channel_ind);
    output_trial_fnames = trial_fnames(use_trial_ind)';

    % Send data to ArtifactScanTool
    delete(wbar);
    %waitbar(.99,wbar,sprintf('Compiling and calculating epoch data for ArtifactScanTool: %s',subID));
    [~,output_channel_names_remove,~,~,~,output_trial_fnames_remove] = bst_ArtifactScanTool(output_p2p,output_gradients,output_trial_labels,output_channel_names,output_trial_fnames,sensor_type,subID,log_path);
    
    wbar = waitbar(.25,sprintf('Saving ArtifactScanTool Results: %s',subID));
    % add all trials in 'output_trial_fnames_remove' into the 'BadTrials' field of the 'brainstormstudy.mat' file
    if ~isempty(output_trial_fnames_remove)
        
        % if any brainstormstudy.mat files doesn't have a backup, make one
        backup_indicator = backup_check(uniq_sub_data_mats, 'brainstormstudy.mat._AST_v1');
        if any(backup_indicator)
        
            % then copy
            cellfun(@(SSS) copyfile(fullfile(SSS,'brainstormstudy.mat'), fullfile(SSS,'brainstormstudy.mat._AST_v1')),...
                uniq_sub_data_mats(backup_indicator), 'UniformOutput', false);
            
        end
        clearvars backup_indicator
        
        % for each uniq bsmat, identify the bsmat structure to manipulate,
        % and it's existing bad trials, and the new bad trials to be added,
        % and assign them in the struct, and save it.
        cellfun(@(SSS) ...
            assign_new_trials(...
                bs_study_mat_data{ismember(uniq_sub_data_mats,SSS)}, ...
                bs_study_mat_data{ismember(uniq_sub_data_mats,SSS)}.BadTrials,...
                output_trial_fnames_remove(ismember(trial_fpaths(ismember(trial_fnames,output_trial_fnames_remove)),SSS))',...
                fullfile(SSS,'brainstormstudy.mat')...
                ),...
            uniq_sub_data_mats, 'UniformOutput', false);
        
        
        %save('brainstormstudy.mat','bst_mat.BadTrials','bst_mat.Name','bst_mat.DateOfStudy');
    end

    
    waitbar(.75,wbar,sprintf('Saving ArtifactScanTool Results: %s',subID));
    
    %index the channels to be removed (from 'output_channel_names_remove')
    %within the 'channel_names' vector 
    % and merge with prior bad channels? maybe this isn'y necessary
    if ~isempty(output_channel_names_remove)
        %output_channel_flags = and(use_channel_ind,~ismember(channel_names,output_channel_names_remove))';
        output_channel_flags = double(~or(output_channel_flags,ismember(channel_names,output_channel_names_remove))');
        output_channel_flags(output_channel_flags==0,1)=-1;
        
        % if any AST_ChannelFlag.mat._v1 files doesn't exist, make one
        backup_indicator = backup_check(uniq_sub_data_mats, 'AST_ChannelFlag.mat._AST_v1');
        if any(backup_indicator)
            % then save a copy
            cellfun(@(SSS) backup_channel_flags(fullfile(SSS,'AST_ChannelFlag.mat._AST_v1'), output_channel_flags),...
                uniq_sub_data_mats(backup_indicator), 'UniformOutput', false)
        end
        
        % for each uniq data file, identify the data structure to manipulate,
        % and it's existing channel flags, and the new channel flags to be added,
        % and assign them in the struct, and save it.
        cellfun(@(SSS) assign_new_channels(output_channel_flags, SSS), fullfile(trial_fpaths,trial_fnames), 'UniformOutput', false);
        
    end
    delete(wbar);
    close all  
% end all subject directory loop
end

% Close Brainstorm
%brainstorm stop
wbar = waitbar(1,sprintf('ArtifactScanTool Batch Complete!'));
%close function
end



function assign_new_trials(orig_bst_mat,orig_bst_mat_bad_trials,new_bst_mat_bad_trials,orig_bst_mat_fname)
    %x=mat file, y=existing bad trials, z=new bad trials, w=fname
    % define function from the command line:
    %assign_new_trials = @(x, y, z) x.BadTrials = sort([y,z]);
    bst_mfile = matfile(orig_bst_mat_fname,'Writable',true);
    bst_mfile.BadTrials = sort([orig_bst_mat_bad_trials,new_bst_mat_bad_trials]);
end

function backup_indicator = backup_check(fname_matrix,fname_string)
    backup_indicator = logical(cell2mat(...
                        cellfun(...
                        @(SSS) ~exist(fullfile(SSS,fname_string),'file'), ...
                        fname_matrix, 'UniformOutput', false)...
                    )...
            );
end

function backup_channel_flags(new_chanel_flag_fname,AST_ChannelFlag)
    save(new_chanel_flag_fname,'AST_ChannelFlag');
end

function assign_new_channels(new_data_mat_chan_flags,orig_data_mat_fname)
    %x=mat file, y=new channel flags, z=fname
    data_mfile = matfile(orig_data_mat_fname,'Writable',true);
    data_mfile.ChannelFlag = new_data_mat_chan_flags;
end
