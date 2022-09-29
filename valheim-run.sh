#!/usr/bin/env bash
source "Defaults" || exit 1

# Container Engine Binary - You will need
# to change this if using something other
# than podman (podman is reINTERFACE_IPcommended, specifically
# Oracle Cloud Infrastructure's version as
# these scripts were designed to use advanced
# features possibly not available yet for other
# versions).
CE_EXEC=$(which podman)
if [[ ! -f "${CE_EXEC}" ]]; then
  echo "Container Engine Binary not found."
  exit 1
fi

sudo "${CE_EXEC}" login -u "${REPOUSER}" -p "${REPOPASS}" "${ENDPOINT}" &> /dev/null

podWaitInterval=$((STEAMWAIT*2+STEAMWAIT/2))
red='\e[31m\e[1m'
green='\e[32m\e[1m'
yellow='\e[33m\e[1m'
background='\e[40m'
normal='\e[0m'

function inspectPod {
  local podStatus
  podStatus="$(sudo "${CE_EXEC}" inspect --format '{{.State.Health.Status}}' "${CONTAINER_NAME}")"
  if [[ "healthy" == "${podStatus}" ]]; then
    echo -e "${green}⬢${normal} ${background}[ ${green}Success${normal}${background}: ${CONTAINER_NAME} ${podStatus} ]${normal}\n"

    if [[ 1 == $(sudo /usr/bin/env netstat -lntup | grep ':2456' | grep -c 'udp') ]]; then
      echo -e "${green}⬢${normal} ${background}[ ${green}Success${normal}${background}: ${CONTAINER_NAME} listening on UDP port 2456 ]${normal}\n"
    else
      echo -e "${yellow}⬢${normal} ${background}[ ${yellow}Warning${normal}${background}: ${CONTAINER_NAME} not listening on UDP port 2456 ]${normal}\n"
    fi

    if [[ 1 == $(sudo /usr/bin/env netstat -lntup | grep ':2456' | grep -c 'tcp') ]]; then
      echo -e "${green}⬢${normal} ${background}[ ${green}Success${normal}${background}: ${CONTAINER_NAME} listening on TCP port 2456 ]${normal}\n"
    else
      echo -e "${yellow}⬢${normal} ${background}[ ${yellow}Warning${normal}${background}: ${CONTAINER_NAME} not listening on TCP port 2456 ]${normal}\n"
    fi

    if [[ 0 == $(sudo /usr/bin/env netstat -lntup | grep ':2456' | grep -c 'udp') && 0 == $(sudo /usr/bin/env netstat -lntup | grep ':2456' | grep -c 'tcp') ]]; then
      echo -e "${red}⬢${normal} ${background}[ ${red}Failure${normal}${background}: ${CONTAINER_NAME} not listening on any open ports. ]${normal}\n"
      return 1
    fi

    return 0
  elif [[ "starting" == "${podStatus}" ]]; then
    echo -e "${yellow}⬢${normal} ${background}[ ${yellow}Warning${normal}${background}: ${CONTAINER_NAME} is still ${podStatus} ]${normal}\n"
    return 0
  else
    echo -e "${red}⬢${normal} ${background}[ ${red}Failure${normal}${background}: ${CONTAINER_NAME} ${podStatus}. Check ${CONTAINER_NAME}.json for more information. ]${normal}\n"
    return 1
  fi
}

if [[ $(sudo "${CE_EXEC}" ps -a | grep -c "${CONTAINER_NAME}") -gt 0 ]]; then
  echo -e "${green}⬢${normal} ${background}[ ${background}Found: ${CONTAINER_NAME} already running... waiting to stop. ]${normal}\n"
  sudo "${CE_EXEC}" stop "${CONTAINER_NAME}"
fi

if [[ $* != "pull" ]]; then
  # Run the container
  echo 'Running container from local image... (Use "pull" option to run image from the latest branch of the registry).'

  if [[ "true" == "${SETCAP}" ]]; then
    sudo "${CE_EXEC}" run --security-opt label=disable --privileged --replace --pull never --restart "${RESTART_POLICY}" --name "${CONTAINER_NAME}" --env [STEAM_DETAILS="${STEAMUSER} ${STEAMPASS}"] -i -t -p "${INTERFACE}:2456:2456/udp" -p "${INTERFACE}:2456:2456/tcp" -p "${INTERFACE}:2457:2457/udp" -p "${INTERFACE}:2457:2457/tcp" -p "${INTERFACE}:2458:2458/udp" -p "${INTERFACE}:2458:2458/tcp" --expose 2456/udp --expose 2456/tcp --expose 2457/udp --expose 2457/tcp --expose 2458/udp --expose 2458/tcp --memory "${MEMORY}" -d "${REPO}/${CONTAINER_NAME}:${TAG}"
  else
    sudo "${CE_EXEC}" run --security-opt label=disable --replace --pull never --restart "${RESTART_POLICY}" --name "${CONTAINER_NAME}" --env [STEAM_DETAILS="${STEAMUSER} ${STEAMPASS}"] -i -t -p "${INTERFACE}:2456:2456/udp" -p "${INTERFACE}:2456:2456/tcp" -p "${INTERFACE}:2457:2457/udp" -p "${INTERFACE}:2457:2457/tcp" -p "${INTERFACE}:2458:2458/udp" -p "${INTERFACE}:2458:2458/tcp" --expose 2456/udp --expose 2456/tcp --expose 2457/udp --expose 2457/tcp --expose 2458/udp --expose 2458/tcp --memory "${MEMORY}" -d "${REPO}/${CONTAINER_NAME}:${TAG}"
  fi

  # Wait for the container to initialize
  # and for the server healthcheck to succeed.
  echo "Waiting ${podWaitInterval} seconds for all container operations to complete."
  sleep "${podWaitInterval}"

  # Check container health
  inspectPod
