#!/usr/bin/env bash
set -euo pipefail

# Ansys Install Helper for Linux
# by AMP HPC
# Copyright 2026

SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="Ansys Install Helper for Linux"
BRAND="AMP HPC"
COPYRIGHT_YEAR="2026"
LOG_FILE="ansys_install_helper.log"
DEFAULT_INSTALL_DIR="/usr/ansys_inc"
SYMLINK_PATH="/ansys_inc"
LICENSE_INI_RELATIVE="shared_files/licensing/ansyslmd.ini"
MIN_DISK_SPACE_MB=50000
MIN_TMP_SPACE_MB=2000
SUPPORTED_VERSIONS=("2023R2" "2024R1" "2024R2" "2025R1" "2025R2" "2026R1")

declare -A VERSION_CODES=(
    [2023R2]=232
    [2024R1]=241
    [2024R2]=242
    [2025R1]=251
    [2025R2]=252
    [2026R1]=261
)

declare -A DISK_COUNTS=(
    [2023R2]=3
    [2024R1]=3
    [2024R2]=4
    [2025R1]=9
    [2025R2]=9
    [2026R1]=13
)

LOG_PATH="${PWD}/${LOG_FILE}"

SELECTED_VERSION=""
SELECTED_VERSION_CODE=""
SOURCE_DIR=""
SOURCE_PATH_TYPE=""
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
PKG_PROFILE="all"
INSTALL_MODE="products"
PRODUCT_SELECTION_MODE="all"
SELECTED_PRODUCT_KEYS=()
CREATE_SYMLINK=1
LICENSE_HOSTNAME=""
DRY_RUN=0
NO_COLOR=0
INSTALLER_NOCHECKS=0
TEMP_DIR_OVERRIDE=""
MEDIA_TYPE=""
CURRENT_MEDIA_LABEL=""
MOUNT_POINTS=()
EXTRACT_DIRS=()
MEDIA_EXTRA_ARGS=()
MERGED_MEDIA_DIR=""
WORK_DIR=""
SCAN_ISOS=()
SCAN_TGZS=()
SCAN_TGZ_VERSIONS=()

OS_ID=""
OS_VERSION_ID=""
OS_MAJOR=""
OS_FAMILY=""
PKG_MGR=""
IS_ROOT=0

STATUS_VERSION_SET=0
STATUS_SOURCE_SET=0
STATUS_PREREQS_DONE=0
STATUS_GOODIES_DONE=0
STATUS_MEDIA_PREPARED=0
STATUS_INSTALL_CONFIGURED=0
STATUS_INSTALL_DONE=0
STATUS_LICENSE_DONE=0
INSTALL_LOG_TAIL_PID=""

RED=""
GREEN=""
YELLOW=""
BLUE=""
CYAN=""
BOLD=""
DIM=""
RESET=""

ALREADY_INSTALLED=()
NEEDS_INSTALL=()

GOODIES_COMMON=(tmux pv moreutils smartmontools)
GOODIES_RHEL=(nfs-utils)
GOODIES_SLES=(nfs-client)
GOODIES_UBUNTU=(nfs-common)

# Embedded prerequisite package arrays

PKGS_INSTALLER_RHEL8=(
    "brotli"
    "bzip2-libs"
    "cyrus-sasl-lib"
    "expat"
    "fontconfig"
    "freetype"
    "glib2"
    "glibc"
    "glibc-devel"
    "gmp"
    "gnutls"
    "gzip"
    "keyutils-libs"
    "krb5-libs"
    "libICE"
    "libSM"
    "libX11"
    "libX11-xcb"
    "libXau"
    "libXext"
    "libXft"
    "libXrender"
    "libcom_err"
    "libcurl"
    "libffi"
    "libidn2"
    "libjpeg-turbo"
    "libnghttp2"
    "libnsl"
    "libnsl2"
    "libpng"
    "libpsl"
    "libselinux"
    "libssh"
    "libtasn1"
    "libunistring"
    "libuuid"
    "libxcb"
    "libxcrypt"
    "libxkbcommon"
    "libxkbcommon-x11"
    "libzstd"
    "nettle"
    "openldap"
    "openssl-libs"
    "p11-kit"
    "pcre"
    "pcre2"
    "tar"
    "which"
    "xcb-util"
    "xcb-util-cursor"
    "xcb-util-image"
    "xcb-util-keysyms"
    "xcb-util-renderutil"
    "xcb-util-wm"
    "xorg-x11-fonts-100dpi"
    "xorg-x11-fonts-75dpi"
    "zlib"
)
# Total: 59 packages

PKGS_LICMGR_RHEL8=(
    "bzip2-libs"
    "expat"
    "fontconfig"
    "freetype"
    "glib2"
    "glibc"
    "glibc-devel"
    "gmp"
    "gnutls"
    "libICE"
    "libSM"
    "libX11"
    "libXau"
    "libXext"
    "libXrender"
    "libffi"
    "libgcc"
    "libidn2"
    "libjpeg-turbo"
    "libnsl"
    "libnsl2"
    "libpng"
    "libstdc++"
    "libtasn1"
    "libunistring"
    "libuuid"
    "libxcb"
    "lz4-libs"
    "nettle"
    "openssl-libs"
    "p11-kit"
    "pcre"
    "pixman"
    "redhat-lsb-core"
    "which"
    "xorg-x11-fonts-100dpi"
    "xorg-x11-fonts-75dpi"
    "xz-libs"
    "zlib"
)
# Total: 39 packages

PKGS_CORE_SOLVERS_RHEL8=(
    "alsa-lib"
    "aspell"
    "at-spi2-atk"
    "at-spi2-core"
    "atk"
    "audit-libs"
    "avahi-libs"
    "brotli"
    "bzip2-libs"
    "cairo"
    "cairo-gobject"
    "compat-hwloc1"
    "compat-openssl10"
    "cups-libs"
    "cyrus-sasl-lib"
    "dbus-libs"
    "elfutils-libelf"
    "enchant2"
    "expat"
    "flac-libs"
    "fontconfig"
    "freetype"
    "fribidi"
    "gdk-pixbuf2"
    "glib2"
    "glibc"
    "glibc-devel"
    "glibc.i686"
    "gmp"
    "gnutls"
    "graphite2"
    "gsm"
    "gstreamer1"
    "gstreamer1-plugins-base"
    "gtk2"
    "gtk3"
    "gzip"
    "harfbuzz"
    "harfbuzz-icu"
    "hwloc-libs"
    "hyphen"
    "infiniband-diags"
    "jbigkit-devel"
    "jbigkit-libs"
    "keyutils-libs"
    "krb5-libs"
    "libX11"
    "libXScrnSaver"
    "libXau"
    "libXcomposite"
    "libXcursor"
    "libXdamage"
    "libXdmcp"
    "libXext"
    "libXfixes"
    "libXft"
    "libXi"
    "libXinerama"
    "libXmu"
    "libXp"
    "libXrandr"
    "libXrender"
    "libXt"
    "libXtst"
    "libXxf86vm"
    "libasyncns"
    "libatomic"
    "libblkid"
    "libcap"
    "libcap-ng"
    "libcom_err"
    "libcurl"
    "libcurl-devel"
    "libcurl-minimal"
    "libdatrie"
    "libdeflate"
    "libdrm"
    "libepoxy"
    "libfontenc"
    "libgcc"
    "libgcc.i686"
    "libgcrypt"
    "libglvnd"
    "libglvnd-egl"
    "libglvnd-gles"
    "libglvnd-glx"
    "libglvnd-opengl"
    "libgpg-error"
    "libibumad"
    "libibverbs"
    "libicu"
    "libicu50"
    "libidn2"
    "libjpeg-turbo"
    "libmount"
    "libnghttp2"
    "libnl3"
    "libnotify"
    "libnsl"
    "libnsl2"
    "libogg"
    "libomp"
    "libpciaccess"
    "libpng"
    "libpng12"
    "libpsl"
    "librdmacm"
    "libreoffice-ure"
    "libsecret"
    "libselinux"
    "libsndfile"
    "libsoup"
    "libssh"
    "libstdc++"
    "libtasn1"
    "libthai"
    "libtheora"
    "libtiff"
    "libtirpc"
    "libtirpc-devel"
    "libunistring"
    "libuuid"
    "libvorbis"
    "libwayland-client"
    "libwayland-cursor"
    "libwayland-egl"
    "libwayland-server"
    "libwebp"
    "libwpe"
    "libxcb"
    "libxcrypt"
    "libxkbcommon"
    "libxkbcommon-x11"
    "libxkbfile"
    "libxml2"
    "libxshmfence"
    "libxslt"
    "libzstd"
    "lz4-libs"
    "make"
    "mesa-libgbm"
    "motif"
    "munge-libs"
    "ncurses-compat-libs"
    "ncurses-libs"
    "nettle"
    "nspr"
    "nss"
    "nss-softokn"
    "nss-softokn-freebl"
    "nss-util"
    "numactl-libs"
    "ocl-icd-devel"
    "octave"
    "openjpeg2"
    "openldap"
    "openssl-libs"
    "orc"
    "p11-kit"
    "pam"
    "pango"
    "pciutils-libs"
    "pcre"
    "pcre2"
    "pcre2-utf32"
    "pcsc-lite-libs"
    "perl-devel"
    "pixman"
    "pulseaudio-libs"
    "pulseaudio-libs-glib2"
    "redhat-lsb-core"
    "rocm-runtime"
    "speex"
    "systemd-libs"
    "tar"
    "ucx"
    "webkit2gtk3"
    "webkit2gtk3-jsc"
    "which"
    "woff2"
    "wpebackend-fdo"
    "xcb-util"
    "xcb-util-cursor"
    "xcb-util-image"
    "xcb-util-keysyms"
    "xcb-util-renderutil"
    "xcb-util-wm"
    "xorg-x11-fonts-100dpi"
    "xorg-x11-fonts-75dpi"
    "xterm"
    "xz-libs"
    "zlib"
)
# Total: 192 packages

PKGS_ALL_RHEL8=(
    "alsa-lib"
    "aspell"
    "at-spi2-atk"
    "at-spi2-core"
    "atk"
    "audit-libs"
    "avahi-libs"
    "brotli"
    "bzip2-libs"
    "cairo"
    "cairo-gobject"
    "compat-hwloc1"
    "compat-libgfortran-48"
    "compat-openssl10"
    "cups-libs"
    "cyrus-sasl-lib"
    "dbus-libs"
    "elfutils-libelf"
    "enchant2"
    "expat"
    "flac-libs"
    "fontconfig"
    "freeglut"
    "freetype"
    "fribidi"
    "gdk-pixbuf2"
    "glib2"
    "glibc"
    "glibc-devel"
    "glibc.i686"
    "gmp"
    "gnutls"
    "graphite2"
    "graphviz"
    "gsm"
    "gstreamer1"
    "gstreamer1-plugins-base"
    "gtk2"
    "gtk3"
    "gzip"
    "harfbuzz"
    "harfbuzz-icu"
    "hwloc-libs"
    "hyphen"
    "infiniband-diags"
    "jbigkit-devel"
    "jbigkit-libs"
    "keyutils-libs"
    "krb5-libs"
    "libICE"
    "libICE.i686"
    "libSM"
    "libSM.i686"
    "libX11"
    "libX11-xcb"
    "libX11.i686"
    "libXScrnSaver"
    "libXau"
    "libXau.i686"
    "libXcomposite"
    "libXcursor"
    "libXdamage"
    "libXdmcp"
    "libXext"
    "libXext.i686"
    "libXfixes"
    "libXft"
    "libXi"
    "libXinerama"
    "libXmu"
    "libXp"
    "libXrandr"
    "libXrender"
    "libXt"
    "libXt.i686"
    "libXtst"
    "libXxf86vm"
    "libasyncns"
    "libatomic"
    "libblkid"
    "libcap"
    "libcap-ng"
    "libcom_err"
    "libcurl"
    "libcurl-devel"
    "libcurl-minimal"
    "libdatrie"
    "libdeflate"
    "libdrm"
    "libepoxy"
    "libffi"
    "libfontenc"
    "libgcc"
    "libgcc.i686"
    "libgcrypt"
    "libgfortran"
    "libglvnd"
    "libglvnd-egl"
    "libglvnd-gles"
    "libglvnd-glx"
    "libglvnd-glx.i686"
    "libglvnd-opengl"
    "libgomp"
    "libgpg-error"
    "libibumad"
    "libibverbs"
    "libicu"
    "libicu50"
    "libidn2"
    "libjpeg-turbo"
    "libmount"
    "libnghttp2"
    "libnl3"
    "libnotify"
    "libnsl"
    "libnsl2"
    "libogg"
    "libomp"
    "libpciaccess"
    "libpng"
    "libpng12"
    "libpsl"
    "libquadmath"
    "librdmacm"
    "libreoffice-ure"
    "libsecret"
    "libselinux"
    "libsndfile"
    "libsoup"
    "libssh"
    "libstdc++"
    "libstdc++.i686"
    "libtasn1"
    "libthai"
    "libtheora"
    "libtiff"
    "libtirpc"
    "libtirpc-devel"
    "libtool-ltdl"
    "libunistring"
    "libuuid"
    "libuuid-devel"
    "libuuid.i686"
    "libvorbis"
    "libwayland-client"
    "libwayland-cursor"
    "libwayland-egl"
    "libwayland-server"
    "libwebp"
    "libwpe"
    "libxcb"
    "libxcb.i686"
    "libxcrypt"
    "libxkbcommon"
    "libxkbcommon-x11"
    "libxkbfile"
    "libxml2"
    "libxshmfence"
    "libxslt"
    "libzstd"
    "lz4-libs"
    "make"
    "mesa-libGLU"
    "mesa-libgbm"
    "mesa-libglapi"
    "motif"
    "munge-libs"
    "ncurses-compat-libs"
    "ncurses-libs"
    "nettle"
    "nspr"
    "nss"
    "nss-softokn"
    "nss-softokn-freebl"
    "nss-util"
    "numactl-libs"
    "ocl-icd"
    "ocl-icd-devel"
    "octave"
    "openjpeg2"
    "openldap"
    "openssl-libs"
    "openssl3-libs"
    "orc"
    "p11-kit"
    "pam"
    "pango"
    "pciutils-libs"
    "pcre"
    "pcre2"
    "pcre2-utf16"
    "pcre2-utf32"
    "pcsc-lite-libs"
    "perl-devel"
    "pixman"
    "pulseaudio-libs"
    "pulseaudio-libs-glib2"
    "redhat-lsb-core"
    "rocm-runtime"
    "speex"
    "sqlite-libs"
    "systemd-libs"
    "tar"
    "tbb"
    "ucx"
    "webkit2gtk3"
    "webkit2gtk3-jsc"
    "which"
    "woff2"
    "wpebackend-fdo"
    "xcb-util"
    "xcb-util-cursor"
    "xcb-util-image"
    "xcb-util-keysyms"
    "xcb-util-renderutil"
    "xcb-util-wm"
    "xorg-x11-fonts-100dpi"
    "xorg-x11-fonts-75dpi"
    "xterm"
    "xz-libs"
    "zlib"
)
# Total: 221 packages

PKGS_INSTALLER_RHEL9=(
    "bzip2-libs"
    "cyrus-sasl-lib"
    "fontconfig"
    "freetype"
    "glib2"
    "glibc"
    "glibc-devel"
    "graphite2"
    "gzip"
    "harfbuzz"
    "keyutils-libs"
    "krb5-libs"
    "libICE"
    "libSM"
    "libX11"
    "libX11-xcb"
    "libXau"
    "libXext"
    "libXft"
    "libXrender"
    "libbrotli"
    "libcom_err"
    "libcurl"
    "libevent"
    "libidn2"
    "libjpeg-turbo"
    "libnghttp2"
    "libnsl"
    "libnsl2"
    "libpng"
    "libpsl"
    "libselinux"
    "libssh"
    "libunistring"
    "libuuid"
    "libxcb"
    "libxcrypt"
    "libxkbcommon"
    "libxkbcommon-x11"
    "libxml2"
    "libzstd"
    "openldap"
    "openssl-libs"
    "pcre"
    "pcre2"
    "tar"
    "which"
    "xcb-util"
    "xcb-util-cursor"
    "xcb-util-image"
    "xcb-util-keysyms"
    "xcb-util-renderutil"
    "xcb-util-wm"
    "xorg-x11-fonts-100dpi"
    "xorg-x11-fonts-75dpi"
    "xz-libs"
    "zlib"
)
# Total: 57 packages

PKGS_LICMGR_RHEL9=(
    "bzip2-libs"
    "fontconfig"
    "freetype"
    "glib2"
    "glibc"
    "glibc-devel"
    "graphite2"
    "harfbuzz"
    "libICE"
    "libSM"
    "libX11"
    "libXau"
    "libXext"
    "libXrender"
    "libbrotli"
    "libgcc"
    "libjpeg-turbo"
    "libnsl"
    "libnsl2"
    "libpng"
    "libstdc++"
    "libuuid"
    "libxcb"
    "libxml2"
    "libzstd"
    "lz4-libs"
    "pcre"
    "pixman"
    "sqlite-libs"
    "which"
    "xorg-x11-fonts-100dpi"
    "xorg-x11-fonts-75dpi"
    "xz-libs"
    "zlib"
)
# Total: 34 packages

