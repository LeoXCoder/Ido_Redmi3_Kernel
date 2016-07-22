#!/bin/bash
# Original build script by Mansi @ https://github.com/Redmi3/xiaomi_kernel_Redmi3

#########################################################################
# Configure these
#########################################################################

MAKE_CONFIG_FILE="yantz_defconfig"
export KBUILD_BUILD_USER="yantz"
export KBUILD_BUILD_HOST="xda"
export TARGET_BUILD_VARIANT=user
export CROSS_COMPILE=~/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export USE_CCACHE=1
STRIP=~/aarch64-linux-android-4.9/bin/aarch64-linux-android-strip
#########################################################################
# End config
#########################################################################

export ARCH=arm64
export SUBARCH=arm64

OUT_DIR="out"
KERNEL_DIR=$PWD
FINAL_DIR=${KERNEL_DIR}/yantz
KERN_IMG=${OUT_DIR}/arch/arm64/boot/Image.gz
NR_CPUS=$(grep -c ^processor /proc/cpuinfo)
BUILD_START=$(date +"%s")
modord="${KERNEL_DIR}/${OUT_DIR}/modules.order"
cpmod="${FINAL_DIR}/modules.txt"
flashfilename="MYKernel_Redmi3_Alpha"

blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e "$red Cleaning previous build $nocol";

if [ -e ${FINAL_DIR}/kernel/Image.gz ]; then
	rm ${FINAL_DIR}/kernel/Image.gz
fi
if [ -e ${FINAL_DIR}/modules.txt ]; then
	rm ${FINAL_DIR}/modules.txt
fi
if [ -d ${OUT_DIR} ]; then
	rm -rf ${OUT_DIR}
fi
mkdir ${OUT_DIR}

echo -e "$cyan Make config (${MAKE_CONFIG_FILE}) $nocol";
make O=${OUT_DIR} ${MAKE_CONFIG_FILE}

echo -e "$cyan Build kernel using ${NR_CPUS} cores $nocol";
ccache make O=${OUT_DIR} -j${NR_CPUS} LOCALVERSION="-$(date +"%Y%m%d_%H%M")"
#ccache make O=${OUT_DIR} -j${NR_CPUS}

if ! [ -a $KERN_IMG ]; then
	echo -e "$red Kernel Compilation failed! Fix the errors! $nocol";
	exit 1
fi

echo -e "$cyan Copy kernel $nocol";
cp ${KERN_IMG}  ${FINAL_DIR}/kernel/Image.gz
cd ${FINAL_DIR}

echo -e "$cyan Build flash file $nocol";
zipfile="${flashfilename}_$(date +"%Y%m%d_%H%M").zip"
zip -r ${zipfile} kernel bin META-INF -x *kernel/.gitignore*

echo -e "$cyan Copy external modules $nocol";
cp $modord $cpmod
sed -i "s/^kernel//g" $cpmod
count=0
while read -r line || [[ -n "$line" ]]; do
  name="${KERNEL_DIR}/${OUT_DIR}$line"
  cp "$name" "${FINAL_DIR}"
  let count+=1
done < "$cpmod"
${STRIP} --strip-unneeded ${FINAL_DIR}/*.ko
echo "$count modules copied and stripped"

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol";
echo -e "Flashable zip at ${KERNEL_DIR}/yantz";
