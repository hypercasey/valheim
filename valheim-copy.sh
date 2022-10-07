#!/usr/bin/env bash
# Copies your Valheim world save files over to the $targetPath.
# Notice: Does NOT actually save any world. Only copies them over to another hellish
nightmare of existence to start all over again from wherever you left off previously.

containerWaitTime=75
containerName="valheim-server"
localPath="./"
localWorldsPath="$HOME/.config/unity3d/IronGate/Valheim"
targetPath="/home/hyperuser/hyperstor"
containerWorldsPath="/container-entrypoint-valheim/valheim-server/.config/unity3d/IronGate/Valheim"
sshRemoteHost="secure.us.hyperspire.net"

cd "${localWorldsPath}" || exit 1

if ssh ${sshRemoteHost} -t "rm ${targetPath}/worlds_local.tar.xz"; then
  echo "Old worlds_local.tar.xz was removed."
fi

if rm "${localWorldsPath}"/worlds_local/*.old; then
  echo "Old worlds_local files were removed."
fi

if [[ -f "worlds_local.tar.xz" ]]; then
  rm -vf worlds_local.tar.xz
fi

if tar -cvJ "worlds_local" -f "worlds_local.tar.xz"; then
  echo "New worlds_local.tar.xz was created."
else
  echo "New worlds_local.tar.xz was not created."
  exit 1
fi

if scp ${localPath}/worlds_local.tar.xz ${sshRemoteHost}:${targetPath}; then
  echo "New worlds_local.tar.xz was copied to ${sshRemoteHost}:${targetPath}."
else
  echo "New worlds_local.tar.xz was not copied to ${sshRemoteHost}:${targetPath}."
  exit 1
fi

if ssh ${sshRemoteHost} -t "sudo podman cp ${targetPath}/worlds_local.tar.xz ${containerName}:${containerWorldsPath}"; then
  echo "New worlds_local.tar.xz was copied to ${containerName}."
else
  echo "New worlds_local.tar.xz was not copied to ${containerName}."
  exit 1
fi

if ssh ${sshRemoteHost} -t sudo podman exec ${containerName} "tar -xvJf ${containerWorldsPath}/worlds_local.tar.xz -C ${containerWorldsPath}"; then
  echo "worlds_local files were updated."
else
  echo "worlds_local files were not updated."
  exit 1
fi

if ssh ${sshRemoteHost} -t sudo podman exec ${containerName} "rm ${containerWorldsPath}/worlds_local.tar.xz"; then
  echo "worlds_local.tar.xz was removed from ${containerName}."
fi

if ssh ${sshRemoteHost} -t "sudo podman stop ${containerName}"; then
  echo "${containerName} was stopped."
fi

if ssh ${sshRemoteHost} -t "sudo podman start ${containerName}"; then
  echo "${containerName} was started."  
fi

echo "Waiting ${containerWaitTime} seconds for ${containerName} to start..."
sleep "${containerWaitTime}"

echo "${containerName} is $(ssh ${sshRemoteHost} -t sudo podman inspect --format '{{.State.Health.Status}}' ${containerName} 2> /dev/null)"

