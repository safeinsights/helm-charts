{{- define "secure-enclave.discoverManagementAddresses" -}}
set -eu

: > ip_addresses
lookup_file=$(mktemp)
addresses_file=$(mktemp)
trap 'rm -f "$lookup_file" "$addresses_file"' 0

if ! nslookup {{ include "secure-enclave.extractHostFromUrl" .Values.managementApp.endpoint | replace "'" "'\"'\"'" | squote }} > "$lookup_file"; then
  echo "Management DNS lookup failed" >&2
  exit 1
fi

# BusyBox prints the resolver before the first Name record.
if ! awk '
  /^Name:[[:space:]]/ { answer = 1; next }
  answer && /^Address([[:space:]]+[0-9]+)?:/ {
    sub(/^Address([[:space:]]+[0-9]+)?:[[:space:]]*/, "")
    address = $1
    if (address ~ /:/) {
      if (address !~ /:.*:/ || address !~ /^[[:xdigit:].:]+$/) invalid = 1
      next
    }
    if (address !~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
      invalid = 1
      next
    }
    split(address, octets, /[.]/)
    for (i = 1; i <= 4; i++) {
      if (length(octets[i]) > 3 || octets[i] > 255 || octets[i] ~ /^0[0-9]/) invalid = 1
    }
    if (!seen[address]++) {
      print address
      count++
    }
  }
  END { if (invalid || !count) exit 1 }
' "$lookup_file" > "$addresses_file"; then
  echo "Management DNS lookup returned no valid IPv4 answer set" >&2
  exit 1
fi

cat "$addresses_file" > ip_addresses
{{- end -}}
