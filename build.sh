#!/usr/bin/env bash

 #
 # Script For Building Android arm64 Kernel
 #
 
 # Specify Kernel Directory
KERNEL_DIR="$(pwd)"

# Zip Name
ZIPNAME="Nexus"

# Specify compiler.
if [ "$@" = "--eva" ]; then
COMPILER=eva
elif [ "$@" = "--azure" ]; then
COMPILER=azure
elif [ "$@" = "--proton" ]; then
COMPILER=proton
elif [ "$@" = "--aosp" ]; then
COMPILER=aosp
elif [ "$@" = "--nexus" ]; then
COMPILER=nexus
elif [ "$@" = "--neutron" ]; then
COMPILER=neutron
fi

# Device Name and Model
MODEL=Xiaomi

DEVICE=Miatoll

# Kernel Version Code
VERSION=X2-BETA

# Kernel Defconfig
DEFCONFIG=cust_defconfig

# Linker
LINKER=ld.lld

# Path
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb

DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")
START=$(date +"%s")
TANGGAL=$(date +"%F%S")

FINAL_ZIP=${ZIPNAME}-${VERSION}-${DEVICE}-KERNEL-${TANGGAL}.zip

##----------------------------------------------------------##

# Cloning Dependencies
function clone() {
    # Clone Toolchain
                if [ $COMPILER = "neutron" ];
                then
                post_msg " Cloning Neutron Clang ToolChain "
		git clone --depth=1  https://github.com/Neutron-Clang/neutron-toolchain.git clang
		PATH="${KERNEL_DIR}/clang/bin:$PATH"
		
		elif [ $COMPILER = "azure" ];
                then
                post_msg " Cloning Azure Clang ToolChain "
		git clone --depth=1  https://gitlab.com/Panchajanya1999/azure-clang.git clang
		PATH="${KERNEL_DIR}/clang/bin:$PATH"
		
		elif [ $COMPILER = "proton" ];
		then
		post_msg " Cloning Proton Clang ToolChain "
		git clone --depth=1  https://github.com/kdrag0n/proton-clang.git clang
		PATH="${KERNEL_DIR}/clang/bin:$PATH"
		
		elif [ $COMPILER = "nexus" ];
		then
		post_msg " Cloning Nexus Clang ToolChain "
		git clone --depth=1  https://github.com/nexus-projects/nexus-clang.git clang
		PATH="${KERNEL_DIR}/clang/bin:$PATH"
		
		elif [ $COMPILER = "aosp" ];
		then
		post_msg " Cloning Aosp Clang 13.0.3 ToolChain "
		git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r433403b.git -b 12.0 aosp-clang
                git clone https://github.com/sohamxda7/llvm-stable -b gcc64 --depth=1 gcc
                git clone https://github.com/sohamxda7/llvm-stable -b gcc32  --depth=1 gcc32
                PATH="${KERNEL_DIR}/aosp-clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
                
		elif [ $COMPILER = "eva" ];
		then
		post_msg " Cloning Eva GCC ToolChain "
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git -b gcc-new gcc64
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git -b gcc-new gcc32
		PATH=$KERNEL_DIR/gcc64/bin/:$KERNEL_DIR/gcc32/bin/:/usr/bin:$PATH
        fi
        # Clone AnyKernel3
		if [ $DEVICE = "Miatoll" ];
		then
		git clone --depth=1 https://github.com/reaPeR1010/AnyKernel3 -b atoll AnyKernel3
		fi
}
##------------------------------------------------------##

function exports() {
    if [ -d ${KERNEL_DIR}/clang ];
    then
    export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    elif [ -d ${KERNEL_DIR}/aosp-clang ];
    then
    export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/aosp-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    elif [ -d ${KERNEL_DIR}/gcc64 ];
    then
    export KBUILD_COMPILER_STRING=$("$KERNEL_DIR/gcc64"/bin/aarch64-elf-gcc --version | head -n 1)
    fi
    export ARCH=arm64
    export SUBARCH=arm64
    export LOCALVERSION="-${VERSION}"
    export KBUILD_BUILD_HOST=ArchLinux
    export KBUILD_BUILD_USER="RoHaN"
    export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
    export DISTRO=$(source /etc/os-release && echo "${NAME}")
    export CI_BRANCH=$DRONE_BRANCH
    export PROCS=$(nproc --all)

}

##----------------------------------------------------------------##

function post_msg() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="$1"
}

##----------------------------------------------------------##

function push() {
    curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
         -F chat_id="$chat_id" \
         -F "disable_web_page_preview=true" \
         -F "parse_mode=html" \
         -F caption="$2"
}

##----------------------------------------------------------##

function compile() {
	post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Linker : </b><code>$LINKER</code>%0a<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
	                        make O=out ARCH=arm64 ${DEFCONFIG}
	                        if [ -d ${KERNEL_DIR}/clang ]; then
	                        make -kj$(nproc --all) O=out \
				ARCH=arm64 \
				CC=clang \
				CROSS_COMPILE=aarch64-linux-gnu- \
				CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
				LD=${LINKER} \
				AR=llvm-ar \
				NM=llvm-nm \
				OBJCOPY=llvm-objcopy \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
				READELF=llvm-readelf \
				OBJSIZE=llvm-size \
				V=$VERBOSE 2>&1 | tee error.log
                                elif [ -d ${KERNEL_DIR}/gcc64 ]; then
				make -kj$(nproc --all) O=out \
				ARCH=arm64 \
				CROSS_COMPILE_ARM32=arm-eabi- \
				CROSS_COMPILE=aarch64-elf- \
				LD=aarch64-elf-${LINKER} \
				AR=llvm-ar \
				NM=llvm-nm \
				OBJCOPY=llvm-objcopy \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
				OBJSIZE=llvm-size \
				V=$VERBOSE 2>&1 | tee error.log
				elif [ -d ${KERNEL_DIR}/aosp-clang ]; then
				make -kj$(nproc --all) O=out \
				ARCH=arm64 \
				CC=clang \
				CLANG_TRIPLE=aarch64-linux-gnu- \
				CROSS_COMPILE=aarch64-linux-android- \
				CROSS_COMPILE_ARM32=arm-linux-androideabi- \
				LD=${LINKER} \
				AR=llvm-ar \
				NM=llvm-nm \
				OBJCOPY=llvm-objcopy \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
				READELF=llvm-readelf \
				OBJSIZE=llvm-size \
				V=$VERBOSE 2>&1 | tee error.log
				fi
				
    if ! [ -a "$IMAGE" ]; then
        push "error.log" "Build Throws Errors"
        exit 1
    fi
    # Copy Files To AnyKernel3 Zip
    cp $IMAGE AnyKernel3
    cp $DTBO AnyKernel3
}
##----------------------------------------------------------##

function zipping() {
    post_msg " Kernel Compilation Finished. Started Zipping "
    cd AnyKernel3 || exit 1
    zip -r9 ${FINAL_ZIP} *
    MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
    push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
    cd ..
}
##----------------------------------------------------------##

clone
exports
compile
END=$(date +"%s")
DIFF=$(($END - $START))
zipping

##----------------*****-----------------------------##