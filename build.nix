#!/run/current-system/sw/bin/nix-build

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
  localShamilton = import ~/GIT/nur-packages-template {inherit pkgs;};
in
pkgs.callPackage (import ./default.nix) {
  datesWeekA = {
    from = "2020-11-02T00:00:00";
    to = "2020-11-08T00:00:00";
  };
  datesWeekB = {
    from = "2020-11-09T00:00:00";
    to = "2020-11-15T00:00:00";
  };
  owner_name = "Scott Hamilton";
  timetable-sha256 = "1zvhrswizvc7lvbj8xa6v4302ipv7kndijhlgac0cvliw3spdllq";

  # Optional build flags
  buildSimulator = true;
  buildBinpack = false;
  buildDebug = false;
  buildDoc = false;
  # Requires a configured ccache folder in /cache
  buildWithCCache = true;
  pdf2timetable = localShamilton.pdf2timetable;
  pronote-timetable-fetch = localShamilton.pronote-timetable-fetch;
  timetable2header = localShamilton.timetable2header;
}
