#!/usr/bin/env bash
source "Defaults" || exit 1

# This script is used for deploying the build to
# the remote DevOps environment. There is an NFS
# mount shared over a virtual private network
# between the local workstations and the remote
# DevOps server running on Oracle Cloud
# Infrastructure.

WORKDIR="/var/home/hyperuser/Projects/valheim-release"
TARGETDIR="/var/home/hyperuser/hyperstor/valheim-release"
REMOTETARGETDIR="${USER}@devops.us.hyperspire.net:/home/hyperuser/hyperstor/valheim-release"
red='\e[31m\e[1m'
green='\e[32m\e[1m'
yellow='\e[33m\e[1m'
background='\e[40m'
normal='\e[0m'

[[ -d "${TARGETDIR}" ]] || mkdir -p "${TARGETDIR}"
unset MANIFEST
MANIFEST=("Defaults" "Dockerfile" "container-entrypoint-steamcmd.sh" "valheim-build.sh" "valheim-create.sh" "valheim-run.sh" "valheim-save.sh" "valheim-update.sh" "valheim-check.sh" "valheim-commit.sh" "valheim-push.sh" "kubernetes-valheim-server-pod.yaml" "License.txt")

function choke {
  echo -e "\n${red}⬢${normal} ${background}[ $(date '+%Y-%m-%dT%R:%SZ') ${red} ${1} ${normal}${background}]${normal}\n"
  exit 1
}

function croak {
  echo -e "\n${yellow}⬢${normal} ${background}[ $(date '+%Y-%m-%dT%R:%SZ') ${yellow} ${1} ${normal}${background}]${normal}\n"
  exit 1
}

function cleanArchives {
  rm -f "${WORKDIR}/${CONTAINER_NAME}.zip"
  return $?
}

unset ARCHIVE
function buildArchive {
  cleanArchives || croak "Warning: function cleanArchives did not exit cleanly. Either no archives were found or they were not removed."

  for resource in "${MANIFEST[@]}"; do
    echo "Adding ${resource} to archive."
    [[ -f "${CONTAINER_NAME}.zip" ]] || zip -r "${CONTAINER_NAME}.zip" "${resource}"
    [[ -f "${CONTAINER_NAME}.zip" ]] && zip -ru "${CONTAINER_NAME}.zip" "${resource}"
  done
  return $?
}

buildArchive

function uploadArchive {
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${CONTAINER_NAME}.zip" "${REMOTETARGETDIR}"
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "Defaults" "${REMOTETARGETDIR}/../../"
  return $?
}

function preDeploy {
  local lineNo=55
  lineNo=$((lineNo+1)); cd "${WORKDIR}" || choke "Failure: Could not change to ${WORKDIR} at line ${lineNo}."
  lineNo=$((lineNo+1)); [[ $(wc -c "${CONTAINER_NAME}.zip" | sed "s/ ${CONTAINER_NAME}.zip//g") -gt 4096 ]] || choke "Failure: Archive empty or failed to compress properly: ${CONTAINER_NAME}.zip at line ${lineNo}."
  lineNo=$((lineNo+1)); if uploadArchive; then
    lineNo=$((lineNo+1)); echo "Uploaded ${CONTAINER_NAME}.zip to ${REMOTETARGETDIR}."
  lineNo=$((lineNo+1)); else
    lineNo=$((lineNo+1)); choke "Failure: Could not upload file at line ${lineNo}."
  fi
  return 0
}

preDeploy

if [[ $? -eq 0 ]]; then
  echo -e "\n${green}⬢${normal} ${background}[ $(date '+%Y-%m-%dT%R:%SZ') ${green}Success: ${CONTAINER_NAME} ready for deployment ${normal}${background} ${normal}${background}]${normal}\n"
else
  echo -e "\n${red}⬢${normal} ${background}[ $(date '+%Y-%m-%dT%R:%SZ') ${red}Failure: ${CONTAINER_NAME} pre-deployment failed ${normal}${background} ${normal}${background}]${normal}\n"
fi

exit $?
