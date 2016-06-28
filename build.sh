#!/bin/bash
# Original build script by Mansi @ https://github.com/Redmi3/xiaomi_kernel_Redmi3

#########################################################################
# Configure these
#########################################################################

MAKE_CONFIG_FILE="wt88509_64-perf_defconfig"
export KBUILD_BUILD_USER="yantz"
export KBUILD_BUILD_HOST="xda"

export TARGET_BUILD_VARIANT=user

export CROSS_COMPILE=~/aarch64-linux-android-4.9/bin/aarch64-linux-android-

export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export USE_CCACHE=1

#########################################################################
# End config
#########################################################################

export ARCH=arm64
export SUBARCH=arm64

OUT_DIR="out"
KERNEL_DIR=$PWD
KERN_IMG=${OUT_DIR}/arch/arm64/boot/Image.gz
NR_CPUS=$(grep -c ^processor /proc/cpuinfo)
BUILD_START=$(date +"%s")

blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

if [ "$NR_CPUS" -le "2" ]; then
echo -e "$red Building kernel with 4 CPU threads $nocol";
else
echo -e "$red Building kernel with $NR_CPUS CPU threads $nocol";
fi;

if [ -e ${KERNEL_DIR}/yantz/kernel/Image.gz ]; then
	rm ${KERNEL_DIR}/yantz/kernel/Image.gz
fi
if [ -e ${KERNEL_DIR}/yantz/kernel/dtb ]; then
	rm ${KERNEL_DIR}/yantz/kernel/dtb
fi
if [ -d ${OUT_DIR} ]; then
	rm -rf ${OUT_DIR}
fi
mkdir ${OUT_DIR}

echo -e "$cyan Make DefConfig $nocol";
make O=${OUT_DIR} ${MAKE_CONFIG_FILE}

echo -e "$cyan Build kernel $nocol";
ccache make O=${OUT_DIR} -j${NR_CPUS}

if ! [ -a $KERN_IMG ]; then
	echo -e "$red Kernel Compilation failed! Fix the errors! $nocol";
	exit 1
fi

echo -e "$cyan Build dtb file $nocol";
scripts/dtbToolCM -2 -o ${OUT_DIR}/arch/arm64/boot/dtb -s 2048 -p ${OUT_DIR}/scripts/dtc/ ${OUT_DIR}/arch/arm64/boot/dts/

echo -e "$cyan Copy kernel $nocol";
cp ${OUT_DIR}/arch/arm64/boot/dtb  ${KERNEL_DIR}/yantz/kernel/dtb
cp ${KERN_IMG}  ${KERNEL_DIR}/yantz/kernel/Image.gz
cd ${KERNEL_DIR}/yantz

echo -e "$cyan Build flash file $nocol";
zipfile="yantz_Redmi3_Alpha_($(date +"%d-%m-%Y(%H.%M%p)")).zip"
zip -r ${zipfile} kernel bin META-INF -x *kernel/.gitignore*

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";

echo -e "Flashable zip at ${KERNEL_DIR}/yantz";
