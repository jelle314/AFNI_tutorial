%Code by AF
clear all
close all

jStartup('+','afni_matlab')
jStartup('+','vistasoft')
jStartup('+','rmDevel')
mrVista
% absPath = '/home/jelle/Documents/Projects/Anatomies/JeDi/pRFmodel';
% absPath = '/home/jelle/Documents/Projects/Anatomies/AkEd/pRFData';
absPath = '/home/jelle/Documents/Projects/Anatomies/BaKl/pRF_Data';

rmFile = [ absPath, '/Inplane/Original/retModel-20170809-152009-sFit.mat' ];
INPLANE{1} = rmSelect( INPLANE{1}, 1, rmFile);
INPLANE{1} = rmLoadDefault( INPLANE{1} );        

%% try with writeFileNifti

%% for afni compatibility
% [data info] = BrikLoad( [ absPath '/Functional/meanTs.nii' ] ); % from 3dTcat over the full 4D-nifti, leaving only the first 4 volumes
[dataInplane info] = BrikLoad( [ absPath '/amplitudeAnatomy.nii' ] ); % from 3dTcat over the full 4D-nifti, leaving only the first 4 volumes
data = zeros( [ size(INPLANE{1}.co{1}) 5 ] );
% info.DATASET_DIMENSIONS = [ size(INPLANE{1}.anat) 5 0 ];

data(:,:,:,1) = INPLANE{1}.co{1}; % coherence
data(:,:,:,2) = INPLANE{1}.ph{1}; % phase
data(:,:,:,3) = INPLANE{1}.amp{1}; % amplitude
data(:,:,:,4) = INPLANE{1}.map{1}; % ecentricity
% data(:,:,:,5) = INPLANE{1}.anat; % epi

%INPLANE{1} = rmLoad( INPLANE{1}, 1, 'sigma', 'amp');
%data(:,:,:,5) = INPLANE{1}.amp{1};
%INPLANE{1} = rmLoad( INPLANE{1}, 1, 'sigma2', 'amp');
%data(:,:,:,6) = INPLANE{1}.amp{1};

saveVolume = flip( permute( data, [2 1 3 4] ), 2 ) ;
saveVolume = flip( saveVolume, 2);
saveVolume(:,:,:,5) = flip( dataInplane, 2); % epi

saveVolume(:,:,:,5) = flip( flip( dataInplane, 1 ), 2 ); % epi
saveVolume = flip( saveVolume, 2);
saveVolume = flip( saveVolume, 1);
size( saveVolume )
figure(45), imagesc( squeeze( saveVolume(:,35,:,1) ) )
figure(46), imagesc( squeeze( saveVolume(:,35,:,5) ) )

info.DATASET_DIMENSIONS = [ size(INPLANE{1}.co{1}) 5 0 ];
info.BRICK_LABS = 'co[0]~ph[1]~amp[2]~ecc[3]~epi[4]';
%saveVolume = data;

Opt.Prefix = 'prfModel';
WriteBrik( saveVolume, info, Opt )
