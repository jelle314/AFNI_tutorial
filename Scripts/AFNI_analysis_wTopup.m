%% Script to do high resolution (< 1 mm/ with TOPUP) preprocessing in AFNI.
%% Author: Jelle van Dijk, j.a.vandijk@uu.nl
%% Called functions/scripts by: Alessio Fracasso, Wietske van der Zwaag & Jelle van Dijk


%Convert your data to .nii with your favourite software. check that it is correct.
% Have separate 'EPI' and 'TOPUP' directory 
% have all the anatomy and ROI data in a folder called 'anatomy' 
% Add afni_matlab toolbox (comes with AFNI) to path
% Make sure you have ran the . startAfniToolbox command in the command line
% before you start MATLAB in that same terminal

%% Prepare
clear all
close all

addpath(genpath('/home/jelle/Documents/Software/matFileAddOn')); %add the right toolboxes
addpath(genpath('/usr/share/afni/matlab');

% Setup the correct directory structure for the rest of the analysis
setupDirectories_highRes

%% For anatomical data processing, see the AFNI_analysis.m file. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 		functional data		        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% compute topup field, creates topUpDir, 7th input is maxlev setting for
% Qwarp
% 8th input how much to blur the data for Qwarp.
% QWarp (higher is more strict)
% keep the 1's. the 1-2-3-4 are the runs you want to use for the correction
% from the EPIs (first numbers) and TOPUP (2nd set).
system('. motionCorrect.afni.blip.sh EPI/ TOPUP/ 1 1 1-2-3-4-5-6 1-2-3-4-5-6 5 -1')

%% motion correct and motion correct + top up the original EPI data
% Last input is the EPI number used for the previous step. 
system('motionCorrectEPI.with.topUp.sh EPI/ topUpDir/ 1') 
%Does the motion correction, with Fourier interpolation
%Then apply top up transform from previous step
% Last input is which volume to allign everything to. 

%% compute mean timeseries from motion corrected EPI only
% Make sure you only have the functional runs for 1 of the conditions in
% the motionCorrectEpi folder when you run the next command.
% copy around files to do the next condition. 
system('. computeMeanTs.sh motionCorrectEpi/') 
system('3dresample -orient RAI -input meanTs.nii -prefix meanTs_RAI.nii.gz' ) %reorients the axes (sometimes needed)
%no real resampling, just reorienting (if needed). 

%% compute amplitude anatomy (average over all timepoints over all runs, used as an inplane anatomy)
system('computeAmplitudeAnatomy.sh motionCorrect_topUp_Epi/')

%% Now use the meanTs_RAI.nii.gz files as your functional data for mrVista, the amplitudeAnatomy.nii as your inplane anatomy
%% and initiate a mr Vista session with this
% Now do your favourite analysis in the mrVista inplane view. 
% then get the model data out of mrVista and into a .nii.gz file.  

saveRmModelAsNifti % some fiddling in the code may be required to make the last volume (the original EPI)
		% line up with the polar angle etc maps.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 		co-registration		        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Co-registration here is slightly different, as we want to touch the timeseries data as little as possible.
% To this end, we move the anatomy around (mostly), rather than the mean timeseries.

%% Setup things for the coregistration
system('3dresample -orient RAI -input amplitudeAnatomy.nii -prefix amplitudeAnatomy_RAI.nii.gz' )
system('mkdir Coregistration')
system('mv amplitudeAnatomy_RAI.nii.gz Coregistration/')
system('mv amplitudeAnatomy.nii Coregistration/')
system('cp anatomy/*.nii.gz Coregistration/')
system('cp anatomy/V*_*h+orig* Coregistration/') %assumes ROIs with that file structure, and in 
			%.BRIK and .HEAD format (AFNI format), are living in the anatomy directory.
cd Coregistration

%% do coregistration
% in Coregistration/coregCommands (see wiki!, under the numerosity instructions)
% Use the AFNI nudge dataset option in the GUI. 
% More information on the wiki

% Clip the anatomy
system('@clip_volume -anterior 180 -input anatomy.nii.gz -prefix anatomy_clip.nii.gz');
	% 180 and anterior are indicators for how much is clipped and which direction is left over
	% the -input and -prefix inputs are what you want them to be.

% Mask the amplitudeAnatomy
system('3dAutomask -apply_prefix amplitudeAnatomy_mask.nii.gz amplitudeAnatomy.nii.gz');

% Zeropad the amplitudeAnatomy to allow for shifting it around in the next steps.
system('3dZeropad -A 20 -P 20 -S 20 -I 20 -prefix amplitudeAnatomy_mask_zp.nii.gz amplitudeAnatomy_mask.nii.gz');

% Now align the centres of mass of the amplitudeAnatomy and anatomy, so they are in the same space
% the inputs after -child are volumes that are shifted with the -dset volume. 
% NB: the -base is now the amplitudeAnatomy! So we are moving the anatomy! 
system(['@Align_Centers -base amplitudeAnatomy_mask_zp.nii.gz -dset anatomy_clip.nii.gz -cm ' ...
	'-child boundaries.nii.gz depth.nii.gz V1_rh_5deg+orig V1_lh_5deg+orig V2_rh_5deg+orig ' ...
	'V2_lh_5deg+orig V3_rh_5deg+orig V3_lh_5deg+orig']);

% now use the Nudge datasets plugin in Afni to get a good start for the coregistration
% nudge the EPI volume, get 3drotate command from 'print'
% NB: we are moving the amplitudeAnatomy now! 
% e.g.:  
system(['3drotate -quintic -clipit -rotate -3.40I -3.01R 1.48A -ashift -6.57S 7.36L 6.06P ' ...
	'-prefix amplitudeAnatomy_mask_zp_rot.nii.gz amplitudeAnatomy_mask_zp.nii.gz']);

% Get the rotation matrix out as a .1D file
system('cat_matvec ''amplitudeAnatomy_mask_zp_rot.nii.gz::ROTATE_MATVEC_000000'' -I -ONELINE > rotateMat.1D');

% Now refine the co-registration automatically
system(['align_epi_anat.py -anat anatomy_clip_shft.nii.gz ' ...
	'-epi amplitudeAnatomy_mask_zp_rot.nii.gz ' ...
	'-epi_base 0 ' ... %the how manieth volume is the amplitudeAnatomy (usually 0, as AFNI starts at 0).
	'-epi2anat ' ...
	'-cost lpc ' ... %cost function. see the help (in the command line) for more info
	'-anat_has_skull no ' ...
	'-epi_strip None' ...
	'-Allineate_opts -maxrot 5 -maxshf 5']);  %Allow a maximum shift and rotation of 5 mm. Can also use 3.

% Refine further (might not be needed)
system(['align_epi_anat.py -anat anatomy_clip_shft.nii.gz ' ...
	'-epi amplitudeAnatomy_mask_zp_rot_al+orig ' ...
	'-epi_base 0 ' ... %the how manieth volume is the amplitudeAnatomy (usually 0, as AFNI starts at 0).
	'-epi2anat ' ...
	'-cost lpc ' ... %cost function. see the help (in the command line) for more info
	'-anat_has_skull no ' ...
	'-epi_strip None' ...
	'-Allineate_opts -maxrot 1 -maxshf 1']);  %Allow a maximum shift and rotation of 1 mm. Can also use 3.

% Combine all transformation matrices into one.
system(['cat_matvec -ONELINE rotateMat.1D amplitudeAnatomy_mask_zp_rot_al_al_reg_mat.aff12.1D ' ...
	'amplitudeAnatomy_mask_zp_rot_al_reg_mat.aff12.1D > combined.1D']);

% Apply the combined co-registration to the amplitudeAnatomy in one resampling step. 
% At the same time, this is a check to see whether the combination of the matrices worked. 
% If not, play around with the order in the previous command. 
system(['3dAllineate -master amplitudeAnatomy_mask_zp_rot_al_al+orig ' ...
 '-source amplitudeAnatomy.nii ' ...
 '-1Dmatrix_apply combined.1D ' ...
 '-final wsinc5 ' ...
 '-prefix amplitudeAnatomy_Coreg.nii.gz']); 

% Reduce the volume size to just the bit that we have left after the clipping.
system('3dAutobox -prefix anatomy_clip_shft_box.nii.gz -input anatomy_clip_shft.nii.gz'); 

% Resample everything into the correct space
system('3dresample -master anatomy_clip_shft_box.nii.gz -inset boundaries_shft.nii.gz -prefix boundaries_shft_box.nii.gz -rmode NN');
system('3dresample -master anatomy_clip_shft_box.nii.gz -inset depth_shft.nii.gz -prefix depth_shft_box.nii.gz -rmode NN');

% Resample the ROIs
system('3dresample -master anatomy_clip_shft_box.nii.gz -inset V1_lh_5deg_shft+orig -prefix V1_lh_5deg_shft_box.nii.gz -rmode NN');
system('3dresample -master anatomy_clip_shft_box.nii.gz -inset V1_rh_5deg_shft+orig -prefix V1_rh_5deg_shft_box.nii.gz -rmode NN');
system('3dresample -master anatomy_clip_shft_box.nii.gz -inset V2_lh_5deg_shft+orig -prefix V2_lh_5deg_shft_box.nii.gz -rmode NN');
system('3dresample -master anatomy_clip_shft_box.nii.gz -inset V2_rh_5deg_shft+orig -prefix V2_rh_5deg_shft_box.nii.gz -rmode NN');
system('3dresample -master anatomy_clip_shft_box.nii.gz -inset V3_lh_5deg_shft+orig -prefix V3_lh_5deg_shft_box.nii.gz -rmode NN');
system('3dresample -master anatomy_clip_shft_box.nii.gz -inset V3_rh_5deg_shft+orig -prefix V3_rh_5deg_shft_box.nii.gz -rmode NN');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 	apply warp field and co-registration	%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd ..
system('mkdir results')
system('computeAmplitudeAnatomy.sh motionCorrectEpi/') %compute amplitude anatomy from motion corrected epi only (not top up)
system('mv amplitudeAnatomy.nii results/') %move it into results/
system('mv results/amplitudeAnatomy.nii results/amplitudeAnatomyMotionCorrEpi.nii') %rename it
system('cp Coregistration/anatomy_res_clip_shft_box.nii.gz results/')
system('cp Coregistration/anatomy_res_boundaries_shft_box.nii.gz results/')
system('cp Coregistration/anatomy_res_depth_shft_box.nii.gz results/')
system('cp Coregistration/amplitudeAnatomy_mask_zp_rot_al_al+orig* results/')
system('mv Coregistration/V*_*h_shft_box.nii.gz results/') 
system('3dcopy results/amplitudeAnatomy_mask_zp_rot_al_al+orig results/masterVolume.nii.gz')

% apply coregistration + top-up to the amplitude anatomy 
instr = ['3dNwarpApply -master results/masterVolume.nii.gz' ...
    ' -source results/amplitudeAnatomyMotionCorrEpi.nii' ...
    ' -nwarp Coregistration/amplitudeAnatomy_mask_zp_rot_al_al_mat.aff12.1D' ...
    ' Coregistration/amplitudeAnatomy_mask_zp_rot_al_mat.aff12.1D' ...
    ' Coregistration/rotateMat.1D' ...
    ' topUpDir/warpTop_PLUS_WARP+orig' ...
    ' -interp wsinc5' ...
    ' -prefix results/amplitudeAnatomyCoreg.nii.gz' ];
system( instr )


% apply coregistration + top-up to mean timeseries 
instr = ['3dNwarpApply -master results/masterVolume.nii.gz' ...
    ' -source meanTs_RAI.nii.gz' ...
    ' -nwarp Coregistration/amplitudeAnatomy_mask_zp_rot_al_al_mat.aff12.1D' ...
    ' Coregistration/amplitudeAnatomy_mask_zp_rot_al_mat.aff12.1D' ...
    ' Coregistration/rotateMat.1D' ...
    ' topUpDir/warpTop_PLUS_WARP+orig' ...
    ' -interp NN' ...
    ' -prefix results/meanTsCoreg.nii.gz' ];
system( instr )

instr = [ '3dresample -master results/anatomy_res_clip_shft_box.nii.gz ' ...
    '-inset results/meanTsCoreg.nii.gz -prefix results/meanTsCoreg_box.nii.gz -rmode NN' ];
system( instr )
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 		surface analysis	        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% build surfaces
system('defineBoundaries.sh results/anatomy_res_boundaries_shft_box.nii.gz 1 2 1')
system('mv boundariesThr.nii.gz results/')
cd results/

system('generateSurfaces.sh 6 4 1200 3') %the 1200 is the inflation. Lower number = less inflation

%% Run from terminal to avoid unexpected behaviour! 
% this will give you a 3d inflated view of your scan. 
afniSurface.sh anatomy_res_clip_shft_box.nii.gz 

%% For ROI definition etc, see the AFNI_analysis.m file under 'surface analysis'.

%% Now it's up to you what you want to do with the data. 
%% Example analysis script. only use for inspiration:
PlotBoldvsDepth
