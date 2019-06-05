FROM debian:stretch as buildstage

ARG KODI_NAME="Leia"
ARG KODI_VERSION="18.2"

ARG DEBIAN_FRONTEND="noninteractive"
COPY dpkg_excludes /etc/dpkg/dpkg.cfg.d/excludes

RUN apt-get update && apt-get install --no-install-recommends -y \
  ant \
  git-core \
  build-essential \
  autoconf \
  automake \
  cmake \
  pkg-config \
  autopoint \
  libtool \
  swig \
  doxygen \
  default-jdk-headless \
  libbz2-dev \
  liblzo2-dev \
  libtinyxml-dev \
  libmariadbclient-dev-compat \
  libcurl4-openssl-dev \
  libssl-dev \
  libyajl-dev \
  libxml2-dev \
  libxslt-dev \
  libsqlite3-dev \
  libnfs-dev \
  libpcre3-dev \
  libtag1-dev \
  libsmbclient-dev \
  libmicrohttpd-dev \
  libgnutls28-dev \
  libass-dev \
  libxrandr-dev \
  libegl1-mesa-dev \
  libgif-dev \
  libjpeg-dev \
  libglu1-mesa-dev \
  gawk \
  gperf \
  curl \
  m4 \
  python-dev \
  uuid-dev \
  yasm \
  unzip \
  libiso9660-dev \
  libfstrcmp-dev \
  zip

COPY kodi-headless.patch /tmp/kodi-headless.patch

RUN mkdir -p /tmp/kodi_src && \
  curl -o /tmp/kodi.tar.gz -L "https://github.com/xbmc/xbmc/archive/${KODI_VERSION}-${KODI_NAME}.tar.gz" && \
  tar xf /tmp/kodi.tar.gz -C /tmp/kodi_src --strip-components=1 && \
  cd /tmp/kodi_src && \
  git apply /tmp/kodi-headless.patch

RUN mkdir /tmp/kodi_src/build && cd /tmp/kodi_src/build && \
  cmake ../ \
  -DCMAKE_INSTALL_LIBDIR=/usr/lib \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DENABLE_INTERNAL_FLATBUFFERS=ON \
  -DENABLE_INTERNAL_FMT=ON \
  -DENABLE_INTERNAL_RapidJSON=ON \
  -DENABLE_SMBCLIENT=ON \
  -DENABLE_MYSQLCLIENT=ON \
  -DENABLE_NFS=ON \
  -DENABLE_UPNP=ON \
  -DENABLE_LCMS2=OFF \
  -DENABLE_AIRTUNES=OFF \
  -DENABLE_CAP=OFF \
  -DENABLE_DVDCSS=OFF \
  -DENABLE_LIBUSB=OFF \
  -DENABLE_EVENTCLIENTS=OFF \
  -DENABLE_OPTICAL=OFF \
  -DENABLE_CEC=OFF \
  -DENABLE_BLURAY=OFF \
  -DENABLE_BLUETOOTH=OFF \
  -DENABLE_PULSEAUDIO=OFF \
  -DENABLE_AVAHI=OFF \
  -DENABLE_ALSA=OFF \
  -DENABLE_DBUS=OFF \
  -DENABLE_UDEV=OFF \
  -DENABLE_VAAPI=OFF \
  -DENABLE_VDPAU=OFF \
  -DENABLE_GLX=OFF \
  -DENABLE_SNDIO=OFF \
  -DENABLE_LIRCCLIENT=OFF \
  && \
  make -j$(nproc --all) && \
  make DESTDIR=/tmp/kodi_build install

RUN cp /tmp/kodi_src/tools/EventClients/Clients/KodiSend/kodi-send.py /tmp/kodi_build/usr/bin/kodi-send && \
  mkdir -p /tmp/kodi_build/usr/lib/python2.7/ && cp /tmp/kodi_src/tools/EventClients/lib/python/xbmcclient.py /tmp/kodi_build/usr/lib/python2.7/xbmcclient.py


FROM debian:stretch

MAINTAINER milaq
LABEL build_version="Build-date:- ${BUILD_DATE}"

COPY --from=buildstage /tmp/kodi_build/usr/ /usr/

ARG DEBIAN_FRONTEND="noninteractive"
COPY dpkg_excludes /etc/dpkg/dpkg.cfg.d/excludes

RUN apt-get update && apt-get install --no-install-recommends -y \
  libcurl3 \
  libegl1-mesa \
  libglu1-mesa \
  libfreetype6 \
  libfribidi0 \
  libglew2.0 \
  liblzo2-2 \
  libmicrohttpd12 \
  libmariadbclient18 \
  libnfs8 \
  libpcrecpp0v5 \
  libpython2.7 \
  libsmbclient \
  libtag1v5 \
  libtinyxml2.6.2v5 \
  libxml2 \
  libcdio13 \
  libxcb-shape0 \
  libxrandr2 \
  libxslt1.1 \
  libyajl2 \
  libass5 \
  libiso9660-8 \
  libfstrcmp0 \
  ca-certificates \
  && \
  apt-get clean

RUN mkdir /var/cache/samba
RUN mkdir -p /config/userdata
COPY advancedsettings.xml.default /usr/local/share/kodi/advancedsettings.xml.default
COPY smb.conf /config/.smb/user.conf
COPY kodi_init /sbin/kodi_init

RUN useradd -m -u 10000 kodi && \
    chown kodi. -R /config && \
    ln -s /config /usr/share/kodi/portable_data

VOLUME /config
WORKDIR /config
EXPOSE 8080 9090 9777/udp
CMD ["/sbin/kodi_init"]