fi

if [[ $* = "pull" ]]; then
  # Pull new image and run the container
  if [[ "true" == "${SETCAP}" ]]; then
    sudo "${CE_EXEC}" run --security-opt label=disable --privileged --replace --pull always --restart "${RESTART_POLICY}" --name "${CONTAINER_NAME}" --env [STEAM_DETAILS="${STEAMUSER} ${STEAMPASS}"] -i -t -p "${INTERFACE}:2456:2456/udp" -p "${INTERFACE}:2456:2456/tcp" -p "${INTERFACE}:2457:2457/udp" -p "${INTERFACE}:2457:2457/tcp" -p "${INTERFACE}:2458:2458/udp" -p "${INTERFACE}:2458:2458/tcp" --expose 2456/udp --expose 2456/tcp --expose 2457/udp --expose 2457/tcp --expose 2458/udp --expose 2458/tcp --memory "${MEMORY}" -d "${REPO}/${CONTAINER_NAME}:${TAG}"
  else
    sudo "${CE_EXEC}" run --security-opt label=disable --replace --pull always --restart "${RESTART_POLICY}" --name "${CONTAINER_NAME}" -i -t -p "${INTERFACE}:2456:2456/udp" -p "${INTERFACE}:2456:2456/tcp" -p "${INTERFACE}:2457:2457/udp" -p "${INTERFACE}:2457:2457/tcp" -p "${INTERFACE}:2458:2458/udp" -p "${INTERFACE}:2458:2458/tcp" --expose 2456/udp --expose 2456/tcp --expose 2457/udp --expose 2457/tcp --expose 2458/udp --expose 2458/tcp --memory "${MEMORY}" -d "${REPO}/${CONTAINER_NAME}:${TAG}"
  fi
  
  # Wait for the container to initialize
  # and for the server healthcheck to succeed.
  echo "Waiting ${podWaitInterval} seconds for all container operations to complete."
  sleep "${podWaitInterval}"

  # Check container health
  inspectPod
fi

# Copy the entrypoint script from the container
[[ -f "${CONTAINER_NAME}-entrypoint.sh" ]] && rm -f "${CONTAINER_NAME}-entrypoint.sh"
sudo "${CE_EXEC}" cp "${CONTAINER_NAME}:${ENTRYPOINT}/${CONTAINER_NAME}-entrypoint.sh" .
sudo "${CE_EXEC}" cp "${CONTAINER_NAME}:${ENTRYPOINT}/${CONTAINER_NAME}/bin/Valheim Dedicated Server Manual.pdf" .

[[ -f "${CONTAINER_NAME}-entrypoint.sh" ]] && sudo chown "$USER". "${CONTAINER_NAME}-entrypoint.sh" && sudo chmod +rw-x "${CONTAINER_NAME}-entrypoint.sh"
[[ -f "Valheim Dedicated Server Manual.pdf" ]] && sudo chown "$USER". "Valheim Dedicated Server Manual.pdf" && sudo chmod +rw-x "Valheim Dedicated Server Manual.pdf"
[[ -f "${CONTAINER_NAME}-entrypoint.sh" ]] && echo -e "${green}⬢${normal} ${background}[ ${green}${CONTAINER_NAME}-entrypoint.sh${normal}${background}: ready for review ]${normal}\n"
[[ -f "Valheim Dedicated Server Manual.pdf" ]] && echo -e "${green}⬢${normal} ${background}[ ${green}Valheim Dedicated Server Manual.pdf${normal}${background}: ready for review ]${normal}\n"
[[ -f "${CONTAINER_NAME}-entrypoint.sh" ]] && echo "Run ./valheim-update.sh to apply any changes to the container if you want to modify the entrypoint script (heads-up: this will restart the server)."
[[ -f "${CONTAINER_NAME}-entrypoint.sh" ]] ||
  echo -e "${red}⬢${normal} ${background}[ ${red}Failure${normal}${background}: ${CONTAINER_NAME} entrypoint script not found. ]${normal}\n"
[[ -f "${CONTAINER_NAME}-entrypoint.sh" ]] || echo "Container image failed to build properly."
[[ -f "${CONTAINER_NAME}-entrypoint.sh" ]] || echo "Check ${CONTAINER_NAME}.json for more information."

exit $?
