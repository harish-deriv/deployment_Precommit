#!/bin/bash

if [ "$(uname -m)" == "x86_64" ]; then
    ARCH="amd64"
elif [ "$(uname -m)" == "aarch64" ]; then
    ARCH="arm64"
else
    echo "Error: Unsupported architecture $(uname -m)."
    exit 1
fi

LOGPATH="/tmp/pre-commit-deployment.log"
if ! command -v trufflehog &> /dev/null; then
    echo "[1] Downloading Trufflehog..." >> $LOGPATH
    wget -q "https://github.com/trufflesecurity/trufflehog/releases/download/v3.34.0/trufflehog_3.34.0_linux_$ARCH.tar.gz" -O trufflehog.tar.gz
    tar -xzf trufflehog.tar.gz
    chmod +x trufflehog
    sudo mv trufflehog /usr/local/bin/
    rm trufflehog.tar.gz
fi

if [ ! -d /opt/skel/.git/hooks ]; then
  mkdir -p /opt/skel/.git/hooks
fi

PRECOMMIT_HOOK_PATH="/opt/skel/.git/hooks/pre-commit"
function generate_precommit_file () {
    echo "[2] Generating Pre-Commit File..." >> $LOGPATH
    sudo echo '# Use `filesysytem` if the git repo does not have any commits i.e its a new git repo.
if git log -1 > /dev/null 2>&1; then
    trufflehog git file://. --no-update --since-commit HEAD --fail > /tmp/trufflehog_output_$(whoami) 2>&1
    trufflehog_exit_code=$?
    echo $trufflehog_exit_code > /tmp/trufflehog_exit_code_$(whoami)
else
    trufflehog filesystem . --no-update --fail > /tmp/trufflehog_output_$(whoami) 2>&1
    trufflehog_exit_code=$?
    echo $trufflehog_exit_code > /tmp/trufflehog_exit_code_$(whoami)
fi

# Only display results to stdout if trufflehog found something.
if [ $trufflehog_exit_code -eq 183 ]; then
    cat /tmp/trufflehog_output_$(whoami)
    echo "TruffleHog found secrets. Aborting commit. use --no-verify to bypass it"
    exit $trufflehog_exit_code
fi' > $PRECOMMIT_HOOK_PATH
    echo "[2.1] Pre-Commit File generated under $PRECOMMIT_HOOK_PATH" >> $LOGPATH;
    sudo chmod +x /opt/skel/.git/hooks/pre-commit
}

generate_precommit_file
sudo -u nobody git config --global core.hooksPath /home/nobody/.git/hooks/
sudo -u nobody mkdir -p /home/nobody/.git/hooks
sudo -u nobody touch /home/nobody/.git/hooks/pre-commit
ln -sf /opt/skel/.git/hooks/pre-commit /home/nobody/.git/hooks/pre-commit
