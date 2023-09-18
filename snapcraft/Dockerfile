ARG RISK=edge
ARG UBUNTU=jammy

FROM riscv64/ubuntu:$UBUNTU as builder
ARG RISK
ARG UBUNTU
RUN echo "Building snapcraft:$RISK in ubuntu:$UBUNTU"

# Grab dependencies
RUN apt-get update
RUN apt-get dist-upgrade --yes
RUN apt-get install --yes \
      curl \
      jq \
      squashfs-tools

COPY fetch_snap.sh /bin/fetch_snap.sh

# Grab the core20 snap (which snapcraft uses as a base) from the stable channel
# and unpack it in the proper place.
RUN bash /bin/fetch_snap.sh core20
RUN mkdir -p /snap/core20
RUN unsquashfs -d /snap/core20/current core20.snap

# Grab the core22 snap (which snapcraft uses as a base) from the stable channel
# and unpack it in the proper place.
RUN bash /bin/fetch_snap.sh core22
RUN mkdir -p /snap/core22
RUN unsquashfs -d /snap/core22/current core22.snap

# Grab the snapcraft snap from the $RISK channel and unpack it in the proper
# place.
RUN bash /bin/fetch_snap.sh snapcraft
RUN mkdir -p /snap/snapcraft
RUN unsquashfs -d /snap/snapcraft/current snapcraft.snap

# Fix Python3 installation: Make sure we use the interpreter from
# the snapcraft snap:
RUN unlink /snap/snapcraft/current/usr/bin/python3
RUN ln -s /snap/snapcraft/current/usr/bin/python3.* /snap/snapcraft/current/usr/bin/python3
RUN echo /snap/snapcraft/current/lib/python3.*/site-packages >> /snap/snapcraft/current/usr/lib/python3/dist-packages/site-packages.pth

# Create a snapcraft runner (TODO: move version detection to the core of
# snapcraft).
RUN mkdir -p /snap/bin
RUN echo "#!/bin/sh" > /snap/bin/snapcraft
RUN snap_version="$(awk '/^version:/{print $2}' /snap/snapcraft/current/meta/snap.yaml | tr -d \')" && echo "export SNAP_VERSION=\"$snap_version\"" >> /snap/bin/snapcraft
RUN echo 'exec "$SNAP/usr/bin/python3" "$SNAP/bin/snapcraft" "$@"' >> /snap/bin/snapcraft
RUN chmod +x /snap/bin/snapcraft

# Multi-stage build, only need the snaps from the builder. Copy them one at a
# time so they can be cached.
FROM riscv64/ubuntu:$UBUNTU
COPY --from=builder /snap/core20 /snap/core20
COPY --from=builder /snap/core22 /snap/core22
COPY --from=builder /snap/snapcraft /snap/snapcraft
COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# Generate locale and install dependencies.
RUN apt-get update && apt-get dist-upgrade --yes && apt-get install --yes snapd sudo locales strace busybox iproute2 iptables curl wget nano net-tools && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    (cd /snap/snapcraft/current/usr/lib/python3.8 && /snap/snapcraft/current/usr/bin/python3.8 -m compileall . || true) && \
    (cd /snap/snapcraft/current/lib/python3.8/site-packages && /snap/snapcraft/current/usr/bin/python3.8 -m compileall . || true) && \
    (cd /snap/snapcraft/current/lib/python3.8/dist-packages && /snap/snapcraft/current/usr/bin/python3.8 -m compileall . || true) && \
    (cd /snap/snapcraft/current/bin && /snap/snapcraft/current/usr/bin/python3.8 -m compileall snapcraft)

RUN mkdir /etc/udhcpc
COPY udhcpc.conf /etc/udhcpc/default.script
RUN chmod a+x /etc/udhcpc/default.script

# Set the proper environment.
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/bin:/snap/snapcraft/current/usr/bin:$PATH"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_ARCH="riscv64"

