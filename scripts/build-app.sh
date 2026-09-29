#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
cd "$project_dir"

mkdir -p .build/ModuleCache .build/cache .build/config .build/security build/QuotaPet.app/Contents/MacOS build/QuotaPet.app/Contents/Resources
export CLANG_MODULE_CACHE_PATH="$project_dir/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_dir/.build/ModuleCache"

swift build -c release --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security
bin_dir="$(swift build -c release --show-bin-path --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security)"
cp "$bin_dir/QuotaPet" build/QuotaPet.app/Contents/MacOS/QuotaPet
cp Resources/Info.plist build/QuotaPet.app/Contents/Info.plist
ditto "$bin_dir/QuotaPet_QuotaPet.bundle" build/QuotaPet.app/Contents/Resources/QuotaPet_QuotaPet.bundle
xcrun actool Resources/Assets.xcassets \
    --compile build/QuotaPet.app/Contents/Resources \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist .build/AppIcon-Info.plist
codesign --force --deep --sign - build/QuotaPet.app

echo "$project_dir/build/QuotaPet.app"
