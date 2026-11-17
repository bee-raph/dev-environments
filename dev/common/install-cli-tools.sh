#!/usr/bin/env bash
set -euo pipefail

case "$(dpkg --print-architecture)" in
    amd64) gh_arch=amd64; aws_arch=x86_64; google_arch=x86_64 ;;
    arm64) gh_arch=arm64; aws_arch=aarch64; google_arch=arm ;;
    *) echo 'Shared CLI tools require Linux amd64 or arm64.' >&2; exit 1 ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
download() { curl --retry 3 -fsSL "$1" -o "$2"; }

# Build the current stable Git instead of using the distro's older release.
git_version=$(git ls-remote --tags --refs https://github.com/git/git.git 'v[0-9]*' |
    awk '{sub(/^refs\/tags\/v/, "", $2); if ($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) print $2}' |
    sort -V | tail -n 1)
: "${git_version:?No stable Git release found}"
download "https://www.kernel.org/pub/software/scm/git/git-${git_version}.tar.gz" git.tar.gz
tar -xzf git.tar.gz
apt-get update
apt-get install -y --no-install-recommends gettext libcurl4-openssl-dev libexpat1-dev libpcre2-dev libssl-dev zlib1g-dev
rm -rf /var/lib/apt/lists/*
# Cap parallel jobs on Docker Desktop, which shares memory across builds.
make -C "git-${git_version}" -j4 prefix=/usr/local sysconfdir=/etc NO_RUST=YesPlease NO_TCLTK=YesPlease USE_LIBPCRE2=YesPlease all >/dev/null
make -C "git-${git_version}" prefix=/usr/local sysconfdir=/etc NO_RUST=YesPlease NO_TCLTK=YesPlease USE_LIBPCRE2=YesPlease install >/dev/null

download https://api.github.com/repos/cli/cli/releases/latest gh-release.json
gh_version=$(jq -er '.tag_name | sub("^v"; "")' gh-release.json)
gh_archive="gh_${gh_version}_linux_${gh_arch}.tar.gz"
download "https://github.com/cli/cli/releases/download/v${gh_version}/${gh_archive}" "$gh_archive"
download "https://github.com/cli/cli/releases/download/v${gh_version}/gh_${gh_version}_checksums.txt" gh-checksums.txt
awk -v asset="$gh_archive" '$2 == asset {print; found=1} END {if (!found) exit 1}' gh-checksums.txt | sha256sum -c -
tar -xzf "$gh_archive"
install -m 0755 "gh_${gh_version}_linux_${gh_arch}/bin/gh" /usr/local/bin/gh

download "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" aws.zip
unzip -q aws.zip
./aws/install --install-dir /opt/aws-cli --bin-dir /usr/local/bin

download "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-${google_arch}.tar.gz" gcloud.tar.gz
tar -xzf gcloud.tar.gz -C /opt
for command in gcloud gsutil bq; do
    ln -s "/opt/google-cloud-sdk/bin/$command" "/usr/local/bin/$command"
done

# Keep Azure CLI dependencies out of system Python and project virtualenvs.
export UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin
export UV_PYTHON_INSTALL_DIR=/opt/uv-python UV_CACHE_DIR="$tmp/uv-cache"
uv tool install --managed-python --python 3.13 azure-cli
