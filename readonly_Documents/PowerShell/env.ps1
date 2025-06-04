$env:HTTPS_PROXY = "127.0.0.1:2080"
$env:EDITOR = "nvim"
$env:LANG = "zh_CN.UTF-8"
$env:SHELL = "pwsh.exe -nologo"
$profile_path = Split-Path -Parent $PROFILE
Invoke-Expression $profile_path/zoxide.ps1
