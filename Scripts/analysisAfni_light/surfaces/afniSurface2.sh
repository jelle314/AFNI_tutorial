#!/usr/bin/env bash

MPRAGE=$1
SURFFOLDER=$2

if [ ! -v SURFFOLDER ] || [ -z "$SURFFOLDER" ]
	then
	SURFFOLDER="surfaces_folder"
fi

afni -niml &

sumaCommand=$(printf 'suma -spec %s/spec.surfaces.smoothed -sv $MPRAGE' $SURFFOLDER)
$sumaCommand &


