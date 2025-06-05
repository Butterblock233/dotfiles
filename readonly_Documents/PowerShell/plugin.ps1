$plugin_list = @(
	"PSReadLine",
	"posh-git"
)

function setup_plugin($plugin_list,$source="PSGallery")
{
	foreach($i in $plugin_list)
	{
		if(-not(Get-Module -ListAvailable -Name $i))
		{ # if package exists
			Write-Output "$i not found, installing..."
			Install-Module $i
			Import-Module $i
		} else
		{
			Import-Module $i
			# Write-Output "$i imported"	
		}
	}

}

function Get-Plugin($plugin_list = $plugin_list)
{
	foreach($i in $plugin_list)
	{
		if(Get-Module -ListAvailable -Name $i)
		{
			Write-Output "Plugin $i is succefully imported"
		}
	}
}

setup_plugin $plugin_list