PKGS_CORE_SOLVERS_RHEL9=(
    "alsa-lib"
    "at-spi2-atk"
    "at-spi2-core"
    "atk"
    "audit-libs"
    "avahi-libs"
    "bzip2-libs"
    "cairo"
    "cairo-gobject"
    "compat-openssl11"
    "cups-libs"
    "cyrus-sasl-lib"
    "dbus-libs"
    "elfutils-libelf"
    "enchant2"
    "expat"
    "flac-libs"
    "fontconfig"
    "freetype"
    "fribidi"
    "gdk-pixbuf2"
    "glib2"
    "glibc"
    "glibc-devel"
    "glibc.i686"
    "gnutls"
    "graphite2"
    "gsm"
    "gstreamer1"
    "gstreamer1-plugins-base"
    "gtk2"
    "gtk3"
    "gzip"
    "harfbuzz"
    "harfbuzz-icu"
    "hwloc-libs"
    "hyphen"
    "infiniband-diags"
    "jbigkit-devel"
    "jbigkit-libs"
    "json-glib"
    "keyutils-libs"
    "krb5-libs"
    "libX11"
    "libXau"
    "libXcomposite"
    "libXcursor"
    "libXdamage"
    "libXdmcp"
    "libXext"
    "libXfixes"
    "libXft"
    "libXi"
    "libXinerama"
    "libXmu"
    "libXp"
    "libXrandr"
    "libXrender"
    "libXt"
    "libXtst"
    "libXxf86vm"
    "libasyncns"
    "libatomic"
    "libblkid"
    "libbrotli"
    "libcap"
    "libcap-ng"
    "libcom_err"
    "libcurl"
    "libcurl-devel"
    "libcurl-minimal"
    "libdatrie"
    "libdeflate"
    "libdrm"
    "libeconf"
    "libedit"
    "libepoxy"
    "libevent"
    "libffi"
    "libfontenc"
    "libgcc"
    "libgcc.i686"
    "libgcrypt"
    "libglvnd"
    "libglvnd-egl"
    "libglvnd-glx"
    "libglvnd-opengl"
    "libgpg-error"
    "libgudev"
    "libibumad"
    "libibverbs"
    "libicu"
    "libicu50"
    "libidn2"
    "libjpeg-turbo"
    "libmount"
    "libnghttp2"
    "libnl3"
    "libnotify"
    "libnsl"
    "libnsl2"
    "libogg"
    "libpciaccess"
    "libpng"
    "libpng12"
    "libpsl"
    "librdmacm"
    "libreoffice-ure"
    "libseccomp"
    "libsecret"
    "libselinux"
    "libsndfile"
    "libsoup"
    "libssh"
    "libstemmer"
    "libtasn1"
    "libthai"
    "libtheora"
    "libtiff"
    "libtirpc"
    "libtirpc-devel"
    "libtracker-sparql"
    "libunistring"
    "libuuid"
    "libvorbis"
    "libwayland-client"
    "libwayland-cursor"
    "libwayland-egl"
    "libwayland-server"
    "libwebp"
    "libwpe"
    "libxcb"
    "libxcrypt"
    "libxcrypt-compat"
    "libxkbcommon"
    "libxkbcommon-x11"
    "libxkbfile"
    "libxml2"
    "libxshmfence"
    "libxslt"
    "libzstd"
    "lz4-libs"
    "make"
    "mesa-libgbm"
    "motif"
    "munge-libs"
    "ncurses-compat-libs"
    "ncurses-libs"
    "nettle"
    "nspr"
    "nss"
    "nss-softokn"
    "nss-softokn-freebl"
    "nss-util"
    "numactl-libs"
    "ocl-icd-devel"
    "openjpeg2"
    "openldap"
    "openldap-compat"
    "openssl-libs"
    "opus"
    "orc"
    "p11-kit"
    "pam"
    "pango"
    "pcre"
    "pcre2"
    "pcre2-utf32"
    "pcsc-lite-libs"
    "perl-devel"
    "pixman"
    "pulseaudio-libs"
    "pulseaudio-libs-glib2"
    "redhat-lsb-core"
    "rocm-runtime"
    "speex"
    "systemd-libs"
    "tar"
    "ucx"
    "webkit2gtk3"
    "webkit2gtk3-jsc"
    "which"
    "woff2"
    "wpebackend-fdo"
    "xcb-util"
    "xcb-util-cursor"
    "xcb-util-image"
    "xcb-util-keysyms"
    "xcb-util-renderutil"
    "xcb-util-wm"
    "xorg-x11-fonts-100dpi"
    "xorg-x11-fonts-75dpi"
    "xterm"
    "xz-libs"
    "zlib"
)
# Total: 195 packages

PKGS_ALL_RHEL9=(
    "abseil-cpp"
    "alsa-lib"
    "at-spi2-atk"
    "at-spi2-core"
    "atk"
    "audit-libs"
    "avahi-libs"
    "bzip2-libs"
    "cairo"
    "cairo-gobject"
    "compat-openssl11"
    "cups-libs"
    "cyrus-sasl-lib"
    "dbus-libs"
    "elfutils-libelf"
    "enchant2"
    "expat"
    "flac-libs"
    "fontconfig"
    "freeglut"
    "freetype"
    "fribidi"
    "gdk-pixbuf2"
    "glib2"
    "glibc"
    "glibc-devel"
    "glibc.i686"
    "gnutls"
    "graphite2"
    "graphviz"
    "grpc"
    "grpc-cpp"
    "gsm"
    "gstreamer1"
    "gstreamer1-plugins-base"
    "gtk2"
    "gtk3"
    "gzip"
    "harfbuzz"
    "harfbuzz-icu"
    "hwloc-libs"
    "hyphen"
    "infiniband-diags"
    "jbigkit-devel"
    "jbigkit-libs"
    "json-glib"
    "keyutils-libs"
    "krb5-libs"
    "libICE"
    "libICE.i686"
    "libSM"
    "libSM.i686"
    "libX11"
    "libX11-xcb"
    "libX11.i686"
    "libXScrnSaver"
    "libXau"
    "libXau.i686"
    "libXcomposite"
    "libXcursor"
    "libXdamage"
    "libXdmcp"
    "libXext"
    "libXext.i686"
    "libXfixes"
    "libXft"
    "libXi"
    "libXinerama"
    "libXmu"
    "libXp"
    "libXrandr"
    "libXrender"
    "libXt"
    "libXt.i686"
    "libXtst"
    "libXxf86vm"
    "libasyncns"
    "libatomic"
    "libblkid"
    "libbrotli"
    "libcap"
    "libcap-ng"
    "libcom_err"
    "libcurl"
    "libcurl-devel"
    "libcurl-minimal"
    "libdatrie"
    "libdeflate"
    "libdrm"
    "libeconf"
    "libedit"
    "libepoxy"
    "libevent"
    "libffi"
    "libfontenc"
    "libgcc"
    "libgcc.i686"
    "libgcrypt"
    "libgfortran"
    "libglvnd"
    "libglvnd-egl"
    "libglvnd-glx"
    "libglvnd-glx.i686"
    "libglvnd-opengl"
    "libgomp"
    "libgpg-error"
    "libgudev"
    "libibumad"
    "libibverbs"
    "libicu"
    "libicu50"
    "libidn2"
    "libjpeg-turbo"
    "libmount"
    "libnghttp2"
    "libnl3"
    "libnotify"
    "libnsl"
    "libnsl2"
    "libogg"
    "libpciaccess"
    "libpng"
    "libpng12"
    "libpsl"
    "libquadmath"
    "librdmacm"
    "libreoffice-ure"
    "libseccomp"
    "libsecret"
    "libselinux"
    "libsndfile"
    "libsoup"
    "libssh"
    "libstdc++"
    "libstdc++.i686"
    "libstemmer"
    "libtasn1"
    "libthai"
    "libtheora"
    "libtiff"
    "libtirpc"
    "libtirpc-devel"
    "libtool-ltdl"
    "libtracker-sparql"
    "libunistring"
    "libuuid"
    "libuuid-devel"
    "libuuid.i686"
    "libvorbis"
    "libwayland-client"
    "libwayland-cursor"
    "libwayland-egl"
    "libwayland-server"
    "libwebp"
    "libwpe"
    "libxcb"
    "libxcb.i686"
    "libxcrypt"
    "libxcrypt-compat"
    "libxkbcommon"
    "libxkbcommon-x11"
    "libxkbfile"
    "libxml2"
    "libxshmfence"
    "libxslt"
    "libzstd"
    "lz4-libs"
    "make"
    "mesa-libGLU"
    "mesa-libgbm"
    "motif"
    "munge-libs"
    "ncurses-compat-libs"
    "ncurses-libs"
    "nettle"
    "nspr"
    "nss"
    "nss-softokn"
    "nss-softokn-freebl"
    "nss-util"
    "numactl-libs"
    "ocl-icd"
    "ocl-icd-devel"
    "openjpeg2"
    "openldap"
    "openldap-compat"
    "openssl-libs"
    "opus"
    "orc"
    "p11-kit"
    "pam"
    "pango"
    "pciutils-libs"
    "pcre"
    "pcre2"
    "pcre2-utf32"
    "pcsc-lite-libs"
    "perl-devel"
    "pixman"
    "pulseaudio-libs"
    "pulseaudio-libs-glib2"
    "re2"
    "redhat-lsb-core"
    "rocm-runtime"
    "speex"
    "sqlite-libs"
    "systemd-libs"
    "tar"
    "tbb"
    "ucx"
    "webkit2gtk3"
    "webkit2gtk3-jsc"
    "which"
    "woff2"
    "wpebackend-fdo"
    "xcb-util"
    "xcb-util-cursor"
    "xcb-util-image"
    "xcb-util-keysyms"
    "xcb-util-renderutil"
    "xcb-util-wm"
    "xorg-x11-fonts-100dpi"
    "xorg-x11-fonts-75dpi"
    "xterm"
    "xz-libs"
    "zlib"
)
# Total: 226 packages

PKGS_INSTALLER_SLES15=(
    "fontconfig"
    "glibc"
    "glibc-devel"
    "gzip"
    "krb5"
    "libICE6"
    "libSM6"
    "libX11-6"
    "libX11-xcb1"
    "libXau6"
    "libXext6"
    "libXft2"
    "libXrender1"
    "libbrotlicommon1"
    "libbrotlidec1"
    "libbz2-1"
    "libcom_err2"
    "libcurl4"
    "libexpat1"
    "libfontconfig1"
    "libfreetype6"
    "libglib-2_0-0"
    "libgthread-2_0-0"
    "libidn2-0"
    "libjitterentropy3"
    "libjpeg62"
    "libkeyutils1"
    "libldap-2_4-2"
    "libnghttp2-14"
    "libnsl2"
    "libopenssl1_1"
    "libopenssl3"
    "libpcre1"
    "libpcre2-8-0"
    "libpng16-16"
    "libpsl5"
    "libsasl2-3"
    "libselinux1"
    "libssh4"
    "libunistring2"
    "libuuid1"
    "libxcb-cursor0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xfixes0"
    "libxcb-xinerama0"
    "libxcb-xkb1"
    "libxcb1"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libz1"
    "libzstd1"
    "tar"
    "which"
    "xorg-x11-fonts"
)
# Total: 63 packages

PKGS_LICMGR_SLES15=(
    "fontconfig"
    "glibc"
    "glibc-32bit"
    "glibc-devel"
    "gzip"
    "krb5"
    "libICE6"
    "libSM6"
    "libX11-6"
    "libXau6"
    "libXcomposite1"
    "libXcursor1"
    "libXdamage1"
    "libXext6"
    "libXfixes3"
    "libXi6"
    "libXinerama1"
    "libXrandr2"
    "libXrender1"
    "libXxf86vm1"
    "libasound2"
    "libatk-1_0-0"
    "libatk-bridge-2_0-0"
    "libatspi0"
    "libavahi-client3"
    "libavahi-common3"
    "libblkid1"
    "libbrotlicommon1"
    "libbrotlidec1"
    "libbz2-1"
    "libcairo-gobject2"
    "libcairo2"
    "libcap2"
    "libcom_err2"
    "libcups2"
    "libdatrie1"
    "libdbus-1-3"
    "libdrm2"
    "libepoxy0"
    "libexpat1"
    "libffi7"
    "libfontconfig1"
    "libfreetype6"
    "libgbm1"
    "libgcc_s1"
    "libgcrypt20"
    "libgdk_pixbuf-2_0-0"
    "libgio-2_0-0"
    "libglib-2_0-0"
    "libglvnd"
    "libgmodule-2_0-0"
    "libgmp10"
    "libgnutls30"
    "libgobject-2_0-0"
    "libgpg-error0"
    "libgraphite2-3"
    "libgthread-2_0-0"
    "libgtk-3-0"
    "libharfbuzz0"
    "libhogweed4"
    "libidn2-0"
    "libjpeg62"
    "libkeyutils1"
    "liblz4-1"
    "liblzma5"
    "libmount1"
    "libnettle6"
    "libnsl2"
    "libp11-kit0"
    "libpango-1_0-0"
    "libpcre1"
    "libpcre2-8-0"
    "libpixman-1-0"
    "libpng16-16"
    "libselinux1"
    "libstdc++6"
    "libsystemd0"
    "libtasn1-6"
    "libthai0"
    "libunistring2"
    "libuuid1"
    "libwayland-client0"
    "libwayland-cursor0"
    "libwayland-egl1"
    "libwayland-server0"
    "libxcb-render0"
    "libxcb-shm0"
    "libxcb1"
    "libxkbcommon0"
    "libz1"
    "mozilla-nspr"
    "mozilla-nss"
    "tar"
    "which"
    "xorg-x11-fonts"
)
# Total: 95 packages

