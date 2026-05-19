# Security policy

## Supported versions

uvenv tracks only the latest release. Please update before reporting issues —
`uvenv self-update` will pull the most recent version.

## Reporting a vulnerability

If you find a security issue (anything that could let one user affect another,
escalate privilege, or be triggered by a malicious package name / repo / shell
input), please report it **privately**:

- GitHub: open a draft security advisory via the
  [Security tab](https://github.com/sidhanthapoddar99/uvenv/security/advisories/new) —
  this keeps the report private until a fix is published.
- Email: not currently provided — use the GitHub advisory flow.

Please include:

- uvenv version (`uvenv version`)
- OS + shell (`uname -a`, `$SHELL`)
- A minimal reproduction
- Impact (what an attacker can do, and how a user gets exposed)

I aim to acknowledge within 7 days. Fixes ship in the next release. Credit in
release notes if you'd like it.

## What's in scope

- Shell injection via uvenv args (env names, paths, package names)
- Installer (`install.sh`) integrity / TOCTOU / atomic-swap weaknesses
- Anything that could let `uvenv self-update` install something unintended

## What's out of scope

- Vulnerabilities in `mise`, `uv`, or Python itself — report those upstream.
- Anything requiring an already-compromised account (you can already
  `rm -rf` everything; uvenv doesn't try to defend against that).
- Running arbitrary code that the user explicitly asked for
  (`uvenv exec mypkg -- ...` runs what you tell it to).
