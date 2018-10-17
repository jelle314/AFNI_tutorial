#!/usr/bin/env bash

MPRAGE=$1

afni -niml &
suma -spec surfaces_folder/spec.surfaces.smoothed -sv $MPRAGE &


