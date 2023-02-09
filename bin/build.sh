#!/usr/bin/env bash
cd $(dirname $0)
_MyPath="$(pwd)"

getSubs() {
  git submodule update --init --recursive
}

if [ -f ../gambit/README ]; then
  echo "Already have gambit"
else
  echo "Updating submodules. This may take a while."
  getSubs
fi

buildGambit () {
 cd $_MyPath
 cd ../gambit
./configure --prefix=$(pwd) --enable-single-host \
            --enable-default-compile-options="(compactness 0)"
make clean
make -j8 core
make _gambit.js
cd -
}

if [[ -f ../gambit/gsc/gsc ]];
then
    echo "Have already built gsc"
else
    echo "Building Gambit"
    buildGambit
fi

GERBIL_SRC=$_MyPath/../gerbil
GAMBIT_SRC=$_MyPath/../gambit

export GERBIL_GSI=$GERBIL_SRC/gsi-js
export GERBIL_GSC=$GAMBIT_SRC/gsc/gsc

echo "Building gsi-js"
cd $GERBIL_SRC/src/gerbil && \
      $GERBIL_GSC -target js -exe -o $GERBIL_GSI ./gsi-js.scm

cd $_MyPath

ln -srvf $GERBIL_GSI $_MyPath/
ln -srvf $GERBIL_GSC $_MyPath/

build_gxi() {
    cd $GERBIL_SRC/src/ && ./build.sh gxi
    cd $_MyPath;
}

if [[ -f $GERBIL_SRC/src/gxi ]]; then
    echo "Already have gxi shim"
else
    build_gxi
fi

 ln -srvf $GERBIL_SRC/src/gxi $_MyPath/gxi-shim

build_bootstrap() {
    cd $GERBIL_SRC/src/ && ./build.sh stage0
    cd $_MyPath;
}

build_bootstrap

build_first_stage() {
    cd $GERBIL_SRC/src/ && ./build.sh stage1
    cd $_MyPath;
}

build_first_stage
