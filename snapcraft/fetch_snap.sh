#!/bin/bash

SNAP=$1
URL=$(curl -s -H 'Snap-Device-Series: 16' http://api.snapcraft.io/v2/snaps/info/$SNAP | jq '."channel-map" | map(select(.channel.architecture == "riscv64" and .channel.name == "stable")) | .[0].download.url')
URL=$(echo $URL | sed "s/\"//g")
curl -L --output $SNAP.snap $URL
