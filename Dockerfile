FROM ubuntu:18.04

ARG STUDIO_VERSION
ARG TIZEN_VERSION 

RUN cp /etc/profile /root/.profile

# Install Tizen Studio specific packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl locales build-essential sudo git ruby-full gettext wget pciutils zip python2.7 \
    libwebkitgtk-1.0-0 cpio rpm2cpio gnome-keyring \
    acl bridge-utils openvpn libfontconfig1 libglib2.0-0 libjpeg-turbo8 libpixman-1-0 \
    libsdl1.2debian libsm6 libv4l-0 libx11-xcb1 libxcb-icccm4 libxcb-image0 libxcb-randr0 \
    libxcb-render-util0 libxcb-shape0 libxcb-xfixes0 libxi6 \
    libpython2.7 tzdata

# Install libpng12-0
RUN \
    wget -qq http://launchpadlibrarian.net/377985746/libpng12-0_1.2.54-1ubuntu1.1_amd64.deb \
    && dpkg -i libpng12-0*.deb \
    && rm libpng12-0*.deb

# Install Oracle java 8
RUN \
    wget -qq https://download.java.net/java/GA/jdk12.0.2/e482c34c86bd4bf8b56c0b35558996b9/10/GPL/openjdk-12.0.2_linux-x64_bin.tar.gz \
    && mkdir -p /usr/java \
    && tar -xzf ./openjdk-12*.tar.gz -C /usr/java/ \
    && rm ./openjdk-12*.tar.gz || true \
    && update-alternatives --install "/usr/bin/java" "java" "/usr/java/jdk-12.0.2/bin/java" 1 \
    && update-alternatives --install "/usr/bin/javac" "javac" "/usr/java/jdk-12.0.2/bin/javac" 1

RUN echo $'JAVA_HOME=/usr/java/jdk-12.0.2 \n\
PATH=$PATH:$HOME/bin:$JAVA_HOME/bin \n\
export JAVA_HOME \n\
export JRE_HOME \n\
export PATH' >> /etc/profile
ENV JAVA_HOME=/usr/java/jdk-12.0.2
ENV PATH $PATH:$JAVA_HOME/bin

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

# Python alias
RUN echo "alias python=python2.7" >> ${HOME}.bash_aliases
RUN ln -s /usr/bin/python2.7 /usr/bin/python

USER ${user}
WORKDIR ${HOME}

# Install Tizen Studio
ENV \
    SDK_URL="http://download.tizen.org/sdk/Installer/tizen-studio_${STUDIO_VERSION}/web-cli_Tizen_Studio_${STUDIO_VERSION}_ubuntu-64.bin" \
    INSTALL_PATH="${HOME}/tizen-studio"
RUN export DISPLAY=:0 \
    && wget ${SDK_URL} \
    chmod +x ./web-cli_Tizen_Studio*.bin \
    && ./web-cli_Tizen_Studio_*.bin --accept-license ${INSTALL_PATH} \
    && rm -rf ./web-cli_Tizen_Studio_*.bin

# Update Tizen Studio
ENV \
    REPOSITORY="http://download.tizen.org/sdk/tizenstudio" \
    DISTRIBUTION="official" \
    SNAPSHOT="Tizen_Studio_${STUDIO_VERSION}"
RUN \
    ${INSTALL_PATH}/package-manager/package-manager-cli.bin \
    -r ${REPOSITORY} \
    -d ${DISTRIBUTION} \
    -s ${SNAPSHOT} \
    install WebCLI NativeCLI \
        NativeToolchain-Gcc-6.2 \
        NativeToolchain-Gcc-9.2 \
        MOBILE-${TIZEN_VERSION}-NativeAppDevelopment-CLI \
        WEARABLE-${TIZEN_VERSION}-NativeAppDevelopment-CLI \
    --remove-installed-sdk --accept-license

# Install sdk-build and security signer
RUN \
    git clone git://git.tizen.org/sdk/tools/sdk-build -b tizen \
    && git clone git://git.tizen.org/platform/core/security/hash-signer -b tizen

# Set PATH
ENV PATH $PATH:$INSTALL_PATH/tools/ide/bin/:$INSTALL_PATH/package-manager/:$HOME/sdk-build/