PKGS_CORE_SOLVERS_SLES15=(
    "fontconfig"
    "glibc"
    "glibc-32bit"
    "glibc-devel"
    "gzip"
    "kernel-firmware-nvidia-gsp-G06"
    "krb5"
    "libFLAC8"
    "libOpenCL1"
    "libSvtAv1Enc1"
    "libX11-6"
    "libX11-6-32bit"
    "libXau6"
    "libXau6-32bit"
    "libXcomposite1"
    "libXcursor1"
    "libXdamage1"
    "libXdmcp6"
    "libXext6"
    "libXext6-32bit"
    "libXfixes3"
    "libXfont1"
    "libXft2"
    "libXi6"
    "libXinerama1"
    "libXm4"
    "libXmu6"
    "libXp6"
    "libXrandr2"
    "libXrender1"
    "libXss1"
    "libXt6"
    "libXtst6"
    "libXxf86vm1"
    "libaom3"
    "libasound2"
    "libatk-1_0-0"
    "libatk-bridge-2_0-0"
    "libatomic1"
    "libatspi0"
    "libaudit1"
    "libavahi-client3"
    "libavahi-common3"
    "libavif16"
    "libavutil56"
    "libblkid1"
    "libbrotlicommon1"
    "libbrotlidec1"
    "libbz2-1"
    "libcairo-gobject2"
    "libcairo2"
    "libcap2"
    "libcom_err2"
    "libcpprest2_10"
    "libcrypt1"
    "libcups2"
    "libcurl4"
    "libdatrie1"
    "libdav1d7"
    "libdbus-1-3"
    "libdeflate0"
    "libdrm2"
    "libdrm_amdgpu1"
    "libdw1"
    "libeconf0"
    "libefa1"
    "libelf1"
    "libenchant-2-2"
    "libenchant1"
    "libepoxy0"
    "libevdev2"
    "libexpat1"
    "libffi7"
    "libfontconfig1"
    "libfontenc1"
    "libfreebl3"
    "libfreetype6"
    "libfribidi0"
    "libgbm1"
    "libgcc_s1"
    "libgcc_s1-32bit"
    "libgcrypt20"
    "libgdk_pixbuf-2_0-0"
    "libgio-2_0-0"
    "libglib-2_0-0"
    "libglvnd"
    "libglvnd-32bit"
    "libgmodule-2_0-0"
    "libgnutls30"
    "libgobject-2_0-0"
    "libgpg-error0"
    "libgraphite2-3"
    "libgstallocators-1_0-0"
    "libgstapp-1_0-0"
    "libgstaudio-1_0-0"
    "libgstfft-1_0-0"
    "libgstgl-1_0-0"
    "libgstpbutils-1_0-0"
    "libgstreamer-1_0-0"
    "libgsttag-1_0-0"
    "libgstvideo-1_0-0"
    "libgthread-2_0-0"
    "libgtk-2_0-0"
    "libgtk-3-0"
    "libgudev-1_0-0"
    "libharfbuzz-icu0"
    "libharfbuzz0"
    "libhogweed4"
    "libhogweed6"
    "libhwloc15"
    "libhwloc5"
    "libhyphen0"
    "libibmad5"
    "libibumad3"
    "libibverbs1"
    "libicu-suse65_1"
    "libicu60_2"
    "libicu73_2"
    "libidn2-0"
    "libjavascriptcoregtk-4_0-18"
    "libjbig2"
    "libjitterentropy3"
    "libjpeg62"
    "libjpeg8"
    "libkeyutils1"
    "libldap-2_4-2"
    "liblz4-1"
    "liblzma5"
    "libmanette-0_2-0"
    "libmlx5-1"
    "libmount1"
    "libncurses6"
    "libnettle6"
    "libnettle8"
    "libnghttp2-14"
    "libnl3-200"
    "libnotify4"
    "libnsl1"
    "libnsl2"
    "libnuma1"
    "libogg0"
    "libomp5-devel"
    "libopenjp2-7"
    "libopenssl10"
    "libopenssl1_1"
    "libopenssl3"
    "liborc-0_4-0"
    "libp11-kit0"
    "libpango-1_0-0"
    "libpci3"
    "libpciaccess0"
    "libpcre1"
    "libpcre2-32-0"
    "libpcre2-8-0"
    "libpcsclite1"
    "libpixman-1-0"
    "libpng12-0"
    "libpng16-16"
    "libpsl5"
    "libpulse-mainloop-glib0"
    "libpulse0"
    "libquadmath0"
    "librav1e0_6"
    "librdmacm1"
    "libsasl2-3"
    "libseccomp2"
    "libsecret-1-0"
    "libselinux1"
    "libsndfile1"
    "libsoftokn3"
    "libsoup-2_4-1"
    "libspeex1"
    "libssh4"
    "libstdc++6"
    "libsystemd0"
    "libtasn1-6"
    "libthai0"
    "libtheoradec1"
    "libtheoraenc1"
    "libtiff5"
    "libtirpc-devel"
    "libtirpc3"
    "libucm0"
    "libucp0"
    "libucs0"
    "libuct0"
    "libudev1"
    "libunistring2"
    "libunwind"
    "libuuid1"
    "libva-drm2"
    "libva2"
    "libvdpau1"
    "libvorbis0"
    "libvorbisenc2"
    "libwayland-client0"
    "libwayland-cursor0"
    "libwayland-egl1"
    "libwayland-server0"
    "libwebkit2gtk-4_0-37"
    "libwebp6"
    "libwebp7"
    "libwebpdemux2"
    "libwebpmux3"
    "libwoff2common1_0_2"
    "libwoff2dec1_0_2"
    "libxcb-cursor0"
    "libxcb-dri2-0"
    "libxcb-dri3-0"
    "libxcb-glx0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-present0"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xfixes0"
    "libxcb-xinerama0"
    "libxcb-xinput0"
    "libxcb-xkb1"
    "libxcb1"
    "libxcb1-32bit"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libxkbfile1"
    "libxml2-2"
    "libxshmfence1"
    "libxslt1"
    "libyuv0"
    "libz1"
    "libzstd1"
    "make"
    "mozilla-nspr"
    "mozilla-nss"
    "octave-cli"
    "pam"
    "perl"
    "tar"
    "which"
    "xorg-x11-fonts"
    "xterm"
)
# Total: 246 packages

PKGS_ALL_SLES15=(
    "Mesa-libglapi0"
    "binutils"
    "fontconfig"
    "glibc"
    "glibc-32bit"
    "glibc-devel"
    "graphviz"
    "gzip"
    "kernel-firmware-nvidia-gsp-G06"
    "krb5"
    "libFLAC8"
    "libGLU1"
    "libICE6"
    "libOpenCL1"
    "libSM6"
    "libSvtAv1Enc1"
    "libX11-6"
    "libX11-6-32bit"
    "libX11-xcb1"
    "libXau6"
    "libXau6-32bit"
    "libXcomposite1"
    "libXcursor1"
    "libXdamage1"
    "libXdmcp6"
    "libXext6"
    "libXext6-32bit"
    "libXfixes3"
    "libXfont1"
    "libXft2"
    "libXi6"
    "libXinerama1"
    "libXm4"
    "libXmu6"
    "libXp6"
    "libXrandr2"
    "libXrender1"
    "libXss1"
    "libXt6"
    "libXt6-32bit"
    "libXtst6"
    "libXxf86vm1"
    "libaom3"
    "libasound2"
    "libatk-1_0-0"
    "libatk-bridge-2_0-0"
    "libatomic1"
    "libatspi0"
    "libaudit1"
    "libavahi-client3"
    "libavahi-common3"
    "libavif16"
    "libavutil56"
    "libblkid1"
    "libbrotlicommon1"
    "libbrotlidec1"
    "libbz2-1"
    "libcairo-gobject2"
    "libcairo2"
    "libcap2"
    "libcom_err2"
    "libcpprest2_10"
    "libcrypt1"
    "libcups2"
    "libcurl4"
    "libdatrie1"
    "libdav1d7"
    "libdbus-1-3"
    "libdeflate0"
    "libdouble-conversion1"
    "libdouble-conversion3"
    "libdrm2"
    "libdrm_amdgpu1"
    "libdw1"
    "libeconf0"
    "libefa1"
    "libelf1"
    "libenchant-2-2"
    "libenchant1"
    "libepoxy0"
    "libevdev2"
    "libexpat1"
    "libffi7"
    "libfontconfig1"
    "libfontenc1"
    "libfreebl3"
    "libfreetype6"
    "libfribidi0"
    "libgbm1"
    "libgcc_s1"
    "libgcc_s1-32bit"
    "libgcrypt20"
    "libgdk_pixbuf-2_0-0"
    "libgfortran5"
    "libgio-2_0-0"
    "libglib-2_0-0"
    "libglut3"
    "libglvnd"
    "libglvnd-32bit"
    "libgmodule-2_0-0"
    "libgmp10"
    "libgnutls30"
    "libgobject-2_0-0"
    "libgomp1"
    "libgpg-error0"
    "libgraphite2-3"
    "libgstallocators-1_0-0"
    "libgstapp-1_0-0"
    "libgstaudio-1_0-0"
    "libgstfft-1_0-0"
    "libgstgl-1_0-0"
    "libgstpbutils-1_0-0"
    "libgstreamer-1_0-0"
    "libgsttag-1_0-0"
    "libgstvideo-1_0-0"
    "libgthread-2_0-0"
    "libgtk-2_0-0"
    "libgtk-3-0"
    "libgudev-1_0-0"
    "libharfbuzz-icu0"
    "libharfbuzz0"
    "libhogweed4"
    "libhogweed6"
    "libhwloc15"
    "libhwloc5"
    "libhyphen0"
    "libibmad5"
    "libibumad3"
    "libibverbs1"
    "libicu-suse65_1"
    "libicu60_2"
    "libicu73_2"
    "libidn2-0"
    "libjavascriptcoregtk-4_0-18"
    "libjbig2"
    "libjitterentropy3"
    "libjpeg62"
    "libjpeg8"
    "libkeyutils1"
    "libldap-2_4-2"
    "libltdl7"
    "liblz4-1"
    "liblzma5"
    "libmanette-0_2-0"
    "libmlx5-1"
    "libmount1"
    "libncurses6"
    "libnettle6"
    "libnettle8"
    "libnghttp2-14"
    "libnl3-200"
    "libnotify4"
    "libnsl1"
    "libnsl2"
    "libnuma1"
    "libogg0"
    "libomp5-devel"
    "libopenjp2-7"
    "libopenssl10"
    "libopenssl1_1"
    "libopenssl3"
    "liborc-0_4-0"
    "libp11-kit0"
    "libpango-1_0-0"
    "libpci3"
    "libpciaccess0"
    "libpcre1"
    "libpcre2-16-0"
    "libpcre2-32-0"
    "libpcre2-8-0"
    "libpcsclite1"
    "libpixman-1-0"
    "libpng12-0"
    "libpng16-16"
    "libpsl5"
    "libpulse-mainloop-glib0"
    "libpulse0"
    "libquadmath0"
    "librav1e0_6"
    "librdmacm1"
    "libre2-9"
    "libsasl2-3"
    "libseccomp2"
    "libsecret-1-0"
    "libselinux1"
    "libsndfile1"
    "libsoftokn3"
    "libsoup-2_4-1"
    "libspeex1"
    "libsqlite3-0"
    "libssh4"
    "libstdc++6"
    "libstdc++6-32bit"
    "libsystemd0"
    "libtasn1-6"
    "libthai0"
    "libtheoradec1"
    "libtheoraenc1"
    "libtiff5"
    "libtirpc-devel"
    "libtirpc3"
    "libucm0"
    "libucp0"
    "libucs0"
    "libuct0"
    "libudev1"
    "libunistring2"
    "libunwind"
    "libuuid1"
    "libva-drm2"
    "libva2"
    "libvdpau1"
    "libvorbis0"
    "libvorbisenc2"
    "libwayland-client0"
    "libwayland-cursor0"
    "libwayland-egl1"
    "libwayland-server0"
    "libwebkit2gtk-4_0-37"
    "libwebp6"
    "libwebp7"
    "libwebpdemux2"
    "libwebpmux3"
    "libwoff2common1_0_2"
    "libwoff2dec1_0_2"
    "libxcb-cursor0"
    "libxcb-dri2-0"
    "libxcb-dri3-0"
    "libxcb-glx0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-present0"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xfixes0"
    "libxcb-xinerama0"
    "libxcb-xinput0"
    "libxcb-xkb1"
    "libxcb1"
    "libxcb1-32bit"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libxkbfile1"
    "libxml2-2"
    "libxshmfence1"
    "libxslt1"
    "libyuv0"
    "libz1"
    "libzstd1"
    "make"
    "mozilla-nspr"
    "mozilla-nss"
    "octave-cli"
    "pam"
    "perl"
    "tar"
    "which"
    "xorg-x11-fonts"
    "xterm"
)
# Total: 265 packages

PKGS_INSTALLER_UBUNTU2204=(
    "debianutils"
    "gzip"
    "libbrotli1"
    "libbsd0"
    "libc6"
    "libcom-err2"
    "libcurl4"
    "libexpat1"
    "libffi8"
    "libfontconfig1"
    "libfreetype6"
    "libglib2.0-0"
    "libgmp10"
    "libgnutls30"
    "libgssapi-krb5-2"
    "libhogweed6"
    "libice6"
    "libidn2-0"
    "libjpeg62"
    "libk5crypto3"
    "libkeyutils1"
    "libkrb5-3"
    "libkrb5support0"
    "libldap-2.5-0"
    "libmd0"
    "libnettle8"
    "libnghttp2-14"
    "libnsl2"
    "libp11-kit0"
    "libpcre3"
    "libpng16-16"
    "libpsl5"
    "librtmp1"
    "libsasl2-2"
    "libsm6"
    "libssh-4"
    "libssl3"
    "libtasn1-6"
    "libunistring2"
    "libuuid1"
    "libx11-6"
    "libx11-xcb1"
    "libxau6"
    "libxcb-cursor0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xfixes0"
    "libxcb-xinerama0"
    "libxcb-xkb1"
    "libxcb1"
    "libxdmcp6"
    "libxext6"
    "libxft2"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libxrender1"
    "libzstd1"
    "lsb-core"
    "tar"
    "xfonts-100dpi"
    "xfonts-75dpi"
    "zlib1g"
)
# Total: 70 packages

PKGS_LICMGR_UBUNTU2204=(
    "debianutils"
    "libbrotli1"
    "libbsd0"
    "libc6"
    "libexpat1"
    "libfontconfig1"
    "libfreetype6"
    "libgcc-s1"
    "libglib2.0-0"
    "libgmp10"
    "libice6"
    "libjpeg-turbo8"
    "libjpeg62"
    "liblz4-1"
    "liblzma5"
    "libmd0"
    "libnsl2"
    "libpcre3"
    "libpixman-1-0"
    "libpng16-16"
    "libsm6"
    "libstdc++6"
    "libuuid1"
    "libx11-6"
    "libxau6"
    "libxcb1"
    "libxdmcp6"
    "libxext6"
    "libxrender1"
    "libzstd1"
    "lsb-core"
    "xfonts-100dpi"
    "xfonts-75dpi"
    "zlib1g"
)
# Total: 34 packages

PKGS_CORE_SOLVERS_UBUNTU2204=(
    "debianutils"
    "gzip"
    "ibverbs-providers"
    "libapparmor1"
    "libasound2"
    "libasyncns0"
    "libatk-bridge2.0-0"
    "libatk1.0-0"
    "libatomic1"
    "libatspi2.0-0"
    "libavahi-client3"
    "libavahi-common3"
    "libavutil56"
    "libblkid1"
    "libbrotli1"
    "libbz2-1.0"
    "libc6"
    "libc6-i386"
    "libc6:i386"
    "libcairo-gobject2"
    "libcairo2"
    "libcap2"
    "libcom-err2"
    "libcpprest2.10"
    "libcrypt1"
    "libcups2"
    "libcurl4"
    "libcurl4-gnutls-dev"
    "libdatrie1"
    "libdbus-1-3"
    "libdeflate0"
    "libdrm-amdgpu1"
    "libdrm2"
    "libdw1"
    "libegl1"
    "libelf1"
    "libenchant-2-2"
    "libepoxy0"
    "libevdev2"
    "libexpat1"
    "libffi8"
    "libflac8"
    "libfontconfig1"
    "libfontenc1"
    "libfribidi0"
    "libgbm1"
    "libgcc-s1:i386"
    "libgcrypt20"
    "libgdk-pixbuf-2.0-0"
    "libglib2.0-0"
    "libglvnd0"
    "libglx0"
    "libgnutls30"
    "libgpg-error0"
    "libgraphite2-3"
    "libgssapi-krb5-2"
    "libgstreamer-gl1.0-0"
    "libgstreamer-plugins-base1.0-0"
    "libgstreamer1.0-0"
    "libgtk-3-0"
    "libgtk2.0-0"
    "libgudev-1.0-0"
    "libharfbuzz-icu0"
    "libharfbuzz0b"
    "libhogweed6"
    "libhsa-runtime64-1"
    "libhwloc15"
    "libhyphen0"
    "libibmad5"
    "libibumad3"
    "libibverbs1"
    "libicu70"
    "libidn2-0"
    "libjavascriptcoregtk-4.0-18"
    "libjbig-dev"
    "libjbig0"
    "libjpeg-turbo8"
    "libjpeg62"
    "libk5crypto3"
    "libkeyutils1"
    "libkrb5-3"
    "libkrb5support0"
    "libldap-2.5-0"
    "liblz4-1"
    "liblzma5"
    "libmanette-0.2-0"
    "libmfx1"
    "libmount1"
    "libmunge2"
    "libncursesw5"
    "libnettle8"
    "libnghttp2-14"
    "libnl-3-200"
    "libnl-route-3-200"
    "libnotify4"
    "libnsl2"
    "libnspr4"
    "libnss3"
    "libnuma1"
    "libnvidia-compute-390"
    "libogg0"
    "libopengl0"
    "libopenjp2-7"
    "libopus0"
    "liborc-0.4-0"
    "libp11-kit0"
    "libpam0g"
    "libpango-1.0-0"
    "libpangocairo-1.0-0"
    "libpangoft2-1.0-0"
    "libpci3"
    "libpciaccess0"
    "libpcre2-32-0"
    "libpcre2-8-0"
    "libpcre3"
    "libpcsclite1"
    "libperl-dev"
    "libpixman-1-0"
    "libpsl5"
    "libpulse-mainloop-glib0"
    "libpulse0"
    "librdmacm1"
    "librtmp1"
    "libsasl2-2"
    "libseccomp2"
    "libsecret-1-0"
    "libselinux1"
    "libsndfile1"
    "libsoup2.4-1"
    "libspeex1"
    "libssh-4"
    "libssl3"
    "libsystemd0"
    "libtasn1-6"
    "libthai0"
    "libtheora0"
    "libtiff5"
    "libtinfo6"
    "libtirpc-dev"
    "libtirpc3"
    "libucx0"
    "libudev1"
    "libunistring2"
    "libuno-cppu3"
    "libuno-cppuhelpergcc3-3"
    "libuno-sal3"
    "libuno-salhelpergcc3-3"
    "libunwind8"
    "libuuid1"
    "libva-drm2"
    "libva-x11-2"
    "libva2"
    "libvdpau1"
    "libvorbis0a"
    "libvorbisenc2"
    "libwayland-client0"
    "libwayland-cursor0"
    "libwayland-egl1"
    "libwayland-server0"
    "libwebkit2gtk-4.0-37"
    "libwebp7"
    "libwebpdemux2"
    "libwebpmux3"
    "libwoff1"
    "libwpe-1.0-1"
    "libwpebackend-fdo-1.0-1"
    "libxcb-cursor0"
    "libxcb-dri2-0"
    "libxcb-dri3-0"
    "libxcb-glx0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-present0"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xfixes0"
    "libxcb-xinerama0"
    "libxcb-xinput0"
    "libxcb-xkb1"
    "libxcomposite1"
    "libxcursor1"
    "libxdamage1"
    "libxdmcp6"
    "libxext6"
    "libxfixes3"
    "libxft2"
    "libxi6"
    "libxinerama1"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libxkbfile1"
    "libxm4"
    "libxml2"
    "libxmu6"
    "libxrandr2"
    "libxrender1"
    "libxshmfence1"
    "libxslt1.1"
    "libxss1"
    "libxt6"
    "libxtst6"
    "libxxf86vm1"
    "libzstd1"
    "lsb-core"
    "make"
    "ocl-icd-opencl-dev"
    "tar"
    "xfonts-100dpi"
    "xfonts-75dpi"
    "xterm"
)
# Total: 216 packages

