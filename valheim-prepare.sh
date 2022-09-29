#!/usr/bin/env bash

cd ~/Projects/valheim-release || exit 1
if rm -vf ~/hyperstor/valheim-release/*; then
  ./predeploy.sh
  rm -vf valheim-server.zip
else
  ./predeploy.sh
  rm -vf valheim-server.zip
fi