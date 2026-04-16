# Ansys Install Helper for Linux

Interactive Bash helper for preparing and running Ansys Linux installs from ISO or TGZ media.

This project is aimed at repeatable bare-metal or VM installs where you want one place to:

- detect the operating system
- install missing prerequisite packages
- prepare Ansys install media
- run silent installs with remembered product selections
- pass license server info to the installer

It currently supports these Ansys releases:

- `2023R2`
- `2024R1`
- `2024R2`
- `2025R1`
- `2025R2`
- `2026R1`

It currently supports these Linux families:

- RHEL / Rocky / Alma / Oracle Linux 8
- RHEL / Rocky / Alma / Oracle Linux 9
- SLES 15
- Ubuntu 22.04
- Ubuntu 24.04

## Main script

- `ansys_install_helper.sh`

The script is self-contained. It embeds the prerequisite package arrays and does not require `prereq/*.txt` at runtime.

## What it does

- Detects the local OS and package manager.
- Offers prerequisite profiles:
  - `All Products`
  - `Core Solvers`
  - `License Manager Only`
  - `Installer Prerequisites Only`
- Supports real installer modes:
  - `Products`
  - `License Manager`
- Supports media preparation for:
  - full multi-disk ISO sets
  - one TGZ archive per install pass
- Remembers product selections during the current session.
- Allows repeated install passes, which is useful for follow-up TGZ or service-pack installs.
- Passes `-licserverinfo` to the installer when you configure a license hostname.

## What it does not do

- It does not support ISO + TGZ mixed media in one install pass.
- It does not auto-chain service packs; instead, you prepare and run a second install pass.

## Requirements

- Bash 4.3 or newer
- Linux host in one of the supported OS families
- Root privileges for package installation, ISO mounting, system install locations, and symlink creation
- Enough disk space for:
  - the target install
  - `/tmp` or your chosen temp directory
  - any TGZ extraction or locally staged ISO copies

## Recommended workflow

1. Run the helper as root.
2. Select the target Ansys version.
3. Set the media source path.
4. Install prerequisites.
5. Prepare media.
6. Configure install options.
7. Optionally set a license hostname.
8. Run the install.
9. Review `install.err` if the installer reports problems.

## CLI usage

```bash
sudo bash ansys_install_helper.sh --help
```

Options:

- `--source <path>`: source directory or single media file path
- `--version <ver>`: Ansys version, for example `2026R1`
- `--install-dir <path>`: custom install root
- `--dry-run`: print mutating commands instead of executing them
- `--no-color`: disable colored output
- `--nochecks`: pass `-nochecks` to the Ansys installer
- `--temp-dir <path>`: use a specific temp directory and pass `-usetempdir`
- `--help`: show help text

## Examples

Prepare a normal interactive session with an ISO directory:

```bash
sudo bash ansys_install_helper.sh \
  --source /mnt/media/2026R1_ISOs \
  --version 2026R1
```

Start from a single TGZ installer with a custom install path:

```bash
sudo bash ansys_install_helper.sh \
  --source /mnt/media/FLUIDSTRUCTURES_2026R1_LINX64.tgz \
  --version 2026R1 \
  --install-dir /usr/ansys_inc_test
```

Preview actions without making changes:

```bash
bash ansys_install_helper.sh \
  --source /mnt/media/ANSYS_2025R2.04_LINX64.tgz \
  --version 2025R2 \
  --dry-run
```

## Media rules

### ISO media

- Point `--source` to a directory containing the full ISO set for the selected release.
- The helper validates that the expected disk count is present.
- Disk 1 is used as the main launch media.
- Additional disks are passed with `-media_dir2`, `-media_dir3`, and so on.

### TGZ media

- Point `--source` to a directory with TGZ files or directly to one TGZ file.
- Each install pass uses one TGZ archive.
- The helper extracts the archive and checks that an `INSTALL` script exists in the extracted tree.
- If you need a second TGZ pass later, prepare media again and rerun install.

## License behavior

- Use menu option `7` to store a license server hostname.
- The helper passes that information to the installer with:

```text
-licserverinfo 2325:1055:hostname
```

- The helper asks only for the hostname.
- The ports are fixed to `2325:1055` by default.
- The helper no longer writes `ansyslmd.ini` directly.

## License Manager mode

`License Manager Only` appears in two different places for different reasons:

- In prerequisites, it selects the smaller `licmgr` package set.
- In install configuration, it switches the real installer into `-lm` mode.

Use both together when you want a license-only deployment.

## Logging and error handling

- The helper writes to `ansys_install_helper.log` in the current working directory.
- Installer errors are checked in:

```text
<install_dir>/install.err
```

- If a previous `install.err` exists, the helper archives it before a new install run.

## Known limitations

- Some network or FUSE-mounted media paths may be readable by your login user but not by `root` under `sudo`. In that case, stage the media to a local root-readable path first.
- The helper does not guarantee every distro package name is still present in every enabled repository; when package installation fails, it reports the remaining missing packages and points you to the log.
- Product flags that require an additional path, such as some AVxcelerate components, will prompt for that path when selected.
