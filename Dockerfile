FROM debian:stretch as buildstage

ARG KODI_NAME="Krypton"
ARG KODI_VER="17.6"
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
  openjdk-8-jre-headless \
  default-jdk \
  libbz2-dev \
  liblzo2-dev \
  libtinyxml-dev \
  libmariadbclient-dev \
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
  zip

COPY kodi-headless.patch /tmp/kodi-headless.patch
RUN mkdir -p /tmp/kodi_src && \
  curl -o /tmp/kodi.tar.gz -L "https://github.com/xbmc/xbmc/archive/${KODI_VER}-${KODI_NAME}.tar.gz" && \
  tar xf /tmp/kodi.tar.gz -C /tmp/kodi_src --strip-components=1 && \
  cd /tmp/kodi_src && \
  git apply /tmp/kodi-headless.patch

RUN mkdir /tmp/kodi_src/build && cd /tmp/kodi_src/build && \
  cmake ../project/cmake/ \
  -DCMAKE_INSTALL_LIBDIR=/usr/lib \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DENABLE_SMBCLIENT=ON \
  -DENABLE_MYSQLCLIENT=ON \
  -DENABLE_NFS=ON \
  -DENABLE_UPNP=ON \
  -DENABLE_LCMS2=OFF \
  -DENABLE_AIRTUNES=OFF \
  -DENABLE_CAP=OFF \
  -DENABLE_DVDCSS=OFF \
  -DENABLE_LIBUSB=OFF \
  -DENABLE_LIRC=OFF \
  -DENABLE_EVENTCLIENTS=OFF \
  -DENABLE_NONFREE=OFF \
  -DENABLE_OPTICAL=OFF \
  -DENABLE_CEC=OFF \
  -DENABLE_BLURAY=OFF \
  -DENABLE_BLUETOOTH=OFF \
  -DENABLE_PULSEAUDIO=OFF \
  -DENABLE_AVAHI=OFF \
  -DENABLE_ALSA=OFF \
  -DENABLE_DBUS=OFF \
  -DENABLE_SDL=OFF \
  -DENABLE_SSH=OFF \
  -DENABLE_UDEV=OFF \
  -DENABLE_VAAPI=OFF \
  -DENABLE_VDPAU=OFF \
  && \
  make -j$(nproc --all) && \
  make DESTDIR=/tmp/kodi_build install

RUN cp /tmp/kodi_src/tools/EventClients/Clients/Kodi\ Send/kodi-send.py /tmp/kodi_build/usr/bin/kodi-send && \
  mkdir -p /tmp/kodi_build/usr/lib/python2.7/ && cp /tmp/kodi_src/tools/EventClients/lib/python/xbmcclient.py /tmp/kodi_build/usr/lib/python2.7/xbmcclient.py


FROM debian:stretch

MAINTAINER milaq
LABEL build_version="Build-date:- ${BUILD_DATE}"
ARG BUILD_DATE
ARG VERSION
ARG DEBIAN_FRONTEND="noninteractive"

COPY --from=buildstage /tmp/kodi_build/usr/ /usr/

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
  && \
  apt-get clean

COPY advancedsettings.xml.default /config/.kodi/userdata/advancedsettings.xml.default
COPY smb.conf /config/.kodi/.smb/user.conf
COPY kodi_init /sbin/kodi_init

RUN useradd -d /config -u 12000 kodi && \
    chown kodi. -R /config

VOLUME /config
WORKDIR /config/.kodi
EXPOSE 8080 9090 9777/udp
CMD ["/sbin/kodi_init"]
