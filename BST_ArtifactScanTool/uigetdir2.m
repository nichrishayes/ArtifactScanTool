%uigetdir2: Select multiple directories
%
%USAGE: filedirs = uigetdir2
%
%OUTPUT: Cell array of directory paths
%
%Author: Tiago (2020)
%Source: https://www.mathworks.com/matlabcentral/fileexchange/32555-uigetfile_n_dir-select-multiple-files-and-directories
%       MATLAB Central File Exchange



function [pathname] = uigetdir2(start_path, dialog_title)
import javax.swing.JFileChooser;
if nargin == 0 || isempty(start_path) %| start_path == 0 % Allow a null argument.
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