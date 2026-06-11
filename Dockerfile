FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git sudo wget unzip nginx \
    openjdk-17-jdk python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir gradio requests duckduckgo_search beautifulsoup4 uvicorn fastapi

RUN mkdir -p /opt/android-sdk && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline.zip && \
    unzip -q /tmp/cmdline.zip -d /opt/android-sdk && \
    rm /tmp/cmdline.zip && \
    mkdir -p /opt/android-sdk/cmdline-tools/latest && \
    mv /opt/android-sdk/cmdline-tools/* /opt/android-sdk/cmdline-tools/latest/ && \
    yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android-sdk \
        "platform-tools" "build-tools;36.0.0" "platforms;android-36" && \
    rm -rf /var/lib/apt/lists/*

ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/36.0.0:$JAVA_HOME/bin:/home/user/.local/bin:$PATH

RUN curl -fsSL https://code-server.dev/install.sh | sh
RUN useradd -m -u 1000 user
RUN echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY nginx.conf /etc/nginx/sites-available/default
COPY start.sh /start.sh
RUN chmod +x /start.sh

USER user
ENV HOME=/home/user
WORKDIR $HOME/app
CMD ["/start.sh"]
