# AGENTS.md — DumprX Agent Context

## Project Overview

DumprX is a Bash-based Android firmware dumper. It accepts a firmware file, an extracted firmware folder, or a supported download URL, extracts Android partitions, parses device/build properties, generates a README dump card, and can push the extracted tree to GitLab.

This project is intentionally a mostly single-script tool. The main behavior lives in `dumper.sh`; helper binaries/scripts live under `utils/`.

## Agent Operating Rules

- Read relevant parts of `dumper.sh` before editing it; do not assume line numbers are stable.
- Prefer minimal, targeted edits. This script handles many firmware formats; avoid broad refactors unless asked.
- Keep compatibility with Bash. Do not rewrite to POSIX `sh` or introduce non-Bash syntax incompatible with the existing style.
- Do not commit or print secrets from `.dumprxenv`.
- Do not add new runtime dependencies without updating `setup.sh` and documenting why.
- Validate shell changes with at least `bash -n dumper.sh`. Run `shellcheck -x dumper.sh` if available.
- There is no formal test suite; firmware validation is usually manual.
- Preserve local user changes. Check `git status --short` before committing/amending.

## Important Commands

```bash
# Syntax check
bash -n dumper.sh
bash -n setup.sh

# Optional lint if installed
shellcheck -x dumper.sh
shellcheck -x setup.sh

# Run locally without GitLab push
./dumper.sh --local <firmware-file-or-url>

# Generate README only
./dumper.sh --readme-only --local <extracted-folder-or-firmware>

# GitLab mode
./dumper.sh --gitlab <firmware-file-or-url>

# GitLab public repo override; default visibility is private
./dumper.sh --gitlab --public <firmware-file-or-url>
```

## Repository Structure

```text
DumprX/
├── dumper.sh              # Main entry point; extraction, parsing, README, GitLab push
├── setup.sh               # Dependency installer for apt/dnf/pacman/apk/brew
├── .dumprxenv.example     # Template for GitLab/Telegram settings
├── .dumprxenv             # Local secrets file; gitignored; never commit
├── .gitignore
├── README.md
├── LICENSE
└── utils/
    ├── bin/               # Prebuilt tools: 7zz, simg2img, magiskboot, payload-dumper-go, etc.
    ├── downloaders/        # URL download helpers
    ├── kdztools/           # LG KDZ/DZ extraction helpers
    ├── keyfiles/           # Decryption keys for OFP/OPS flows
    ├── sdat2img.py
    ├── avbtool.py
    ├── splituapp.py
    ├── unpackboot.sh
    ├── extract-ikconfig
    ├── dtc
    ├── unsin
    ├── lpunpack
    ├── nb0-extract
    ├── aml-upgrade-package-extract
    └── RUU_Decrypt_Tool
```

## Runtime Tooling

`dumper.sh` may clone external tools into `utils/` on first run. These directories are generated/runtime dependencies and should generally stay out of commits unless intentionally vendored.

Known runtime clones include:

- `bkerler/oppo_ozip_decrypt` — OZIP decryption
- `bkerler/oppo_decrypt` — OFP/OPS decryption
- `marin-m/vmlinux-to-elf` — kernel ELF/kallsyms extraction
- `ShivamKumarJha/android_tools` — miscellaneous Android tooling
- `HemanthJabalpuri/pacextractor` — Spreadtrum PAC extraction

## `dumper.sh` CLI

```bash
./dumper.sh [OPTIONS] <Firmware File/Extracted Folder -OR- Supported Website Link>

Options:
  -p, --push-only             Push only; skip extraction
  -r, --readme-only           Generate README.md only; skip extraction
  -m, --mode <local|gitlab>   Choose output mode
  -g, --gitlab                Shortcut for --mode gitlab
  -l, --local                 Shortcut for --mode local
      --public                Create GitLab repo as public; default is private
  -h, --help                  Show help
```

Current code initializes `MODE="gitlab"` while the help text may mention local as default. Verify actual code before changing behavior or docs.

## Key Variables in `dumper.sh`

| Variable | Purpose |
|---|---|
| `PROJECT_DIR` | Directory containing `dumper.sh` |
| `INPUTDIR` | Firmware download/preload directory, usually `${PROJECT_DIR}/input` |
| `UTILSDIR` | Helper scripts and binaries |
| `OUTDIR` | Final extracted output, currently `/tmp/out` |
| `WORK_TMPDIR` | Temporary work directory under `/tmp/out/tmp` |
| `MODE` | `local` or `gitlab` output behavior |
| `REPO_VISIBILITY` | GitLab repo visibility; `private` by default, `public` with `--public` |
| `PUSH_ONLY` | Skip extraction and push existing output |
| `README_ONLY` | Generate README only |

## Main Execution Areas

