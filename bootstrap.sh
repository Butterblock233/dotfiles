#!/bin/bash

# 设置 -e 选项，表示如果任何命令失败，脚本将立即退出
set -e

# --- 1. 检查 GPG 密钥是否存在 ---
echo "--- 正在检查 GPG 密钥的存在 ---"
# ***重要提示***：请将 'YOUR_GPG_KEY_ID' 替换为您的实际 GPG 密钥 ID
GPG_KEY_ID="5443D40CFB826567374D73B8FD13251EBE42D48D"

if ! gpg --list-secret-keys "${GPG_KEY_ID}" &> /dev/null; then
    echo "错误：未找到 GPG 密钥 '${GPG_KEY_ID}'。请确保您的 GPG 密钥已导入并可用。"
    echo "如果您不确定 GPG 密钥 ID，可以尝试 'gpg --list-secret-keys' 来查看您的密钥。"
    exit 1
fi
echo "GPG 密钥 '${GPG_KEY_ID}' 已找到，可以进行解密操作。"

# --- 2. 检查并解密 SSH 密钥 ---
SSH_KEY_PATH="$HOME/.ssh/bbk_main"
# ***重要提示***：请确认此路径与您 Chezmoi 仓库中加密 SSH 密钥的实际路径一致
ENCRYPTED_SSH_KEY_PATH="$HOME/.local/share/chezmoi/dot_ssh/encrypted_private_bbk_main.asc"

echo "--- 正在检查 SSH 密钥 ($SSH_KEY_PATH) ---"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "SSH 密钥 '$SSH_KEY_PATH' 不存在，正在尝试从 Chezmoi 解密..."

    if [ ! -f "$ENCRYPTED_SSH_KEY_PATH" ]; then
        echo "错误：加密的 SSH 密钥文件 '$ENCRYPTED_SSH_KEY_PATH' 未找到。"
        echo "请确保您的 Chezmoi 仓库中包含此文件，并且它已通过 chezmoi init 被同步到本地。"
        exit 1
    fi

    # 确保 ~/.ssh 目录存在并有正确的权限
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # 执行解密操作
    # GPG 会提示您输入密钥密码
    echo "请根据提示输入您的 GPG 密钥密码以解密 SSH 密钥..."
    if gpg --decrypt "$ENCRYPTED_SSH_KEY_PATH" > "$SSH_KEY_PATH"; then
        chmod 600 "$SSH_KEY_PATH"
        echo "SSH 密钥已成功解密并放置到 '$SSH_KEY_PATH'。"
    else
        echo "错误：SSH 密钥解密失败。请检查 GPG 环境、加密文件或您输入的密码。"
        # 删除可能已创建的不完整文件
        rm -f "$SSH_KEY_PATH"
        exit 1
    fi
else
    echo "SSH 密钥 '$SSH_KEY_PATH' 已存在，跳过解密步骤。"
fi

# --- 2.5. 替换 Git 远程 URL 为 SSH ---
echo "--- 正在替换 Git 远程 URL 为 SSH ---"
# ***重要提示***：请将 'https://github.com/your-username/your-dotfiles.git' 替换为您的 HTTPS 仓库地址
# ***重要提示***：请将 'git@github.com:your-username/your-dotfiles.git' 替换为您的 SSH 仓库地址
HTTPS_REPO_URL="https://github.com/Butterblock233/dotfiles.git"
SSH_REPO_URL="git@github.com:Butterblock233/dotfiles.git"

CURRENT_REMOTE_URL=$(git -C "$HOME/.local/share/chezmoi" remote get-url origin)

if [[ "$CURRENT_REMOTE_URL" == "$HTTPS_REPO_URL" ]]; then
    echo "当前远程 URL 为 HTTPS，正在切换到 SSH URL..."
    git -C "$HOME/.local/share/chezmoi" remote set-url origin "$SSH_REPO_URL" || { echo "错误：替换 Git 远程 URL 失败！" ; exit 1; }
    echo "Git 远程 URL 已成功切换到 '$SSH_REPO_URL'。"
else
    echo "当前远程 URL 已是 '$CURRENT_REMOTE_URL'，无需切换。"
fi

# --- 3. 应用 Chezmoi 配置 ---
echo "--- 正在应用 Chezmoi 配置 ---"
# 因为脚本放在 Chezmoi 仓库中，所以不需要执行 'chezmoi init' 步骤。
echo "正在执行 'chezmoi apply -v'..."
chezmoi apply -v

echo "--- Chezmoi 设置完成！ ---"