PKGS_ALL_UBUNTU2204=(
    "debianutils"
    "freeglut3"
    "graphviz"
    "gzip"
    "ibverbs-providers"
    "libapparmor1"
    "libasound2"
    "libasyncns0"
    "libatk-bridge2.0-0"
    "libatk1.0-0"
    "libatomic1"
    "libatspi2.0-0"
    "libavahi-client3"
    "libavahi-common3"
    "libavutil56"
    "libblkid1"
    "libbrotli1"
    "libbsd0"
    "libbz2-1.0"
    "libc6"
    "libc6-i386"
    "libc6:i386"
    "libcairo-gobject2"
    "libcairo2"
    "libcap2"
    "libcom-err2"
    "libcpprest2.10"
    "libcrypt1"
    "libcups2"
    "libcurl4"
    "libcurl4-gnutls-dev"
    "libdatrie1"
    "libdbus-1-3"
    "libdeflate0"
    "libdrm-amdgpu1"
    "libdrm2"
    "libdw1"
    "libegl1"
    "libelf1"
    "libenchant-2-2"
    "libepoxy0"
    "libevdev2"
    "libexpat1"
    "libffi8"
    "libflac8"
    "libfontconfig1"
    "libfontenc1"
    "libfreetype6"
    "libfribidi0"
    "libgbm1"
    "libgcc-s1"
    "libgcc-s1:i386"
    "libgcrypt20"
    "libgdk-pixbuf-2.0-0"
    "libgfortran5"
    "libgl1"
    "libgl1:i386"
    "libglapi-mesa"
    "libglib2.0-0"
    "libglu1-mesa"
    "libglvnd0"
    "libglx0"
    "libgmp10"
    "libgnutls30"
    "libgomp1"
    "libgpg-error0"
    "libgraphite2-3"
    "libgssapi-krb5-2"
    "libgstreamer-gl1.0-0"
    "libgstreamer-plugins-base1.0-0"
    "libgstreamer1.0-0"
    "libgtk-3-0"
    "libgtk2.0-0"
    "libgudev-1.0-0"
    "libharfbuzz-icu0"
    "libharfbuzz0b"
    "libhogweed6"
    "libhsa-runtime64-1"
    "libhwloc15"
    "libhyphen0"
    "libibmad5"
    "libibumad3"
    "libibverbs1"
    "libice6"
    "libicu70"
    "libidn2-0"
    "libjavascriptcoregtk-4.0-18"
    "libjbig-dev"
    "libjbig0"
    "libjpeg-turbo8"
    "libjpeg62"
    "libk5crypto3"
    "libkeyutils1"
    "libkrb5-3"
    "libkrb5support0"
    "libldap-2.5-0"
    "libltdl7"
    "liblz4-1"
    "liblzma5"
    "libmanette-0.2-0"
    "libmd0"
    "libmfx1"
    "libmount1"
    "libmunge2"
    "libncursesw5"
    "libnettle8"
    "libnghttp2-14"
    "libnl-3-200"
    "libnl-route-3-200"
    "libnotify4"
    "libnsl2"
    "libnspr4"
    "libnss3"
    "libnuma1"
    "libnvidia-compute-390"
    "libogg0"
    "libopengl0"
    "libopenjp2-7"
    "libopus0"
    "liborc-0.4-0"
    "libp11-kit0"
    "libpam0g"
    "libpango-1.0-0"
    "libpangocairo-1.0-0"
    "libpangoft2-1.0-0"
    "libpci3"
    "libpciaccess0"
    "libpcre2-32-0"
    "libpcre2-8-0"
    "libpcre3"
    "libpcsclite1"
    "libperl-dev"
    "libpixman-1-0"
    "libpng16-16"
    "libpsl5"
    "libpulse-mainloop-glib0"
    "libpulse0"
    "libpython3.10"
    "libquadmath0"
    "librdmacm1"
    "libre2-9"
    "librtmp1"
    "libsasl2-2"
    "libseccomp2"
    "libsecret-1-0"
    "libselinux1"
    "libsm6"
    "libsndfile1"
    "libsoup2.4-1"
    "libspeex1"
    "libsqlite3-0"
    "libssh-4"
    "libssl3"
    "libstdc++5:i386"
    "libstdc++6"
    "libstdc++6:i386"
    "libsystemd0"
    "libtasn1-6"
    "libtbb12"
    "libtbbmalloc2"
    "libthai0"
    "libtheora0"
    "libtiff5"
    "libtinfo6"
    "libtirpc-dev"
    "libtirpc3"
    "libucx0"
    "libudev1"
    "libunistring2"
    "libuno-cppu3"
    "libuno-cppuhelpergcc3-3"
    "libuno-sal3"
    "libuno-salhelpergcc3-3"
    "libunwind8"
    "libuuid1"
    "libva-drm2"
    "libva-x11-2"
    "libva2"
    "libvdpau1"
    "libvorbis0a"
    "libvorbisenc2"
    "libwayland-client0"
    "libwayland-cursor0"
    "libwayland-egl1"
    "libwayland-server0"
    "libwebkit2gtk-4.0-37"
    "libwebp7"
    "libwebpdemux2"
    "libwebpmux3"
    "libwoff1"
    "libwpe-1.0-1"
    "libwpebackend-fdo-1.0-1"
    "libx11-6"
    "libx11-6:i386"
    "libx11-xcb1"
    "libxau6"
    "libxcb-cursor0"
    "libxcb-dri2-0"
    "libxcb-dri3-0"
    "libxcb-glx0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-present0"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xfixes0"
    "libxcb-xinerama0"
    "libxcb-xinput0"
    "libxcb-xkb1"
    "libxcb1"
    "libxcomposite1"
    "libxcursor1"
    "libxdamage1"
    "libxdmcp6"
    "libxext6"
    "libxext6:i386"
    "libxfixes3"
    "libxft2"
    "libxi6"
    "libxinerama1"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libxkbfile1"
    "libxm4"
    "libxml2"
    "libxmu6"
    "libxrandr2"
    "libxrender1"
    "libxshmfence1"
    "libxslt1.1"
    "libxss1"
    "libxt6"
    "libxt6:i386"
    "libxtst6"
    "libxxf86vm1"
    "libzstd1"
    "lsb-core"
    "make"
    "ocl-icd-libopencl1"
    "ocl-icd-opencl-dev"
    "tar"
    "uuid-dev"
    "xfonts-100dpi"
    "xfonts-75dpi"
    "xterm"
    "zlib1g"
)
# Total: 252 packages

PKGS_INSTALLER_UBUNTU2404=(
    "debianutils"
    "gzip"
    "libbrotli1"
    "libbsd0"
    "libbz2-1.0"
    "libc6"
    "libcom-err2"
    "libcurl4t64"
    "libexpat1"
    "libffi8"
    "libfontconfig1"
    "libfreetype6"
    "libglib2.0-0t64"
    "libgmp10"
    "libgnutls30t64"
    "libgssapi-krb5-2"
    "libhogweed6t64"
    "libice6"
    "libidn2-0"
    "libjpeg62"
    "libk5crypto3"
    "libkeyutils1"
    "libkrb5-3"
    "libkrb5support0"
    "libldap2"
    "libmd0"
    "libnettle8t64"
    "libnghttp2-14"
    "libnsl2"
    "libp11-kit0"
    "libpcre2-8-0"
    "libpng16-16t64"
    "libpsl5t64"
    "librtmp1"
    "libsasl2-2"
    "libsm6"
    "libssh-4"
    "libssl3t64"
    "libtasn1-6"
    "libunistring5"
    "libuuid1"
    "libx11-6"
    "libx11-xcb1"
    "libxau6"
    "libxcb-cursor0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xfixes0"
    "libxcb-xinerama0"
    "libxcb-xkb1"
    "libxcb1"
    "libxdmcp6"
    "libxext6"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libzstd1"
    "tar"
    "xfonts-100dpi"
    "xfonts-75dpi"
    "zlib1g"
)
# Total: 68 packages

PKGS_LICMGR_UBUNTU2404=(
    "debianutils"
    "libbrotli1"
    "libbsd0"
    "libbz2-1.0"
    "libc6"
    "libexpat1"
    "libfontconfig1"
    "libfreetype6"
    "libgcc-s1"
    "libglib2.0-0t64"
    "libice6"
    "libjpeg62"
    "libmd0"
    "libnsl2"
    "libpcre2-8-0"
    "libpng16-16t64"
    "libsm6"
    "libstdc++6"
    "libuuid1"
    "libx11-6"
    "libxau6"
    "libxcb1"
    "libxdmcp6"
    "libxext6"
    "libxrender1"
    "xfonts-100dpi"
    "xfonts-75dpi"
    "zlib1g"
)
# Total: 28 packages

PKGS_CORE_SOLVERS_UBUNTU2404=(
    "debianutils"
    "ibverbs-providers"
    "libapparmor1"
    "libasound2t64"
    "libasyncns0"
    "libatk-bridge2.0-0t64"
    "libatk1.0-0t64"
    "libatomic1"
    "libatspi2.0-0t64"
    "libavahi-client3"
    "libavahi-common3"
    "libblkid1"
    "libbrotli1"
    "libbsd0"
    "libbz2-1.0"
    "libc6"
    "libc6-i386"
    "libc6:i386"
    "libcairo-gobject2"
    "libcairo2"
    "libcap2"
    "libcom-err2"
    "libcrypt1"
    "libcups2t64"
    "libcurl4-gnutls-dev"
    "libcurl4t64"
    "libdatrie1"
    "libdbus-1-3"
    "libdeflate0"
    "libdrm-amdgpu1"
    "libdrm-intel1"
    "libdrm-radeon1"
    "libdrm2"
    "libdw1t64"
    "libedit2"
    "libegl1"
    "libelf1t64"
    "libepoxy0"
    "libexpat1"
    "libffi8"
    "libflac12t64"
    "libfontconfig1"
    "libfontenc1"
    "libfribidi0"
    "libgbm1"
    "libgcrypt20"
    "libgdk-pixbuf-2.0-0"
    "libglib2.0-0t64"
    "libglvnd0"
    "libglx0"
    "libgnutls30t64"
    "libgpg-error0"
    "libgraphite2-3"
    "libgssapi-krb5-2"
    "libgstreamer-plugins-base1.0-0"
    "libgstreamer1.0-0"
    "libgtk-3-0t64"
    "libharfbuzz0b"
    "libhogweed6t64"
    "libhsa-runtime64-1"
    "libhwloc15"
    "libibmad5"
    "libibumad3"
    "libibverbs1"
    "libidn2-0"
    "libjbig-dev"
    "libjbig0"
    "libjpeg-turbo8"
    "libjpeg62"
    "libk5crypto3"
    "libkeyutils1"
    "libkrb5-3"
    "libkrb5support0"
    "libldap2"
    "liblerc4"
    "libllvm19"
    "liblz4-1"
    "liblzma5"
    "libmd0"
    "libmount1"
    "libmp3lame0"
    "libmpg123-0t64"
    "libmunge2"
    "libnccl2"
    "libnettle8t64"
    "libnghttp2-14"
    "libnl-3-200"
    "libnl-route-3-200"
    "libnotify4"
    "libnsl2"
    "libnspr4"
    "libnss3"
    "libnuma1"
    "libnvidia-compute-470"
    "libogg0"
    "libopengl0"
    "libopenjp2-7"
    "libopus0"
    "liborc-0.4-0t64"
    "libp11-kit0"
    "libpam0g"
    "libpango-1.0-0"
    "libpangocairo-1.0-0"
    "libpangoft2-1.0-0"
    "libpciaccess0"
    "libpcre2-32-0"
    "libpcre2-8-0"
    "libpcsclite1"
    "libperl-dev"
    "libpixman-1-0"
    "libpsl5t64"
    "libpulse-mainloop-glib0"
    "libpulse0"
    "librccl1"
    "librdmacm1t64"
    "librtmp1"
    "libsasl2-2"
    "libsecret-1-0"
    "libselinux1"
    "libsensors5"
    "libsharpyuv0"
    "libsndfile1"
    "libsoup-2.4-1"
    "libssh-4"
    "libssl3t64"
    "libsystemd0"
    "libtasn1-6"
    "libthai0"
    "libtheora0"
    "libtiff6"
    "libtinfo6"
    "libtirpc-dev"
    "libtirpc3t64"
    "libucx0"
    "libudev1"
    "libunistring5"
    "libuno-cppu3t64"
    "libuno-cppuhelpergcc3-3t64"
    "libuno-sal3t64"
    "libuno-salhelpergcc3-3t64"
    "libunwind8"
    "libuuid1"
    "libvorbis0a"
    "libvorbisenc2"
    "libwayland-client0"
    "libwayland-cursor0"
    "libwayland-egl1"
    "libwayland-server0"
    "libwebp7"
    "libxcb-cursor0"
    "libxcb-dri2-0"
    "libxcb-dri3-0"
    "libxcb-glx0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-present0"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xinput0"
    "libxcb-xkb1"
    "libxcomposite1"
    "libxcursor1"
    "libxdamage1"
    "libxdmcp6"
    "libxext6"
    "libxfixes3"
    "libxft2"
    "libxi6"
    "libxinerama1"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libxkbfile1"
    "libxm4"
    "libxml2"
    "libxmu6"
    "libxrandr2"
    "libxrender1"
    "libxshmfence1"
    "libxt6t64"
    "libxtst6"
    "libxxf86vm1"
    "libzstd1"
    "make"
    "mesa-libgallium"
    "ocl-icd-opencl-dev"
    "xfonts-100dpi"
    "xfonts-75dpi"
    "xterm"
)
# Total: 194 packages

