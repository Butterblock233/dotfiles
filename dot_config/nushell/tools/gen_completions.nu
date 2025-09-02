let autoload_dir = ($nu.data-dir | path join "vendor" "autoload")
def ensure_autoload [
    name: string,  # file name with extension name(.nu)
    bin: string,   # 检查的二进制
    cmd: closure   # 生成补全的命令 block
] {
    mkdir $autoload_dir
    let target = ($autoload_dir | path join $name)
    
    if not ($target | path exists) and (which $bin | is-not-empty) {
        do $cmd | save -f $target
        print $"Generating ($name | path expand )..."
        true  # 返回 true 表示生成了文件
    } else {
        false  # 返回 false 表示没有生成文件
    }
}

let completions = [
    ["zoxide.nu" "zoxide" { zoxide init nushell }]
    ["pixi.nu" "pixi" { pixi completion --shell nushell }]
]

if ($completions | length) > 0 {
    # 使用 any 检查是否有任何文件被生成
    let generated = (do {
        mut any_generated = false
        for $i in $completions {
            if (ensure_autoload $i.0 $i.1 $i.2) {
                $any_generated = true
            }
        }
        $any_generated
    })
    
    if $generated {
        print "Done"
    } else {
        print "There's nothing to do today"
    }
} else { 
    print "There's nothing to do today"
}
