{ lib
, stdenvNoCC
, coreutils
, pdf2timetable
, pronote-timetable-fetch
, timetable2header
}:

{
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
datesWeekA
# Strings in ISO 8601 format
, datesWeekB
# Name of the file, pronote-timetable otherwise
, name ? ""

, outputHash     ? ""
, outputHashAlgo ? ""
, md5            ? ""
, sha1           ? ""
, sha256         ? ""
, sha512         ? ""

# Username to use to log in (string)
, username    
# Password to use to log in (string) 
, password
# Url to use to log in (string)
, url

# Meta information, if any.
, meta ? {}
# Passthru information, if any.
, passthru ? {}
}:

stdenvNoCC.mkDerivation {

  # New-style output content requirements.
  outputHashAlgo = if outputHashAlgo != "" then outputHashAlgo else
      if sha512 != "" then "sha512" else if sha256 != "" then "sha256" else if sha1 != "" then "sha1" else if md5 != "" then "md5" else "sha256";
  outputHash = if outputHash != "" then outputHash else
      if sha512 != "" then sha512 else if sha256 != "" then sha256 else if sha1 != "" then sha1 else if md5 != "" then md5 else "";
  outputHashMode = "recursive";

  name =
    if name != "" then name
    else "pronote-timetable";

  builder = ./builder.sh;
  nativeBuildInputs = [
    coreutils
    pdf2timetable
    pronote-timetable-fetch
    timetable2header
  ];

  fromWeekA = datesWeekA.from;
  toWeekA = datesWeekA.to;
  fromWeekB = datesWeekB.from;
  toWeekB = datesWeekB.to;

  inherit username password url;
  inherit meta;
  inherit passthru;
}