PKGS_ALL_UBUNTU2404=(
    "debianutils"
    "graphviz"
    "gzip"
    "ibverbs-providers"
    "libapparmor1"
    "libasound2t64"
    "libasyncns0"
    "libatk-bridge2.0-0t64"
    "libatk1.0-0t64"
    "libatomic1"
    "libatspi2.0-0t64"
    "libavahi-client3"
    "libavahi-common3"
    "libblkid1"
    "libbrotli1"
    "libbsd0"
    "libbz2-1.0"
    "libc6"
    "libc6-i386"
    "libc6:i386"
    "libcairo-gobject2"
    "libcairo2"
    "libcap2"
    "libcom-err2"
    "libcrypt1"
    "libcudart12"
    "libcups2t64"
    "libcurl4-gnutls-dev"
    "libcurl4t64"
    "libdatrie1"
    "libdbus-1-3"
    "libdeflate0"
    "libdrm-amdgpu1"
    "libdrm-intel1"
    "libdrm-radeon1"
    "libdrm2"
    "libdw1t64"
    "libedit2"
    "libegl1"
    "libelf1t64"
    "libepoxy0"
    "libexpat1"
    "libffi8"
    "libflac12t64"
    "libfontconfig1"
    "libfontenc1"
    "libfreetype6"
    "libfribidi0"
    "libgbm1"
    "libgcc-s1"
    "libgcc-s1:i386"
    "libgcrypt20"
    "libgdk-pixbuf-2.0-0"
    "libgl1"
    "libglapi-amber"
    "libglapi-mesa"
    "libglib2.0-0t64"
    "libglu1-mesa"
    "libglvnd0"
    "libglx0"
    "libgmp10"
    "libgnutls30t64"
    "libgomp1"
    "libgpg-error0"
    "libgraphite2-3"
    "libgssapi-krb5-2"
    "libgstreamer-plugins-base1.0-0"
    "libgstreamer1.0-0"
    "libgtk-3-0t64"
    "libharfbuzz0b"
    "libhogweed6t64"
    "libhsa-runtime64-1"
    "libhwloc15"
    "libibmad5"
    "libibumad3"
    "libibverbs1"
    "libice6"
    "libicu74"
    "libidn2-0"
    "libjbig-dev"
    "libjbig0"
    "libjpeg-turbo8"
    "libjpeg62"
    "libk5crypto3"
    "libkeyutils1"
    "libkrb5-3"
    "libkrb5support0"
    "libldap2"
    "liblerc4"
    "libllvm19"
    "libltdl7"
    "liblz4-1"
    "liblzma5"
    "libmd0"
    "libmount1"
    "libmp3lame0"
    "libmpg123-0t64"
    "libmunge2"
    "libnccl2"
    "libnettle8t64"
    "libnghttp2-14"
    "libnl-3-200"
    "libnl-route-3-200"
    "libnotify4"
    "libnsl2"
    "libnspr4"
    "libnss3"
    "libnuma1"
    "libnvidia-compute-470"
    "libogg0"
    "libopengl0"
    "libopenjp2-7"
    "libopus0"
    "liborc-0.4-0t64"
    "libp11-kit0"
    "libpam0g"
    "libpango-1.0-0"
    "libpangocairo-1.0-0"
    "libpangoft2-1.0-0"
    "libpci3"
    "libpciaccess0"
    "libpcre2-32-0"
    "libpcre2-8-0"
    "libpcsclite1"
    "libperl-dev"
    "libpixman-1-0"
    "libpng16-16t64"
    "libpsl5t64"
    "libpulse-mainloop-glib0"
    "libpulse0"
    "librccl1"
    "librdmacm1t64"
    "librtmp1"
    "libsasl2-2"
    "libsecret-1-0"
    "libselinux1"
    "libsensors5"
    "libsharpyuv0"
    "libsm6"
    "libsndfile1"
    "libsoup-2.4-1"
    "libssh-4"
    "libssl3t64"
    "libstdc++6"
    "libstdc++6:i386"
    "libsystemd0"
    "libtasn1-6"
    "libtbb12"
    "libthai0"
    "libtheora0"
    "libtiff6"
    "libtinfo6"
    "libtirpc-dev"
    "libtirpc3t64"
    "libucx0"
    "libudev1"
    "libunistring5"
    "libuno-cppu3t64"
    "libuno-cppuhelpergcc3-3t64"
    "libuno-sal3t64"
    "libuno-salhelpergcc3-3t64"
    "libunwind8"
    "libuuid1"
    "libvorbis0a"
    "libvorbisenc2"
    "libwayland-client0"
    "libwayland-cursor0"
    "libwayland-egl1"
    "libwayland-server0"
    "libwebp7"
    "libx11-6"
    "libx11-6:i386"
    "libx11-xcb1"
    "libxau6"
    "libxcb-cursor0"
    "libxcb-dri2-0"
    "libxcb-dri3-0"
    "libxcb-glx0"
    "libxcb-icccm4"
    "libxcb-image0"
    "libxcb-keysyms1"
    "libxcb-present0"
    "libxcb-randr0"
    "libxcb-render-util0"
    "libxcb-render0"
    "libxcb-shape0"
    "libxcb-shm0"
    "libxcb-sync1"
    "libxcb-util1"
    "libxcb-xfixes0"
    "libxcb-xinerama0"
    "libxcb-xinput0"
    "libxcb-xkb1"
    "libxcb1"
    "libxcomposite1"
    "libxcursor1"
    "libxdamage1"
    "libxdmcp6"
    "libxext6"
    "libxfixes3"
    "libxft2"
    "libxi6"
    "libxinerama1"
    "libxkbcommon-x11-0"
    "libxkbcommon0"
    "libxkbfile1"
    "libxm4"
    "libxml2"
    "libxmu6"
    "libxrandr2"
    "libxrender1"
    "libxshmfence1"
    "libxslt1.1"
    "libxss1"
    "libxt6t64"
    "libxt6t64:i386"
    "libxtst6"
    "libxxf86vm1"
    "libzstd1"
    "make"
    "mesa-libgallium"
    "ocl-icd-libopencl1"
    "ocl-icd-opencl-dev"
    "tar"
    "uuid-dev"
    "xfonts-100dpi"
    "xfonts-75dpi"
    "xterm"
    "zlib1g"
)
# Total: 229 packages

declare -A PRODUCT_LABELS=(
    [acad_reader]="AutoCAD Reader"
    [acis]="ACIS Geometry Interface"
    [adinventor_reader]="Autodesk Inventor Reader"
    [ansyscust]="Ansys Customization Files"
    [aqwa]="Ansys Aqwa"
    [autodyn]="Ansys Autodyn"
    [avxsensors]="Ansys AVxcelerate Sensors"
    [avxsensorscarmaker]="Ansys AVxcelerate Sensors Library for CarMaker"
    [avxsensorsscaner]="Ansys AVxcelerate Sensors Library for SCANeR"
    [blademodeler]="BladeModeler"
    [catia4_reader]="CATIA 4 Reader"
    [catia5_reader]="CATIA 5 Reader"
    [catia6_reader]="CATIA 6 Reader"
    [cfdpost]="Ansys CFD-Post"
    [cfx]="Ansys CFX"
    [chemkin]="Ansys Chemkin"
    [chemkinpro]="Ansys Chemkin Pro"
    [dcs]="Distributed Compute Services"
    [electromagneticsrsm]="Ansys Electromagnetics RSM"
    [electromagneticssuite]="Ansys Electromagnetics Suite"
    [ensight]="Ansys EnSight"
    [fensapice]="Ansys FENSAP-ICE"
    [fluent]="Ansys Fluent"
    [forte]="Ansys Forte"
    [geometryservice]="Geometry Service Packet"
    [icemcfd]="Ansys ICEM CFD"
    [icepak]="Ansys Icepak"
    [jtopen]="JT Open Reader"
    [lsdyna]="Ansys LS-DYNA"
    [lumerical]="Ansys Lumerical"
    [mcre]="Ansys ModelCenter Remote Execution"
    [mechapdl]="Ansys Mechanical APDL"
    [mfl]="Ansys Model Fuel Library (Encrypted)"
    [motion]="Ansys Motion"
    [optislang]="Ansys optiSLang"
    [optislang_ai]="Ansys optiSLang AI"
    [optislang_core]="Ansys optiSLang Core Headless"
    [optislang_saf]="Ansys optiSLang App Generation"
    [parasolid]="Parasolid Geometry Interface"
    [polyflow]="Ansys Polyflow"
    [proe_reader]="Creo Parametric Reader"
    [reactionwb]="Ansys Reaction Workbench"
    [rocky]="Ansys Rocky"
    [rsm]="Ansys Remote Solve Manager Standalone Services"
    [sherlock]="Ansys Sherlock"
    [solidedge_reader]="Solid Edge Reader"
    [solidworks_reader]="SOLIDWORKS Reader"
    [speoshpc]="Ansys Speos HPC"
    [turbogrid]="Ansys TurboGrid"
    [twinai]="Ansys TwinAI"
    [twinbuilder]="Ansys Twin Builder"
    [ug_plugin]="NX Geometry Interface Plugin"
    [ug_reader]="NX Reader"
)

declare -A PRODUCT_EXTRA_FLAG=(
    [avxsensors]="-avxlib_path"
    [avxsensorscarmaker]="-carmaker_path"
    [avxsensorsscaner]="-sensors_scaner_path"
)

declare -A PRODUCT_EXTRA_PATHS=()

CAD_READER_KEYS=(
    acad_reader
    adinventor_reader
    catia4_reader
    catia5_reader
    catia6_reader
    proe_reader
    jtopen
    ug_reader
    solidedge_reader
    solidworks_reader
    ug_plugin
    parasolid
    acis
)

PRODUCT_KEYS_232=(
    aqwa autodyn cfx cfdpost chemkinpro ansyscust ensight fensapice forte fluent
    icemcfd motion mechapdl lsdyna mfl optislang polyflow reactionwb speoshpc
    turbogrid acis icepak rsm catia5_reader dcs ug_plugin parasolid
)

PRODUCT_KEYS_241=(
    aqwa autodyn cfx cfdpost chemkin ansyscust ensight fensapice forte fluent
    icemcfd motion mechapdl lsdyna mfl optislang polyflow reactionwb sherlock
    speoshpc turbogrid acis icepak rsm catia5_reader dcs ug_plugin parasolid
)

PRODUCT_KEYS_242=(
    aqwa autodyn cfx cfdpost chemkin ansyscust ensight fensapice forte fluent
    icemcfd motion mechapdl lsdyna mfl optislang polyflow reactionwb sherlock
    speoshpc turbogrid acis icepak rsm catia5_reader ug_plugin parasolid
)

PRODUCT_KEYS_251=(
    aqwa autodyn cfx cfdpost chemkin ansyscust ensight fensapice forte fluent
    icemcfd motion mechapdl lsdyna mfl optislang polyflow reactionwb sherlock
    speoshpc turbogrid acis icepak rsm catia5_reader ug_plugin parasolid
    avxsensors avxsensorsscaner avxsensorscarmaker blademodeler
    electromagneticssuite electromagneticsrsm lumerical rocky twinai twinbuilder
)

PRODUCT_KEYS_252=(
    aqwa autodyn cfx cfdpost chemkin ansyscust ensight fensapice forte fluent
    icemcfd motion mechapdl lsdyna mfl optislang polyflow reactionwb sherlock
    speoshpc turbogrid acis icepak rsm catia5_reader ug_plugin parasolid
    avxsensors avxsensorscarmaker blademodeler electromagneticssuite
    electromagneticsrsm lumerical rocky twinai twinbuilder mcre optislang_ai
    optislang_saf geometryservice acad_reader adinventor_reader catia4_reader
    catia6_reader proe_reader jtopen ug_reader solidedge_reader solidworks_reader
)

PRODUCT_KEYS_261=(
    aqwa autodyn cfx cfdpost chemkin ansyscust ensight fensapice forte fluent
    icemcfd motion mechapdl lsdyna mfl optislang optislang_core optislang_ai
    optislang_saf polyflow reactionwb sherlock speoshpc turbogrid acis icepak
    rsm catia5_reader ug_plugin parasolid avxsensors avxsensorscarmaker
    blademodeler electromagneticssuite electromagneticsrsm lumerical rocky
    twinai twinbuilder mcre geometryservice acad_reader adinventor_reader
    catia4_reader catia6_reader proe_reader jtopen ug_reader solidedge_reader
    solidworks_reader
)

init_colors() {
    if (( NO_COLOR )) || [[ ! -t 1 ]]; then
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        CYAN=""
        BOLD=""
        DIM=""
        RESET=""
        return
    fi

    if command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null || printf '0') -ge 8 ]]; then
        RED="$(tput setaf 1)"
        GREEN="$(tput setaf 2)"
        YELLOW="$(tput setaf 3)"
        BLUE="$(tput setaf 4)"
        CYAN="$(tput setaf 6)"
        BOLD="$(tput bold)"
        DIM="$(tput dim 2>/dev/null || true)"
        RESET="$(tput sgr0)"
    else
        RED=$'\033[31m'
        GREEN=$'\033[32m'
        YELLOW=$'\033[33m'
        BLUE=$'\033[34m'
        CYAN=$'\033[36m'
        BOLD=$'\033[1m'
        DIM=$'\033[2m'
        RESET=$'\033[0m'
    fi
}

ensure_log_file() {
    touch "$LOG_PATH"
}

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    ensure_log_file
    printf '%s %s\n' "$(timestamp)" "$*" >>"$LOG_PATH"
}

info() {
    log "[INFO] $*"
    printf '%b[INFO]%b %s\n' "$CYAN" "$RESET" "$*"
}

warn() {
    log "[WARN] $*"
    printf '%b[WARN]%b %s\n' "$YELLOW" "$RESET" "$*"
}

error() {
    log "[ERROR] $*"
    printf '%b[ERROR]%b %s\n' "$RED" "$RESET" "$*" >&2
}

success() {
    log "[OK] $*"
    printf '%b[OK]%b %s\n' "$GREEN" "$RESET" "$*"
}

separator() {
    printf '%s\n' "------------------------------------------------------------"
}

header() {
    separator
    printf '%b%s%b\n' "$BOLD" "$*" "$RESET"
    separator
}

banner() {
    printf '%b%s%b\n' "$BOLD" "$SCRIPT_NAME" "$RESET"
    printf '%s\n' "by $BRAND"
    printf '%s\n' "Version $SCRIPT_VERSION"
    printf '%s\n' "Copyright $COPYRIGHT_YEAR"
    separator
}

pause() {
    read -r -p "Press Enter to continue..." _unused
}

prompt_yn() {
    local question="$1"
    local default_answer="${2:-y}"
    local prompt="[y/n]"
    local answer=""

    case "$default_answer" in
        y|Y) prompt="[Y/n]" ;;
        n|N) prompt="[y/N]" ;;
    esac

    while true; do
        read -r -p "$question $prompt " answer
        if [[ -z "$answer" ]]; then
            answer="$default_answer"
        fi
        case "$answer" in
            y|Y|yes|YES) return 0 ;;
            n|N|no|NO) return 1 ;;
            *) warn "Please answer y or n." ;;
        esac
    done
}

prompt_input() {
    local question="$1"
    local default_value="${2:-}"
    local answer=""

    if [[ -n "$default_value" ]]; then
        read -r -p "$question [$default_value]: " answer
        if [[ -z "$answer" ]]; then
            answer="$default_value"
        fi
    else
        read -r -p "$question: " answer
    fi

    printf '%s\n' "$answer"
}

prompt_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local idx=1
    local answer=""

    printf '%s\n' "$prompt" >&2
    for option in "${options[@]}"; do
        printf '  %d. %s\n' "$idx" "$option" >&2
        ((idx += 1))
    done

    while true; do
        read -r -p "Select option: " answer
        if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= ${#options[@]} )); then
            printf '%s\n' "$answer"
            return 0
        fi
        warn "Please enter a number between 1 and ${#options[@]}."
    done
}

status_line() {
    local label="$1"
    local value="$2"
    local state="$3"
    printf '  %-24.24s [%-20.20s] %s\n' "$label" "$value" "$state"
}

print_command() {
    local parts=()
    local arg=""
    for arg in "$@"; do
        printf -v arg '%q' "$arg"
        parts+=("$arg")
    done
    printf '%s' "${parts[*]}"
}

run_cmd() {
    local description="$1"
    shift
    local rendered=""
    rendered=$(print_command "$@")
    log "$description: $rendered"
    if (( DRY_RUN )); then
        info "[dry-run] $rendered"
        return 0
    fi
    if "$@" >>"$LOG_PATH" 2>&1; then
        return 0
    fi
    local exit_code=$?
    error "$description failed (exit $exit_code). See $LOG_PATH"
    return "$exit_code"
}

run_shell_cmd() {
    local description="$1"
    shift
    local rendered=""
    rendered=$(print_command bash -c "$*")
    log "$description: $rendered"
    if (( DRY_RUN )); then
        info "[dry-run] $*"
        return 0
    fi
    if bash -c "$*" >>"$LOG_PATH" 2>&1; then
        return 0
    fi
    local exit_code=$?
    error "$description failed (exit $exit_code). See $LOG_PATH"
    return "$exit_code"
}

require_bash_version() {
    if (( BASH_VERSINFO[0] < 4 )) || { (( BASH_VERSINFO[0] == 4 )) && (( BASH_VERSINFO[1] < 3 )); }; then
        error "This script requires Bash 4.3 or newer. Found ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}."
        exit 1
    fi
}

load_package_arrays() {
    local required_arrays=(
        PKGS_INSTALLER_RHEL8 PKGS_LICMGR_RHEL8 PKGS_CORE_SOLVERS_RHEL8 PKGS_ALL_RHEL8
        PKGS_INSTALLER_RHEL9 PKGS_LICMGR_RHEL9 PKGS_CORE_SOLVERS_RHEL9 PKGS_ALL_RHEL9
        PKGS_INSTALLER_SLES15 PKGS_LICMGR_SLES15 PKGS_CORE_SOLVERS_SLES15 PKGS_ALL_SLES15
        PKGS_INSTALLER_UBUNTU2204 PKGS_LICMGR_UBUNTU2204 PKGS_CORE_SOLVERS_UBUNTU2204 PKGS_ALL_UBUNTU2204
        PKGS_INSTALLER_UBUNTU2404 PKGS_LICMGR_UBUNTU2404 PKGS_CORE_SOLVERS_UBUNTU2404 PKGS_ALL_UBUNTU2404
    )
    local array_name=""

    for array_name in "${required_arrays[@]}"; do
        if ! declare -p "$array_name" >/dev/null 2>&1; then
            error "Missing embedded package array: $array_name"
            exit 1
        fi
    done
}

validate_version() {
    local version="$1"
    local item=""
    for item in "${SUPPORTED_VERSIONS[@]}"; do
        if [[ "$item" == "$version" ]]; then
            return 0
        fi
    done
    return 1
}

set_selected_version() {
    local version="$1"

    if ! validate_version "$version"; then
        error "Unsupported version: $version"
        return 1
    fi

    SELECTED_VERSION="$version"
    SELECTED_VERSION_CODE="${VERSION_CODES[$version]}"
    STATUS_VERSION_SET=1
    normalize_product_selection_for_version
    success "Selected version: $SELECTED_VERSION"
}

