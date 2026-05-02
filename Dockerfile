# Use the official BlocksDS slim image as it contains the full DS toolchain
FROM skylyrac/blocksds:slim-latest

# 1. Install System Dependencies
# Note: skylyrac/blocksds is based on Ubuntu
USER root
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    cmake \
    python3 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install .NET 9.0 SDK (Required for PicoLoaderConverter)
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 9.0 --install-dir /usr/local/bin/dotnet \
    && ln -s /usr/local/bin/dotnet/dotnet /usr/bin/dotnet

# 3. Environment variables for BlocksDS are already set in the base image, 
# but we ensure the .NET path is added.
ENV PATH="/usr/bin/dotnet:${PATH}"

# 4. Setup Build Directory
WORKDIR /build
COPY . .
RUN chmod +x build.sh

# 5. Default command is to run the build script
CMD ["/bin/bash", "/build/build.sh"]
