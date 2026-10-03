function __ai_prune_versions --argument-names versions selected kind
    test -d "$versions"; or return 0
    set versions (path resolve -- "$versions")
    for entry in "$versions"/*
        test -L "$entry"; and continue
        string match -qr '^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$' -- (path basename -- "$entry"); or continue
        if test "$kind" = claude
            test -f "$entry"; and test -x "$entry"; or continue
        else
            test -d "$entry"; and test -f "$entry/codex-package.json"; and test -x "$entry/bin/codex"; or continue
        end
        # Re-read the selected version and running binaries before each removal.
        set -l current (path resolve -- "$selected")
        if not test -e "$selected"; or test (path dirname -- "$current") != "$versions"
            printf 'Skipping cleanup: cannot identify current version via %s\n' "$selected" >&2
            return 1
        end
        if test "$entry" = "$current"
            printf 'Keep current: %s\n' "$entry"
            continue
        end

        set -l open_files (command lsof -nP -d txt -Fn 2>&1)
        if test $status -ne 0; or string match -qr '^lsof:' -- $open_files; or not string match -qr '^n/' -- $open_files
            printf 'Skipping cleanup: lsof could not inspect running binaries.\n' >&2
            return 1
        end
        set -l loaded (string match -r '^n/.*' -- $open_files | string sub -s 2 | path resolve)
        # Match the executable itself or any loaded file inside its release.
        set -l entry_pattern '^'(string escape --style=regex -- "$entry")'(/|$)'
        if string match -qr -- "$entry_pattern" $loaded
            printf 'Keep running: %s\n' "$entry"
        else
            command rm -rf -- "$entry"; or return $status
            printf 'Removed: %s\n' "$entry"
        end
    end
end

function update_ai --description 'Update Claude and Codex; prune unused native versions'
    argparse --max-args=0 h/help -- $argv; or return 2
    if set -q _flag_help
        printf 'Usage: update_ai\nUpdates Claude, then Codex, then cleans old Claude/CLI/app-server versions.\nRequires lsof for running-version detection.\n'
        return 0
    end
    claude update; and codex update; or return $status

    set -l data_home "$HOME/.local/share"
    set -q XDG_DATA_HOME[1]; and set data_home "$XDG_DATA_HOME"
    set -l codex_home "$HOME/.codex"
    set -q CODEX_HOME[1]; and set codex_home "$CODEX_HOME"
    set -l claude_bin (command -s claude)
    __ai_prune_versions "$data_home/claude/versions" "$claude_bin" claude; or return $status
    for package in standalone app-server-daemon
        set -l root "$codex_home/packages/$package"
        __ai_prune_versions "$root/releases" "$root/current" codex; or return $status
    end
end
