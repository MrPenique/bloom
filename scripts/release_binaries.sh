#!/bin/bash

##
#  Bloom
#
#  HTTP REST API caching middleware
#  Copyright: 2020, Valerian Saliou <valerian@valeriansaliou.name>
#  License: Mozilla Public License v2.0 (MPL v2.0)
##

# Read arguments
while [ "$1" != "" ]; do
    argument_key=`echo $1 | awk -F= '{print $1}'`
    argument_value=`echo $1 | awk -F= '{print $2}'`

    case $argument_key in
        -v | --version)
            BLOOM_VERSION="$argument_value"
            ;;
        *)
            echo "Unknown argument received: '$argument_key'"
            exit 1
            ;;
    esac

    shift
done

# Ensure release version is provided
if [ -z "$BLOOM_VERSION" ]; then
  echo "No Bloom release version was provided, please provide it using '--version'"

  exit 1
fi

# Define release pipeline
function release_for_architecture {
    final_tar="v$BLOOM_VERSION-$1.tar.gz"

    rm -rf ./bloom/ && \
        docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder:stable cargo build --target=$2 --release && \
        docker run --rm -it -v "$(pwd)":/home/rust/src ekidd/rust-musl-builder:stable strip ./target/$2/release/bloom && \
        mkdir ./bloom && \
        mv "target/$2/release/bloom" ./bloom/ && \
        cp ./config.cfg bloom/ && \
        tar -czvf "$final_tar" ./bloom && \
        rm -r ./bloom/
    release_result=$?

    if [ $release_result -eq 0 ]; then
        echo "Result: Packed architecture: $1 to file: $final_tar"
    fi

    return $release_result
}

# Run release tasks
ABSPATH=$(cd "$(dirname "$0")"; pwd)
BASE_DIR="$ABSPATH/../"

rc=0

pushd "$BASE_DIR" > /dev/null
    echo "Executing release steps for Bloom v$BLOOM_VERSION..."

    release_for_architecture "amd64" "x86_64-unknown-linux-musl"
    rc=$?

    if [ $rc -eq 0 ]; then
        echo "Success: Done executing release steps for Bloom v$BLOOM_VERSION"
    else
        echo "Error: Failed executing release steps for Bloom v$BLOOM_VERSION"
    fi
popd > /dev/null

exit $rc
