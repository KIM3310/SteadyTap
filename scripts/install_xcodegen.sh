#!/bin/sh
set -eu

version="2.45.4"
archive_sha256="090ec29491aad50aec10631bf6e62253fed733c50f3aab0f5ffc86bc170bdbef"
binary_sha256="6aa2b4da95304b343bea12890c59f9655aa428c08b351d57d592cfab4e88a9f1"
install_root="${XCODEGEN_INSTALL_ROOT:-${TMPDIR:-/tmp}/steadytap-xcodegen-${version}}"
binary_path="${install_root}/xcodegen/bin/xcodegen"

if [ -x "${binary_path}" ]; then
    cached_sha256="$(shasum -a 256 "${binary_path}" | awk '{print $1}')"
    if [ "${cached_sha256}" = "${binary_sha256}" ]; then
        printf '%s\n' "${binary_path}"
        exit 0
    fi
fi

archive_path="${install_root}/xcodegen.zip"
mkdir -p "${install_root}"
curl --fail --silent --show-error --location \
    "https://github.com/yonaskolb/XcodeGen/releases/download/${version}/xcodegen.zip" \
    --output "${archive_path}"

actual_sha256="$(shasum -a 256 "${archive_path}" | awk '{print $1}')"
if [ "${actual_sha256}" != "${archive_sha256}" ]; then
    printf 'XcodeGen checksum mismatch: expected %s, got %s\n' \
        "${archive_sha256}" "${actual_sha256}" >&2
    exit 1
fi

unzip -q -o "${archive_path}" -d "${install_root}"
test -x "${binary_path}"
actual_binary_sha256="$(shasum -a 256 "${binary_path}" | awk '{print $1}')"
if [ "${actual_binary_sha256}" != "${binary_sha256}" ]; then
    printf 'XcodeGen binary checksum mismatch: expected %s, got %s\n' \
        "${binary_sha256}" "${actual_binary_sha256}" >&2
    exit 1
fi
printf '%s\n' "${binary_path}"
