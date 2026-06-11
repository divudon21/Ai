FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Base tools + Android SDK dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    wget \
    unzip \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Android SDK install (yeh Docker image mein baked rahega, refresh par nahi udega)
RUN mkdir -p /opt/android-sdk && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline.zip && \
    unzip -q /tmp/cmdline.zip -d /opt/android-sdk && \
    rm /tmp/cmdline.zip && \
    mkdir -p /opt/android-sdk/cmdline-tools/latest && \
    mv /opt/android-sdk/cmdline-tools/* /opt/android-sdk/cmdline-tools/latest/ && \
    yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android-sdk \
        "platform-tools" \
        "build-tools;36.0.0" \
        "platforms;android-36" && \
    rm -rf /var/lib/apt/lists/*

ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/36.0.0:$JAVA_HOME/bin:$PATH

# Code-server install
RUN curl -fsSL https://code-server.dev/install.sh | sh

# HF user create
RUN useradd -m -u 1000 user
RUN echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER user
ENV HOME=/home/user
ENV PATH=/home/user/.local/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/36.0.0:/usr/lib/jvm/java-17-openjdk-amd64/bin:$PATH

WORKDIR $HOME/app

CMD ["code-server", "--bind-addr", "0.0.0.0:7860", "--auth", "none", "."]
