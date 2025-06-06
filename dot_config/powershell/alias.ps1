# Write-Output "Module alias loaded"
Set-Alias -Name cd -Value __zoxide_z -Option AllScope -Scope Global -Force
if ($env.OS -eq "Windows_NT") {
	Remove-Alias -Name ls
	Remove-Alias -Name rm
}
