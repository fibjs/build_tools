#!/bin/bash
#
# Self test for build_tools.
#
# Two minimal repositories are built with the cmake and the compiler of the
# host, so CI can run this on every platform without touching vender:
#
#   case A  a single CMake project at the repository root (vender/fibjs layout),
#           including cmake/Library.cmake and cmake/LibraryTest.cmake
#   case B  a repository that drives its build from a script-mode build.cmake
#           (addon layout, see fibjs/fib-addon)
#
# It also checks that cmake-scripts/dist_dirname.cmake reports the same
# distribution directory that the build scripts use.

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${ARCH:-x64}"
TARGET="${TARGET:-}"
TYPE="${TYPE:-release}"
JOBS="${JOBS:-4}"
WORK="${ROOT}/tests/work"

fail() {
    # Workflow commands are only parsed on stdout, and annotations are readable
    # without authentication (the raw job log is not).
    echo "::error::SELFTEST FAILED: $*"
    echo "SELFTEST FAILED: $*"
    exit 1
}

# Surface the interesting part of a log as an annotation: reading the raw job log
# needs authentication, reading annotations does not.
annotate_log() {
    local log="$1"
    local lines="${2:-5}"

    [ -f "${log}" ] || return 0
    tail -n "${lines}" "${log}" | while IFS= read -r line; do
        [ -n "${line}" ] && echo "::error::${line}"
    done
}

# The name of a library depends on the toolchain: GNU builds libfoo.a, the
# Windows build keeps the Unix prefix (libfoo.lib) and MSVC naming (foo.lib) is
# possible as well.
find_artifact() {
    local dir="$1"
    local name="$2"

    ls "${dir}" 2>/dev/null | grep -E "^(lib)?${name}\.(a|lib)$" | head -n 1
}

# Report the contents of an artifact directory: the raw job log is not readable
# without authentication, the annotations are.
annotate_dir() {
    local dir="$1"

    { ls -ld "${dir}" 2>&1; ls -la "${dir}" 2>&1; } | head -20 | while IFS= read -r line; do
        echo "::error::${line}"
    done
}

rm -rf "${WORK}"
mkdir -p "${WORK}"

# Artifact names depend on the toolchain: GNU (libfoo.a) vs MSVC (foo.lib), and
# executables carry a .exe suffix on Windows.
EXE_SUFFIX=""
case "$(uname)" in
MINGW* | MSYS* | CYGWIN*) EXE_SUFFIX=".exe" ;;
esac

# A cross built binary can only be run inside the build image, so case C runs
# the executable it built only when the build was for this machine.
case "$(uname -m)" in
x86_64 | amd64) HOST_ARCH=x64 ;;
i386 | i686 | x86) HOST_ARCH=ia32 ;;
aarch64 | arm64) HOST_ARCH=arm64 ;;
armv7l | armv7) HOST_ARCH=arm ;;
*) HOST_ARCH="" ;;
esac

# --- distribution directory name (script mode) -------------------------------
HELPER_LOG="${WORK}/dist_dirname.log"
DIST="$(cmake -DBUILD_ARCH="${ARCH}" -DBUILD_TYPE="${TYPE}" \
    -P "${ROOT}/cmake-scripts/dist_dirname.cmake" > "${HELPER_LOG}" 2>&1
    tail -n 1 "${HELPER_LOG}" | sed 's/^-- //' | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r')"

case "${DIST}" in
*_*_*) ;;
*)
    echo "--- dist_dirname.cmake output:"
    cat "${HELPER_LOG}"
    annotate_log "${HELPER_LOG}" 10
    fail "dist_dirname.cmake returned '${DIST}'"
    ;;
esac
echo "== distribution directory: ${DIST}"

# --- case C: entry script (the case the architecture matrix runs) ------------
# The matrix always states a target, so only case C runs there; CASES asks for
# the cases that drive the build scripts directly (project, script) as well.
if [[ -z "${CASES}" ]]; then
    if [[ -n "${TARGET}" ]]; then
        CASES="entry"
    else
        CASES="project script entry"
    fi
fi

