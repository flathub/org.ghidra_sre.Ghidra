#!/usr/bin/env bash

BRANCH=test

rm -f org.ghidra_sre.Ghidra.flatpak
rm -rf _build ; mkdir _build
rm -rf _repo ; mkdir _repo

flatpak-builder --ccache --force-clean --default-branch=$BRANCH _build org.ghidra_sre.Ghidra.json --repo=_repo
