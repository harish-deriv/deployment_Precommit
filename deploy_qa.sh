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

PRE_COMMIT_URL="https://raw.githubusercontent.com/security-binary/deployment_Precommit/main/pre-commit"
curl -sSL "$PRE_COMMIT_URL" > /opt/skel/.git/hooks/pre-commit
chmod +x /opt/skel/.git/hooks/pre-commit


chmod +x /opt/skel/.git/hooks/pre-commit
sudo -u nobody git config --global core.hooksPath /home/nobody/.git/hooks/
sudo -u nobody mkdir -p /home/nobody/.git/hooks
sudo -u nobody touch /home/nobody/.git/hooks/pre-commit
ln -sf /opt/skel/.git/hooks/pre-commit /home/nobody/.git/hooks/pre-commit
