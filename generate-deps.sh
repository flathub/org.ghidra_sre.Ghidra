#!/usr/bin/env bash

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

SDK=$(get_sdk)
verify_jdk

rm -rf _deps_build
git clone https://github.com/NationalSecurityAgency/ghidra.git -b stable _deps_build
cd _deps_build
echo "Generating deps log in Sdk $SDK"
echo "source /usr/lib/sdk/openjdk21/enable.sh && gradle -g gradle-cache --init-script gradle/support/fetchDependencies.gradle && rm -rf gradle-cache && gradle -g gradle-cache --info --console plain buildGhidra > gradle-log.txt" | flatpak run --share=network --filesystem=`pwd` --devel $SDK
wget https://raw.githubusercontent.com/flatpak/flatpak-builder-tools/master/gradle/flatpak-gradle-generator.py
chmod +x flatpak-gradle-generator.py
./flatpak-gradle-generator.py gradle-log.txt ../gradle-dependencies.json --destdir dependencies/flatRepo --arches x86_64,aarch64
