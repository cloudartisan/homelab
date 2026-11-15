#!/usr/bin/env bash
# Fails if a tracked file contains private network detail: an RFC 1918 address,
# a MAC address, a .local hostname or a Tailscale auth key. That detail belongs
# in the private ops repo, not in this public one.
#
# Checks the git index, so it works as a pre-commit hook and in CI.
set -u

pattern='(^|[^0-9.])(10\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)'
pattern="$pattern"'|([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'
pattern="$pattern"'|[A-Za-z0-9-]+\.local([^A-Za-z0-9]|$)'
pattern="$pattern"'|tskey-[A-Za-z0-9]'

git grep --cached -n -I -E "$pattern" -- . ':!.github'
rc=$?

case $rc in
  0)
    echo "Private network detail found in the lines above. Move it to the private ops repo." >&2
    exit 1
    ;;
  1)
    echo "No private network detail found."
    exit 0
    ;;
  *)
    echo "git grep failed with exit code $rc." >&2
    exit 2
    ;;
esac
