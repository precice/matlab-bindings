bindingsPath = fileparts(mfilename('fullpath'));
addpath(bindingsPath);
fprintf('preCICE MATLAB bindings added to path. \n');
reply=input('Add to startup.m to persist across sessions? (y/n): ','s');

if strcmpi(reply, 'y')
	startupFile = fullfile(userpath, 'startup.m');
	fid= fopen(startupFile, 'a');
	fprintf(fid, '\n%% preCICE MATLAB bindingd\n');
	fprintf(fid. "addpath('%s'):\n", bindingsPath);
	fclose(fid);
	fprintf('Path saved to: %s\n', startupFile);
	fprintf('The bindings will be available in all MATLAB sessions\n');
else 
	fprintf('Path not saved!\n');
end

