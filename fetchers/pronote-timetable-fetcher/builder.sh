source $stdenv/setup

set -e
unset PATH
for p in $nativeBuildInputs; do
  export PATH=$p/bin${PATH:+:}$PATH
done

echo "Fetching..."
pronote-timetable-fetch --from "$fromWeekA" --to "$toWeekA" -u "$username" -p "$password" -U "$url" -o timetable_week_a.json
pronote-timetable-fetch --from "$fromWeekB" --to "$toWeekB" -u "$username" -p "$password" -U "$url" -o timetable_week_b.json
echo "Fetched"
mkdir -p "$out"
cp timetable_week_?.json "$out"
echo "Converting json to timetable..."
pdf2timetable -m "json2timetable timetable_week_a.json timetable_week_b.json timetable.xlsx"
cp timetable.xlsx "$out"
echo "Converting json to timetable..."
echo "Converting to header..."
timetable2header timetable.xlsx > "$out/header.h"

exit 0
