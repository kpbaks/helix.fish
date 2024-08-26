function hx.reload -d "Request each running hx process to reload their config.toml"
    set -l hx_pids (command pgrep hx)
    for pid in $hx_pids
        command kill -USR1 $pid
    end

    set -l reset (set_color normal)
    set -l blue (set_color blue)

    if test (count $hx_pids) -gt 0
        # TODO: format USR1 as a kitty hyperlink to link to the man page for the signal
        printf 'Sent signal USR1 to these %shx%s processes, requesting them to reload their config:\n' (set_color $fish_color_command) $reset
        set -l config_url https://docs.helix-editor.com/configuration.html
        printf 'Read more about this feature here %s%s%s\n' $blue $config_url $reset

    else
        printf 'No %shx%s processes are running\n' (set_color $fish_color_command) $reset
    end
end
