if [ "$(uname -m)" == "x86_64" ]; then
    ARCH="amd64"
elif [ "$(uname -m)" == "aarch64" ]; then
    ARCH="arm64"
else
    echo "Error: Unsupported architecture $(uname -m)."
    exit 1
fi

if ! command -v trufflehog &> /dev/null; then
    echo "Downloading Trufflehog..."
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
LOGPATH="/tmp/pre-commit-deployment.log"
function generate_precommit_file () {
    echo "[2] Generating Pre-Commit File..." >> $LOGPATH
    sudo echo '#!/bin/bash

    function get_precommit_hook(){
        pre_commit_hook=$(curl -fsSL "$1" 2>&1)
        if [ $? -ne 0 ]; then
            echo "Please check your internet and then run again. add --no-verify flag to git commit if this error persists"
            exit 1
        else
            echo "$pre_commit_hook" | /bin/bash
        fi
    }

    get_precommit_hook https://gist.githubusercontent.com/security-binary/29086ac0a834564da2e0da64dd05c728/raw/07344d69825609ad678613d90e6d0ac1a40595eb/pre-commit.sh' > $PRECOMMIT_HOOK_PATH
    echo "[2.1] Pre-Commit File generated under $PRECOMMIT_HOOK_PATH" >> $LOGPATH;
    sudo chmod +x /opt/skel/.git/hooks/pre-commit
}

generate_precommit_file
sudo -u nobody git config --global core.hooksPath /home/nobody/.git/hooks/
sudo -u nobody mkdir -p /home/nobody/.git/hooks
sudo -u nobody touch /home/nobody/.git/hooks/pre-commit
ln -sf /opt/skel/.git/hooks/pre-commit /home/nobody/.git/hooks/pre-commit
