FROM container-registry.oracle.com/os/oraclelinux:8-slim
ARG STEAM_DETAILS
ENV ENTRYPOINT="/container-entrypoint-valheim"
ENV BUILD_NAME="valheim-server"
ENV SERVICE_NAME="valheim"
ENV DEFAULTS="${ENTRYPOINT}/Defaults"
WORKDIR "${ENTRYPOINT}"
COPY "Defaults" "${ENTRYPOINT}"

# Check to see if Defaults file can be sourced.
RUN if [[ -f "${DEFAULTS}" ]]; then \
  echo -e "\n\e[32m\e[1m⬢ \e[40m[\e[1m Sourced: ${DEFAULTS} ]\e[0m\n"; else echo -e "\n\e[31m\e[1m⬢ \e[40m[\e[1m Failure: ${DEFAULTS} file not found ]\e[0m\n"; \
  exit 1; \
fi

# Prepare and install required dependencies.
RUN microdnf update
RUN microdnf install libstdc++.i686 \
libstdc++-devel.i686 procps-ng tar curl \
gzip zip unzip xz

RUN useradd -u 2456 -d "${ENTRYPOINT}/${BUILD_NAME}" -s /usr/bin/bash -U -m "${SERVICE_NAME}"
RUN source "${DEFAULTS}" && \
echo -e "\nexport PATH=${PATH}\n" >> "${ENTRYPOINT}/${BUILD_NAME}/.bashrc"

# Prepare the server environment.
ENV LD_LIBRARY_PATH=${ENTRYPOINT}/${BUILD_NAME}/linux32:${ENTRYPOINT}/${BUILD_NAME}/linux64
ENV SteamAppId=892970

# Generate entrypoint script.
RUN echo -e "#!/usr/bin/env bash\n" > "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh"
RUN echo "[[ 0 == \"\${UID}\" ]] && su ${SERVICE_NAME} && cd ${ENTRYPOINT}/${BUILD_NAME}" >> "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh"
RUN echo "export LD_LIBRARY_PATH=${ENTRYPOINT}/${BUILD_NAME}/linux32:${ENTRYPOINT}/${BUILD_NAME}/linux64" >> "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh"
RUN echo "SteamAppId=${SteamAppId}" >> "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh"

# TODO: Make sure the container builds and runs
# stable on your host first before enabling this
# optional steamcmd auto update code. This is a 
# precautionary measure so any unstable containers
# out there don't accidently DDoS Valve's login servers.
RUN export STEAM=(${STEAM_DETAILS}) && echo "${ENTRYPOINT}/${BUILD_NAME}/container-entrypoint-steamcmd.sh +force_install_dir bin +login \"${STEAM[0]}\" \"${STEAM[1]}\" +app_update 896660 validate +quit" >> "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh"
# Give steamcmd time to download the server.
RUN source "${DEFAULTS}" && \
echo "sleep ${STEAMWAIT}" >> "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh"
# Run the server with the supplied details. The run
# command has to be like the one described in the
# dedicated server manual. If not, it goes into
# an infinite loop consuming 100% CPU. They uh...
# they forgot to mention this in the manual.
RUN source "${DEFAULTS}" && if [[ 1 == "${PUBLIC}" ]]; then \
echo "${ENTRYPOINT}/${BUILD_NAME}/bin/${ENTRYCMD} -name \"${NAME}\" -port 2456 -world \"${WORLD}\" -password \"${PASSWORD}\"" >> "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh"; \
else \
echo "${ENTRYPOINT}/${BUILD_NAME}/bin/${ENTRYCMD} -name \"${NAME}\" -port 2456 -world \"${WORLD}\" -password \"${PASSWORD}\" -public 0" >> "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh"; \
fi

COPY License.txt "${ENTRYPOINT}"

# Download the latest version of the server
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" -o \
    "steamcmd_linux.tar.gz"

# Extract the server tarball
RUN tar -xzvf "steamcmd_linux.tar.gz" -C "${ENTRYPOINT}/${BUILD_NAME}"

