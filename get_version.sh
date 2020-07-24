#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 <packagename> <minimum version> <maximum version>"
    exit 1
fi

pkgname="$1"
minversion="$2"
maxversion="$3"

V="0"

for version in `apt-cache madison $pkgname | awk -F'|' '{print $2}'`; do
    # echo "Considering $version"
    if dpkg --compare-versions $version ge $minversion; then
        if dpkg --compare-versions $version le $maxversion; then
            # echo "- Version is at least $minversion"
            if dpkg --compare-versions $version gt $V; then
                # echo "- This is the newest version so far"
                V=$version
            fi
        fi
    fi
done

if [ "$V" = "0" ]; then
    exit 1
fi

echo "$V"
exit 0
