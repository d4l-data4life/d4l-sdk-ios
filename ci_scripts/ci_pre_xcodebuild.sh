#!/bin/sh


cd $CI_WORKSPACE
printf '%s\n' "$D4L_EXAMPLE_CONFIG_JSON" > d4l-example-app-config.json
./config-generator.swift d4l staging



exit 0
