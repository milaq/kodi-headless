FROM ubuntu:18.04
MAINTAINER milaq
LABEL build_version="Build-date:- ${BUILD_DATE}"
ARG KODI_VERSION="18.1"

ARG DEBIAN_FRONTEND="noninteractive"
COPY dpkg_excludes /etc/dpkg/dpkg.cfg.d/excludes

RUN apt-get update && \
  apt-get install --no-install-recommends -y software-properties-common && \
  add-apt-repository -y ppa:team-xbmc/ppa

RUN apt-get update && \
  apt-get install --no-install-recommends -y \
  xpra \
  pulseaudio \
  kodi=2:$KODI_VERSION\* \
  kodi-eventclients-kodi-send=2:$KODI_VERSION\* \
  && \
  apt-get clean

RUN mkdir /var/cache/samba
RUN mkdir -p /config/userdata
COPY advancedsettings.xml.default /usr/local/share/kodi/advancedsettings.xml.default
COPY smb.conf /config/.smb/user.conf
COPY kodi_init /sbin/kodi_init
RUN useradd -m -u 10000 kodi
RUN chown kodi. -R /config
RUN ln -s /config /usr/share/kodi/portable_data

VOLUME /config
WORKDIR /config
EXPOSE 8080 9090 9777/udp
CMD ["/sbin/kodi_init"]
