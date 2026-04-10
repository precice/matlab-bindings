fp = mfilename('fullpath');
fp = extractBefore(fp, "/add_matlab_bindings_at_startup");
startupFile = fopen(userpath+"/startup.m", 'a');
fprintf(startupFile, "addpath "+ fp + newline);
fclose(startupFile);
