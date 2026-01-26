function load_node
    fnm env --shell fish | source

    # pnpm
    set -gx PNPM_HOME ~/Library/pnpm
    if not string match -q -- $PNPM_HOME $PATH
        set -gx PATH "$PNPM_HOME" $PATH
    end
end

function load_bun
    set -gx BUN_INSTALL ~/.bun
    if not string match -q -- $BUN_INSTALL/bin $PATH
        set -gx PATH "$BUN_INSTALL/bin" $PATH
    end
end

# Auto-load on startup
load_node
load_bun
