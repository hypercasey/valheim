#!/usr/bin/env bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/container-entrypoint-valheim/valheim-server:/container-entrypoint-valheim/valheim-server/bin:/container-entrypoint-valheim/valheim-server/linux32:/container-entrypoint-valheim/valheim-server/linux64

STEAMROOT="$(cd "${0%/*}" && echo $PWD)"
STEAMCMD=`basename "$0" .sh`

UNAME=`uname`
if [ "$UNAME" == "Linux" ]; then
  STEAMEXE="steamcmd"
  PLATFORM="linux32"
  export LD_LIBRARY_PATH="$STEAMROOT/$PLATFORM:$LD_LIBRARY_PATH"
else # if [ "$UNAME" == "Darwin" ]; then
  STEAMEXE="${STEAMROOT}/${STEAMCMD}"
  if [ ! -x ${STEAMEXE} ]; then
    STEAMEXE="${STEAMROOT}/Steam.AppBundle/Steam/Contents/MacOS/${STEAMCMD}"
  fi
  export DYLD_LIBRARY_PATH="$STEAMROOT:$DYLD_LIBRARY_PATH"
  export DYLD_FRAMEWORK_PATH="$STEAMROOT:$DYLD_FRAMEWORK_PATH"
fi

# Setting ulimit using this method won't work
# inside a container.
# ulimit -n 2048

# Use something like this on your container host in
# /usr/share/containers/containers.conf:
# default_ulimits = [
# "nofile=65535:65535",
#]

MAGIC_RESTART_EXITCODE=42

if [ "$DEBUGGER" == "gdb" ] || [ "$DEBUGGER" == "cgdb" ]; then
  ARGSFILE=$(mktemp $USER.steam.gdb.XXXX)

  # Set the LD_PRELOAD varname in the debugger, and unset the global version.
  if [ "$LD_PRELOAD" ]; then
    echo set env LD_PRELOAD=$LD_PRELOAD >> "$ARGSFILE"
    echo show env LD_PRELOAD >> "$ARGSFILE"
    unset LD_PRELOAD
  fi

  $DEBUGGER -x "$ARGSFILE" "$STEAMEXE" "$@"
  rm "$ARGSFILE"
else
  $DEBUGGER "$STEAMEXE" "$@"
fi

STATUS=$?

if [ $STATUS -eq $MAGIC_RESTART_EXITCODE ]; then
    exec "$0" "$@"
fi
exit $STATUS
