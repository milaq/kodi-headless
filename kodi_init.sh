#!/bin/bash
set -e

echo -e "\nStarting container...\n======================================================="

if [ ! -e $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml ]; then
  cp $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml.default $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
  chown kodi. $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
fi

if [ ! -z $KODI_DBHOST ] && [ ! -z $KODI_DBUSER ] && [ ! -z $KODI_DBPASS ]; then
  echo "Shared MySQL database: YES"
  cp $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml.default $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
  sed -i -e "s/\(<host>\)\([^<]*\)\(<[^>]*\)/\1$KODI_DBHOST\3/g" $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
  sed -i -e "s/\(<user>\)\([^<]*\)\(<[^>]*\)/\1$KODI_DBUSER\3/g" $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
  sed -i -e "s/\(<pass>\)\([^<]*\)\(<[^>]*\)/\1$KODI_DBPASS\3/g" $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
  sed -i -e "s/\(<type>\)\([^<]*\)\(<[^>]*\)/\1mysql\3/g" $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
  sed -i -e "s/\(<port>\)\([^<]*\)\(<[^>]*\)/\13306\3/g" $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
  chown kodi. $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml
else
  echo "Shared MySQL database: NO"
fi

if [ -z $KODI_UPDATE_INTERVAL ]; then
  KODI_UPDATE_INTERVAL="300"
fi
if [ -z $KODI_CLEAN_INTERVAL ]; then
  KODI_CLEAN_INTERVAL="86400"
fi

function update_library_job {
  while true; do
    sleep $KODI_UPDATE_INTERVAL
    su kodi -c "$KODI_WORKDIR/EventClients/Clients/Kodi\ Send/kodi-send.py --action='UpdateLibrary(video)'" > /dev/null
    su kodi -c "$KODI_WORKDIR/EventClients/Clients/Kodi\ Send/kodi-send.py --action='UpdateLibrary(music)'" > /dev/null
  done
}

function clean_library_job {
  while true; do
    sleep $KODI_CLEAN_INTERVAL
    su kodi -c "$KODI_WORKDIR/EventClients/Clients/Kodi\ Send/kodi-send.py --action='CleanLibrary(video)'" > /dev/null
    su kodi -c "$KODI_WORKDIR/EventClients/Clients/Kodi\ Send/kodi-send.py --action='CleanLibrary(music)'" > /dev/null
  done
}

update_library_job &
echo "Automatic library update: YES (${KODI_UPDATE_INTERVAL}s)"

if [[ $KODI_CLEAN == "yes" ]] || [[ $KODI_CLEAN == "true" ]]; then
  if [ -e $KODI_WORKDIR/.kodi/userdata/sources.xml ]; then
    echo "Automatic library cleaning: YES (${KODI_CLEAN_INTERVAL}s)"
    clean_library_job &
  else
    echo "Automatic library cleaning: NO (sources.xml not found)"
  fi
else
  echo "Automatic library cleaning: NO"
fi
if [[ $DEBUG == "yes" ]] || [[ $DEBUG == "true" ]]; then
  echo "Debug: YES"
fi

echo "======================================================="

if [[ $DEBUG == "yes" ]] || [[ $DEBUG == "true" ]]; then
  sleep 5 && tail -f -n100 $KODI_WORKDIR/.kodi/temp/kodi.log &
else
  sleep 5 && tail -f -n100 $KODI_WORKDIR/.kodi/temp/kodi.log | grep -v "NOTICE:" &
fi
su kodi -c "$KODI_WORKDIR/bin/kodi --headless"
