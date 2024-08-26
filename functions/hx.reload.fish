function hx.reload -d "Request each running hx process to reload their config.toml"
    set -l argv_unparsed $argv
    set -l options j/jobs
    argparse $options -- $argv; or return 2

    set -l hx_pids (hx.pids $argv_unparsed)

    for pid in $hx_pids
        command kill -USR1 $pid
    end

    set -l reset (set_color normal)
    set -l blue (set_color blue)

    set -l n (count $hx_pids)

    if test (count $hx_pids) -eq 0
        printf 'No %shx%s processes are running\n' (set_color $fish_color_command) $reset
        return
    end

    # TODO: format USR1 as a kitty hyperlink to link to the man page for the signal
    switch (count $hx_pids)
        case 1
            printf 'Sent signal USR1 to the only %shx%s process running, requesting them to reload their config:\n' (set_color $fish_color_command) $reset
        case '*'
            printf 'Sent signal USR1 to %d %shx%s processes, requesting them to reload their config:\n' $n (set_color $fish_color_command) $reset
    end


    set -l config_url https://docs.helix-editor.com/configuration.html
    printf 'Read more about this feature here %s%s%s\n' $blue $config_url $reset
end
