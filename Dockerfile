FROM debian:buster as buildstage

#ARG KODI_NAME="Leia"
#ARG KODI_VERSION="18.8"
ARG KODI_NAME="Matrix"
ARG KODI_VERSION="19.0a2"

ARG DEBIAN_FRONTEND="noninteractive"
COPY dpkg_excludes /etc/dpkg/dpkg.cfg.d/excludes

RUN echo "deb http://deb.debian.org/debian buster-backports main non-free" > /etc/apt/sources.list.d/backports.list && \
    echo "Package: *\nPin: release a=buster-backports\nPin-Priority: 500\n"  > /etc/apt/preferences.d/99debian-backports && \
    apt-get update && apt-get install --no-install-recommends -y \
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
  libfmt-dev \
  libspdlog-dev \
  libgtest-dev \
  libunistring-dev \
  gawk \
  gperf \
  curl \
  m4 \
  python3-dev \
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
  -DX11_RENDER_SYSTEM=gl \
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


FROM debian:buster

MAINTAINER milaq
LABEL build_version="Build-date:- ${BUILD_DATE}"

COPY --from=buildstage /tmp/kodi_build/usr/ /usr/

ARG DEBIAN_FRONTEND="noninteractive"
COPY dpkg_excludes /etc/dpkg/dpkg.cfg.d/excludes

RUN echo "deb http://deb.debian.org/debian buster-backports main non-free" > /etc/apt/sources.list.d/backports.list && \
    echo "Package: *\nPin: release a=buster-backports\nPin-Priority: 500\n"  > /etc/apt/preferences.d/99debian-backports && \
    apt-get update && apt-get install --no-install-recommends -y \
  libcurl4 \
  libegl1-mesa \
  libglu1-mesa \
  libfreetype6 \
  libfribidi0 \
  libglew2.1 \
  liblzo2-2 \
  libmicrohttpd12 \
  libmariadb3 \
  libnfs12 \
  libpcrecpp0v5 \
  libpython3.7 \
  libsmbclient \
  libtag1v5 \
  libtinyxml2.6.2v5 \
  libxml2 \
  libcdio18 \
  libxcb-shape0 \
  libxrandr2 \
  libxslt1.1 \
  libyajl2 \
  libass9 \
  libiso9660-11 \
  libfstrcmp0 \
  libspdlog1 \
  libatomic1 \
  libunistring2 \
  ca-certificates \
  xmlstarlet \
  && \
  apt-get clean

RUN mkdir /var/cache/samba && \
    mkdir /usr/lib/kodi/addons && \
    mkdir -p /config/userdata && \
    useradd -m -u 10000 kodi && \
    chown kodi. -R /config && \
    ln -s /config /usr/share/kodi/portable_data

COPY advancedsettings.xml.default guisettings.xml.default smb.conf /usr/local/share/kodi/
COPY kodi_init /sbin/kodi_init

VOLUME /config
WORKDIR /config
EXPOSE 8080 9090 9777/udp
CMD ["/sbin/kodi_init"]
