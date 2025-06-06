# Write-Output "Module alias loaded"
Set-Alias -Name cd -Value __zoxide_z -Option AllScope -Scope Global -Force
Remove-Alias -Name ls
Remove-Alias -Name rm