# Create healthcheck
RUN echo -e "#!/usr/bin/env bash\n" > "${ENTRYPOINT}/${BUILD_NAME}-healthcheck.sh"
RUN echo "[[ 0 == \"\${UID}\" ]] && su ${SERVICE_NAME}" >> "${ENTRYPOINT}/${BUILD_NAME}-healthcheck.sh"
RUN source "${DEFAULTS}" && \
echo "[[ 2 == \$(ps x | grep -c '${ENTRYCMD}') ]] && serverOnline=true" >> "${ENTRYPOINT}/${BUILD_NAME}-healthcheck.sh"
RUN echo "[[ \$serverOnline ]] && echo \"${BUILD_NAME} is running\" && exit 0" >> "${ENTRYPOINT}/${BUILD_NAME}-healthcheck.sh"
RUN echo "[[ ! \$serverOnline ]] && echo \"${BUILD_NAME} is not running\" && exit 1" >> "${ENTRYPOINT}/${BUILD_NAME}-healthcheck.sh"

# Prepare the server for installation
COPY container-entrypoint-steamcmd.sh "${ENTRYPOINT}/${BUILD_NAME}"
RUN mkdir -p "${ENTRYPOINT}/${BUILD_NAME}/.config/unity3d/IronGate/Valheim"
RUN source "${DEFAULTS}" && \
for steamId in "${PERMITTEDLIST[@]}"; do \
  echo "${steamId}" >> "${ENTRYPOINT}/${BUILD_NAME}/.config/unity3d/IronGate/Valheim/permittedlist.txt"; \
done
RUN source "${DEFAULTS}" && \
for steamId in "${ADMINLIST[@]}"; do \
  echo "${steamId}" >> "${ENTRYPOINT}/${BUILD_NAME}/.config/unity3d/IronGate/Valheim/adminlist.txt"; \
done
RUN source "${DEFAULTS}" && \
for steamId in "${BANNEDLIST[@]}"; do \
  echo "${steamId}" >> "${ENTRYPOINT}/${BUILD_NAME}/.config/unity3d/IronGate/Valheim/bannedlist.txt"; \
done

RUN chown ${SERVICE_NAME}:${SERVICE_NAME} "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh" "${ENTRYPOINT}/${BUILD_NAME}-healthcheck.sh" "${ENTRYPOINT}/${BUILD_NAME}/.config/unity3d/IronGate/Valheim/adminlist.txt" "${ENTRYPOINT}/${BUILD_NAME}/.config/unity3d/IronGate/Valheim/permittedlist.txt" "${ENTRYPOINT}/${BUILD_NAME}/.config/unity3d/IronGate/Valheim/bannedlist.txt"
RUN chmod +x "${ENTRYPOINT}/${BUILD_NAME}/container-entrypoint-steamcmd.sh" "${ENTRYPOINT}/${BUILD_NAME}-entrypoint.sh" "${ENTRYPOINT}/${BUILD_NAME}-healthcheck.sh"

# Remove Defaults.
RUN if rm -f "${ENTRYPOINT}/Defaults"; then \
  echo -e "\n\e[32m\e[1m⬢ \e[40m[\e[1m Removed: ${DEFAULTS} ]\e[0m\n"; else echo -e "\n\e[31m\e[1m⬢ \e[40m[\e[1m Failure: ${DEFAULTS} not removed ]\e[0m\n"; \
  exit 1; \
fi

RUN rm -vf "${ENTRYPOINT}/${BUILD_NAME}/steamcmd_linux.tar.gz"
RUN chown -R ${SERVICE_NAME}. "${ENTRYPOINT}/${BUILD_NAME}/."

WORKDIR "${ENTRYPOINT}/${BUILD_NAME}"

# SteamCMD will run as the user who owns the
# working directory to have the sufficient
# privileges for installing the server.
USER ${SERVICE_NAME}

# Install the server
RUN export STEAM=(${STEAM_DETAILS}) && \
echo -e "\n\e[32m\e[1m⬢ \e[40m[\e[1m Steam +login user ${STEAM[0]} ]\e[0m\n"
RUN export STEAM=(${STEAM_DETAILS}) && \
"${ENTRYPOINT}/${BUILD_NAME}/container-entrypoint-steamcmd.sh" +force_install_dir bin +login "${STEAM[0]}" "${STEAM[1]}" +app_update 896660 validate +quit

