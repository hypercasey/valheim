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

userDetails=("$(grep ${USER} /etc/passwd)")

sudo "${CE_EXEC}" create --security-opt label=disable --privileged --replace -i -t --memory "${MEMORY}" -p ${INTERFACE_IP}:2456:2456/udp -p ${INTERFACE_IP}:2456:2456/tcp -p ${INTERFACE_IP}:2457:2457/udp -p ${INTERFACE_IP}:2457:2457/tcp -p ${INTERFACE_IP}:2458:2458/udp -p ${INTERFACE_IP}:2458:2458/tcp --expose 2456/udp --expose 2456/tcp --expose 2457/udp --expose 2457/tcp --expose 2458/udp --expose 2458/tcp --name "${CONTAINER_NAME}" "${REPO}/${CONTAINER_NAME}:${TAG}"

sudo "${CE_EXEC}" commit -a "${userDetails[4]} ${USER}@$(hostnamectl --transient)" "${CONTAINER_NAME}"

exit $?
