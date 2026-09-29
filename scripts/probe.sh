#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
cd "$project_dir"
mkdir -p .build/ModuleCache .build/cache .build/config .build/security
export CLANG_MODULE_CACHE_PATH="$project_dir/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_dir/.build/ModuleCache"
swift run --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security QuotaProbe
