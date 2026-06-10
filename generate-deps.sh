#!/usr/bin/env bash

set -e

get_sdk()
{
	OUTPUT=$(flatpak info org.freedesktop.Sdk 2>&1)
	RET=$?

	if [ $RET -eq 0 ] ; then
		echo org.freedesktop.Sdk
	else
		echo $OUTPUT | awk '{print $NF}'
	fi
}

verify_jdk()
{
	JDK=$(flatpak info $SDK | grep "Ref:" | sed -e 's,Ref: runtime/,,' -e 's,org.freedesktop.Sdk,org.freedesktop.Sdk.Extension.openjdk21,')
	OUTPUT=$(flatpak info $JDK 2>&1)
	if [ $? -ne 0 ] ; then
		echo "$JDK extension missing for runtime $SDK"
		exit 1
	fi
}

get_ghidra_version()
{
	TAG=$(jq -r '.["modules"].[] | select(.name=="ghidra")["sources"][] | select(.url=="https://github.com/NationalSecurityAgency/ghidra.git")["tag"]' org.ghidra_sre.Ghidra.json 2> /dev/null)
	if [ -z "$TAG" ] ; then
		echo "Could not extract current release tag from org.ghidra_sre.Ghidra.json"
		exit 1
	fi
	echo $TAG
}

get_ghidra_data_version()
{
	TAG=$(jq -r '.["modules"].[] | select(.name=="ghidra")["sources"][] | select(.url=="https://github.com/NationalSecurityAgency/ghidra-data.git")["tag"]' org.ghidra_sre.Ghidra.json 2> /dev/null)
	if [ -z "$TAG" ] ; then
		echo "Could not extract current data release tag from org.ghidra_sre.Ghidra.json"
		exit 1
	fi
	echo $TAG | sed 's/Ghidra_//'
}

SDK=$(get_sdk)
verify_jdk
TAG=$(get_ghidra_version)
DATA_VERSION=$(get_ghidra_data_version)

rm -rf _deps_build
echo "Checking out Ghidra $VERSION"
git clone https://github.com/NationalSecurityAgency/ghidra.git -b "$TAG" _deps_build
cd _deps_build
echo "Generating fetched gradle dependencies (ghidra-data v$DATA_VERSION)"
../gradle-fetched-deps-generator.py gradle/support/fetchDependencies.gradle ../gradle-fetched-dependencies.json --version "$DATA_VERSION"
echo "Generating deps log in Sdk $SDK"
echo "source /usr/lib/sdk/openjdk21/enable.sh && gradle -g gradle-cache --init-script gradle/support/fetchDependencies.gradle && rm -rf gradle-cache && gradle -g gradle-cache --info --console plain buildGhidra > gradle-log.txt" | flatpak run --share=network --filesystem=`pwd` --devel $SDK
wget https://raw.githubusercontent.com/flatpak/flatpak-builder-tools/master/gradle/flatpak-gradle-generator.py
chmod +x flatpak-gradle-generator.py
echo "Generating gradle dependencies"
./flatpak-gradle-generator.py gradle-log.txt ../gradle-dependencies.json --destdir dependencies/flatRepo --arches x86_64,aarch64
