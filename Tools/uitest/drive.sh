#!/bin/zsh
S=${FV_SCRATCH:?set FV_SCRATCH to a scratch directory holding dd/ (derived data)}
APP=$S/dd/Build/Products/Debug/FViewer.app
C=/Users/miro/Library/Containers/croakie.FViewer/Data/tmp/fvtest
mkdir -p $C/run $S/run
find $C/run -type f -delete
cp $2 $C/run/script.txt
pkill -x FViewer; sleep 0.5
open -g -n $APP --args --windowed --library $C --open $C/$1 --script $C/run/script.txt
for i in {1..160}; do sleep 0.5; [ -f $C/run/log.txt ] && break; done
pkill -x FViewer
for f in $C/run/*.png(N); do sips -Z 1600 $f --out $S/run/${f:t} >/dev/null 2>&1; done
cat $C/run/log.txt
