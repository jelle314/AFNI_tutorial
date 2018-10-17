%% Sets up the directories and moves the converted .nii files to the right folders.
% Input are the results from r2agui 

% make directories 
mkdir('ScannerOutput','PARRECs')
mkdir ('EPI','PHASE')
mkdir ('TOPUP','PHASE')
mkdir anatomy
mkdir Coregistration
mkdir Layering

%move PARRECs to the apprpriate folders
system('mv *.PAR ./ScannerOutput/PARRECs')
system('mv *.REC ./ScannerOutput/PARRECs')

%move all .nii out of their folders
moveOneUp

%move .nii files to correct folders
system('mv *INV*.nii ./anatomy')
system('mv *B0*.nii ./ScannerOutput')
system('mv *Survey*.nii ./ScannerOutput')
system('mv *TU*.nii ./TOPUP')
system('mv *EPI*.nii ./EPI')
