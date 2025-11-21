if status is-interactive
    # Commands to run in interactive sessions can go here
end


# 设置语言为英文（UTF-8）
set -x LANG zh_CN.UTF-8
set -x LC_ALL zh_CN.UTF-8


# Http proxy
set -gx http_proxy "http://127.0.0.1:2080"
set -gx https_proxy "http://127.0.0.1:2080"

# 设置默认编辑器（如 Neovim）
set -gx EDITOR /usr/bin/nvim
set -gx VISUAL $EDITOR
if type -q  zoxide 
	zoxide init fish | source
end

if type -q oh-my-posh 
	oh-my-posh init fish | source
end

alias pixix "pixi x"
# alias uvx\ tool "uv tool"
