#!/bin/bash
# shellcheck disable=2103,2164

cd "$(dirname "$0")"/..

# avoid command failure
exit_check() { [ "$1" = 0 ] || exit "$1"; }
trap 'exit_check $?' EXIT

# Shallow clone source
git clone \
	--depth 1 \
	-b "$BRANCH" \
	--shallow-submodules \
	--recurse-submodules \
	"$SOURCE" source

cd source

# Get variables
MSG=$(git log -1 --pretty=format:'%s')
DATE=$(git log -1 --pretty=format:'%ad' --date=format:'%a, %d %b %Y %H:%M:%S %z')
MAINTAINER=$(git log -1 --pretty=format:'%an <%ae>')
DISTRO="${DISTRO:-unstable}"

parse() {
	local var="$1"
	# Try to find the assignment, strip spaces, default to 0 if missing
	grep -m1 -E "^${var}[[:space:]]*=" "Makefile" |
		sed -E "s/^${var}[[:space:]]*=[[:space:]]*(.*)$/\1/" |
		tr -d '[:space:]'
}

VERSION=$(parse VERSION)
PATCHLEVEL=$(parse PATCHLEVEL)
SUBLEVEL=$(parse SUBLEVEL)
EXTRAVERSION=$(parse EXTRAVERSION)
: "${VERSION:=0}" "${PATCHLEVEL:=0}" "${SUBLEVEL:=0}" "${EXTRAVERSION:=0}"

cd ..

# Generate changelog
cat <<EOF >debian/changelog
linux-zenith ($VERSION.$PATCHLEVEL.$SUBLEVEL-$EXTRAVERSION) $DISTRO; urgency=medium

$(echo -e "$MSG" | sed -r 's/^/  * /g')

 -- $MAINTAINER  $DATE

EOF

# Move source
mv source/* .

# Additional files
## selinux_diffconfig
wget -O selinux_diffconfig https://raw.githubusercontent.com/BlissOS/device_generic_common/refs/heads/voyager-x86/selinux_diffconfig
