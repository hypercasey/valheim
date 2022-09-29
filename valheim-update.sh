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

podWaitInterval=15

function inspectPod() {
  local podStatus
  podStatus=$(sudo "${CE_EXEC}" inspect --format '{{.State.Status}}' "${CONTAINER_NAME}")
  if [[ "${podStatus}" == "running" ]]; then
    echo "${CONTAINER_NAME} is running."
    return 0
  else
    echo "${CONTAINER_NAME} failed to run."
    echo "Check ${CONTAINER_NAME}.json for more information."
    return 1
  fi
}

echo "Updating entrypoint script..."
if [ -f "./${CONTAINER_NAME}-entrypoint.sh" ]; then
  sudo "${CE_EXEC}" cp "${CONTAINER_NAME}-entrypoint.sh" "${CONTAINER_NAME}:${ENTRYPOINT}/${CONTAINER_NAME}-entrypoint.sh"
  sudo "${CE_EXEC}" exec -it -u 0 "${CONTAINER_NAME}" chmod +x "${ENTRYPOINT}/${CONTAINER_NAME}-entrypoint.sh"
else
  echo "./${CONTAINER_NAME}-entrypoint.sh file not found."
  exit 1
fi
echo "Restarting ${CONTAINER_NAME}."
sudo "${CE_EXEC}" restart "${CONTAINER_NAME}"
sleep "${podWaitInterval}"
inspectPod
exit $?
