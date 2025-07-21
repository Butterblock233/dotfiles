# 确保 autoload 补全文件存在
def ensure_autoload [
    name: string,  # file name with extension name(.nu)
    bin: string,   # 检查的二进制
    cmd: closure   # 生成补全的命令 block
] {
    let autoload_dir = ($nu.data-dir | path join "vendor" "autoload")
    mkdir $autoload_dir

    let target = ($autoload_dir | path join $name)

    if not ($target | path exists) and (which $bin | is-not-empty) {
        do $cmd | save -f $target
    }
}

# 使用示例：
ensure_autoload "zoxide.nu" "zoxide" { zoxide init nushell }
ensure_autoload "pixi.nu" "pixi" { pixi completion --shell nushell }