if [[ "${CASES}" == *entry* ]]; then
    echo "== case C: entry script (arch=${ARCH} target=${TARGET:-native} type=${TYPE})"
    ENTRY_ARGS=("${ARCH}" "${TYPE}" -j"${JOBS}")
    if [[ -n "${TARGET}" ]]; then
        ENTRY_ARGS=("${ARCH}" "${TARGET}" "${TYPE}" -j"${JOBS}")
    fi

    ( cd "${ROOT}/tests/entry" && bash build "${ENTRY_ARGS[@]}" ) > "${WORK}/entry.log" 2>&1 \
        || {
            annotate_log "${WORK}/entry.log"
            tail -25 "${WORK}/entry.log"

            # A regression of the assembly language pin (cmake/Library.cmake,
            # asm_language_<library>) shows up as an assembler error or as a
            # missing assembler rule, not as a plain compile failure; name it so
            # the annotation can be read without the raw log.
            if grep -qE "ASM-ATT|ASM_NASM|nasm" "${WORK}/entry.log"; then
                echo "::error::the assembly language pin of tests/entry/asmprobe did not reach its sources (cmake/Library.cmake: asm_language_asmprobe)"
            fi

            fail "case C build"
        }

    ENTRY_BIN="$(grep -o 'FIBJS_BIN_DIR is .*' "${WORK}/entry.log" | tail -n 1 | sed 's/.* is //' | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r')"
    [ -n "${ENTRY_BIN}" ] || { annotate_log "${WORK}/entry.log"; tail -25 "${WORK}/entry.log"; fail "case C: FIBJS_BIN_DIR not reported"; }

    if ! ls "${ENTRY_BIN}" 2>/dev/null | grep -q "entrycheck"; then
        # Report what is actually there: the raw log is not readable without
        # authentication, the annotations are.
        echo "::error::entrycheck missing in ${ENTRY_BIN}"
        { ls -ld "${ENTRY_BIN}" 2>&1; ls -la "${ENTRY_BIN}" 2>&1; } | head -12 | while IFS= read -r line; do
            echo "::error::${line}"
        done
        { ls -ld "$(dirname "${ENTRY_BIN}")" 2>&1; ls -la "$(dirname "${ENTRY_BIN}")" 2>&1; } | head -12 | while IFS= read -r line; do
            echo "::error::${line}"
        done
        annotate_log "${WORK}/entry.log" 5
        fail "case C: entrycheck missing in ${ENTRY_BIN}"
    fi

    # The C++ libraries of the entry repository carry the checks that a vender
    # build failure is about (tests/entry/cxxprobe/src/cxxprobe.cpp): they only
    # build when the base flags of the tree reach every library of libs.cmake.
    CXX_LIB="$(find_artifact "${ENTRY_BIN}" cxxprobe)"
    [ -n "${CXX_LIB}" ] || {
        annotate_dir "${ENTRY_BIN}"
        annotate_log "${WORK}/entry.log" 5
        fail "case C: cxxprobe library missing in ${ENTRY_BIN}"
    }

    CXX_LIB2="$(find_artifact "${ENTRY_BIN}" cxxprobe2)"
    [ -n "${CXX_LIB2}" ] || {
        annotate_dir "${ENTRY_BIN}"
        annotate_log "${WORK}/entry.log" 5
        fail "case C: cxxprobe2 library missing in ${ENTRY_BIN}"
    }

    CXX_TEST="${ENTRY_BIN}/cxxprobe_test${EXE_SUFFIX}"
    [ -f "${CXX_TEST}" ] || {
        annotate_dir "${ENTRY_BIN}"
        annotate_log "${WORK}/entry.log" 5
        fail "case C: cxxprobe_test${EXE_SUFFIX} missing in ${ENTRY_BIN}"
    }

    # The assembly probe (tests/entry/asmprobe): its .asm source is only
    # assembled by the language stated in libs.cmake (asm_language_asmprobe),
    # which is what a library of the vendored tree needs as well.
    ASM_LIB="$(find_artifact "${ENTRY_BIN}" asmprobe)"
    [ -n "${ASM_LIB}" ] || {
        annotate_dir "${ENTRY_BIN}"
        annotate_log "${WORK}/entry.log" 5
        fail "case C: asmprobe library missing in ${ENTRY_BIN}"
    }

    ASM_TEST="${ENTRY_BIN}/asmprobe_test${EXE_SUFFIX}"
    [ -f "${ASM_TEST}" ] || {
        annotate_dir "${ENTRY_BIN}"
        annotate_log "${WORK}/entry.log" 5
        fail "case C: asmprobe_test${EXE_SUFFIX} missing in ${ENTRY_BIN}"
    }

    if [ -n "${HOST_ARCH}" ] && [ "${ARCH}" = "${HOST_ARCH}" ] && [ -z "${TARGET}" ]; then
        "${CXX_TEST}" > "${WORK}/cxxprobe.log" 2>&1 \
            || { annotate_log "${WORK}/cxxprobe.log" 5; tail -5 "${WORK}/cxxprobe.log"; fail "case C: cxxprobe_test exited non-zero"; }
        cat "${WORK}/cxxprobe.log"

        "${ASM_TEST}" > "${WORK}/asmprobe.log" 2>&1 \
            || { annotate_log "${WORK}/asmprobe.log" 5; tail -5 "${WORK}/asmprobe.log"; fail "case C: asmprobe_test exited non-zero"; }
        cat "${WORK}/asmprobe.log"

        # The platform link flags link the C++ runtime statically, and the build
        # images rely on it: their target root filesystems do not always ship
        # libstdc++.so (the loong64ow image keeps it outside the rootfs, and the
        # test binaries of a debug build failed with exit code 127 there).
        if [ "$(uname)" = "Linux" ] && command -v readelf > /dev/null 2>&1; then
            if readelf -d "${CXX_TEST}" 2>/dev/null | grep -q "libstdc++"; then
                echo "::error::cxxprobe_test links the shared C++ runtime"
                readelf -d "${CXX_TEST}" | grep -E "NEEDED|libstdc" | while IFS= read -r line; do
                    echo "::error::${line}"
                done
                fail "case C: the platform link flags did not reach the executable"
            fi
        fi
    fi
