# $env:HTTPS_PROXY = '127.0.0.1:2080'
# $env:EDITOR = 'nvim'
$profile_path = Split-Path -Parent $PROFILE
Invoke-Expression $profile_path/zoxide.ps1
Invoke-Expression $profile_path/env.ps1
# Set-Alias -Name "cd" -Value "z"

