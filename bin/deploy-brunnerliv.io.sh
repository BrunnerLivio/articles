#!/usr/bin/env bash

git config --global user.name 'Github Actions'
git config --global user.email '41898282+github-actions[bot]@users.noreply.github.com'
cd "brunnerliv.io"
git submodule update --remote --init --recursive
git add -A .
git commit -m "Update submodules"

git push --force "https://${G_PUSH_TOKEN}@github.com/BrunnerLivio/brunnerliv.io.git" master:master
