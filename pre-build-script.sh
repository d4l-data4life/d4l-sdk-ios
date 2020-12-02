#!/usr/bin/env bash
mkdir -p $PROJECT_DIR/generated
exec > $PROJECT_DIR/generated/pre-build-${CONFIGURATION}-script.log 2>&1
${SRCROOT}/config-generator.rb
