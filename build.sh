#!/bin/bash
#
# Copyright (C) 2020 azrim.
# All rights reserved.

# Init
KERNEL_DIR="${PWD}"
KERN_IMG="${KERNEL_DIR}"/out/arch/arm64/boot/Image.gz-dtb
ANYKERNEL="${HOME}"/anykernel
COMPILER_STRING="Neutron Clang 17.0.0"

# Repo URL
ANYKERNEL_REPO="https://github.com/Meghthedev/Anykernel3-tissot.git" 
ANYKERNEL_BRANCH="Anykernel3"

# Compiler
CLANG_DIR="${HOME}"/clang/neutron
if ! [ -d "${CLANG_DIR}" ]; then
(
mkdir -p "$HOME/clang/neutron"
cd "$HOME/clang/neutron"
bash <(curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman") -S
)
fi

# Defconfig
DEFCONFIG="tissot_defconfig"
REGENERATE_DEFCONFIG="false" # unset if don't want to regenerate defconfig

# Costumize
KERNEL="PristineCore"
RELEASE_VERSION="1.0"
DEVICE="Tissot"
KERNELTYPE="NonOC-NonTreble"
KERNEL_SUPPORT="10 - 13"
KERNELNAME="${KERNEL}-${DEVICE}-${KERNELTYPE}-$(TZ=Asia/Jakarta date +%y%m%d-%H%M)"
TEMPZIPNAME="${KERNELNAME}.zip"
ZIPNAME="${KERNELNAME}.zip"

# Telegram
CHATIDQ="-1974207517"
CHATID="-1974207517" # Group/channel chatid (use rose/userbot to get it)
TELEGRAM_TOKEN="6107027569:AAGxyksRe9xS9X0JWJmfjwAO1AowlhPPma0" # Get from botfather

# Export Telegram.sh
TELEGRAM_FOLDER="${HOME}"/telegram
if ! [ -d "${TELEGRAM_FOLDER}" ]; then
    git clone https://github.com/Anothermi1/telegram.sh/ "${TELEGRAM_FOLDER}"
fi

TELEGRAM="${TELEGRAM_FOLDER}"/telegram

tg_cast() {
    "${TELEGRAM}" -t "${TELEGRAM_TOKEN}" -c "${CHATID}" -H \
    "$(
        for POST in "${@}"; do
            echo "${POST}"
        done
    )"
}

# Regenerating Defconfig
regenerate() {
    cp out/.config arch/arm64/configs/"${DEFCONFIG}"
    git add arch/arm64/configs/"${DEFCONFIG}"
    git commit -m "defconfig: Regenerate"
}

# Building
makekernel() {
    echo ".........................."
    echo ".     Building Kernel    ."
    echo ".........................."
    export PATH="${HOME}"/clang/neutron/bin:$PATH
    rm -rf "${KERNEL_DIR}"/out/arch/arm64/boot # clean previous compilation
    mkdir -p out
    make O=out ARCH=arm64 ${DEFCONFIG}
    if [[ "${REGENERATE_DEFCONFIG}" =~ "true" ]]; then
        regenerate
    fi
    make -j$(nproc --all) CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- O=out ARCH=arm64

# Check If compilation is success
    if ! [ -f "${KERN_IMG}" ]; then
        END=$(TZ=Asia/Jakarta date +"%s")
        DIFF=$(( END - START ))
        echo -e "You are an idiot"
        tg_cast "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check Instance for errors @meghthebot"
        exit 1
    fi
}

# Packing Kernel
packingkernel() {
    echo "........................"
    echo ".    Packing Kernel    ."
    echo "........................"
    # Copy compiled kernel
    if [ -d "${ANYKERNEL}" ]; then
        rm -rf "${ANYKERNEL}"
    fi
    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "${ANYKERNEL}"
        cp "${KERN_IMG}" "${ANYKERNEL}"/Image.gz-dtb

    # Zip the kernel, or fail
    cd "${ANYKERNEL}" || exit
    zip -r9 "${TEMPZIPNAME}" ./*

    # Ship it to the CI channel
    "${TELEGRAM}" -f "$ZIPNAME" -t "${TELEGRAM_TOKEN}" -c "${CHATIDQ}" 
}

# Starting
tg_cast "<b>STARTING KERNEL BUILD</b>" \
    "Device: ${DEVICE}" \
    "Kernel Name: <code>${KERNEL}</code>" \
    "Build Type: <code>${KERNELTYPE}</code>" \
    "Release Version: ${RELEASE_VERSION}" \
    "Linux Version: <code>$(make kernelversion)</code>" \
    "Android Supported: ${KERNEL_SUPPORT}"
START=$(TZ=Asia/Jakarta date +"%s")
makekernel
packingkernel
END=$(TZ=Asia/Jakarta date +"%s")
DIFF=$(( END - START ))
tg_cast "Build for ${DEVICE} with ${COMPILER_STRING} <b>succeed</b> took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! by @zh4ntech"

tg_cast  "<b>Changelog :</b>" \
    "- Compile with Neutron Clang 17.0.0" 
     
    echo "........................"
    echo ".    Build Finished    ."
    echo "........................"