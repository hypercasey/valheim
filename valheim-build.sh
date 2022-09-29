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

echo "# This part was automated by the build script." >>"./Dockerfile"
echo "LABEL Name=\"${CONTAINER_NAME}\" Version=\"${VERSION}\"" >>"./Dockerfile"
echo "LABEL description=\"${CONTAINER_NAME} container for podman. ${CAPABILITIES[*]}\"" >>"./Dockerfile"
echo "LABEL org.opencontainers.image.authors=\"casey@hyperspire.com\"" >>"./Dockerfile"
echo "LABEL org.opencontainers.image.created=\"$(date '+%Y-%m-%dT%R:%SZ')\"" >>"./Dockerfile"
echo "LABEL org.opencontainers.image.title=\"${CONTAINER_NAME}\"" >>"./Dockerfile"
echo "LABEL org.opencontainers.image.url=\"${REPO}/${CONTAINER_NAME}:${TAG}\"" >>"./Dockerfile"
echo "LABEL org.opencontainers.image.vendor=\"HyperSpire Foundation\"" >>"./Dockerfile"
echo -e "LABEL org.opencontainers.image.version=\"1.0.0\"\n" >>"./Dockerfile"
echo 'HEALTHCHECK --interval='$((STEAMWAIT*2))'s --timeout=15s \' >>"./Dockerfile"
echo '    --start-period='"${STEAMWAIT}"'s \' >>"./Dockerfile"
echo "    --retries=1 CMD [ \"${ENTRYPOINT}/${CONTAINER_NAME}-healthcheck.sh\" ]" >>"./Dockerfile"
echo "EXPOSE 2456/udp 2456/tcp 2457/udp 2457/tcp 2458/udp 2458/tcp" >>"./Dockerfile"
echo "ENTRYPOINT [ \"${ENTRYPOINT}/${CONTAINER_NAME}-entrypoint.sh\" ]" >>"./Dockerfile"
echo "# End of automated part." >>"./Dockerfile"

if [[ "true" == "${SETCAP}" ]]; then
  echo "Setting capabilities " "${CAPABILITIES[@]}"
  sudo "${CE_EXEC}" build "${CAPABILITIES[@]}" --security-opt label=disable --format "${FORMAT}" --no-cache --memory "${MEMORY}" --build-arg STEAM_DETAILS="$STEAMUSER $STEAMPASS" -t "${REPO}/${CONTAINER_NAME}:${TAG}" -f Dockerfile .
else
  sudo "${CE_EXEC}" build --security-opt label=disable --format "${FORMAT}" --no-cache --memory "${MEMORY}" --build-arg STEAM_DETAILS="$STEAMUSER $STEAMPASS" -t "${REPO}/${CONTAINER_NAME}:${TAG}" -f Dockerfile .
fi

exit $?
