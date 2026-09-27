#!/bin/bash
# cloneBuild.sh <GroupsCommit> <cloneDir> -- build ~/bin/incant as of a Groups commit, OUTSIDE Dropbox.
# Three repos at one date (Groups, InProcess/TOK, data/support); pbxproj absolute paths rewritten to the
# clone; Parse/Tokf/PLG linked live (headers only); committed .mm, NO retok. Prints the binary path.
set -e
G=/Users/anthony/Library/CloudStorage/Dropbox/data/InProcess
SUP=/Users/anthony/Library/CloudStorage/Dropbox/data/support
c=$1; C=$2; rm -rf "$C"; mkdir -p "$C/InProcess"
D=$(git -C "$G/Groups" log -1 --format=%cI "$c")
git clone -q "$G/Groups" "$C/InProcess/Groups"; git -C "$C/InProcess/Groups" checkout -q "$c"
git clone -q "$G/TOK" "$C/InProcess/TOK"; t=$(git -C "$G/TOK" rev-list -1 --before="$D" HEAD); git -C "$C/InProcess/TOK" checkout -q "$t"
git clone -q "$SUP" "$C/support"; s=$(git -C "$SUP" rev-list -1 --before="$D" HEAD); git -C "$C/support" checkout -q "$s"
for d in Frame Include KeyTable; do ln -s "$C/support/$d" "$C/InProcess/$d"; done
for d in Parse Tokf PLG; do [ -e "$G/$d" ] && ln -s "$G/$d" "$C/InProcess/$d"; done
P="$C/InProcess/TOK/TOK.xcodeproj/project.pbxproj"
sed -i '' -e "s|/Users/anthony/Dropbox/data/InProcess/|$C/InProcess/|g" -e "s|/Users/anthony/Library/CloudStorage/Dropbox/data/support/|$C/support/|g" "$P"
echo "Groups $c ($D)  TOK $t  support $s" > "$C/versions"
xcodebuild -project "$C/InProcess/TOK/TOK.xcodeproj" -scheme Groups -configuration Debug -derivedDataPath "$C/dd" build > "$C/build.log" 2>&1 || { tail -20 "$C/build.log"; exit 1; }
echo "live Groups paths in build log: $(grep -c "$G/Groups" "$C/build.log")" >> "$C/versions"
cat "$C/versions"; echo "BIN $C/dd/Build/Products/Debug/Groups"
