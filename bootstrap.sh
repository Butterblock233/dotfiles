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

# --- 新增步骤：启动 SSH 代理并加载 SSH 密钥 ---
echo "--- 正在启动 SSH 代理并加载 SSH 密钥 ---"

# 检查 ssh-agent 是否已运行，如果没有则启动
# 'ssh-agent -s' 在 bash 中输出 shell 命令，所以用 eval 执行
# 如果 pgrep 命令不存在，它会失败，但 eval 仍会尝试运行 ssh-agent
# 更好的方法是检查SSH_AGENT_PID和SSH_AUTH_SOCK环境变量
if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
    echo "启动 ssh-agent..."
    # 使用 eval 执行 ssh-agent -s 的输出，以设置必要的环境变量
    eval "$(ssh-agent -s)" || { echo "错误：无法启动 ssh-agent！" ; exit 1; }
else
    echo "ssh-agent 已经运行。"
fi

# 检查密钥是否已添加到代理，如果没有则添加
# ssh-add -l 列出已加载的密钥
# ssh-keygen -lf "$SSH_KEY_PATH" | awk '{print $2}' 获取密钥指纹（hash）
# grep -q 用于静默检查，如果找到则返回 0
if ! ssh-add -l | grep -q "$(ssh-keygen -lf "$SSH_KEY_PATH" | awk '{print $2}')"; then
    echo "添加 SSH 密钥 '$SSH_KEY_PATH' 到 ssh-agent..."
    # ssh-add 会提示您输入 SSH 密钥的密码
    ssh-add "$SSH_KEY_PATH" || { echo "错误：无法将 SSH 密钥添加到 ssh-agent！" ; exit 1; }
else
    echo "SSH 密钥 '$SSH_KEY_PATH' 已经加载到 ssh-agent。"
fi

# --- 2.5. 替换 Git 远程 URL 为 SSH ---
echo "--- 正在替换 Git 远程 URL 为 SSH ---"

CHEZMOI_REPO="$HOME/.local/share/chezmoi"

if [ ! -d "$CHEZMOI_REPO" ]; then
    echo "错误：Chezmoi 源码目录 '$CHEZMOI_REPO' 不存在。请确保您已手动克隆您的仓库。"
    exit 1
fi

# 获取当前远程 URL
CURRENT_REMOTE_URL=$(git -C "$CHEZMOI_REPO" remote get-url origin | xargs)

# 使用 Python 脚本处理 URL 转换逻辑（确保 convert_url_to_ssh.py 在 PATH 或当前目录中）
SCRIPT_DIR="$(dirname "$0")"
CONVERT_SCRIPT="$SCRIPT_DIR/convert_url_to_ssh.py"

if [ ! -f "$CONVERT_SCRIPT" ]; then
    echo "错误：找不到 Python 脚本 '$CONVERT_SCRIPT'。"
    exit 1
fi

SSH_REPO_URL=$(python3 "$CONVERT_SCRIPT" "$CURRENT_REMOTE_URL")

if [ -n "$SSH_REPO_URL" ]; then
    echo "检测到 HTTPS URL，正在切换为 SSH：$SSH_REPO_URL"
    git -C "$CHEZMOI_REPO" remote set-url origin "$SSH_REPO_URL" || { echo "错误：替换 Git 远程 URL 失败！" ; exit 1; }
    echo "Git 远程 URL 已成功切换为 SSH：$SSH_REPO_URL"
else
    echo "当前远程 URL 不符合 HTTPS GitHub 模式或已经是 SSH，无需修改：$CURRENT_REMOTE_URL"
fi


# --- 3. 应用 Chezmoi 配置 ---
echo "--- 正在应用 Chezmoi 配置 ---"
# 因为脚本放在 Chezmoi 仓库中，所以不需要执行 'chezmoi init' 步骤。
echo "正在执行 'chezmoi apply -R'..."
chezmoi apply -R

echo "--- Chezmoi 设置完成！ ---"
