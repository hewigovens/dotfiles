if status is-interactive && set -q SSH_TTY
    set -l agent_file ~/.ssh/agent.fish
    if ssh-add -l >/dev/null 2>&1
    else
        if test -f $agent_file
            source $agent_file >/dev/null 2>&1
        end

        if not ssh-add -l >/dev/null 2>&1
            eval (ssh-agent -c | tee $agent_file)
            ssh-add 2>/dev/null
        end
    end
end
