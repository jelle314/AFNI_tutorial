%% Sets up the directories and moves the converted .nii files to the right folders.
% Input are the results from r2agui


% make directories
mkdir('ScannerOutput','PARRECs')
mkdir ('EPI','PHASE')
mkdir ('TOPUP','PHASE')
mkdir anatomy
mkdir Coregistration

%move PARRECs to the apprpriate folders
system('mv *.PAR ./ScannerOutput/PARRECs')
system('mv *.REC ./ScannerOutput/PARRECs')

%move all .nii out of their folders
moveOneUp

%Rename all files so that the files are numbered 05, 06, etc, instead of 5,6.
files = dir;
files = files( 3: end);
for i = 1: length( files)
    kk = regexp( files(i).name,'_._');
    if ~isempty( kk)
        newname = [files( i).name( 1: kk) num2str(0) files( i).name( kk+1: end)];
        movefile( files(i).name, newname);
    end
end

%move .nii files to correct folders
system('mv *INV*.nii ./anatomy')
system('mv *B0*.nii ./ScannerOutput')
system('mv *Survey*.nii ./ScannerOutput')
system('mv *SmartBrain*.nii ./ScannerOutput')

system('mv *TU*t003*.nii ./TOPUP/PHASE')
system('mv *TU*.nii ./TOPUP')
system('mv *EPI*t003*.nii ./EPI/PHASE')
system('mv *EPI*.nii ./EPI')

%Remove empty folders from the r2agui output.
%Assumes that part of the folder name is the same as the participant
%directory name
[~, ppFolder] = fileparts(pwd);
RemoveFolders = dir([ppFolder '*']);
for iRemove = 1: length(RemoveFolders)
    if RemoveFolders( iRemove).isdir == 1
        cd( RemoveFolders( iRemove).name);
        CheckEmpty = dir([ppFolder '*']);
        if isempty( CheckEmpty) && RemoveFolders( iRemove).isdir == 1
            cd ..
            system(['rm ' RemoveFolders( iRemove).name ' -R']);
        else
            cd ..
        end
    end
end