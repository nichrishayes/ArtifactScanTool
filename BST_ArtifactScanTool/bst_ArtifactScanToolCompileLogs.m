function ArtifactScanToolCompileLogs

% GET GENERIC PROJECT/SUBJECT/FILE INFO %

% project directory %
filedirs=uigetdir2;

savedir = uigetdir('C:\','Please select save directory');

if length(filedirs)==1
    allDirs = genpath(filedirs{1});
    allDirs = regexp(allDirs, ';', 'split');
    allDirs(ismember(allDirs,{''})) = [];
    % for all directories under the parent directory %
else
    allDirs=filedirs;
end


for d = 1:length(allDirs)
    % all csv files for a directory %
    logFileInfo = dir(fullfile(allDirs{d}, '*_log.csv'));
    if size(logFileInfo,1) > 1
        for r = 1:size(logFileInfo,1)
            if exist(strcat(allDirs{d},'\',logFileInfo(r).name), 'file') ~= 0
                filetable = readtable(strcat(allDirs{d},'\',logFileInfo(r).name));
                if d == 1 && r == 1
                    alltables = filetable.Properties.VariableNames;
                end
                filetable = table2cell(filetable);
                % avoids error if additional columns exits
                if size(filetable,2) == size(alltables,2)
                    alltables=[alltables;filetable];
                else
                    disp(fprintf('File not added (different column count): %s',logFileInfo(r).name));
                end
            end
        end
    else
        
        % check if log exists, if so add to compilation %
        if exist(sprintf('%s\\%s', logFileInfo(1).folder,logFileInfo(1).name), 'file') ~= 0
            filetable = readtable(sprintf('%s\\%s', logFileInfo(1).folder,logFileInfo(1).name));
            % if it's the first file, use the column headers for the compiled
            % table %
            if d==1
                alltables = filetable.Properties.VariableNames;
            end
            
            filetable = table2cell(filetable);
            % avoids error if additional columns exits
            if size(filetable,2) == size(alltables,2)
                alltables=[alltables;filetable];
            else
                disp(fprintf('File not added (different column count): %s',logFileInfo(1).name));
            end
        end
    end
end

alltables=cell2table(alltables(2:end,:),'VariableNames',alltables(1,:));
writetable(alltables,strcat(savedir,'\','BSTPreprocessingCompiledLog.csv'));
disp('Done!!!');

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    

function [pathname] = uigetdir2(start_path, dialog_title)
% Pick multiple directories and/or files 

%%Downloaded this function from the internets

import javax.swing.JFileChooser;

if nargin == 0 || start_path == '' || start_path == 0 % Allow a null argument.
    start_path = pwd;
end

jchooser = javaObjectEDT('javax.swing.JFileChooser', start_path);

jchooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
if nargin > 1
    jchooser.setDialogTitle(dialog_title);
end

jchooser.setMultiSelectionEnabled(true);

status = jchooser.showOpenDialog([]);

if status == JFileChooser.APPROVE_OPTION
    jFile = jchooser.getSelectedFiles();
	pathname{size(jFile, 1)}=[];
    for i=1:size(jFile, 1)
		pathname{i} = char(jFile(i).getAbsolutePath);
	end
	
elseif status == JFileChooser.CANCEL_OPTION
    pathname = [];
else
    error('Error occured while picking file.');
end
end
