if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression ((&zoxide init powershell) -join "`n")
}