fi

# --- case A / B: driven directly, with the toolchain of the host --------------
# (skipped for cross builds: those run through the entry script, case C)
if [[ "${CASES}" == *project* ]]; then

# --- case A: single CMake project --------------------------------------------
echo "== case A: single CMake project"
( cd "${ROOT}/tests/project" && WORK_ROOT="${WORK}/project" VENDER_ROOT="${ROOT}" \
    bash "${ROOT}/scripts/build" "${ARCH}" "${TYPE}" -j"${JOBS}" ) > "${WORK}/project.log" 2>&1 \
    || { annotate_log "${WORK}/project.log"; tail -25 "${WORK}/project.log"; fail "case A build"; }

A_BIN="${WORK}/project/bin/${DIST}"
A_LIB="$(find_artifact "${A_BIN}" selfcheck)"
[ -n "${A_LIB}" ] || { annotate_dir "${A_BIN}"; fail "case A: selfcheck library missing in ${A_BIN}"; }
[ -f "${A_BIN}/selfcheck_test${EXE_SUFFIX}" ] || fail "case A: selfcheck_test${EXE_SUFFIX} missing in ${A_BIN}"
"${A_BIN}/selfcheck_test${EXE_SUFFIX}" > /dev/null || fail "case A: selfcheck_test exited non-zero"

# --- case B: script-mode repository (addon layout) ---------------------------
echo "== case B: script-mode build.cmake repository"
( cd "${ROOT}/tests/script" && WORK_ROOT="${WORK}/script" VENDER_ROOT="${ROOT}" \
    bash "${ROOT}/scripts/build" "${ARCH}" "${TYPE}" -j"${JOBS}" ) > "${WORK}/script.log" 2>&1 \
    || { annotate_log "${WORK}/script.log"; tail -25 "${WORK}/script.log"; fail "case B build"; }

B_BIN="${WORK}/script/bin/${DIST}"
ls "${B_BIN}" | grep -q "scriptcheck" || fail "case B: scriptcheck library missing in ${B_BIN}"

fi # CASES project

echo "== SELFTEST OK (${DIST})"