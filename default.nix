
let
  pkgs = import (
    builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs-channels/archive/84d74ae9c9cbed73274b8e4e00be14688ffc93fe.tar.gz";
      sha256 = "0ww70kl08rpcsxb9xdx8m48vz41dpss4hh3vvsmswll35l158x0v";
    }
  ) {};
  shamilton = import (
      builtins.fetchTarball {
        url = "https://github.com/SCOTT-HAMILTON/nur-packages-template/archive/ea08d876f8f23f19ef8259cb548f480c4065427f.tar.gz";
        sha256 = "074qgw2i3cj0nnhwinjnfgvp0kyakxbpbfgwkaab3mk5xjij04lg";
      }
    ) {
    inherit pkgs;
  };
  credentials = import ./credentials.nix;
in 
{ lib
, callPackage
, stdenv
, pdf2timetable ? shamilton.pdf2timetable
, pronote-timetable-fetch ? shamilton.pronote-timetable-fetch
, timetable2header ? shamilton.timetable2header

# Intervals to fetch the timetable from
# example :
#   datesWeekA = {
#     from = "2020-11-02T00:00:00";
#     to = "2020-11-08T00:00:00";
#   }
#   datesWeekB = {
#     from = "2020-11-09T00:00:00";
#     to = "2020-11-15T00:00:00";
#   }
, datesWeekA
, datesWeekB
#  Username to use to log in (string)
, username ? credentials.username
#  Password to use to log in (string) 
, password ? credentials.password
#  Url to use to log in (string)
, url ? credentials.url
#  Name of the timetable owner (string)
, name ? credentials.name
# sha256 of the fetched timetable
, timetable-sha256 ? "0000000000000000000000000000000000000000000000000000"

, buildBinpack ? false
, buildDebug ? false
, buildDoc ? true
, buildSimulator ? true
, buildWithCCache ? false
, numworks_model ? "n0110"
, owner_name
}:
let
  pronote-timetable-fetcher = callPackage ./fetchers/pronote-timetable-fetcher {
    inherit pronote-timetable-fetch pdf2timetable timetable2header;
  };
  timetable = pronote-timetable-fetcher {
    inherit datesWeekA datesWeekB username password url;
    sha256 = timetable-sha256;
  };
  extraAgendas = {
    "${lib.toLower name}" = "${timetable}";
  };
  omega = callPackage ./omega {
    inherit buildWithCCache buildSimulator buildBinpack buildDebug buildDoc owner_name;
    extraAgendas = lib.concatStringsSep " " (lib.mapAttrsToList (name: value: name+"@"+value) extraAgendas);
  };
in
stdenv.mkDerivation rec {
  pname = "pronote-timetable-toolchain";
  version = "unstable";

  src = ./run.sh;
  dontUnpack = true;

  sourceRoot = ".";

  propagatedBuildInputs = [ omega ];
  
  postPatch = ''
    cp "${src}" run.sh
    substituteInPlace run.sh \
      --replace "@omega@" "${omega}"
    cat "${timetable}/header.h"
    echo "${timetable}"
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    install -Dm 555 run.sh "$out/bin/run"
    patchShebangs  "$out/bin/run"
  '';

  meta = with lib; {
    description = "Omega rom builder with timetable fetched from pronote to agenda app";
    license = licenses.mit;
    maintainers = [ "Scott Hamilton <sgn.hamilton+nixpkgs@protonmail.com>" ];
    platforms = platforms.linux;
  };
}
