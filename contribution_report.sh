#!/usr/bin/env bash
set -euo pipefail

# Generates a consolidated git contribution report and writes it to report.txt
# by default, then prints the report to stdout.
output_file="${1:-report.txt}"

tmp_input="$(mktemp)"
trap 'rm -f "$tmp_input"' EXIT
git log --all --format='%an%x09%ae' > "$tmp_input"

python3 - "$tmp_input" > "$output_file" <<'PY'
import re
import sys
from collections import Counter


def normalize_name(name):
    # Strip non-alphanumeric and lowercase
    return re.sub(r'[^a-z0-9]', '', name.lower())


def is_generic(local_part):
    # Digits only
    if re.match(r'^\d+$', local_part):
        return True
    # System users
    if local_part in ['root', 'nobody', 'daemon', 'localhost']:
        return True
    # GitHub noreply style local part (e.g. 12345+user)
    if re.match(r'^\d+\+[\w-]+$', local_part):
        return True
    return False


identities = []
with open(sys.argv[1], 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

for line in lines:
    line = line.strip()
    if not line:
        continue
    parts = line.split('\t')
    if len(parts) != 2:
        continue
    name, email = parts
    identities.append((name, email))

total_commits = len(identities)
raw_counts = Counter(identities)
raw_identities_count = len(raw_counts)

# Grouping
groups = {}  # key -> list of (name, email)
for name, email in identities:
    email_lower = email.lower()
    local_part = email_lower.split('@')[0]

    if is_generic(local_part):
        key = 'name_' + normalize_name(name)
    else:
        key = 'email_' + local_part

    if key not in groups:
        groups[key] = []
    groups[key].append((name, email))

consolidated_results = []
major_merges = []

for key, members in groups.items():
    count = len(members)
    member_counts = Counter(members)

    # Canonical is the identity that appeared most often in the group.
    canonical = member_counts.most_common(1)[0][0]
    canonical_display = f"{canonical[0]} <{canonical[1]}>"

    consolidated_results.append(
        {
            'commits': count,
            'canonical': canonical_display,
            'variants': member_counts,
        }
    )

    if len(member_counts) >= 2:
        major_merges.append({'canonical': canonical_display, 'variants': member_counts})

consolidated_results.sort(key=lambda x: x['commits'], reverse=True)

print(f"Total commits: {total_commits}")
print(f"Number of raw identities: {raw_identities_count}")
print(f"Number of consolidated identities: {len(consolidated_results)}")
print('')
print(f"{'Commits':>8} {'%':>7}   {'Canonical Display'}")
print('-' * 60)
for item in consolidated_results:
    perc = (item['commits'] / total_commits) * 100
    print(f"{item['commits']:8d} {perc:6.2f}%   {item['canonical']}")

print('\nMajor Merges (2+ raw identities merged):')
print('-' * 60)
for m in sorted(major_merges, key=lambda x: sum(x['variants'].values()), reverse=True):
    total = sum(m['variants'].values())
    print(f"Canonical: {m['canonical']} (Total: {total})")
    for (name, email), count in m['variants'].most_common():
        print(f"  - {count:5d}: {name} <{email}>")
PY

cat "$output_file"