#!/bin/sh

cd "$(dirname "$0")"
if [ ! -f "buf.lock" ]; then
    buf dep update
fi
buf generate