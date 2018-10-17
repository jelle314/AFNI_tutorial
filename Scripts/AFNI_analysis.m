%% Script to do regular resolution (> 1 mm, no TOPUP) preprocessing in AFNI.
%% Author: Jelle van Dijk, j.a.vandijk@uu.nl
%% Called functions/scripts by: Alessio Fracasso, Wietske van der Zwaag & Jelle van Dijk

% ALWAYS CHECK YOUR OUTPUTS! 
% in the command line: use '3dinfo nameOfVolume' to get info about TR, space etc. 
% or visually check by opening e.g. afni. 

% Individual cells can be run by pressing ctrl+enter

% Make sure you have ran the . startAfniToolbox command in the command line 
% (after adjusting the startAfniToolbox file to include the correct paths).
% before you start MATLAB in that same terminal

%% Prepare
clear all
close all

addpath(genpath('/home/jelle/Documents/Software/matFileAddOn')); %add the right toolboxes
addpath(genpath('/usr/share/afni/matlab');

% Convert PAR and REC files to .nii
r2agui % or something else. 

% Setup the correct directory structure for the rest of the analysis (feel free to edit)
setupDirectories

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 		anatomical data           	%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% For MP2RAGE data
% Make sure that all files are called the same stem, with suffixes _INV1, _INV1ph, _INV2, INV2ph 
% for the appropriate files. INV2 is the proton density volume

% Use mp2rageB to combine INV1 and INV2 of the MP2RAGE 
mp2rageB('MP2RAGE',100,1); %stem string, threshold (play around with this!), movie yes/no

%% From here on also for MRPAGE data
system('skullStrip01.sh MPRAGE PD res coregFlag'); % MPRAGE = name of T1 file, PD = name of PD file, 
	% res = output resn (mm), coregFlag = 0 or 1: 0 for MP2RAGE data 
	% (as T1 and PD are inherently coregistered), 1 for MPRAGE data

%% Now segment the resulting anatomy. 
% This can be done using e.g. mipav with the cbs tools plugin.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 		segmentation	           	%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% mipav needs the anatomy to be strictly isotropic.
% Start mipav e.g. from /mipavinst, ./mipav in terminal 
% Open the jist layout tool (under the plugins tab)

% Blue boxes are inputs. E.g. click the blue box and replace the .nii.gz file with the current anatomy.
% All white dots above are required inputs. Click on the coloured box to see what the inputs are.
% Mouse over the white dots to see which input needs adjustment. The input still in that box should give
% you a clue as to what should be entered there. 
 
% Use brain-segmentation-05_server.LayoutXML or brain-segmentation-08.LayoutXML
% both layouts should give you a segmentation as output.

% Then, adjust any mistakes in the segmentation manually (in e.g. itk gray or 3Dslicer)

% the _Remove_Handles layout is untested, but worth a try. 
% Should remove handles from the manually adjusted segmentation and run the layering etc.

% After correcting the segmentation, use that and the anatomy as inputs for sdjutSegmentationmanually.LayoutXML
% This does the equivolume layering for you. 

%% Split segmentation into left and right hemisphere 
system(['hemisphereSeparation.sh anat seg atlaspath nonlinflag']);
	% anat = anatomy, seg = segmentation, atlaspath = full path to afni atlas you want to register to
	% (necessary). If possible, use the TT_icbm+tlrc atlas. example: /usr/share/afni/atlases/TT_icbm452+tlrc 
	% nonlinflag = 0 linear, use when the border between hemispheres is straight, 1 nonlinear. 

%% Make the segmentation ready to be installed in mrVista
system(['3dcalc -a segmentation.nii.gz -b leftSeg.nii.gz -c rightSeg.nii.gz -expr ''and( within(a,3,3), '...
 	'within(b,3,3) )*3 + and( within(a,3,3), within(c,3,3) )*4 + within(a,0,0)*1 + within(a,1,1)*0'' -prefix segmentation_mrVista.nii.gz'])
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 		functional data		        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

system('motionCorrect.afni.sh')    %prepare motion correction. Expects EPIs in EPI/ directory 
system('tcsh -xef proc.motionCorrect |& tee output.proc.motionCorrect') %Run motion correction
system('computeAmplitudeAnatomy.sh') %compute mean EPI over runs, same as inplane in mrVista 

%% Compute mean timeseries from the volreg files in the motionCorrect.results directory
% NB: for multiple conditions, make sure you have only the volreg files in motionCorrect.results directory
% of 1 condition, otherwise they will all be averaged together.  
system('computeMeanTs.sh')

% Now rename the meanTs.nii file if you have more than one condition, and rerun with the volreg files 
% for the other condition in the motionCorrect.results directory. 

%% Optional: automask the EPI data to make everything not brain 0 (for faster modeling)  
meanTsnii = dir( 'meanTs*.nii');
for imeanTs = 1:length( meanTsnii) 
    system( ['3dAutomask -clfrac 0.5 -apply_prefix ' meanTsnii(imeanTs).name(1:end-4) '_auto.nii ' meanTsnii(imeanTs).name])
end

%% Now you can run the modelling in mrVista inplane (MrInit etc).
% Do this if you want to do the surface projection in AFNI
% Once completed the modelling in the inplane view, run:

saveRmModelAsNifti % some fiddling in the code may be required to make the last volume (the original EPI)
		% line up with the polar angle etc maps. 

% To run in the volume view, continue with the following steps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 		co-registration		        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% co-register the functional volume(s) to the anatomy

% Move the skullstripped anatomy and the amplitudeAnatomy to the Coregistration directory
% and check the size and origin of the anatomy using 3dinfo
% run all this from the Coregistration directory, and keep checking using AFNI via the command line! 

% Clip the anatomy:
system('@clip_volume -anterior 120 -input anatomy.nii.gz -prefix anatomy_clip.nii.gz');
	% 120 and anterior are indicators for how much is clipped and which direction is left over
	% the -input and -prefix inputs are what you want them to be.
	% clipping at this resolution is optional, but improves visualisation speed for high-resolution data.

% OPTIONAL: if some volume is in the +orig format, this is a way to convert it to .nii/ .nii.gz
system('3dcopy file+orig file.nii.gz') ; 

% Mask the amplitudeAnatomy to reduce the volume size.
system('3dAutomask -apply_prefix amplitudeAnatomy_mask.nii.gz amplitudeAnatomy.nii');

% Zeropad the amplitudeAnatomy to allow for shifting it around in the next steps.
system('3dZeropad -A 20 -P 20 -S 20 -I 20 -prefix amplitudeAnatomy_mask_zp.nii.gz amplitudeAnatomy_mask.nii.gz');

% Now align the centres of mass of the amplitudeAnatomy and anatomy, so they are in the same space
system('@Align_Centers -base anatomy_clip.nii.gz -dset amplitudeAnatomy_mask_zp.nii.gz -cm );

% now use the Nudge datasets plugin in Afni to get a good start for the coregistration
% nudge the EPI volume, get 3drotate command from 'print' 
% e.g.: 
system(['3drotate -quintic -clipit -rotate 0.00I 0.00R 0.00A -ashift 13.50S -6.00L 17.00P -prefix ' ...
 'amplitudeAnatomy_mask_zp_shft_rot.nii.gz amplitudeAnatomy_mask_zp_shft.nii.gz']);

% Get the rotation matrix out as a .1D file
cat_matvec 'amplitudeAnatomy_mask_zp_shft_rot.nii.gz::ROTATE_MATVEC_000000' -I -ONELINE > rotateMat.1D

% Now refine the co-registration automatically
system(['align_epi_anat.py -anat anatomy_res_clip.nii.gz ' ...
	'-epi amplitudeAnatomy_mask_zp_shft_rot.nii.gz ' ...
	'-epi_base 0 ' ... %the how manieth volume is the amplitudeAnatomy (usually 0, as AFNI starts at 0).
	'-epi2anat ' ...
	'-cost lpc ' ... %cost function. see the help (in the command line) for more info
	'-anat_has_skull no ' ...
	'-epi_strip None']);

% Combine all transformation matrices into one.
system('cat_matvec -ONELINE amplitudeAnatomy_mask_zp_shft.1D rotateMat.1D amplitudeAnatomy_mask_zp_shft_rot_al_reg_mat.aff12.1D > combined.1D');

% Apply the combined co-registration to the amplitudeAnatomy in one resampling step. 
% At the same time, this is a check to see whether the combination of the matrices worked. 
% If not, play around with the order in the previous command. 
system(['3dAllineate -master ampltidueAnatomy_mask_zp_shft_rot_al+orig ' ...
 '-source amplitudeAnatomy.nii ' ...
 '-1Dmatrix_apply combined.1D ' ...
 '-final wsinc5 ' ...
 '-prefix amplitudeAnatomy_Coreg.nii.gz']); 

% NOW GO AND DOUBLE CHECK ALL THE STEPS!

% Apply the coregistration matrix to each mean timeseries
system(['3dAllineate -master ampltidueAnatomy_mask_zp_shft_rot_al+orig ' ...
 '-source meanTs.nii ' ... %replace with the meanTs file for a specific condition
 '-1Dmatrix_apply combined.1D ' ...
 '-final NN ' ... %final interpolation. change to desired way.
 '-prefix meanTs_Coreg.nii.gz']); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 		surface analysis	        %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% The co-registered volumes can now be used in mrVista or AFNI (see below).
%% load up rxAlign. The angulation is now perfect, but you will need to shift/flip it manually. 
%% This is an unfortunate effect of mrVista not reading the .nii headers correctly.

%% surface analysis in AFNI:
% This bit assumes that you have done the segmentation using mipave and cbs tools.
% for more info on the inputs, type the function name without inputs in the command line.

% define boundaries
system('defineBoundaries.sh anatomy/boundaries.nii.gz 1 2 1')

system('3dcalc -a boundariesThr.nii.gz -b Layering/rightHemi.nii.gz -expr ''a*step(b)'' -prefix boundariesThr_clip.nii.gz')
system('rm boundariesThr.nii.gz')
system('mv boundariesThr_clip.nii.gz boundariesThr.nii.gz')
% check the number of boundaries with 3dinfo, number of time steps = num
% surfaces = num for generating surfaces (first numeric argument)

% generate surfaces
system('generateSurfaces.sh 6 4 1200 3') % 6 = number of surfaces, 4 = smoothing, 1200 = inflation iterations,
	% 3 = inflation index, aka which layer you want to inflate.

% surface project results, RUN FROM TERMINAL, as this may otherwise cause unexpected behaviour. 
% anatomy.nii.gz is the name of the skullstripped anatomy here.
afniSurface.sh anatomy.nii.gz 

% r-click on the brain mesh, then press 't' to link the 2D and 3D views. 
% use the draw ROI menu to draw ROIS.
% SAVE AS .1D.roi files! 

% Grow the ROIs over all layers
lst = dir('*.roi');
for iN = 1:length(lst)
    system(['surf2vol.sh ' lst(iN).name ' boundary03 anatomy_res_depth_box.nii.gz 100']) 
end

% Combine ROIs (examples)
system('3dcopy V1_lh.1D.roi_clust+orig V1_lh+orig')
system('3dcalc -a V1_lh+orig -b V2v_lh.1D.roi_clust+orig -c V2d_lh.1D.roi_clust+orig -expr ''(b+c)-(a*(b+c))'' -prefix V2_lh+orig')
system('3dcalc -a V2_lh+orig -b V3v_lh.1D.roi_clust+orig -c V3d_lh.1D.roi_clust+orig -expr ''(b+c)-(a*(b+c))'' -prefix V3_lh+orig')
system('3dcopy V1_rh.1D.roi_clust+orig V1_rh+orig')
system('3dcalc -a V1_rh+orig -b V2v_rh.1D.roi_clust+orig -c V2d_rh.1D.roi_clust+orig -expr ''(b+c)-(a*(b+c))'' -prefix V2_rh+orig')
system('3dcalc -a V2_rh+orig -b V3v_rh.1D.roi_clust+orig -c V3d_rh.1D.roi_clust+orig -expr ''(b+c)-(a*(b+c))'' -prefix V3_rh+orig')

% Now it's up to you to decide what you want to do. 