detect_os() {
    local os_release="/etc/os-release"
    if [[ ! -r "$os_release" ]]; then
        warn "Cannot read $os_release. OS detection will be limited."
        return 1
    fi

    OS_ID=""
    OS_VERSION_ID=""
    # shellcheck disable=SC1091
    . "$os_release"
    OS_ID="${ID:-}"
    OS_VERSION_ID="${VERSION_ID:-}"
    OS_MAJOR="${OS_VERSION_ID%%.*}"
    OS_FAMILY="unsupported"
    PKG_MGR=""

    case "$OS_ID" in
        rhel|rocky|almalinux|ol|centos)
            case "$OS_MAJOR" in
                8) OS_FAMILY="rhel8"; PKG_MGR="dnf" ;;
                9) OS_FAMILY="rhel9"; PKG_MGR="dnf" ;;
            esac
            ;;
        sles|sled)
            if [[ "$OS_MAJOR" == "15" ]]; then
                OS_FAMILY="sles15"
                PKG_MGR="zypper"
            fi
            ;;
        ubuntu)
            case "$OS_VERSION_ID" in
                22.04) OS_FAMILY="ubuntu2204"; PKG_MGR="apt" ;;
                24.04) OS_FAMILY="ubuntu2404"; PKG_MGR="apt" ;;
            esac
            ;;
    esac

    if [[ "$OS_FAMILY" == "unsupported" ]]; then
        warn "Detected OS ${OS_ID:-unknown} ${OS_VERSION_ID:-unknown}. This platform is not in the supported helper matrix."
    else
        info "Detected OS: $OS_ID $OS_VERSION_ID ($OS_FAMILY, package manager: $PKG_MGR)"
    fi
}

check_root() {
    if (( EUID == 0 )); then
        IS_ROOT=1
        info "Running as root."
    else
        IS_ROOT=0
        warn "Not running as root. Package installation, ISO mounting, system install paths, and symlink creation may fail."
    fi
}

require_root_for_action() {
    local action="$1"
    if (( IS_ROOT == 1 )); then
        return 0
    fi
    error "$action requires root privileges. Re-run the helper as root or choose a user-writable workflow."
    return 1
}

df_available_mb() {
    local path="$1"
    df -Pm "$path" 2>/dev/null | awk 'NR==2 {print $4}'
}

check_disk_space() {
    local install_parent="${INSTALL_DIR%/*}"
    local install_space=""
    local tmp_space=""

    [[ -n "$install_parent" ]] || install_parent="/"
    if [[ ! -d "$install_parent" ]]; then
        install_parent="/"
    fi

    install_space="$(df_available_mb "$install_parent" 2>/dev/null || true)"
    tmp_space="$(df_available_mb "/tmp" 2>/dev/null || true)"

    if [[ -n "$install_space" ]] && (( install_space < MIN_DISK_SPACE_MB )); then
        warn "Available space at $install_parent is ${install_space} MB; recommended minimum is ${MIN_DISK_SPACE_MB} MB."
    fi
    if [[ -n "$tmp_space" ]] && (( tmp_space < MIN_TMP_SPACE_MB )); then
        warn "Available space at /tmp is ${tmp_space} MB; recommended minimum is ${MIN_TMP_SPACE_MB} MB."
    fi
}

package_is_installed() {
    local pkg="$1"
    case "$PKG_MGR" in
        dnf|zypper)
            rpm -q --quiet "$pkg"
            ;;
        apt)
            dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -q 'install ok installed'
            ;;
        *)
            return 1
            ;;
    esac
}

install_packages() {
    local packages=("$@")
    case "$PKG_MGR" in
        dnf)
            run_cmd "Installing packages" dnf install -y "${packages[@]}"
            ;;
        zypper)
            run_cmd "Installing packages" zypper install -y --no-confirm "${packages[@]}"
            ;;
        apt)
            run_cmd "Installing packages" apt-get install -y "${packages[@]}"
            ;;
        *)
            error "Unsupported package manager: $PKG_MGR"
            return 1
            ;;
    esac
}

dedupe_array() {
    local -n input_ref=$1
    local -n output_ref=$2
    local item=""
    declare -A seen=()
    output_ref=()
    for item in "${input_ref[@]}"; do
        [[ -n "$item" ]] || continue
        if [[ -z ${seen[$item]+x} ]]; then
            output_ref+=("$item")
            seen[$item]=1
        fi
    done
}

check_installed_packages() {
    local -n packages_ref=$1
    local -n installed_ref=$2
    local -n missing_ref=$3
    local pkg=""

    installed_ref=()
    missing_ref=()

    for pkg in "${packages_ref[@]}"; do
        if package_is_installed "$pkg"; then
            installed_ref+=("$pkg")
        else
            missing_ref+=("$pkg")
        fi
    done
}

needs_i386_architecture() {
    local -n packages_ref=$1
    local pkg=""
    for pkg in "${packages_ref[@]}"; do
        if [[ "$pkg" == *":i386" ]]; then
            return 0
        fi
    done
    return 1
}

i386_arch_enabled() {
    dpkg --print-foreign-architectures 2>/dev/null | grep -qx 'i386'
}

enable_required_repos() {
    if [[ -z "$PKG_MGR" ]]; then
        warn "Package manager not detected; skipping repo enablement."
        return 0
    fi

    if (( IS_ROOT == 0 )); then
        warn "Skipping repo enablement because the helper is not running as root."
        return 0
    fi

    case "$OS_FAMILY" in
        rhel8)
            if ! rpm -q epel-release >/dev/null 2>&1; then
                run_cmd "Installing EPEL release" dnf install -y epel-release || warn "Could not install epel-release."
            fi
            if command -v dnf >/dev/null 2>&1; then
                run_cmd "Enabling CRB repository" dnf config-manager --set-enabled crb || \
                    run_cmd "Enabling PowerTools repository" dnf config-manager --set-enabled powertools || \
                    warn "Could not enable CRB/PowerTools. Some RHEL packages may remain unavailable."
            fi
            ;;
        rhel9)
            if ! rpm -q epel-release >/dev/null 2>&1; then
                run_cmd "Installing EPEL release" dnf install -y epel-release || warn "Could not install epel-release."
            fi
            if command -v dnf >/dev/null 2>&1; then
                run_cmd "Enabling CRB repository" dnf config-manager --set-enabled crb || warn "Could not enable CRB."
            fi
            ;;
        sles15)
            if command -v SUSEConnect >/dev/null 2>&1; then
                if ! SUSEConnect -l 2>/dev/null | grep -q 'PackageHub'; then
                    run_cmd "Enabling PackageHub" SUSEConnect -p "PackageHub/15.${OS_VERSION_ID#15.}/x86_64" || \
                        warn "Could not enable PackageHub. Some SLES packages may remain unavailable."
                fi
            else
                warn "SUSEConnect is not available; cannot auto-enable PackageHub."
            fi
            ;;
        ubuntu2204|ubuntu2404)
            if ! grep -RhsE '^[^#].*universe' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | grep -q 'universe'; then
                if command -v add-apt-repository >/dev/null 2>&1; then
                    run_cmd "Enabling universe repository" add-apt-repository -y universe || warn "Could not enable universe repository."
                else
                    warn "add-apt-repository is unavailable; cannot auto-enable universe."
                fi
            fi
            run_cmd "Refreshing APT metadata" apt-get update || warn "apt-get update failed; package installs may fail."
            ;;
    esac
}

ensure_i386_arch_if_needed() {
    local -n package_list_ref=$1
    if [[ "$PKG_MGR" != "apt" ]]; then
        return 0
    fi
    if ! needs_i386_architecture package_list_ref; then
        return 0
    fi
    if i386_arch_enabled; then
        return 0
    fi
    require_root_for_action "Adding the i386 architecture" || return 1
    if run_cmd "Adding i386 architecture" dpkg --add-architecture i386; then
        run_cmd "Refreshing APT metadata" apt-get update || warn "apt-get update failed after adding i386 architecture."
    else
        warn "Could not add the i386 architecture. Some Ubuntu packages may remain unavailable."
    fi
}

get_pkg_array_name() {
    local family="$1"
    local profile="$2"
    local family_upper="${family^^}"
    local profile_upper=""
    case "$profile" in
        installer) profile_upper="INSTALLER" ;;
        all) profile_upper="ALL" ;;
        core_solvers) profile_upper="CORE_SOLVERS" ;;
        licmgr) profile_upper="LICMGR" ;;
        *) return 1 ;;
    esac
    printf 'PKGS_%s_%s\n' "$profile_upper" "$family_upper"
}

get_pkg_array() {
    local family="$1"
    local profile="$2"
    local array_name=""
    array_name="$(get_pkg_array_name "$family" "$profile")" || return 1
    if ! declare -p "$array_name" >/dev/null 2>&1; then
        return 1
    fi
    local -n array_ref="$array_name"
    printf '%s\n' "${array_ref[@]}"
}

profile_display_name() {
    case "$1" in
        all) printf 'All Products' ;;
        core_solvers) printf 'Core Solvers' ;;
        licmgr) printf 'License Manager Only' ;;
        installer) printf 'Installer Prerequisites Only' ;;
        *) printf '%s' "$1" ;;
    esac
}

