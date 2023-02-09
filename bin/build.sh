#!/usr/bin/env bash
_MyPath=$(dirname $0)
cd $_MyPath;

getSubs() {
  git submodule update --init --recursive
}

if [ -f ../gambit/README ]; then
  echo "Already have gambit"
else
  git submodule update --init --recursive
fi
