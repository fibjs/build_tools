#!/bin/bash

# iOS Simulator runner script
# Usage: ios-simulator-run.sh <executable_path> [args...]
# This script boots an iOS simulator and runs the specified executable within it.

set -e

EXECUTABLE="$1"
shift
ARGS="$@"

if [ -z "${EXECUTABLE}" ]; then
    echo "Usage: ios-simulator-run.sh <executable_path> [args...]"
    exit 1
fi

if [ ! -f "${EXECUTABLE}" ]; then
    echo "Error: Executable not found: ${EXECUTABLE}"
    exit 1
fi

# Convert to absolute path if needed
if [[ "${EXECUTABLE}" != /* ]]; then
    EXECUTABLE="$(pwd)/${EXECUTABLE}"
fi

# Get the first available simulator UDID
UDID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')

if [ -z "${UDID}" ]; then
    echo "Error: Could not find any available iOS simulator"
    exit 1
fi

# Shutdown any running simulators
xcrun simctl shutdown all 2>/dev/null || true

# Boot the simulator
xcrun simctl boot "${UDID}" 2>/dev/null || true

# Wait for simulator to be ready
for i in {1..30}; do
    if xcrun simctl list devices | grep "${UDID}" | grep -q "(Booted)"; then
        break
    fi
    sleep 2
done

# Run executable in simulator with arguments
xcrun simctl spawn "${UDID}" "${EXECUTABLE}" ${ARGS}
EXIT_CODE=$?

# Shutdown simulator after test
xcrun simctl shutdown "${UDID}" 2>/dev/null || true

exit ${EXIT_CODE}