install_prerequisites() {
    local choice=""
    local requested_packages=()
    local deduped_packages=()
    local display_profile=""

    if [[ "$OS_FAMILY" == "unsupported" ]]; then
        warn "This OS family is not fully supported by the helper. Package installation may fail."
    fi

    choice="$(prompt_choice "Select prerequisite profile:" \
        "All Products" \
        "Core Solvers" \
        "License Manager Only" \
        "Installer Prerequisites Only")"

    case "$choice" in
        1) PKG_PROFILE="all" ;;
        2) PKG_PROFILE="core_solvers" ;;
        3) PKG_PROFILE="licmgr" ;;
        4) PKG_PROFILE="installer" ;;
    esac

    if ! mapfile -t requested_packages < <(get_pkg_array "$OS_FAMILY" "$PKG_PROFILE"); then
        error "No package list found for OS family '$OS_FAMILY' and profile '$PKG_PROFILE'."
        pause
        return 1
    fi

    requested_packages+=(csh)
    dedupe_array requested_packages deduped_packages

    enable_required_repos
    ensure_i386_arch_if_needed deduped_packages || true
    check_installed_packages deduped_packages ALREADY_INSTALLED NEEDS_INSTALL

    display_profile="$(profile_display_name "$PKG_PROFILE")"
    header "Prerequisite Summary"
    printf 'Profile: %s\n' "$display_profile"
    printf 'Already installed: %d\n' "${#ALREADY_INSTALLED[@]}"
    printf 'Need installation: %d\n' "${#NEEDS_INSTALL[@]}"

    if (( ${#NEEDS_INSTALL[@]} == 0 )); then
        success "All prerequisite packages are already installed."
        STATUS_PREREQS_DONE=1
        pause
        return 0
    fi

    printf '\nPackages to install:\n'
    printf '  %s\n' "${NEEDS_INSTALL[@]}"
    printf '\n'

    require_root_for_action "Package installation" || { pause; return 1; }
    if ! prompt_yn "Install missing prerequisite packages now?" y; then
        warn "Skipped prerequisite installation."
        pause
        return 0
    fi

    if install_packages "${NEEDS_INSTALL[@]}"; then
        check_installed_packages deduped_packages ALREADY_INSTALLED NEEDS_INSTALL
        if (( ${#NEEDS_INSTALL[@]} == 0 )); then
            STATUS_PREREQS_DONE=1
            success "Prerequisite installation completed successfully."
        else
            warn "Some prerequisite packages are still missing after installation:"
            printf '  %s\n' "${NEEDS_INSTALL[@]}"
            warn "Review package-manager errors in $LOG_PATH."
        fi
    else
        check_installed_packages deduped_packages ALREADY_INSTALLED NEEDS_INSTALL
        warn "Prerequisite installation failed. Remaining missing packages:"
        printf '  %s\n' "${NEEDS_INSTALL[@]}"
        warn "Review package-manager errors in $LOG_PATH."
    fi

    pause
}

install_goodies() {
    local requested=()
    local deduped=()

    requested=("${GOODIES_COMMON[@]}")
    case "$OS_FAMILY" in
        rhel8|rhel9) requested+=("${GOODIES_RHEL[@]}") ;;
        sles15) requested+=("${GOODIES_SLES[@]}") ;;
        ubuntu2204|ubuntu2404) requested+=("${GOODIES_UBUNTU[@]}") ;;
        *) warn "Goodies list is not defined for OS family '$OS_FAMILY'." ; pause; return 0 ;;
    esac

    dedupe_array requested deduped
    check_installed_packages deduped ALREADY_INSTALLED NEEDS_INSTALL

    header "Goodies Summary"
    printf 'Already installed: %d\n' "${#ALREADY_INSTALLED[@]}"
    printf 'Need installation: %d\n' "${#NEEDS_INSTALL[@]}"

    if (( ${#NEEDS_INSTALL[@]} == 0 )); then
        success "All goodies packages are already installed."
        STATUS_GOODIES_DONE=1
        pause
        return 0
    fi

    printf '\nPackages to install:\n'
    printf '  %s\n' "${NEEDS_INSTALL[@]}"
    printf '\n'

    require_root_for_action "Goodies installation" || { pause; return 1; }
    if ! prompt_yn "Install goodies packages now?" y; then
        warn "Skipped goodies installation."
        pause
        return 0
    fi

    if install_packages "${NEEDS_INSTALL[@]}"; then
        STATUS_GOODIES_DONE=1
        success "Goodies installation completed successfully."
    else
        warn "Goodies installation failed. Review $LOG_PATH for details."
    fi

    pause
}

get_product_array_name() {
    if [[ -z "$SELECTED_VERSION_CODE" ]]; then
        return 1
    fi
    printf 'PRODUCT_KEYS_%s\n' "$SELECTED_VERSION_CODE"
}

get_product_keys_for_version() {
    local array_name=""
    array_name="$(get_product_array_name)" || return 1
    if ! declare -p "$array_name" >/dev/null 2>&1; then
        return 1
    fi
    local -n array_ref="$array_name"
    printf '%s\n' "${array_ref[@]}"
}

display_product_name() {
    local key="$1"
    printf '%s\n' "${PRODUCT_LABELS[$key]:-$key}"
}

array_contains() {
    local needle="$1"
    shift
    local item=""
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

normalize_product_selection_for_version() {
    local valid_keys=()
    local normalized=()
    local key=""

    if ! mapfile -t valid_keys < <(get_product_keys_for_version 2>/dev/null); then
        SELECTED_PRODUCT_KEYS=()
        PRODUCT_SELECTION_MODE="all"
        return 0
    fi

    for key in "${SELECTED_PRODUCT_KEYS[@]}"; do
        if array_contains "$key" "${valid_keys[@]}"; then
            normalized+=("$key")
        fi
    done

    SELECTED_PRODUCT_KEYS=("${normalized[@]}")
    if (( ${#SELECTED_PRODUCT_KEYS[@]} == 0 )) && [[ "$PRODUCT_SELECTION_MODE" == "expert" ]]; then
        PRODUCT_SELECTION_MODE="all"
    fi
}

toggle_key_in_selection() {
    local key="$1"
    local existing=()
    local found=0
    local item=""
    for item in "${SELECTED_PRODUCT_KEYS[@]}"; do
        if [[ "$item" == "$key" ]]; then
            found=1
        else
            existing+=("$item")
        fi
    done
    if (( found == 1 )); then
        SELECTED_PRODUCT_KEYS=("${existing[@]}")
    else
        existing+=("$key")
        SELECTED_PRODUCT_KEYS=("${existing[@]}")
    fi
}

toggle_cad_group() {
    local valid_keys=()
    local cad_valid=()
    local key=""
    local all_selected=1
    local new_selection=()

    mapfile -t valid_keys < <(get_product_keys_for_version)
    for key in "${CAD_READER_KEYS[@]}"; do
        if array_contains "$key" "${valid_keys[@]}"; then
            cad_valid+=("$key")
        fi
    done

    if (( ${#cad_valid[@]} == 0 )); then
        warn "No CAD reader group entries are available for this version."
        return 0
    fi

    for key in "${cad_valid[@]}"; do
        if ! array_contains "$key" "${SELECTED_PRODUCT_KEYS[@]}"; then
            all_selected=0
            break
        fi
    done

    if (( all_selected == 1 )); then
        for key in "${SELECTED_PRODUCT_KEYS[@]}"; do
            if ! array_contains "$key" "${cad_valid[@]}"; then
                new_selection+=("$key")
            fi
        done
        SELECTED_PRODUCT_KEYS=("${new_selection[@]}")
    else
        for key in "${cad_valid[@]}"; do
            if ! array_contains "$key" "${SELECTED_PRODUCT_KEYS[@]}"; then
                SELECTED_PRODUCT_KEYS+=("$key")
            fi
        done
    fi
}

select_products() {
    local mode_choice=""
    local valid_keys=()
    local idx=1
    local key=""
    local answer=""
    local group_index=0
    local display_state=""
    local tokens=()
    local token=""

    if [[ "$INSTALL_MODE" == "license_manager" ]]; then
        warn "Product selection is not used for License Manager mode."
        pause
        return 0
    fi

    mode_choice="$(prompt_choice "Product Selection:" \
        "Install Everything (default)" \
        "Expert Mode - Select Individual Products")"

    if [[ "$mode_choice" == "1" ]]; then
        PRODUCT_SELECTION_MODE="all"
        SELECTED_PRODUCT_KEYS=()
        STATUS_INSTALL_CONFIGURED=1
        success "Product selection reset to install everything."
        pause
        return 0
    fi

    mapfile -t valid_keys < <(get_product_keys_for_version)
    if (( ${#valid_keys[@]} == 0 )); then
        warn "No product list is available for the current version."
        pause
        return 1
    fi

    PRODUCT_SELECTION_MODE="expert"
    while true; do
        header "Expert Product Selection"
        idx=1
        for key in "${valid_keys[@]}"; do
            if array_contains "$key" "${SELECTED_PRODUCT_KEYS[@]}"; then
                display_state="[X]"
            else
                display_state="[ ]"
            fi
            printf '  %2d. %s %s\n' "$idx" "$display_state" "$(display_product_name "$key")"
            ((idx += 1))
        done

        group_index=$idx
        if array_contains "catia5_reader" "${valid_keys[@]}" || array_contains "acad_reader" "${valid_keys[@]}" || array_contains "acis" "${valid_keys[@]}"; then
            if array_contains "acis" "${SELECTED_PRODUCT_KEYS[@]}" || array_contains "catia5_reader" "${SELECTED_PRODUCT_KEYS[@]}" || array_contains "acad_reader" "${SELECTED_PRODUCT_KEYS[@]}"; then
                display_state="[X]"
            else
                display_state="[ ]"
            fi
            printf '  %2d. %s CAD Readers Group\n' "$group_index" "$display_state"
        else
            group_index=0
        fi

        printf '\nEnter numbers to toggle, separated by spaces.\n'
        printf 'Press Enter when done, or type all / none.\n\n'
        read -r -p "Selection: " answer

        if [[ -z "$answer" ]]; then
            if (( ${#SELECTED_PRODUCT_KEYS[@]} == 0 )); then
                warn "No products are selected. Choose at least one product or use Install Everything."
                continue
            fi
            STATUS_INSTALL_CONFIGURED=1
            success "Stored expert product selection for this session."
            pause
            return 0
        fi

        case "$answer" in
            all|ALL)
                SELECTED_PRODUCT_KEYS=("${valid_keys[@]}")
                continue
                ;;
            none|NONE)
                SELECTED_PRODUCT_KEYS=()
                continue
                ;;
        esac

        read -r -a tokens <<<"$answer"
        for token in "${tokens[@]}"; do
            if [[ ! "$token" =~ ^[0-9]+$ ]]; then
                warn "Ignoring invalid token: $token"
                continue
            fi
            if (( token >= 1 && token <= ${#valid_keys[@]} )); then
                toggle_key_in_selection "${valid_keys[token-1]}"
            elif (( group_index > 0 && token == group_index )); then
                toggle_cad_group
            else
                warn "Ignoring out-of-range selection: $token"
            fi
        done
    done
}

ensure_extra_path_for_product() {
    local key="$1"
    local extra_flag="${PRODUCT_EXTRA_FLAG[$key]:-}"
    local current_path="${PRODUCT_EXTRA_PATHS[$key]:-}"
    local new_path=""

    if [[ -z "$extra_flag" ]]; then
        return 0
    fi

    if [[ -n "$current_path" && -e "$current_path" ]]; then
        return 0
    fi

    warn "$(display_product_name "$key") requires an additional path argument: $extra_flag"
    while true; do
        new_path="$(prompt_input "Enter path for $(display_product_name "$key")")"
        if [[ -n "$new_path" ]]; then
            PRODUCT_EXTRA_PATHS[$key]="$new_path"
            return 0
        fi
        warn "A path is required for $(display_product_name "$key")."
    done
}

build_product_flags() {
    local -n output_ref=$1
    local key=""
    output_ref=()

    if [[ "$INSTALL_MODE" == "license_manager" ]]; then
        return 0
    fi

    if [[ "$PRODUCT_SELECTION_MODE" == "all" ]]; then
        return 0
    fi

    normalize_product_selection_for_version
    for key in "${SELECTED_PRODUCT_KEYS[@]}"; do
        ensure_extra_path_for_product "$key"
        output_ref+=("-$key")
        if [[ -n ${PRODUCT_EXTRA_FLAG[$key]:-} ]]; then
            output_ref+=("${PRODUCT_EXTRA_FLAG[$key]}" "${PRODUCT_EXTRA_PATHS[$key]}")
        fi
    done
}

detect_version_from_files() {
    local dir="$1"
    local path=""
    local base=""
    local version=""
    local matches=()
    declare -A seen=()
    shopt -s nullglob
    for path in "$dir"/*; do
        [[ -f "$path" ]] || continue
        base="$(basename "$path")"
        if [[ "$base" =~ (20[0-9]{2}R[12])(\.[0-9]{2})? ]]; then
            version="${BASH_REMATCH[1]}"
            if validate_version "$version" && [[ -z ${seen[$version]+x} ]]; then
                matches+=("$version")
                seen[$version]=1
            fi
        fi
    done
    shopt -u nullglob

    if (( ${#matches[@]} == 1 )); then
        printf '%s\n' "${matches[0]}"
    fi
}

detect_version_from_name() {
    local name="$1"
    if [[ "$name" =~ (20[0-9]{2}R[12])(\.[0-9]{2})? ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    fi
}

scan_single_media_file() {
    local source_file="$1"
    local base=""

    SCAN_ISOS=()
    SCAN_TGZS=()
    SCAN_TGZ_VERSIONS=()

    [[ -f "$source_file" ]] || return 1
    base="$(basename "$source_file")"
    case "$base" in
        *.iso)
            SCAN_ISOS+=("$source_file")
            ;;
        *.tgz|*.tar.gz)
            SCAN_TGZS+=("$source_file")
            SCAN_TGZ_VERSIONS+=("$(detect_version_from_name "$base" || true)")
            ;;
        *)
            return 1
            ;;
    esac
}

scan_media() {
    local path=""
    SCAN_ISOS=()
    SCAN_TGZS=()
    SCAN_TGZ_VERSIONS=()

    if [[ -z "$SOURCE_DIR" ]]; then
        return 1
    fi

    if [[ -f "$SOURCE_DIR" ]]; then
        SOURCE_PATH_TYPE="file"
        scan_single_media_file "$SOURCE_DIR"
        return $?
    fi

    if [[ ! -d "$SOURCE_DIR" ]]; then
        return 1
    fi

    SOURCE_PATH_TYPE="directory"

    shopt -s nullglob
    for path in "$SOURCE_DIR"/*.iso; do
        [[ -f "$path" ]] && SCAN_ISOS+=("$path")
    done
    for path in "$SOURCE_DIR"/*.tgz "$SOURCE_DIR"/*.tar.gz; do
        if [[ -f "$path" ]]; then
            SCAN_TGZS+=("$path")
            SCAN_TGZ_VERSIONS+=("$(detect_version_from_name "$(basename "$path")" || true)")
        fi
    done
    shopt -u nullglob
}

select_source_dir() {
    local choice=""
    local candidate=""
    local detected_version=""

    choice="$(prompt_choice "Select source path:" \
        "Use current directory ($PWD)" \
        "Enter a custom directory or media file path")"

    case "$choice" in
        1) candidate="$PWD" ;;
        2) candidate="$(prompt_input "Enter source directory path")" ;;
    esac

    if [[ ! -e "$candidate" || ! -r "$candidate" ]]; then
        error "Source path is not readable: $candidate"
        pause
        return 1
    fi

    SOURCE_DIR="$candidate"
    STATUS_SOURCE_SET=1
    if ! scan_media; then
        error "Source path does not contain supported media: $SOURCE_DIR"
        pause
        return 1
    fi
    if [[ -d "$SOURCE_DIR" ]]; then
        detected_version="$(detect_version_from_files "$SOURCE_DIR" || true)"
    else
        detected_version="$(detect_version_from_name "$(basename "$SOURCE_DIR")" || true)"
    fi

    header "Source Media Summary"
    printf 'Source: %s\n' "$SOURCE_DIR"
    printf 'Source Type: %s\n' "$SOURCE_PATH_TYPE"
    printf 'ISO files: %d\n' "${#SCAN_ISOS[@]}"
    printf 'TGZ files: %d\n' "${#SCAN_TGZS[@]}"

    if [[ -n "$detected_version" ]]; then
        printf 'Detected version: %s\n' "$detected_version"
        if [[ -z "$SELECTED_VERSION" ]] || prompt_yn "Use detected version $detected_version?" y; then
            set_selected_version "$detected_version" || true
        fi
    fi

    pause
}

create_work_dir() {
    local base_dir=""
    if [[ -n "$TEMP_DIR_OVERRIDE" ]]; then
        base_dir="$TEMP_DIR_OVERRIDE"
    else
        base_dir="/tmp"
    fi

    mkdir -p "$base_dir"
    WORK_DIR="$(mktemp -d "$base_dir/ansys_install_helper.XXXXXX")"
    log "Created work directory: $WORK_DIR"
}

find_iso_for_disk() {
    local disk_number="$1"
    local path=""
    local base_upper=""
    local version_upper="${SELECTED_VERSION^^}"

    for path in "${SCAN_ISOS[@]}"; do
        base_upper="$(basename "$path")"
        base_upper="${base_upper^^}"
        if [[ "$base_upper" =~ ${version_upper}.*DISK([0-9]+)\.ISO$ ]] && [[ "${BASH_REMATCH[1]}" == "$disk_number" ]]; then
            printf '%s\n' "$path"
            return 0
        fi
    done
    return 1
}

cleanup_prepared_media() {
    local mp=""
    local dir=""

    if (( ${#MOUNT_POINTS[@]} > 0 )); then
        for (( idx=${#MOUNT_POINTS[@]}-1; idx>=0; idx-=1 )); do
            mp="${MOUNT_POINTS[idx]}"
            if mountpoint -q "$mp" 2>/dev/null; then
                run_cmd "Unmounting $mp" umount "$mp" || warn "Failed to unmount $mp"
            fi
            [[ -d "$mp" ]] && rmdir "$mp" 2>/dev/null || true
        done
    fi

    for dir in "${EXTRACT_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            if (( DRY_RUN )); then
                info "[dry-run] rm -rf $(print_command "$dir")"
            else
                rm -rf "$dir"
                log "Removed extracted work directory: $dir"
            fi
        fi
    done

    if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] && (( ${#EXTRACT_DIRS[@]} == 0 )); then
        if (( DRY_RUN )); then
            info "[dry-run] rm -rf $(print_command "$WORK_DIR")"
        else
            rm -rf "$WORK_DIR"
            log "Removed work directory: $WORK_DIR"
        fi
    fi

    MOUNT_POINTS=()
    EXTRACT_DIRS=()
    MEDIA_EXTRA_ARGS=()
    MERGED_MEDIA_DIR=""
    MEDIA_TYPE=""
    CURRENT_MEDIA_LABEL=""
    WORK_DIR=""
    STATUS_MEDIA_PREPARED=0
}

find_install_root() {
    local base_dir="$1"
    local candidate=""

    if [[ -f "$base_dir/INSTALL" ]]; then
        printf '%s\n' "$base_dir"
        return 0
    fi

    while IFS= read -r candidate; do
        printf '%s\n' "$(dirname "$candidate")"
        return 0
    done < <(find "$base_dir" -maxdepth 3 -type f -name INSTALL 2>/dev/null | sort)

    return 1
}

prepare_media_iso() {
    local expected_disks=""
    local disk=""
    local iso_path=""
    local mount_point=""

    [[ -n "$SELECTED_VERSION" ]] || { error "Select an Ansys version before preparing ISO media."; pause; return 1; }
    require_root_for_action "ISO mounting" || { pause; return 1; }

    expected_disks="${DISK_COUNTS[$SELECTED_VERSION]:-}"
    if [[ -z "$expected_disks" ]]; then
        error "No disk count is defined for version $SELECTED_VERSION."
        pause
        return 1
    fi

    cleanup_prepared_media
    create_work_dir

    for (( disk=1; disk<=expected_disks; disk+=1 )); do
        if ! iso_path="$(find_iso_for_disk "$disk")"; then
            error "Missing ISO for disk $disk of $expected_disks in $SOURCE_DIR."
            cleanup_prepared_media
            pause
            return 1
        fi

        mount_point="$WORK_DIR/disk$disk"
        mkdir -p "$mount_point"
        if ! run_cmd "Mounting ISO disk $disk" mount -o loop,ro "$iso_path" "$mount_point"; then
            cleanup_prepared_media
            pause
            return 1
        fi
        MOUNT_POINTS+=("$mount_point")

        if (( disk == 1 )); then
            MERGED_MEDIA_DIR="$mount_point"
        else
            MEDIA_EXTRA_ARGS+=("-media_dir${disk}" "$mount_point")
        fi
    done

    if [[ ! -f "$MERGED_MEDIA_DIR/INSTALL" ]]; then
        error "INSTALL script was not found in the mounted disk 1 media."
        cleanup_prepared_media
        pause
        return 1
    fi

    MEDIA_TYPE="iso"
    CURRENT_MEDIA_LABEL="ISO disk set for $SELECTED_VERSION"
    STATUS_MEDIA_PREPARED=1
    success "Prepared ISO media for $SELECTED_VERSION."
    pause
}

prepare_media_tgz() {
    local options=()
    local candidate_archives=()
    local choice=""
    local archive=""
    local extract_base=""
    local install_root=""
    local free_space=""
    local idx=""
    local archive_version=""

    [[ -n "$SELECTED_VERSION" ]] || warn "No version is currently selected. TGZ detection will rely on the archive filename."

    if (( ${#SCAN_TGZS[@]} == 0 )); then
        warn "No TGZ archives were found in $SOURCE_DIR."
        pause
        return 1
    fi

    cleanup_prepared_media

    for (( idx=0; idx<${#SCAN_TGZS[@]}; idx+=1 )); do
        archive="${SCAN_TGZS[idx]}"
        archive_version="${SCAN_TGZ_VERSIONS[idx]:-}"
        if [[ -n "$SELECTED_VERSION" && -n "$archive_version" && "$archive_version" != "$SELECTED_VERSION" ]]; then
            continue
        fi
        candidate_archives+=("$archive")
        if [[ -n "$archive_version" ]]; then
            options+=("$(basename "$archive") [$archive_version]")
        else
            options+=("$(basename "$archive") [version unknown]")
        fi
    done

    if (( ${#candidate_archives[@]} == 0 )); then
        warn "No TGZ archives match the selected version ${SELECTED_VERSION:-unknown}."
        pause
        return 1
    fi

    choice="$(prompt_choice "Select a single TGZ archive for this install pass:" "${options[@]}")"
    archive="${candidate_archives[$choice-1]}"

    extract_base="$(prompt_input "Extraction parent directory" "${TEMP_DIR_OVERRIDE:-/tmp}")"
    if [[ ! -d "$extract_base" ]]; then
        if (( DRY_RUN )); then
            info "[dry-run] mkdir -p $(print_command "$extract_base")"
        else
            mkdir -p "$extract_base"
        fi
    fi

    free_space="$(df_available_mb "$extract_base" 2>/dev/null || true)"
    if [[ -n "$free_space" ]] && (( free_space < MIN_TMP_SPACE_MB )); then
        warn "Available space at $extract_base is ${free_space} MB; recommended minimum is ${MIN_TMP_SPACE_MB} MB for extraction."
    fi

    WORK_DIR="$(mktemp -d "$extract_base/ansys_install_helper.XXXXXX")"
    EXTRACT_DIRS=("$WORK_DIR")

    if ! run_cmd "Extracting TGZ media" tar -xzf "$archive" -C "$WORK_DIR"; then
        cleanup_prepared_media
        pause
        return 1
    fi

    if ! install_root="$(find_install_root "$WORK_DIR")"; then
        error "Could not locate a valid INSTALL root in extracted archive $(basename "$archive")."
        cleanup_prepared_media
        pause
        return 1
    fi

    MERGED_MEDIA_DIR="$install_root"
    MEDIA_TYPE="tgz"
    CURRENT_MEDIA_LABEL="TGZ: $(basename "$archive")"
    STATUS_MEDIA_PREPARED=1
    success "Prepared TGZ media from $(basename "$archive")."
    pause
}

prepare_media() {
    local media_choice=""

    if [[ -z "$SOURCE_DIR" ]]; then
        warn "Select a source directory first."
        pause
        return 1
    fi

    scan_media
    if (( ${#SCAN_ISOS[@]} == 0 && ${#SCAN_TGZS[@]} == 0 )); then
        warn "No supported media files were found in $SOURCE_DIR."
        pause
        return 1
    fi

    if (( ${#SCAN_ISOS[@]} > 0 && ${#SCAN_TGZS[@]} > 0 )); then
        media_choice="$(prompt_choice "Choose media type for this install pass:" \
            "ISO disk set" \
            "Single TGZ archive")"
    elif (( ${#SCAN_ISOS[@]} > 0 )); then
        media_choice=1
    else
        media_choice=2
    fi

    case "$media_choice" in
        1) prepare_media_iso ;;
        2) prepare_media_tgz ;;
    esac
}

license_ini_path() {
    printf '%s/%s\n' "${INSTALL_DIR%/}" "$LICENSE_INI_RELATIVE"
}

install_err_path() {
    printf '%s/install.err\n' "${INSTALL_DIR%/}"
}

install_log_path() {
    printf '%s/install.log\n' "${INSTALL_DIR%/}"
}

archive_existing_installer_file() {
    local file_path="$1"
    local archive_path=""

    if [[ ! -e "$file_path" ]]; then
        return 0
    fi

    archive_path="${file_path}.old.$(date '+%Y%m%d_%H%M%S')"
    if run_cmd "Archiving $(basename "$file_path")" mv "$file_path" "$archive_path"; then
        info "Archived existing $(basename "$file_path") to $(basename "$archive_path")."
    fi
}

archive_install_artifacts() {
    archive_existing_installer_file "$(install_err_path)" || true
    archive_existing_installer_file "$(install_log_path)" || true
}

start_install_log_tail() {
    local log_path=""
    log_path="$(install_log_path)"

    INSTALL_LOG_TAIL_PID=""
    if (( DRY_RUN )); then
        return 0
    fi

    (
        local waited=0
        while (( waited < 7200 )); do
            if [[ -f "$log_path" ]]; then
                printf '\n[INFO] Streaming %s\n\n' "$log_path"
                exec tail -n +1 -f "$log_path"
            fi
            sleep 2
            waited=$((waited + 2))
        done
    ) &
    INSTALL_LOG_TAIL_PID=$!
}

stop_install_log_tail() {
    if [[ -n "$INSTALL_LOG_TAIL_PID" ]] && kill -0 "$INSTALL_LOG_TAIL_PID" 2>/dev/null; then
        kill "$INSTALL_LOG_TAIL_PID" 2>/dev/null || true
        wait "$INSTALL_LOG_TAIL_PID" 2>/dev/null || true
    fi
    INSTALL_LOG_TAIL_PID=""
}

check_install_errors() {
    local install_err_path=""
    install_err_path="$(install_err_path)"

    if [[ ! -e "$install_err_path" ]]; then
        success "No install.err file found under $INSTALL_DIR."
        return 0
    fi

    if [[ ! -s "$install_err_path" ]]; then
        success "install.err exists but is empty."
        return 0
    fi

    warn "Installer reported errors in $install_err_path:"
    separator
    sed -n '1,200p' "$install_err_path"
    separator
}

maybe_write_license_ini() {
    local ini_path=""
    local ini_dir=""

    if [[ -z "$LICENSE_HOSTNAME" ]]; then
        return 0
    fi

    ini_path="$(license_ini_path)"
    ini_dir="$(dirname "$ini_path")"

    if [[ ! -d "$ini_dir" ]]; then
        warn "License directory does not exist yet: $ini_dir"
        return 0
    fi

    if [[ -e "$ini_path" ]]; then
        info "License file already exists at $ini_path; leaving it unchanged."
        STATUS_LICENSE_DONE=1
        return 0
    fi

    if (( DRY_RUN )); then
        info "[dry-run] would write $ini_path with SERVER=1055@$LICENSE_HOSTNAME"
        STATUS_LICENSE_DONE=1
        return 0
    fi

    printf 'SERVER=1055@%s\n' "$LICENSE_HOSTNAME" >"$ini_path"
    success "Wrote license configuration to $ini_path."
    STATUS_LICENSE_DONE=1
}

configure_license() {
    local choice=""
    local hostname=""

    choice="$(prompt_choice "License configuration:" \
        "Set or update license hostname" \
        "Clear stored license hostname" \
        "Back")"

    case "$choice" in
        1)
            hostname="$(prompt_input "License server hostname" "$LICENSE_HOSTNAME")"
            if [[ -z "$hostname" ]]; then
                warn "License hostname cannot be empty."
            else
                LICENSE_HOSTNAME="$hostname"
                STATUS_LICENSE_DONE=0
                success "Stored license hostname: $LICENSE_HOSTNAME"
                if (( STATUS_INSTALL_DONE == 1 )); then
                    maybe_write_license_ini
                fi
            fi
            ;;
        2)
            LICENSE_HOSTNAME=""
            STATUS_LICENSE_DONE=0
            success "Cleared stored license hostname."
            ;;
        3)
            ;;
    esac

    pause
}

installer_mode_display() {
    case "$INSTALL_MODE" in
        products) printf 'Products' ;;
        license_manager) printf 'License Manager' ;;
        *) printf '%s' "$INSTALL_MODE" ;;
    esac
}

product_selection_display() {
    if [[ "$INSTALL_MODE" == "license_manager" ]]; then
        printf 'N/A'
    elif [[ "$PRODUCT_SELECTION_MODE" == "all" ]]; then
        printf 'All Products'
    elif (( ${#SELECTED_PRODUCT_KEYS[@]} > 0 )); then
        printf 'Expert (%d selected)' "${#SELECTED_PRODUCT_KEYS[@]}"
    else
        printf 'Expert (none selected)'
    fi
}

menu_install_config_display() {
    if [[ "$INSTALL_MODE" == "license_manager" ]]; then
        printf 'LicMgr / N/A'
    elif [[ "$PRODUCT_SELECTION_MODE" == "all" ]]; then
        printf 'Products / All'
    else
        printf 'Products / Expert'
    fi
}

configure_install_options() {
    local choice=""
    local new_dir=""
    local temp_dir=""

    while true; do
        header "Install Configuration"
        printf 'Install Directory: %s\n' "$INSTALL_DIR"
        printf 'Install Mode: %s\n' "$(installer_mode_display)"
        printf 'Product Selection: %s\n' "$(product_selection_display)"
        printf 'Create %s symlink: %s\n' "$SYMLINK_PATH" "$([[ "$CREATE_SYMLINK" -eq 1 ]] && printf 'Yes' || printf 'No')"
        printf 'Installer -nochecks: %s\n' "$([[ "$INSTALLER_NOCHECKS" -eq 1 ]] && printf 'Enabled' || printf 'Disabled')"
        printf 'Installer temp dir override: %s\n\n' "${TEMP_DIR_OVERRIDE:-Not set}"

        choice="$(prompt_choice "Change install options:" \
            "Change install directory" \
            "Change install mode" \
            "Change product selection" \
            "Toggle symlink creation" \
            "Toggle -nochecks" \
            "Set or clear temp dir override" \
            "Back")"

        case "$choice" in
            1)
                new_dir="$(prompt_input "Install directory" "$INSTALL_DIR")"
                if [[ -n "$new_dir" ]]; then
                    INSTALL_DIR="$new_dir"
                    check_disk_space
                    STATUS_INSTALL_CONFIGURED=1
                fi
                ;;
            2)
                case "$(prompt_choice "Select install mode:" "Products" "License Manager")" in
                    1) INSTALL_MODE="products" ;;
                    2) INSTALL_MODE="license_manager" ;;
                esac
                STATUS_INSTALL_CONFIGURED=1
                ;;
            3)
                select_products
                ;;
            4)
                if (( CREATE_SYMLINK == 1 )); then CREATE_SYMLINK=0; else CREATE_SYMLINK=1; fi
                STATUS_INSTALL_CONFIGURED=1
                ;;
            5)
                if (( INSTALLER_NOCHECKS == 1 )); then INSTALLER_NOCHECKS=0; else INSTALLER_NOCHECKS=1; fi
                STATUS_INSTALL_CONFIGURED=1
                ;;
            6)
                temp_dir="$(prompt_input "Temp directory override (leave blank to clear)" "$TEMP_DIR_OVERRIDE")"
                if [[ -n "$temp_dir" ]]; then
                    TEMP_DIR_OVERRIDE="$temp_dir"
                else
                    TEMP_DIR_OVERRIDE=""
                fi
                STATUS_INSTALL_CONFIGURED=1
                ;;
            7)
                pause
                return 0
                ;;
        esac
    done
}

build_install_command() {
    local -n output_ref=$1
    local product_flags=()

    output_ref=("$MERGED_MEDIA_DIR/INSTALL" -silent -install_dir "$INSTALL_DIR")

    if [[ "$INSTALL_MODE" == "license_manager" ]]; then
        output_ref+=(-lm)
    else
        build_product_flags product_flags
        if (( ${#product_flags[@]} > 0 )); then
            output_ref+=("${product_flags[@]}")
        fi
    fi

    if (( ${#MEDIA_EXTRA_ARGS[@]} > 0 )); then
        output_ref+=("${MEDIA_EXTRA_ARGS[@]}")
    fi
    if (( INSTALLER_NOCHECKS == 1 )); then
        output_ref+=(-nochecks)
    fi
    if [[ -n "$TEMP_DIR_OVERRIDE" ]]; then
        output_ref+=(-usetempdir "$TEMP_DIR_OVERRIDE")
    fi
}

parent_writable() {
    local path="$1"
    local parent="${path%/*}"
    [[ -n "$parent" ]] || parent="/"
    [[ -d "$parent" ]] && [[ -w "$parent" ]]
}

run_installation() {
    local install_cmd=()
    local rendered=""

    if (( STATUS_MEDIA_PREPARED == 0 )) || [[ -z "$MERGED_MEDIA_DIR" ]]; then
        warn "Prepare media before running the installer."
        pause
        return 1
    fi

    if [[ ! -f "$MERGED_MEDIA_DIR/INSTALL" ]]; then
        error "INSTALL script was not found in prepared media directory $MERGED_MEDIA_DIR."
        pause
        return 1
    fi

    if [[ "$INSTALL_MODE" == "products" ]] && [[ "$PRODUCT_SELECTION_MODE" == "expert" ]] && (( ${#SELECTED_PRODUCT_KEYS[@]} == 0 )); then
        warn "Expert product mode is enabled but no products are selected."
        pause
        return 1
    fi

    if (( STATUS_PREREQS_DONE == 0 )); then
        warn "Prerequisites have not been marked complete. The installer may fail if dependencies are missing."
        if ! prompt_yn "Continue anyway?" n; then
            return 0
        fi
    fi

    if [[ ! -w "$INSTALL_DIR" ]] && ! parent_writable "$INSTALL_DIR" && (( IS_ROOT == 0 )); then
        warn "Install directory $INSTALL_DIR is not writable by the current user."
    fi

    archive_install_artifacts
    build_install_command install_cmd
    rendered="$(print_command "${install_cmd[@]}")"

    header "Installer Command"
    printf '%s\n\n' "$rendered"
    if ! prompt_yn "Run this installer command?" y; then
        warn "Installation cancelled."
        pause
        return 0
    fi

    info "Starting installer. install.log will stream here when the file appears."
    start_install_log_tail
    if run_cmd "Running Ansys installer" "${install_cmd[@]}"; then
        stop_install_log_tail
        STATUS_INSTALL_DONE=1
        success "Installer run completed."
        if (( CREATE_SYMLINK == 1 )); then
            if (( IS_ROOT == 1 )); then
                if run_cmd "Updating symlink $SYMLINK_PATH" ln -sfn "$INSTALL_DIR" "$SYMLINK_PATH"; then
                    success "Updated $SYMLINK_PATH -> $INSTALL_DIR"
                fi
            else
                warn "Skipping symlink creation because root privileges are required for $SYMLINK_PATH."
            fi
        fi
        check_install_errors
        maybe_write_license_ini
    else
        stop_install_log_tail
        warn "Installer returned a failure status."
        check_install_errors || true
    fi

    pause
}

show_main_menu() {
    header "$SCRIPT_NAME"
    status_line "1. Select Ansys Version" "${SELECTED_VERSION:-Not set}" "$([[ $STATUS_VERSION_SET -eq 1 ]] && printf 'DONE' || printf 'PENDING')"
    status_line "2. Select Source" "${SOURCE_DIR:-Not set}" "$([[ $STATUS_SOURCE_SET -eq 1 ]] && printf 'DONE' || printf 'PENDING')"
    status_line "3. Install Prerequisites" "$(profile_display_name "$PKG_PROFILE")" "$([[ $STATUS_PREREQS_DONE -eq 1 ]] && printf 'DONE' || printf 'PENDING')"
    status_line "4. Install Goodies" "$([[ $STATUS_GOODIES_DONE -eq 1 ]] && printf 'Installed' || printf 'Optional')" "$([[ $STATUS_GOODIES_DONE -eq 1 ]] && printf 'DONE' || printf 'PENDING')"
    status_line "5. Prepare Media" "${CURRENT_MEDIA_LABEL:-Not prepared}" "$([[ $STATUS_MEDIA_PREPARED -eq 1 ]] && printf 'READY' || printf 'PENDING')"
    status_line "6. Configure Install" "$(menu_install_config_display)" "$([[ $STATUS_INSTALL_CONFIGURED -eq 1 ]] && printf 'DONE' || printf 'DEFAULTS')"
    status_line "7. Configure License" "${LICENSE_HOSTNAME:-Not set}" "$([[ $STATUS_LICENSE_DONE -eq 1 ]] && printf 'DONE' || printf 'PENDING')"
    status_line "8. Run Installation" "${INSTALL_DIR}" "$([[ $STATUS_INSTALL_DONE -eq 1 ]] && printf 'DONE' || printf 'PENDING')"
    status_line "9. Check install.err" "install.err" "INFO"
    status_line "10. Unmount and Cleanup" "Unmount temp media" "ACTION"
    status_line "0. Exit" "Leave helper" "ACTION"
    separator
    printf 'OS: %s %s | Family: %s | Pkg Mgr: %s | Root: %s\n' \
        "${OS_ID:-unknown}" "${OS_VERSION_ID:-unknown}" "${OS_FAMILY:-unknown}" "${PKG_MGR:-unknown}" "$([[ $IS_ROOT -eq 1 ]] && printf 'Yes' || printf 'No')"
}

select_version() {
    local choice=""
    choice="$(prompt_choice "Select Ansys version:" "${SUPPORTED_VERSIONS[@]}")"
    set_selected_version "${SUPPORTED_VERSIONS[choice-1]}" || true
    pause
}

show_usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --source <path>        Set source directory or media file path
  --version <ver>        Set Ansys version (for example: 2025R2)
  --install-dir <path>   Set install directory
  --dry-run              Print commands without executing them
  --no-color             Disable colored output
  --nochecks             Pass -nochecks to the installer
  --temp-dir <path>      Pass -usetempdir <path> to the installer and use it for work dirs
  --help                 Show this help text
EOF
}

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --source)
                SOURCE_DIR="$2"
                STATUS_SOURCE_SET=1
                shift 2
                ;;
            --version)
                set_selected_version "$2"
                shift 2
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                STATUS_INSTALL_CONFIGURED=1
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --no-color)
                NO_COLOR=1
                shift
                ;;
            --nochecks)
                INSTALLER_NOCHECKS=1
                STATUS_INSTALL_CONFIGURED=1
                shift
                ;;
            --temp-dir)
                TEMP_DIR_OVERRIDE="$2"
                STATUS_INSTALL_CONFIGURED=1
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

trap_handler() {
    stop_install_log_tail || true
    cleanup_prepared_media || true
}

main_menu_loop() {
    local choice=""
    while true; do
        clear 2>/dev/null || true
        show_main_menu
        read -r -p "Select option: " choice
        case "$choice" in
            1) select_version ;;
            2) select_source_dir ;;
            3) install_prerequisites ;;
            4) install_goodies ;;
            5) prepare_media ;;
            6) configure_install_options ;;
            7) configure_license ;;
            8) run_installation ;;
            9) check_install_errors ; pause ;;
            10) cleanup_prepared_media; success "Cleanup complete."; pause ;;
            0) return 0 ;;
            *) warn "Unknown menu option."; pause ;;
        esac
    done
}

main() {
    require_bash_version
    parse_args "$@"
    init_colors
    banner
    ensure_log_file
    log "Session started"
    load_package_arrays
    detect_os || true
    check_root
    check_disk_space
    trap trap_handler EXIT INT TERM

    if [[ -n "$SOURCE_DIR" ]]; then
        if [[ -d "$SOURCE_DIR" ]]; then
            scan_media
            if [[ -z "$SELECTED_VERSION" ]]; then
                local detected_version=""
                detected_version="$(detect_version_from_files "$SOURCE_DIR" || true)"
                if [[ -n "$detected_version" ]]; then
                    set_selected_version "$detected_version" || true
                fi
            fi
        elif [[ -f "$SOURCE_DIR" ]]; then
            scan_media || true
            if [[ -z "$SELECTED_VERSION" ]]; then
                local detected_version=""
                detected_version="$(detect_version_from_name "$(basename "$SOURCE_DIR")" || true)"
                if [[ -n "$detected_version" ]]; then
                    set_selected_version "$detected_version" || true
                fi
            fi
        else
            warn "Provided source path does not exist: $SOURCE_DIR"
        fi
    fi

    main_menu_loop
}

main "$@"
