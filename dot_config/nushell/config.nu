const OS = $nu.os-info.name

source (
    if $OS == "windows" { "./windows.nu" } # needs to be constant, see https://github.com/nushell/nushell/pull/10326 for details
)

alias cat = open
alias nivm = nvim
alias nviim = nvim
alias nvimm = nvim
alias nnvim = nvim
alias nvvim = nvim
alias "uvx tool" = uv tool
alias "podman compose resume" = podman compose unpause

# Fix for wezterm scrolling issue - disable OSC133 shell integration
$env.config = {
    shell_integration: {
        osc133: false
    }
}

alias login = just -f ~/justfile login



