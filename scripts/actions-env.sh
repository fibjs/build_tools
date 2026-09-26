set -ev

BUILD_NAME=$(basename $GITHUB_REPOSITORY)

if [[ "$BUILD_TYPE" == "" ]]; then
    BUILD_TYPE="release"
fi

HOST_OS=$(uname)

if [[ "$HOST_OS" == "Linux" ]]; then
    if [[ "$BUILD_TARGET" == "android" ]]; then
        BUILD_OS="Android"
    elif [[ "$BUILD_TARGET" == "alpine" ]]; then
        BUILD_OS="Alpine"
    else
        BUILD_OS="Linux"
        BUILD_TARGET="linux"
    fi

    sudo apt update

    # Registering the qemu handlers is best effort: newer runner images ship
    # their own (or none at all) and the build images carry the emulators they
    # need, so a missing package must not fail the job.  docker/setup-qemu-action
    # is the reliable way to get the handlers for the cross architecture jobs.
    sudo apt install qemu-user-static binfmt-support -y || \
        echo "notice: qemu-user-static/binfmt-support are not available, relying on the runner's handlers"

    if command -v update-binfmts >/dev/null 2>&1; then
        sudo update-binfmts --enable || true
    fi

    # The loongarch64 emulator lives inside the build image, not on the runner:
    # register it only when it is actually present.
    if command -v update-binfmts >/dev/null 2>&1 && [[ -e /usr/cross-tools/qemu-loongarch64 ]]; then
        sudo update-binfmts --install qemu-loongarch64 /usr/cross-tools/qemu-loongarch64 \
            --magic "\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x02\x01" \
            --mask "\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff"
    fi

    # The handlers from the distribution's qemu-user-static carry fix_binary (F):
    # the kernel opens the interpreter when the handler is registered, so the
    # qemu installed in the build environment image is never used and every
    # emulated guest is run by the runner's own qemu instead (6.2 on
    # ubuntu-22.04).  That qemu loops forever in V8's parser hash table on the
    # android/arm64 suite - it hangs right after the "path" suite header - while
    # the 7.2 pinned into the image does not.  For that job, re-register the
    # handler without F: the interpreter path is then resolved inside the
    # container, where the pinned qemu lives.  Children started through
    # process.execPath go through binfmt as well, so this covers them too, which
    # invoking qemu explicitly from test.sh would not.
    if [[ "$BUILD_TARGET" == "android" && "$BUILD_ARCH" == "arm64" ]]; then
        binfmt=/proc/sys/fs/binfmt_misc/qemu-aarch64
        if [[ -e "$binfmt" ]]; then
            magic=$(sed -n 's/^magic //p' "$binfmt" | sed 's/../\\x&/g')
            mask=$(sed -n 's/^mask //p' "$binfmt" | sed 's/../\\x&/g')
            sudo sh -c "echo -1 > $binfmt"
            sudo sh -c "printf '%s' ':qemu-aarch64:M:0:$magic:$mask:/usr/bin/qemu-aarch64-static:' > /proc/sys/fs/binfmt_misc/register"
            cat "$binfmt"
        fi
    fi

    sudo rm -rf \
                "$AGENT_TOOLSDIRECTORY" \
                /opt/ghc \
                /opt/hostedtoolcache \
                /opt/google/chrome \
                /opt/microsoft/msedge \
                /opt/microsoft/powershell \
                /opt/pipx \
                /usr/lib/mono \
                /usr/local/julia* \
                /usr/local/lib/android \
                /usr/local/lib/node_modules \
                /usr/local/share/chromium \
                /usr/local/share/powershell \
                /usr/share/dotnet \
                /usr/share/swift
fi

if [[ "$HOST_OS" == "Darwin" ]]; then
    if [[ "$BUILD_TARGET" == "iphone" ]]; then
        BUILD_OS="iPhone"
    elif [[ "$BUILD_TARGET" == "iphone-simulator" ]]; then
        BUILD_OS="iPhoneSimulator"
    else
        BUILD_OS="Darwin"
        BUILD_TARGET="darwin"
    fi
fi

if [[ "$HOST_OS" =~ "MINGW" ]]; then
    HOST_OS="Windows"
fi

if [[ "$HOST_OS" == "Windows" ]]; then
    BUILD_OS="Windows"
    BUILD_TARGET="win32"
fi

BUILD_TAG=$(git tag --contains HEAD)
COMMIT_ID=$(git show -s --format="%cd-%h" --date=format:%Y%m%d%H%M%S HEAD)

echo "HOST_OS=${HOST_OS}" >>$GITHUB_ENV

echo "BUILD_OS=${BUILD_OS}" >>$GITHUB_ENV
echo "BUILD_TARGET=${BUILD_TARGET}" >>$GITHUB_ENV
echo "BUILD_ARCH=${BUILD_ARCH}" >>$GITHUB_ENV
echo "BUILD_TYPE=${BUILD_TYPE}" >>$GITHUB_ENV

echo "BUILD_NAME=${BUILD_NAME}" >>$GITHUB_ENV
echo "BUILD_TAG=${BUILD_TAG}" >>$GITHUB_ENV
echo "COMMIT_ID=${COMMIT_ID}" >>$GITHUB_ENV
