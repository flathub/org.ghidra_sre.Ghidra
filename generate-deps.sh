#!/usr/bin/env bash

rm -rf _deps_build
git clone https://github.com/NationalSecurityAgency/ghidra.git -b stable _deps_build
cd _deps_build
echo "source /usr/lib/sdk/openjdk11/enable.sh && gradle -g gradle-cache -I gradle/support/fetchDependencies.gradle init && rm -rf gradle-cache && gradle -g gradle-cache --info --console plain buildGhidra > gradle-log.txt" | flatpak run --share=network --filesystem=`pwd` --devel org.freedesktop.Sdk//21.08
wget https://raw.githubusercontent.com/flatpak/flatpak-builder-tools/wip/hadess/add-gradle/gradle/flatpak-gradle-generator.py
chmod +x flatpak-gradle-generator.py
./flatpak-gradle-generator.py gradle-log.txt ../gradle-dependencies.json --destdir dependencies/flatRepo --arches x86_64,aarch64
