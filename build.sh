#!/bin/bash

set -e

cd snapcraft
docker buildx build --push --platform linux/riscv64 --tag localhost:5001/tide-container-snapcraft:latest .
cd ..

