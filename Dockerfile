FROM ubuntu:22.04

# 1. Install System Dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    cmake \
    python3 \
    unzip \
    libarchive-tools \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 2. Install .NET 9.0 SDK (Required for PicoLoaderConverter)
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 9.0 --install-dir /usr/local/bin/dotnet \
    && ln -s /usr/local/bin/dotnet/dotnet /usr/bin/dotnet

# 3. Install Wonderful Toolchain & BlocksDS
RUN wget -qO- https://wonderful.asie.pl/key.gpg | gpg --dearmor > /usr/share/keyrings/wonderful.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wonderful.gpg] https://wonderful.asie.pl/apt generic main" > /etc/apt/sources.list.d/wonderful.list \
    && apt-get update \
    && apt-get install -y wonderful-toolchain \
    && export PATH=/opt/wonderful/bin:$PATH \
    && wf-pacman -Syu --noconfirm \
    && wf-tools repo enable blocksds \
    && wf-pacman -Syu --noconfirm \
    && wf-pacman -S --noconfirm blocksds-toolchain

# 4. Set Environment Variables
ENV PATH="/usr/bin/dotnet:/opt/wonderful/bin:/opt/wonderful/toolchain/gcc-arm-none-eabi/bin:${PATH}"
ENV BLOCKSDATA=/opt/wonderful/thirdparty/blocksds/core
ENV BLOCKSDS=/opt/wonderful/thirdparty/blocksds/core

# 5. Setup Build Directory
WORKDIR /build

# 6. Default command is to run the build script
CMD ["/bin/bash", "/build/build.sh"]
