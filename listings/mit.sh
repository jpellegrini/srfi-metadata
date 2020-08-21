#!/bin/bash
set -eu -o pipefail
cd "$(dirname "$0")"
curl --fail --silent --show-error \
    https://git.savannah.gnu.org/cgit/mit-scheme.git/plain/src/runtime/feature.scm |
    grep -ioE "srfi[ -][0-9]+" |
    grep -oE '[0-9]+' |
    sort -g |
    uniq >mit.scm