
const OS = $nu.os-info.name

source (
    if $OS == "windows" { "./windows.nu" } # needs to be constant
)
alias cat = open
alias nivm = nvim

# Fix for wezterm scrolling issue - disable OSC133 shell integration
$env.config = {
    shell_integration: {
        osc133: false
    }
}
