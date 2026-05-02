#!/bin/bash
set -e

echo "--- Starting DS Pico Full Toolchain Build Process ---"

# 1. Clone or Update Repositories
REPOS=("pico-loader" "pico-launcher" "dspico-firmware")

for repo in "${REPOS[@]}"; do
    if [ ! -d "/build/$repo" ]; then
        echo "Cloning $repo..."
        git clone --recursive https://github.com/LNH-team/$repo.git /build/$repo
    else
        echo "Updating $repo..."
        cd /build/$repo
        git pull
        git submodule update --init --recursive
    fi
done

# 2. Build pico-loader (The backend engine)
echo "Building pico-loader..."
cd /build/pico-loader
make -j$(nproc)

# 3. Build pico-launcher (The frontend UI)
echo "Building pico-launcher..."
cd /build/pico-launcher
make -j$(nproc)

# 4. Prepare dspico-firmware (The Pico-side firmware)
echo "Preparing dspico-firmware..."
cd /build/dspico-firmware
mkdir -p roms
mkdir -p data

# A. Determine which ROM to use for the firmware
# Priority: User provided default.nds > Freshly built LAUNCHER.nds
if [ -f "/roms/default.nds" ]; then
    echo "Using USER provided default.nds"
    cp /roms/default.nds /build/dspico-firmware/roms/default.nds
elif [ -f "/build/pico-launcher/LAUNCHER.nds" ]; then
    echo "Using freshly built LAUNCHER.nds as the default ROM"
    cp /build/pico-launcher/LAUNCHER.nds /build/dspico-firmware/roms/default.nds
else
    echo "ERROR: No ROM found to embed in the firmware!"
    exit 1
fi

# B. Include Optional BIOS/Files if present in /roms mount
if [ -f "/roms/biosnds7.rom" ]; then
    echo "Including biosnds7.rom for DSiWare support"
    cp /roms/biosnds7.rom /build/dspico-firmware/roms/biosnds7.rom
fi

if [ -f "/roms/uartBufv060.bin" ]; then
    echo "Including uartBufv060.bin (WRFUxxed enabled)"
    cp /roms/uartBufv060.bin /build/dspico-firmware/data/uartBufv060.bin
fi

# 5. Build dspico-firmware
echo "Compiling DSpico.uf2..."
git submodule update --init pico-sdk
cd pico-sdk && git submodule update --init && cd ..

mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)

# 6. Export Finished Files to /output mount
echo "Exporting files to TrueNAS output folder..."
cp /build/dspico-firmware/build/DSpico.uf2 /output/DSpico.uf2

# Also provide the loader binaries which are needed on the SD card
mkdir -p /output/_pico
cp /build/pico-loader/picoLoader7.bin /output/_pico/
cp /build/pico-loader/picoLoader9.bin /output/_pico/
cp /build/pico-loader/data/*.bin /output/_pico/

echo "------------------------------------------------"
echo "SUCCESS: All components built!"
echo "Files ready in /mnt/SSD/DSPICO/output/:"
echo "  - DSpico.uf2 (Flash this to your Pico)"
echo "  - _pico/ (Copy this folder to your SD card root)"
echo "------------------------------------------------"
