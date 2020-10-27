#!/run/current-system/sw/bin/nix-build

(import <nixpkgs> {}).callPackage (import ./default.nix) { 
  datesWeekA = {
    from = "2020-11-02T00:00:00";
    to = "2020-11-08T00:00:00";
  };
  datesWeekB = {
    from = "2020-11-09T00:00:00";
    to = "2020-11-15T00:00:00";
  };
  timetable-sha256 = "0rck9p176px3nal9cdikgca88sxy2l15msnjd6d1gnq57vsrhqwf";
}