Use searches over fixed line numbers, but conceptually `dumper.sh` is organized as:

1. Banner, usage, CLI parsing, input validation
2. `.dumprxenv` sourcing, cleanup trap, helper functions
3. Tool setup, helper aliases, input resolution/download, archive detection
4. Format-specific extraction: OZIP/OPS/OFP/TGZ/KDZ/RUU/AML/other partition archives
5. Partition extraction: payload.bin, QFIL, NB0, chunks, SIN, PAC, bin, super images, DAT OTA
6. Partition conversion/normalization: `simg2img`, header stripping, `super_*.img` handling
7. Boot/recovery/vendor_boot/dtbo extraction and kernel metadata extraction
8. Filesystem extraction: EROFS, 7zz fallback, loop mount fallback
9. Property parsing via `prop_get` and vendor-specific fallbacks/overrides
10. README generation
11. TWRP device tree generation via `twrpdtgen`
12. GitLab repo creation, staged commits, LFS handling, push retry, Telegram notification

## Supported Firmware Families

- Archives: ZIP, RAR, 7z, TAR, TAR.GZ, TGZ, TAR.MD5
- Oppo/Realme/OnePlus: OZIP, OFP, OPS
- LG: KDZ/DZ
- HTC: RUU
- Sony: SIN
- Huawei: UPDATE.APP
- Qualcomm/QFIL: rawprogram XML, signed images
- Spreadtrum: PAC
- Amlogic: AML upgrade packages
- Rockchip images
- Generic Android: `payload.bin`, `super.img`, `system.new.dat*`, sparse/raw images, NB0, chunked images, `emmc.img`, `img.ext4`

## Property Extraction Pattern

`prop_get` is the central helper for reading Android `build*.prop` files from multiple possible partition paths.

Example pattern:

```bash
prop_get "ro.product.manufacturer:{system,system/system,vendor}"
```

This searches matching `build*.prop` files under the listed locations and returns the first useful value. Property logic uses cascading fallbacks across `system`, `vendor`, `product`, Euclid/Transsion layouts, Oppo/My* partitions, and other vendor-specific paths.

When adding properties:

- Prefer adding to existing fallback chains instead of creating a separate one-off parser.
- Preserve vendor-specific overrides already present.
- Quote variables and paths because firmware filenames/paths can contain spaces or unusual characters.

## GitLab Push Pipeline Notes

GitLab mode requires `GITLAB_TOKEN` and usually `GITLAB_GROUP` in `.dumprxenv`.

Pipeline responsibilities:

1. Check whether firmware is already dumped through remote `all_files.txt`.
2. Create/find manufacturer subgroup.
3. Create/find project repo.
4. Initialize git repo in `OUTDIR`.
5. Commit in stages: README, LFS setup, APKs, partition groups, extras.
6. Push via SSH to avoid HTTPS issues with large repos.
7. Update default branch.
8. Optionally send Telegram notification.

### Retry/LFS Gotcha

Normal git pushes use `retry_push()`, which wraps `git push "$@"`.

Do **not** use `retry_push` for LFS object uploads inside `push_lfs_objects()` workers. Those workers run through `xargs ... bash -c`, and LFS uploads must call:

```bash
git lfs push --object-id origin "$oid"
```

Using `retry_push lfs push ...` would become the wrong command (`git push lfs push ...`) and may also fail because shell functions are not exported into the `bash -c` worker.

## Shell Style Guidelines

- Existing code uses Bash features: `[[ ]]`, arrays, regex matching, process substitution, functions.
- Keep `set -e` assumptions conservative; many extraction branches intentionally tolerate failures and fallback.
- Quote paths and variable expansions unless intentionally using globbing or word splitting.
- Be careful with `find ... -exec rm -rf`; constrain paths tightly.
- Be careful with recursive self-invocation (`reload_and_rerun`, `bash "${0}"`); preserve arguments and mode flags.
- Prefer local git config changes inside generated repos over global git config mutations.

## Secrets and Generated Files

Never commit:

- `.dumprxenv`
- `input/`, `tmp/`, local output folders
- Runtime-cloned tool directories unless intentionally vendored
- Python caches or generated extraction output

`.dumprxenv.example` is safe to edit when adding new supported environment variables.

## Common Change Checklist

Before finishing a code change:

- [ ] `git status --short` checked for unrelated changes
- [ ] Relevant section of `dumper.sh` read before editing
- [ ] `bash -n dumper.sh` passes
- [ ] `shellcheck -x dumper.sh` run if available
- [ ] Help text updated if CLI flags changed
- [ ] `setup.sh` updated if dependencies changed
- [ ] `.dumprxenv.example` updated if env vars changed
- [ ] README/AGENTS updated if behavior or workflow changed
