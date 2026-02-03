#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${LAMBDA_SRC_DIR:-services/tasks/src}"
BUILD_DIR="${BUILD_DIR:-build/lambda}"
ZIP_PATH="${ZIP_PATH:-build/tasks.zip}"

if [[ ! -d "${SRC_DIR}" ]]; then
  echo "Lambda source directory not found: ${SRC_DIR}" >&2
  exit 1
fi

rm -rf "${BUILD_DIR}" "${ZIP_PATH}"
mkdir -p "${BUILD_DIR}"

if [[ -f "${SRC_DIR}/requirements.txt" ]]; then
  python -m pip install -r "${SRC_DIR}/requirements.txt" -t "${BUILD_DIR}"
fi

cp -R "${SRC_DIR}/." "${BUILD_DIR}/"

(cd "${BUILD_DIR}" && zip -r "${ZIP_PATH}" .)

echo "Lambda package created at ${ZIP_PATH}"
