function hx.status

    set -l argv_unparsed $argv
    set -l options j/jobs
    argparse $options -- $argv; or return 2

    # TODO: figure out which of these properties are Linux only, and not MacOS or Windows/WSL
    # Or find out how to query these in a portable way
    # uname -a

    set -l hx_pids (hx.pids $argv_unparsed)

    set -l reset (set_color normal)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l b (set_color --bold)
    set -l pid_color (set_color --background yellow '#000000')

    if test (count $hx_pids) -eq 0
        printf 'No %shx%s processes are running\n' (set_color $fish_color_command) $reset
        return
    end

    set -l CLK_TCK (getconf CLK_TCK)
    # START_TIME=$(awk '{print $22}' /proc/[PID]/stat)
    # UPTIME=$(awk '{print $1}' /proc/uptime)

    # # Convert start time to seconds
    # START_TIME_SECS=$(echo "$START_TIME / $CLK_TCK" | bc -l)

    # # Calculate elapsed time
    # ELAPSED_TIME=$(echo "$UPTIME - $START_TIME_SECS" | bc -l)

    set -l uptime (string split ' ' --fields=1 </proc/uptime)

    for pid in $hx_pids
        printf '- %s%d%s\n' $pid_color $pid $reset
        printf '  - %sexe%s:          %s%s%s\n' $b $reset (set_color $fish_color_command) (path resolve /proc/$pid/exe) $reset
        printf '  - %scwd%s:          %s%s%s\n' $b $reset (set_color $fish_color_cwd) (path resolve /proc/$pid/cwd) $reset
        printf '  - %scmdline%s:      %s%s\n' $b $reset (printf (echo (string split0 </proc/$pid/cmdline) | fish_indent --ansi)) $reset
        printf '  - %scpu%s:          todo\n' $b $reset
        printf '  - %sram%s:          todo\n' $b $reset
        # IDEA: this is to see which lsps it is running
        printf '  - %ssubprocesses%s: todo\n' $b $reset
        # TODO: fetch version of latest release from github, and cache it on disk. If not the newest the notify user
        printf '  - %sversion%s:      %s\n' $b $reset (/proc/$pid/exe --version | string split ' ' --fields=2)
        # IDEA: walk the process tree, using the pids ppid until we hit pid=0, on the way look for known terminals like `kitty` or `alacritty`
        # set -l terminal
        begin
            set -l ppid $pid
            while true
                set ppid (string match --regex --groups-only '^PPid:\s+(\d+)' </proc/$ppid/status)
                # echo $ppid
                # set -l exe (path resolve /proc/$pid/exe)
                set -l exe (string split0 </proc/$ppid/cmdline)[1]
                set -l name (path basename $exe)
                # echo "exe: $exe"
                # echo "name: $name"
                switch $name
                    case kitty alacritty konsole
                        set -f terminal (path resolve /proc/$ppid/exe)
                        break
                    case '*'
                end

                test $ppid -gt 1; or break # Can not be process 0 or 1
            end

            printf '  - %sterminal%s:     ' $b $reset
            if set -q terminal
                printf '%s%s%s\n' (set_color $fish_color_command) $terminal $reset
            else
                printf '%s UNKNOWN %s\n' (set_color --background brred '#000000') $reset
            end
        end
        # set -l ppids $pid
        # while test $ppids[1] != 0
        #     set -l pid $ppids[1]
        #     set --prepend ppids $ppid
        #     # printf 'ppid: %s exe: %s\n' $ppid (path resolve /proc/$ppid/exe)
        # end


        # IDEA: it must be possible to list which fds the process has open or which files it has mmapped into its virtual memory
        printf '  - %sconfig.toml%s:  todo\n' $b $reset
        printf '  - %setime%s:        todo\n' $b $reset

        # IDEA: look at some env vars that might be related to helix
        # (string split0 </proc/$pid/environ)
        # Found by searching for `std::env::var` in github.com/helix-editor/helix codebase tir 27 aug 00:10:22 CEST 2024
        # - HELIX_RUNTIME
        # - HELIX_LOG_LEVEL # https://github.com/helix-editor/helix/blob/af7a1fd20c0a2915e0dae1b5bea7cb6bde6c2746/helix-term/src/application.rs#L81
        # - COLORTERM # https://github.com/helix-editor/helix/blob/af7a1fd20c0a2915e0dae1b5bea7cb6bde6c2746/helix-term/src/lib.rs#L31
        # Since `hx` is a rust program maybe also look for relavant rust env vars like `RUST_BACKTRACE`
        printf '  - %senv%s:          todo\n' $b $reset

        # cat /proc/[PID]/cgroup
        printf '  - %scgroup%s:       todo\n' $b $reset
        # cat /proc/[PID]/io
        printf '  - %sio%s:           todo\n' $b $reset
        # ls /proc/[PID]/task
        printf '  - %sthreads%s:      todo\n' $b $reset
        # TODO: color the state accordingly, i.e. green or red or ..
        # cat /proc/[PID]/status | grep State
        printf '  - %sstate%s:        todo\n' $b $reset

        # TODO: Look at open fds to get an idea of which files are open
    end
end
