#!/bin/sh
VERSION_FILE_PATH="./WeaveUISpark/src/weave/weave_version.txt"
if [ -z `git status --porcelain -uno` ]; then
    echo Automated Build `git rev-parse --short HEAD`, `date` > $VERSION_FILE_PATH;
else
    echo Custom > $VERSION_FILE_PATH
fi
