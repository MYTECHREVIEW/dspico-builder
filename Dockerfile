FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    python3 \
    unzip \
    zip \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 9.0 SDK
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-9.0 \
    && rm -rf /var/lib/apt/lists/*

# Install BlocksDS
RUN mkdir -p /opt/blocksds \
    && wget https://github.com/blocksds/sdk/releases/download/v1.7.0/blocksds-linux-x64.zip -O blocksds.zip \
    && unzip blocksds.zip -d /opt/blocksds \
    && rm blocksds.zip
ENV BLOCKSDS=/opt/blocksds

# Setup build directory
WORKDIR /build

# Copy build script
COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh

# Environment variables for Pico SDK (will be set during build)
ENV PICO_SDK_PATH=/build/dspico-firmware/pico-sdk

# Default command
CMD ["/build/build.sh"]
