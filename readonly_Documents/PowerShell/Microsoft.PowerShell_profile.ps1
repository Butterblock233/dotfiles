$profile_path = Split-Path -Parent $PROFILE
$modules= @(
	"zoxide.ps1",
	"env.ps1",
	"plugin.ps1",
	"alias.ps1"
)

function load_module()
{
	foreach($i in $modules)
	{
		$full_path = Join-Path $profile_path $i
		# Write-Output("Loading $full_path")
		Invoke-Expression $full_path
	}
}

load_module

oh-my-posh init pwsh --eval | Invoke-Expression
