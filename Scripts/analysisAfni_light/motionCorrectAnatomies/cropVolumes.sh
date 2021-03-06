#!/usr/bin/env bash

INDIR=$1
SEARCHSTRING=$2
CROPSTRING=$3

if [ -z "$1" ]
then
echo 'crops the volumes in a directory using @clip_volume, 3dAutobox and 3dresample with NN recursively'
echo 'Inputs:'
echo 'INDIR=$1, directory where the volumes are stored'
echo 'SEARCHSTRING=$2, regular expr to search for specific volumes in the directory'
echo 'CROPSTRING=$3, string to pass to @clip_volume, use _ to concatenate, example: -anterior_25_-left_10'
exit 1
fi

Rscript $AFNI_TOOLBOXDIRCOREGISTRATION/cropVolumes.R $INDIR $SEARCHSTRING $CROPSTRING
