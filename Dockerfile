FROM ubuntu:16.04

# Install Tizen Studio specific packages
RUN \
    apt-get update \
    && apt-get install -y \
    wget \
    curl \
    zip \
    apt-utils \
    software-properties-common \
    python2.7 \
    libpython2.7 \
    gnome-keyring \
    ca-certificates \
    locales \
    build-essential \
    pciutils \
    gettext \
    git \
    acl \
    openvpn \
    ruby-full \
    rpm2cpio \
    bridge-utils \
    xdg-utils \
    xmlstarlet \
    gtk2.0 \
    zlib1g \
    libwebkitgtk-1.0-0 \
    libglib2.0-0 \
    libcurl3-gnutls \
    libsdl1.2debian \
    libpixman-1-0 \
    libfontconfig1 \
    libjpeg-turbo8 \
    libpng12-0 \
    libsm6 \
    libv4l-0 \
    libx11-xcb1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xfixes0 \
    libxi6 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /etc/apt/sources.list.d/*

# Python alias
RUN echo "alias python=python2.7" >> /home/build/.bash_aliases
RUN ln -s /usr/bin/python2.7 /usr/bin/python

# Install Oracle java 8
#RUN \
#    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list \
#    && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list \
#    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 \
#    && apt-get update
#RUN \
#    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections \
#    && echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections \
#    && DEBIAN_FRONTEND=noninteractive  apt-get install -y --force-yes oracle-java8-installer oracle-java8-set-default
#RUN \
#    rm -rf /var/cache/oracle-jdk8-installer \
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/*
#ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Install Java
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections \
  && add-apt-repository -y ppa:webupd8team/java \
  && apt-get update \
  && apt-get install -y oracle-java8-installer \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /var/cache/oracle-jdk8-installer

# Setup timezone
ENV TZ 'Asia/Seoul'
RUN \
    echo $TZ > /etc/timezone \
    && rm /etc/localtime \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

# Set encoding
ENV LANG="en_US.UTF-8"
RUN locale-gen en_US.UTF-8 \
    && echo $'LANG="en_US.UTF-8" \n\
LC_NUMERIC="en_US.UTF-8" \n\
LC_TIME="en_US.UTF-8" \n\
LC_MONETARY="en_US.UTF-8" \n\
LC_PAPER="en_US.UTF-8" \n\
LC_NAME="en_US.UTF-8" \n\
LC_ADDRESS="en_US.UTF-8" \n\
LC_TELEPHONE="en_US.UTF-8" \n\
LC_MEASUREMENT="en_US.UTF-8" \n\
LC_IDENTIFICATION="en_US.UTF-8"' >> /etc/default/locale \
    && echo $'LANG=en_US.UTF-8 \n\
LANGUAGE=en_US:en \n\
LC_ALL=en_US.UTF-8' >> /etc/environment

# Add a user
ARG user=build
ARG group=build
ARG uid=9671
ARG gid=9671
ENV HOME /home/${user}
RUN \
    groupadd -g ${gid} ${group} \
    && useradd -d "$HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    &&usermod -aG sudo ${user} \
    && mkdir /share

USER ${user}
WORKDIR ${HOME}

# Install Tizen Studio
ENV SDK_URL="http://download.tizen.org/sdk/Installer/tizen-studio_3.7/web-cli_Tizen_Studio_3.7_ubuntu-64.bin" \
    INSTALL_PATH="${HOME}/tizen-studio"
RUN export DISPLAY=:0 \
    && wget -q ${SDK_URL} \
    && chmod +x ./web-cli_Tizen_Studio*.bin \
    && ./web-cli_Tizen_Studio_*.bin --accept-license ${INSTALL_PATH} \
    && rm -rf ./web-cli_Tizen_Studio_*.bin

# Install sdk-build
RUN \
    git clone git://git.tizen.org/sdk/tools/sdk-build -b tizen


# Set PATH
ENV PATH $PATH:$INSTALL_PATH/tools/ide/bin/:$INSTALL_PATH/package-manager/:$HOME/sdk-build/

CMD ["/bin/bash"]
