{ lib
, stdenv
, fetchFromGitHub
, ccacheStdenv
, ccache
, doxygen
, gcc-arm-embedded-8
, git
, pkg-config
, python3

, freetype
, libX11
, libXext
, libjpeg_drop
, libpng12

, buildBinpack ? false
, buildDebug ? false
, buildDoc ? false
, buildSimulator ? true
, buildWithCCache ? false
, numworks_model ? "n0110"
, owner_name

# extra agendas to include in the agenda app
# example : 
# extraAgendas = {
#   john = "store/path/or/directory/generated/by/pronote/timetable/fetcher";
#   jack = "same/but/for/jack";
# }
, extraAgendas ? null

, breakpointHook
}:

stdenv.mkDerivation rec {
  pname = "omega-numworks";
  version = "master";

  src = fetchFromGitHub {
    owner = "SCOTT-HAMILTON";
    repo = "Omega";
    rev = "f857b6f644b48c95c74f8e02db4ad57cca6ec286";
    sha256 = "0000000000000000000000000000000000000000000000000000";
    fetchSubmodules = true;
  };

  # src = ./src.tar.gz;

  patches = [
    ./use-coreutils-shasum.patch
    ./agenda_icon_themes.patch
  ];

  inherit extraAgendas;
  update-headers-script = ./update-headers.py;
  postPatch = lib.optionalString (extraAgendas != null) ''
    cd apps/agenda
    echo
    echo "Extra agendas : ${extraAgendas}"
    for agenda in ${extraAgendas}; do
      name=$(python -c "print('$agenda'.split('@')[0])")
      timetable="$(python -c "print('$agenda'.split('@')[1])")/header.h"
      echo "name : '$name'"
      echo "timetable : '$timetable'"
      python ${update-headers-script} "$name" "$timetable"
    done
    echo
    echo
    cd ../..
    '' + 
    lib.optionalString buildWithCCache
      (lib.optionalString buildBinpack
      ''
      substituteInPlace "build/toolchain.arm-gcc.mak" \
        --replace "CC = arm-none-eabi-gcc" "CC = ccache arm-none-eabi-gcc" \
        --replace "CXX = arm-none-eabi-g++" "CXX = ccache arm-none-eabi-g++" \
        --replace "LD = arm-none-eabi-gcc" "LD = ccache arm-none-eabi-gcc" \
        --replace "OBJCOPY = arm-none-eabi-objcopy" "OBJCOPY = ccache arm-none-eabi-objcopy" \
        --replace "SIZE = arm-none-eabi-size" "SIZE = ccache arm-none-eabi-size"
      '' +
      lib.optionalString buildSimulator
      ''
      substituteInPlace "build/toolchain.host-gcc.mak" \
        --replace "CC = gcc" "CC = ccache gcc" \
        --replace "CXX = g++" "CXX = ccache g++" \
        --replace "LD = g++" "LD = ccache g++"
      '');

  nativeBuildInputs = [
    breakpointHook
    doxygen
    gcc-arm-embedded-8
    git
    pkg-config
    python3
  ] ++ 
  lib.optional buildWithCCache [ ccache ];
  
  buildInputs = [
    freetype
    libpng12
    libX11
    libXext
    libjpeg_drop
  ];
  
  buildPhase = 
    lib.optionalString buildWithCCache ''
    export CCACHE_COMPRESS=1
    export CCACHE_DIR="/cache"
    export CCACHE_UMASK=007
    if [ ! -d "$CCACHE_DIR" ]; then
      echo "====="
      echo "Directory '$CCACHE_DIR' does not exist"
      echo "Please create it with:"
      echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
      echo "  sudo chown root:nixbld '$CCACHE_DIR'"
      echo "====="
      exit 1
    fi
    if [ ! -w "$CCACHE_DIR" ]; then
      echo "====="
      echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
      echo "Please verify its access permissions"
      echo "====="
      exit 1
    fi
    echo $CCACHE_DIR
    '' +
    lib.optionalString buildBinpack
    ''
    make -j4 OMEGA_USERNAME="${owner_name}" THEME_NAME=omega_dark binpack
    '' +
    lib.optionalString buildSimulator
    ''
    make -j4 ''+lib.optionalString buildDebug " DEBUG=1 "+ ''THEME_NAME=omega_dark OMEGA_USERNAME="${owner_name}" PLATFORM=simulator
    '' +
    lib.optionalString buildDoc
    ''
    make -j4 doc
    '';

  dontStrip = buildDebug;

  installPhase = lib.optionalString buildSimulator
    (''
    install -Dm 755 "output/''+(if buildDebug then "debug" else "release")+''/simulator/linux/epsilon.bin" "$out/bin/espilon-simulator"
    '') +
    lib.optionalString buildBinpack
    ''
    ls -lh "output/release"
    ls -lh "output/release/device/${numworks_model}"
    # Install binpack
    install -Dm 755 "output/release/device/${numworks_model}/epsilon.onboarding.elf" "$out/binpacks/${numworks_model}/epsilon.onboarding.elf"
    install -Dm 755 "output/release/device/${numworks_model}/epsilon.onboarding.external.bin" "$out/binpacks/${numworks_model}/epsilon.onboarding.external.bin"
    install -Dm 755 "output/release/device/${numworks_model}/epsilon.onboarding.internal.bin" "$out/binpacks/${numworks_model}/epsilon.onboarding.internal.bin"
    install -Dm 755 "output/release/device/${numworks_model}/flasher.light.bin" "$out/binpacks/${numworks_model}/flasher.light.bin"
    install -Dm 755 "output/release/device/${numworks_model}/flasher.light.elf" "$out/binpacks/${numworks_model}/flasher.light.elf"
    '' +
    lib.optionalString buildDoc
    ''
      ls -lh docs
      mkdir -p "$out"
      cp -r output/doc "$out"

    '';

  meta = with lib; {
    description = "Omega rom for numworks calculator";
    license = licenses.cc-by-nc-sa-40;
    homepage = "https://getomega.dev/";
    maintainers = [ "Scott Hamilton <sgn.hamilton+nixpkgs@protonmail.com>" ];
    platforms = platforms.linux;
  };
}
