#!/bin/bash

BOUNDARYNAME=$1
ANAT=$2
DEPTH=$3
MAP=$4
INDEXAVERAGE=$5
INDEXWEIGHT=$6
OUTNAME=$7

if [ -z "$1" ]
then
echo
echo
echo 'collapses an index map (e.g. eccentricity map) across cortical depth, weighting for a given index map,
usually variance explained, but it could be anything you want. The function computes the connection matrix across depth and weights the index map by the weight map. The output consists on the upsampled map into the parent space plus 3 volumes: wAverage meanIndex meanWeight, in this order, the last three 3D volumes in the 4D volume.'
echo
echo
echo 'Inputs:'
echo 'BOUNDARY=$1, e.g. boundary05, generated by generateSurfaces.sh'
echo 'ANAT=$2, e.g. anatomy_crop.nii.gz'
echo 'DEPTH=$3, e.g. continous_depth.nii.gz, from MIPAV'
echo 'MAP=$4, the coregistered volume that contains the maps to average (index + weight)'
echo 'INDEXAVERAGE=$5, the volume number in the coregistered volume where the index lives, in AFNI reference, so starting from 0 (for the first volume), 1 (for the second volume) and so forth'
echo 'INDEXWEIGHT=$6, the volume number in the coregistered volume where the weight lives, in AFNI reference, so starting from 0 (for the first volume), 1 (for the second volume) and so forth'
echo 'OUTNAME=$7, file output name'
exit 1
fi

Rscript $AFNI_TOOLBOXDIR/surfaces/collapseOverLayers.R \
 $BOUNDARYNAME \
 $ANAT \
 $DEPTH \
 $MAP \
 $INDEXAVERAGE \
 $INDEXWEIGHT \
 $OUTNAME \
 $AFNI_INSTALLDIR \
 $AFNI_TOOLBOXDIRSURFACES