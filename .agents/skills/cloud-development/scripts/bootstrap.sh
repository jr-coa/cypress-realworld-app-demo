#!/usr/bin/env bash
set -euo pipefail

RWA_REPO_DIR="$(python3 - <<'PY'
import os
import subprocess
from pathlib import Path
from urllib.parse import urlsplit

workspace = Path('/workspace').resolve()
provided = os.environ.get('RWA_REPO_DIR')
if provided:
    candidates = [Path(provided)]
else:
    candidates = []
    skip = {'.git', '.tools', 'node_modules', 'build', 'dist', '.cache', '.nyc_output', 'artifacts', 'attachments'}
    for current, dirs, files in os.walk(workspace):
        if '.git' in dirs or '.git' in files:
            candidates.append(Path(current))
        dirs[:] = [name for name in dirs if name not in skip]

matches = set()
for candidate in candidates:
    try:
        root = Path(subprocess.check_output(
            ['git', '-C', str(candidate), 'rev-parse', '--show-toplevel'],
            text=True, stderr=subprocess.DEVNULL).strip()).resolve()
        remote = subprocess.check_output(
            ['git', '-C', str(root), 'remote', 'get-url', 'origin'],
            text=True, stderr=subprocess.DEVNULL).strip()
        parsed = urlsplit(remote)
        identity = parsed.path.strip('/').removesuffix('.git')
        if remote.startswith('git@github.com:'):
            identity = remote.split(':', 1)[1].removesuffix('.git')
            host = 'github.com'
        else:
            host = parsed.hostname
        if host == 'github.com' and identity == 'jr-coa/cypress-realworld-app-demo':
            if not root.is_relative_to(workspace) or root == workspace:
                raise SystemExit('The checkout must be inside /workspace.')
            matches.add(str(root))
    except (OSError, subprocess.CalledProcessError):
        continue

if len(matches) != 1:
    raise SystemExit('Select the fork checkout, or set RWA_REPO_DIR to its exact path.')
print(matches.pop())
PY
)"
export RWA_REPO_DIR

rwa_installer="$RWA_REPO_DIR/.agents/skills/cloud-development/scripts/install.sh"
if [[ ! -f "$rwa_installer" ]]; then
  printf 'Setup files are missing. Select the fork develop branch in the new environment.\n' >&2
  exit 1
fi
exec bash "$rwa_installer"
