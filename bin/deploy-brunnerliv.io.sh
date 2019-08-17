#!/usr/bin/env bash

GITHUB_REF=github.com/BrunnerLivio/brunnerliv.io.git
REPO=brunnerliv.io


git clone "https://${GITHUB_REF}" "${REPO}"
git config user.name "Travis CI" && \
git config user.email "github@travis-ci.org" && \
cd "${REPO}"
git submodule update --remote --init --recursive
git add -A .
git commit -m "Update submodules"

git push --force "https://${GITHUB_TOKEN}@${GITHUB_REF}" master:master
echo "Pushed to https://${GITHUB_REF}"
cd ..
rm -rf "${REPO}"