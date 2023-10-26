set -ev

BUILD_NAME=`basename $GITHUB_REPOSITORY`

if [[ "$BUILD_TYPE" == "" ]]; then
BUILD_TYPE="release"
fi

HOST_OS=`uname`

if [[ "$HOST_OS" == "Linux" ]]; then
if [[ "$BUILD_TARGET" == "android" ]]; then
    HOST_OS="Android";
elif [[ "$BUILD_TARGET" == "alpine" ]]; then
    HOST_OS="Alpine";
else
    BUILD_TARGET="linux";
fi

sudo apt update

sudo apt install qemu-user-static -y

sudo update-binfmts --enable
sudo update-binfmts --install qemu-loongarch64 /usr/cross-tools/qemu-loongarch64 \
    --magic "\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x02\x01" \
    --mask "\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff"
fi

if [[ "$HOST_OS" == "Darwin" ]]; then
if [[ "$BUILD_TARGET" == "iphone" ]]; then
    HOST_OS="iPhone";
else
    BUILD_TARGET="darwin";
fi
fi

if [[ "$HOST_OS" == "Windows" ]]; then
BUILD_TARGET="win32";
fi

if [[ "$HOST_OS" =~ "MINGW" ]]; then
HOST_OS="Windows";
BUILD_TARGET="win32";
fi

BUILD_TAG=`git tag --contains HEAD`

echo "BUILD_NAME=${BUILD_NAME}" >> $GITHUB_ENV
echo "HOST_OS=${HOST_OS}" >> $GITHUB_ENV
echo "BUILD_TARGET=${BUILD_TARGET}" >> $GITHUB_ENV
echo "BUILD_ARCH=${BUILD_ARCH}" >> $GITHUB_ENV
echo "BUILD_TYPE=${BUILD_TYPE}" >> $GITHUB_ENV
echo "BUILD_TAG=${BUILD_TAG}" >> $GITHUB_ENV
