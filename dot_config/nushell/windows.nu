alias paste = win32yank.exe -o
alias copy = win32yank.exe -i
alias expo = explorer.exe .
alias expl = explorer.exe

alias start = cmd /c start
alias zed = cmd /c start zed
alias zedo = cmd /c start zed . 
alias nvim-qt = cmd /c start nvim-qt
alias neovide = cmd /c start neovide
alias nqt = nvim-qt
alias nqto = nvim-qt .
alias codeo = cmd /c code .

alias ss = scoop-search

alias typora = cmd /c start typora

chcp 65001 | ignore # use UTF-8 for shell

$env.PYTHONUTF8 = "1" # use UTF-8 in Python
