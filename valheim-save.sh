#!/usr/bin/env bash
source "Defaults" || exit 1

# Container Engine Binary - You will need
# to change this if using something other
# than podman (podman is recommended,
# specifically Oracle Cloud Infrastructure's 
# version as these scripts were designed to use 
# advanced features possibly not available yet
# for other versions).
CE_EXEC=$(which podman)
if [[ ! -f "${CE_EXEC}" ]]; then
  echo "Container Engine Binary not found."
  exit 1
fi

sudo "${CE_EXEC}" export --format "${SAVE_FORMAT}" -o "${CONTAINER_NAME}.tar" "${CONTAINER_NAME}"

exit $?
