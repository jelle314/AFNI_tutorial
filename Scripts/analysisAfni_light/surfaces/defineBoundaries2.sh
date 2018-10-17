#!/bin/bash

if [ -z "$1" ]
 then
  echo 'Inputs:'
  echo 'INPUTFILE=$1'
  echo 'FILETYPE=$2'
  echo 'SEGMENTATIONWM=$3'
  echo 'SEGMENTATIONGM=$4'
  echo 'ALTNAME=$5 (0, 1, or empty)' 
  exit 1
fi

INPUTFILE=$1
FILETYPE=$2
SEGMENTATIONWM=$3
SEGMENTATIONGM=$4
## BOUNDNAME=$5
ALTNAME=$5


if (( $FILETYPE==1 )) ## generate threshold 3d+t bucket across separate surfaces
 	then
	3dcalc -a $INPUTFILE -expr '( within(a,-1000,0) )' -prefix boundariesThr+orig
else
	instrWM=$(printf '3dcalc -a %s -expr \u0027within(a,%s,%s)\u0027 -prefix boundariesThrWM+orig' $INPUTFILE $SEGMENTATIONWM $SEGMENTATIONWM )
    instrGM=$(printf '3dcalc -a %s -expr \u0027step(a)\u0027 -prefix boundariesThrGM+orig' $INPUTFILE )
    echo $instrWM
    echo $instrGM
    Rscript $AFNI_TOOLBOXDIR/runCommandViaR.R $instrWM
    Rscript $AFNI_TOOLBOXDIR/runCommandViaR.R $instrGM
    3dTcat boundariesThrWM+orig boundariesThrGM+orig -prefix boundariesThr+orig
    rm boundariesThrWM+orig.HEAD
    rm boundariesThrWM+orig.BRIK
    rm boundariesThrGM+orig.HEAD
    rm boundariesThrGM+orig.BRIK
fi

3dAFNItoNIFTI boundariesThr+orig

gzip boundariesThr.nii
rm boundariesThr+orig.BRIK
rm boundariesThr+orig.HEAD

if [ -v ALTNAME ] && [[ $ALTNAME==1 ]] && [ ! -z "$ALTNAME" ] 
	then
	instrRE=$(printf 'mv boundariesThr.nii.gz Thr_%s' $INPUTFILE)
	$instrRE 	
	
fi
	
# if [ -v BOUNDNAME ] && [ ! -z "$BOUNDNAME" ]
# 	then
#	instrRE=$(printf 'mv boundariesThr.nii.gz %s.nii.gz' $BOUNDNAME)
#	$instrRE 	
#fi





