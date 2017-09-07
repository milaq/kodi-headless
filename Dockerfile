FROM debian:jessie
MAINTAINER milaq

ARG KODI_NAME="Krypton"
ARG KODI_VER="17.4"
ENV KODI_WORKDIR=/opt/kodi-headless

ARG BUILD_DATE
ARG VERSION
LABEL build_version="Build-date:- ${BUILD_DATE}"
ARG DEBIAN_FRONTEND="noninteractive"

ARG BUILD_DEPENDENCIES="\
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
  openjdk-7-jre-headless \
  default-jdk \
  libbz2-dev \
  liblzo2-dev \
  libtinyxml-dev \
  libmysqlclient-dev \
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
  zip \
  "

ARG RUNTIME_DEPENDENCIES="\
  libcurl3 \
  libegl1-mesa \
  libglu1-mesa \
  libfreetype6 \
  libfribidi0 \
  libglew1.10 \
  liblzo2-2 \
  libmicrohttpd10 \
  libmysqlclient18 \
  libnfs4 \
  libpcrecpp0 \
  libpython2.7 \
  libsmbclient \
  libtag1c2a \
  libtinyxml2.6.2 \
  libxml2 \
  libxrandr2 \
  libxslt1.1 \
  libyajl2 \
  "

COPY kodi-headless.patch /tmp/kodi-headless.patch
COPY advancedsettings.xml.default $KODI_WORKDIR/.kodi/userdata/advancedsettings.xml.default
COPY kodi_init.sh /sbin/kodi_init.sh

RUN \
  apt-get update && \
  apt-get install --no-install-recommends -y $BUILD_DEPENDENCIES && \

  mkdir -p /tmp/kodi_src && \
  curl -o /tmp/kodi.tar.gz -L "https://github.com/xbmc/xbmc/archive/${KODI_VER}-${KODI_NAME}.tar.gz" && \
  tar xf /tmp/kodi.tar.gz -C /tmp/kodi_src --strip-components=1 && \
  cd /tmp/kodi_src && \
  git apply /tmp/kodi-headless.patch && \
  make -C tools/depends/target/crossguid PREFIX=/usr && \
  ./bootstrap && \
  ./configure \
    --build=$CBUILD \
    --disable-airplay \
    --disable-airtunes \
    --disable-alsa \
    --disable-avahi \
    --disable-dbus \
    --disable-debug \
    --disable-lcms2 \
    --disable-libbluetooth \
    --disable-libcap \
    --disable-lirc \
    --disable-libcec \
    --disable-libusb \
    --disable-non-free \
    --disable-openmax \
    --disable-optical-drive \
    --disable-pulse \
    --disable-udev \
    --disable-vaapi \
    --disable-vdpau \
    --disable-libbluray \
    --disable-gtest \
    --disable-ssh \
    --enable-nfs \
    --enable-static=no \
    --enable-upnp \
    --host=$CHOST \
    --prefix=$KODI_WORKDIR \
    && \
  make -j$(nproc --all) && \
  make install && \
  cp -r tools/EventClients/ $KODI_WORKDIR/ && \

  apt-get purge --auto-remove -y $BUILD_DEPENDENCIES && \
  apt-get install --no-install-recommends -y $RUNTIME_DEPENDENCIES && \
  apt-get clean && \
  rm -rf /tmp/kodi* && \

  useradd -d $KODI_WORKDIR kodi && \
  chown kodi. -R $KODI_WORKDIR

VOLUME $KODI_WORKDIR/.kodi
EXPOSE 8080 9090 9777/udp
WORKDIR $KODI_WORKDIR
ENTRYPOINT ["/sbin/kodi_init.sh"]
