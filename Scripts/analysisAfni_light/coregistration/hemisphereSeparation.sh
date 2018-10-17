#!/bin/bash

INPUTANAT=$1
INPUTSEG=$2
ATLASPATH=$3
NONLINFLAG=$4

if [ -z "$1" ]
then
echo 'Use the anatomy and segmentation to separate the 2 hemispheres'
echo 'Inputs:'
echo 'INPUTANAT = $1, anatomy'
echo 'INPUTSEG = $2, segmentation'
echo 'ATLASPATH  = $3, full path to the afni atlas you want to register to (only for the separation)'
echo 'we advise to use TT_icbm452+tlrc'
echo 'NONLINFLAG = $4, 1 allows for non-linear midline, 0 is off '
echo 'example call: hemisphereSeparation.sh anatomy.nii.gz segmentation.nii.gz /usr/share/afni/atlases/TT_icbm452+tlrc 1 '
exit 1
fi

Rscript $AFNI_TOOLBOXDIRCOREGISTRATION/hemisphereSeparation.R $INPUTANAT $INPUTSEG $ATLASPATH $NONLINFLAG

