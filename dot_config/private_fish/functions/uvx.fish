function uvx --description "Safe wrapper to avoid confusing uv tool with uvx"
    if test (count $argv) -gt 0
        if test "$argv[1]" = "tool"
            echo "Warning: 'uvx tool' is not the intended command."
            echo "Use:    uv tool ..."
            return 1
        end
    end

    # 真正调用外部 uvx
    command uvx $argv
end
