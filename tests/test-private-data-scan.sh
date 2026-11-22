#!/usr/bin/env bash
# Tests of the private-data guard: scripts/private-data-scan.sh with the rules of .gitleaks.toml.
# Each case writes one temporary file and checks the exit code of `gitleaks dir` on it: 1 when the
# guard must refuse the file, 0 when it must admit it. The cases build each private value at run
# time, so this file holds no value that the guard refuses. Run it with
# `mise exec -- tests/test-private-data-scan.sh`.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scan="$root/scripts/private-data-scan.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

# ip A B C D writes the IPv4 address A.B.C.D.
ip() {
  local IFS=.
  echo "$*"
}
dev=dev
lan=lan
local_tld=local

# expect WANT NAME CONTENT [DOMAINS]: scan a file that holds CONTENT, with PRIVATE_DOMAINS set to
# DOMAINS, and compare the exit code with WANT.
expect() {
  local want="$1" name="$2" content="$3" domains="${4-}" got=0
  local dir="$work/$name"
  cases=$((cases + 1))
  mkdir -p "$dir"
  printf '%s\n' "$content" >"$dir/file.txt"
  PRIVATE_DOMAINS="$domains" GITHUB_ACTIONS='' "$scan" dir "$dir" >"$dir.log" 2>&1 || got=$?
  if [ "$got" -eq "$want" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name: exit $got, want $want"
    sed 's/^/     /' "$dir.log"
    failures=$((failures + 1))
  fi
}

# expect_log NAME TEXT: the log of case NAME holds TEXT.
expect_log() {
  cases=$((cases + 1))
  if grep -qF -- "$2" "$work/$1.log"; then
    echo "ok   $1 log"
  else
    echo "FAIL $1 log: no line holds: $2"
    failures=$((failures + 1))
  fi
}

# The cases of the acceptance criteria of dan-petty/infra#4.
expect 1 issue-host "address: $(ip 10 0 0 1)
host: node1.$lan"
expect 0 k3s-cluster-cidr "cluster-cidr: $(ip 10 42 0 0)/16"

# RFC 1918, CGNAT and link-local host addresses and subnets.
expect 1 rfc1918-10 "server: $(ip 10 1 2 3)"
expect 1 rfc1918-172 "server: $(ip 172 16 5 4)"
expect 1 rfc1918-172-top "server: $(ip 172 31 255 1)"
expect 1 rfc1918-192 "server: http://$(ip 192 168 1 10):8080/"
expect 1 rfc1918-subnet "subnet: $(ip 192 168 1 0)/24"
expect 1 cgnat "server: $(ip 100 64 0 1)"
expect 1 cgnat-top "server: $(ip 100 127 255 254)"
expect 1 link-local-ipv4 "server: $(ip 169 254 1 1)"
expect 1 link-local-ipv6 "server: fe$((80))::1"
expect 1 k3s-pod-address "pod: $(ip 10 42 3 17)"

# Public addresses, the RFC 5737 ranges, the k3s defaults and the block of each range.
expect 0 public-172 "server: $(ip 172 15 0 1) and $(ip 172 32 0 1)"
expect 0 public-100 "server: $(ip 100 128 0 1)"
expect 0 version-string "version: 1.$(ip 10 0 0 1)"
expect 0 rfc5737 "servers: $(ip 192 0 2 10), $(ip 198 51 100 7) and $(ip 203 0 113 0)/24"
expect 0 k3s-service-cidr "service-cidr: $(ip 10 43 0 0)/16"
expect 0 rfc-blocks "except: [$(ip 10 0 0 0)/8, $(ip 172 16 0 0)/12, $(ip 192 168 0 0)/16, $(ip 100 64 0 0)/10, $(ip 169 254 0 0)/16]"

# Names of a local network.
expect 1 lan-name "host: printer.$lan"
expect 1 local-name "host: nas.$local_tld."
expect 0 cluster-local "url: http://web.default.svc.cluster.$local_tld:8080"
expect 0 local-file-name "file: mise.$local_tld.toml"

# Device paths.
expect 1 block-device "device: /$dev/sda"
expect 1 disk-by-id "device: /$dev/disk/by-id/nvme-EXAMPLE_SERIAL"
expect 0 pseudo-devices "out: /$dev/null /$dev/stdout /$dev/stderr /$dev/urandom /$dev/fd/3 /$dev/shm."
expect 0 termination-log "terminationMessagePath: /$dev/termination-log"
expect 0 not-a-device "path: /var/$dev/sda and https://example.com/$dev/sda"

# The rule private-domain, which the guard makes from PRIVATE_DOMAINS.
domains="example.net
EXAMPLE.org "
expect 1 private-domain "url: https://www.example.net/path" "$domains"
expect_log private-domain "The rule private-domain refuses the 2 domains of PRIVATE_DOMAINS."
expect 1 private-domain-upper "mail: admin@EXAMPLE.ORG" "$domains"
expect 0 public-domain "url: https://example.com and https://notexample.net and example.network" "$domains"
expect 0 no-private-domains "url: https://www.example.net/path"
expect_log no-private-domains "PRIVATE_DOMAINS is not set, so the rule private-domain did not run."
expect 2 bad-private-domains "url: https://example.com" "example.net
not a domain"
expect_log bad-private-domains "Line 2 of PRIVATE_DOMAINS is not a domain name."

echo "$((cases - failures)) of $cases cases passed"
[ "$failures" -eq 0 ]
