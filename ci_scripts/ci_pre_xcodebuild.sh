#!/bin/sh

#  ci_post_clone.sh
#  Data4LifeSDK
#
#  Created by Alessio Borraccino on 14.01.22.
#  Copyright © 2022 HPS Gesundheitscloud gGmbH. All rights reserved.

cd $CI_PROJECT_FILE_PATH
printf '%s\n' "$D4L_EXAMPLE_CONFIG_JSON" > d4l-example-app-config.json
./config-generator.swift d4l staging
