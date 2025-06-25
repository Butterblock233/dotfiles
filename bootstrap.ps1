# Requires PowerShell 7 or later due to features like `~` for home directory and improved cross-platform compatibility.
# To check your PowerShell version, run: $PSVersionTable.PSVersion.Major

# Set error action preference to stop on any non-terminating error. This mimics 'set -e' in bash.
$ErrorActionPreference = 'Stop'

# --- 1. Check for GPG key existence ---
Write-Host "--- 正在检查 GPG 密钥的存在 ---"

# IMPORTANT: Replace 'YOUR_GPG_KEY_ID' with your actual GPG key ID
$GpgKeyId = "5443D40CFB826567374D73B8FD13251EBE42D48D"

try {
    # Attempt to list secret keys. Output is redirected to $null to suppress it.
    # $LASTEXITCODE is used to check the success of the external command.
    gpg --list-secret-keys $GpgKeyId | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "未找到 GPG 密钥 '$GpgKeyId'。请确保您的 GPG 密钥已导入并可用。您可以尝试 'gpg --list-secret-keys' 来查看您的密钥。"
    }
    Write-Host "GPG 密钥 '$GpgKeyId' 已找到，可以进行解密操作。"
}
catch {
    Write-Host "错误：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# --- 2. Check and decrypt SSH key ---
# IMPORTANT: Confirm this path matches the actual path of your encrypted SSH key in your Chezmoi repo
$SshKeyPath = Join-Path $HOME ".ssh\bbk_main"
$EncryptedSshKeyPath = Join-Path $HOME ".local\share\chezmoi\dot_ssh\encrypted_private_bbk_main.asc"

Write-Host "--- 正在检查 SSH 密钥 ($SshKeyPath) ---"
if (-not (Test-Path -Path $SshKeyPath -PathType Leaf)) { # Check if file does not exist
    Write-Host "SSH 密钥 '$SshKeyPath' 不存在，正在尝试从 Chezmoi 解密..."

    if (-not (Test-Path -Path $EncryptedSshKeyPath -PathType Leaf)) {
        Write-Host "错误：加密的 SSH 密钥文件 '$EncryptedSshKeyPath' 未找到。" -ForegroundColor Red
        Write-Host "请确保您的 Chezmoi 仓库中包含此文件，并且它已通过 chezmoi init 被同步到本地。" -ForegroundColor Red
        exit 1
    }

    # Ensure ~/.ssh directory exists
    $SshDirPath = Join-Path $HOME ".ssh"
    if (-not (Test-Path -Path $SshDirPath -PathType Container)) {
        Write-Host "正在创建 .ssh 目录: $SshDirPath"
        New-Item -ItemType Directory -Path $SshDirPath -Force | Out-Null
    }
    # For Windows, directory permissions for .ssh are typically managed implicitly or less strictly by SSH clients.
    # We will focus on key file permissions.

    # Perform decryption
    # GPG will prompt you for the key passphrase
    Write-Host "请根据提示输入您的 GPG 密钥密码以解密 SSH 密钥..."
    try {
        # Decrypting and piping to Set-Content with -Encoding Byte for raw binary output
        gpg --decrypt $EncryptedSshKeyPath | Set-Content -Path $SshKeyPath -Encoding Byte -Force # -Force overwrites if exists

        # Set permissions for the SSH key on Windows using icacls
        # This command ensures only the current user has read access (R)
        # /inheritance:r removes inherited permissions from parent folders
        # /grant:r "$env:USERNAME:(R)" grants read permission to the current user
        # This is the Windows equivalent of chmod 600 for the key file.
        icacls "$SshKeyPath" /inheritance:r /grant:r "$env:USERNAME:(R)"
        if ($LASTEXITCODE -ne 0) {
            throw "未能使用 icacls 设置 SSH 密钥权限。退出代码: $LASTEXITCODE"
        }

        Write-Host "SSH 密钥已成功解密并放置到 '$SshKeyPath'。"
    }
    catch {
        Write-Host "错误：SSH 密钥解密失败。请检查您的 GPG 环境、加密文件或您输入的密码。$($_.Exception.Message)" -ForegroundColor Red
        # Delete potentially incomplete file
        Remove-Item -Path $SshKeyPath -ErrorAction SilentlyContinue
        exit 1
    }
}
else {
    Write-Host "SSH 密钥 '$SshKeyPath' 已存在，跳过解密步骤。"
}
# ---

# --- 新增步骤：启动 SSH 代理并加载 SSH 密钥 ---
Write-Host "--- 正在启动 SSH 代理并加载 SSH 密钥 ---"

# 检查 SSH_AUTH_SOCK 环境变量是否存在并且指向一个有效的文件
# 这样可以判断 ssh-agent 是否已经运行并设置了环境
if (-not $env:SSH_AUTH_SOCK -or -not (Test-Path -Path $env:SSH_AUTH_SOCK -PathType Leaf -ErrorAction SilentlyContinue)) {
    Write-Host "启动 ssh-agent..."
    try {
        # Capture the output of ssh-agent and parse environment variables
        # ssh-agent.exe outputs environment variables like SSH_AUTH_SOCK=/tmp/...; export SSH_AUTH_SOCK;
        $agentOutput = (ssh-agent.exe) -split "`n"
        foreach ($line in $agentOutput) {
            if ($line -match '^SSH_AUTH_SOCK=(.*?);') {
                $env:SSH_AUTH_SOCK = $matches[1]
            } elseif ($line -match '^SSH_AGENT_PID=(\d+);') {
                $env:SSH_AGENT_PID = [int]$matches[1]
            }
        }
        if (-not $env:SSH_AUTH_SOCK -or -not $env:SSH_AGENT_PID) {
            throw "未能启动 ssh-agent 或解析其输出。请确保 ssh-agent.exe 可用且正常工作。"
        }
        Write-Host "ssh-agent 已启动，PID: $($env:SSH_AGENT_PID)"
    }
    catch {
        Write-Host "错误：无法启动 ssh-agent！$($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ssh-agent 已经运行。"
}

# 获取 SSH 密钥的指纹用于检查密钥是否已加载
# ssh-keygen.exe -Lf "$SshKeyPath" 输出指纹信息
try {
    $KeyFingerprint = (ssh-keygen.exe -Lf "$SshKeyPath" | Select-Object -Last 1).Trim()
    if (-not $KeyFingerprint) {
        throw "未能获取 SSH 密钥 '$SshKeyPath' 的指纹。"
    }
} catch {
    Write-Host "错误：获取 SSH 密钥指纹失败。请确保 ssh-keygen.exe 可用且密钥文件有效。$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 检查密钥是否已添加到代理，如果没有则添加
# ssh-add -l 列出已加载的密钥
# -like "*$KeyFingerprint*" 用于检查列表中是否包含此密钥的指纹
if (-not ((ssh-add.exe -l) -like "*$KeyFingerprint*")) {
    Write-Host "添加 SSH 密钥 '$SshKeyPath' 到 ssh-agent..."
    # ssh-add 会提示您输入 SSH 密钥的密码
    ssh-add.exe "$SshKeyPath"
    if ($LASTEXITCODE -ne 0) {
        throw "未能将 SSH 密钥添加到 ssh-agent！退出代码: $LASTEXITCODE。请检查您的 SSH 密钥密码。"
    }
    Write-Host "SSH 密钥 '$SshKeyPath' 已成功加载到 ssh-agent。"
} else {
    Write-Host "SSH 密钥 '$SshKeyPath' 已经加载到 ssh-agent。"
}

# ---


# --- 2.5. Replace Git remote URL to SSH ---
Write-Host "--- 正在替换 Git 远程 URL 为 SSH ---"
# IMPORTANT: Replace with your actual HTTPS and SSH repository URLs
$HttpsRepoUrl = "https://github.com/Butterblock233/dotfiles.git"
$SshRepoUrl = "git@github.com:Butterblock233/dotfiles.git"

$ChezmoiSourceDir = Join-Path $HOME ".local\share\chezmoi"

try {
    # Get current remote URL. Trim() is important to remove any trailing whitespace.
    $CurrentRemoteUrl = (git -C "$ChezmoiSourceDir" remote get-url origin).Trim()

    if ($CurrentRemoteUrl -eq $HttpsRepoUrl) {
        Write-Host "当前远程 URL 为 HTTPS，正在切换到 SSH URL..."
        git -C "$ChezmoiSourceDir" remote set-url origin "$SshRepoUrl"
        if ($LASTEXITCODE -ne 0) {
            throw "替换 Git 远程 URL 失败！退出代码: $LASTEXITCODE"
        }
        Write-Host "Git 远程 URL 已成功切换到 '$SshRepoUrl'。"
    }
    else {
        Write-Host "当前远程 URL 已是 '$CurrentRemoteUrl'，无需切换。"
    }
}
catch {
    Write-Host "错误：Git 远程 URL 替换失败。$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# --- 2.5. Replace Git remote URL to SSH ---
Write-Host "--- 正在替换 Git 远程 URL 为 SSH ---"

$ChezmoiSourceDir = Join-Path $HOME ".local\share\chezmoi"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConvertScript = Join-Path $ScriptDir "convert_url_to_ssh.py"

if (-Not (Test-Path $ConvertScript)) {
    Write-Host "错误：找不到 Python 脚本 '$ConvertScript'。" -ForegroundColor Red
    exit 1
}

try {
    $CurrentRemoteUrl = (git -C "$ChezmoiSourceDir" remote get-url origin).Trim()

    # 调用 Python 脚本转换 URL
    $SshRepoUrl = python "$ConvertScript" "$CurrentRemoteUrl"

    if ([string]::IsNullOrWhiteSpace($SshRepoUrl)) {
        Write-Host "当前远程 URL 不符合 HTTPS GitHub 模式或已经是 SSH，无需修改：$CurrentRemoteUrl"
    }
    else {
        Write-Host "检测到 HTTPS URL，正在切换为 SSH：$SshRepoUrl"
        git -C "$ChezmoiSourceDir" remote set-url origin "$SshRepoUrl"
        if ($LASTEXITCODE -ne 0) {
            throw "替换 Git 远程 URL 失败！退出代码: $LASTEXITCODE"
        }
        Write-Host "Git 远程 URL 已成功切换到 '$SshRepoUrl'。"
    }
}
catch {
    Write-Host "错误：Git 远程 URL 替换失败。$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}


# --- 3. Apply Chezmoi configuration ---
Write-Host "--- 正在应用 Chezmoi 配置 ---"
# Since the script is in the Chezmoi repository, there's no need for a 'chezmoi init' step.
Write-Host "正在执行 'chezmoi apply -v'..."
try {
    chezmoi apply -v
    if ($LASTEXITCODE -ne 0) {
        throw "Chezmoi apply 失败。退出代码: $LASTEXITCODE"
    }
    Write-Host "--- Chezmoi 设置完成！ ---"
}
catch {
    Write-Host "错误：Chezmoi apply 失败。$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

