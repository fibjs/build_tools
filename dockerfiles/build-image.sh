export DOCKER_BUILDKIT=1

docker build --rm -f linux-build-env.x64 -t fibjs/linux-build-env:x64 .
docker build --rm -f linux-build-env.ia32 -t fibjs/linux-build-env:ia32 .
docker build --rm -f linux-build-env.arm64 -t fibjs/linux-build-env:arm64 .
docker build --rm -f linux-build-env.arm -t fibjs/linux-build-env:arm .
docker build --rm -f linux-build-env.mips64 -t fibjs/linux-build-env:mips64 .
docker build --rm -f linux-build-env.ppc64 -t fibjs/linux-build-env:ppc64 .
docker build --rm -f linux-build-env.riscv64 -t fibjs/linux-build-env:riscv64 .
docker build --rm -f linux-build-env.loong64 -t fibjs/linux-build-env:loong64 .
docker build --rm -f linux-build-env.loong64ow -t fibjs/linux-build-env:loong64ow .

docker build --rm -f alpine-build-env.x64 -t fibjs/alpine-build-env:x64 .
docker build --rm -f alpine-build-env.ia32 -t fibjs/alpine-build-env:ia32 .
docker build --rm -f alpine-build-env.arm64 -t fibjs/alpine-build-env:arm64 .

docker build --rm -f android-build-env.x64 -t fibjs/android-build-env:x64 .
docker build --rm -f android-build-env.ia32 -t fibjs/android-build-env:ia32 .
docker build --rm -f android-build-env.arm64 -t fibjs/android-build-env:arm64 .
docker build --rm -f android-build-env.arm -t fibjs/android-build-env:arm .
