# zoxide init nushell | save -f "~/.config/nushell/completions/zoxide.nu"
#
# pixi completion --shell nushell | save -f "~/.config/nushell/completions/pixi.nu"


$env.SHELL = "nu"
$env.https_proxy = "http://127.0.0.1:2081"
$env.EDITOR = "nvim"
$env.LANG = "zh_cn.UTF-8"

def proxy-on () {
	$env.https_proxy = "http://127.0.0.1:2081"
	echo "Https Proxy On"
}

def proxy-off () {
    $env.https_proxy = ""
	echo "Https Proxy Off"
}
