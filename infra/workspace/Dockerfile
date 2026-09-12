# Image for one user workspace container (§0B): Flutter + Android SDK + Chromium + AI CLIs.
FROM ubuntu:24.04

ARG FLUTTER_VERSION=3.38.9
ARG ANDROID_CMDLINE_TOOLS=13114758
ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/opt/flutter \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    CHROME_EXECUTABLE=/usr/bin/chromium \
    PUB_CACHE=/home/dev/.pub-cache
ENV PATH=$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip procps openjdk-17-jdk-headless \
      chromium libglu1-mesa \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Non-root user uid 1000 (ubuntu:24.04 ships "ubuntu" with uid 1000 — replace it).
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -u 1000 -s /bin/bash dev \
    && mkdir -p /workspace $FLUTTER_HOME $ANDROID_SDK_ROOT \
    && chown -R dev:dev /workspace $FLUTTER_HOME $ANDROID_SDK_ROOT

RUN npm install -g @anthropic-ai/claude-code @openai/codex @google/gemini-cli

USER dev
RUN git clone --depth 1 --branch $FLUTTER_VERSION https://github.com/flutter/flutter.git $FLUTTER_HOME \
    && flutter config --no-analytics --enable-web --no-enable-linux-desktop \
    && flutter precache --web --android

RUN curl -fsSL -o /tmp/tools.zip https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip \
    && mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && unzip -q /tmp/tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
    && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
    && rm /tmp/tools.zip \
    && yes | sdkmanager --licenses >/dev/null \
    && sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0" \
    && flutter doctor -v || true

WORKDIR /workspace
CMD ["sleep", "infinity"]
