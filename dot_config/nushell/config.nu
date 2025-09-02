alias ss = scoop-search
alias expo = explorer.exe .
alias expl = explorer.exe
alias cat = open

if $env.OS == "Windows_NT" { let $explorer = "explorer.exe" } else { let $explorer = "dolphin" }
# alias cd = __zoxide_z

# Fix for wezterm scrolling issue - disable OSC133 shell integration
$env.config = {
    shell_integration: {
        osc133: false
    }
} 


