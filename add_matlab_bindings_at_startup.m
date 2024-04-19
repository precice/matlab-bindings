startupFile = fopen(userpath+"/startup.m", 'a');
fprintf(startupFile, "addpath "+ pwd + newline);
fclose(startupFile);
