function hx.status

    set -l argv_unparsed $argv
    set -l options j/jobs
    argparse $options -- $argv; or return 2

    if not isatty stdout
        echo todo
        return 2
    end

    # TODO: figure out which of these properties are Linux only, and not MacOS or Windows/WSL
    # Or find out how to query these in a portable way
    # uname -a

    set -l hx_pids (hx.pids $argv_unparsed)

    set -l reset (set_color normal)
    set -l yellow (set_color yellow)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)
    set -l b (set_color --bold)
    set -l i (set_color --italics)
    set -l dim (set_color --dim)
    set -l pid_color (set_color --background yellow '#000000' --bold)

    if test (count $hx_pids) -eq 0
        printf 'No %shx%s processes are running\n' (set_color $fish_color_command) $reset
        return
    end

    set -l cache_dir $__fish_user_data_dir/helix.fish
    test -d $cache_dir; or command mkdir $cache_dir; or return

    # Fetch version of latest release from github, and cache it on disk. If not the newest the notify user
    set -l releases_url https://api.github.com/repos/helix-editor/helix/releases/latest
    set -l latest_hx_version $cache_dir/latest_hx_version
    if not test -f $latest_hx_version; or test (path mtime --relative $latest_hx_version) -gt 86400
        echo "downloading version ..."
        command curl -s $releases_url | string match --regex --groups-only '"tag_name": "(.+)"' >$latest_hx_version
    end
    set -l hx_latest_version_parts (string split '.' <$cache_dir/latest_hx_version)
    # echo $latest_hx_version_parts
    # return

    set -l CLK_TCK (getconf CLK_TCK)
    # START_TIME=$(awk '{print $22}' /proc/[PID]/stat)
    # UPTIME=$(awk '{print $1}' /proc/uptime)

    # # Convert start time to seconds
    # START_TIME_SECS=$(echo "$START_TIME / $CLK_TCK" | bc -l)

    # # Calculate elapsed time
    # ELAPSED_TIME=$(echo "$UPTIME - $START_TIME_SECS" | bc -l)

    set -l uptime (string split ' ' --fields=1 </proc/uptime)

    if test (count $hx_pids) -ge 2
        set_color --dim
        string repeat --count $COLUMNS -
        set_color normal
    end

    for pid in $hx_pids
        test -d /proc/$pid; or continue

        printf '%spid%s:          %s %d %s\n' $b $reset $pid_color $pid $reset
        printf '%sexe%s:          %s%s%s\n' $b $reset (set_color $fish_color_command) (path resolve /proc/$pid/exe) $reset
        printf '%scwd%s:          %s%s%s\n' $b $reset (set_color $fish_color_cwd) (path resolve /proc/$pid/cwd) $reset
        printf '%scmdline%s:      %s%s\n' $b $reset (printf (echo (string split0 </proc/$pid/cmdline) | fish_indent --ansi)) $reset

        printf '%scpu%s:          todo\n' $b $reset

        begin
            set -l vmrss (string match --regex --groups-only 'VmRSS:\s*(.+)' </proc/$pid/status)
            printf '%sram%s:          %s%s%s\n' $b $reset $red $vmrss $reset
        end

        # IDEA: this is to see which lsps it is running
        printf '%ssubprocesses%s: todo\n' $b $reset

        # helix version
        begin
            set -l hx_version (/proc/$pid/exe --version | string split ' ' --fields=2)
            set -l hx_version_parts (string split '.' -- $hx_version)

            set -l nparts (math max "$(count $hx_version_parts),$(count $hx_latest_version_parts)")
            if test (count $hx_version_parts) -lt $nparts
                set -a hx_version_parts (for i in (seq (math "$nparts - $(count $hx_version_parts)")); echo 0; end)
            end
            if test (count $hx_latest_version_parts) -lt $nparts
                set -a hx_latest_version_parts (for i in (seq (math "$nparts - $(count $hx_latest_version_parts)")); echo 0; end)
            end

            set -l newer_version_available 0
            for i in (seq $nparts)
                if test $hx_version_parts[$i] -lt $hx_latest_version_parts[$i]
                    set newer_version_available 1
                    break
                end
            end

            printf '%sversion%s:      ' $b $reset
            if test $newer_version_available -eq 1
                printf '%s%s%s %sa newer release version is available %s%s%s%s\n' $red $hx_version $reset $dim $reset (set_color green --dim) (cat $latest_hx_version) $reset
            else
                printf '%s%s%s %snewest release version%s\n' $green $hx_version $reset $dim $reset
            end
        end
        # IDEA: walk the process tree, using the pids ppid until we hit pid=0, on the way look for known terminals like `kitty` or `alacritty`
        # TODO: can probably be made more reliable by querying which ptys and ttys the pid is connected to.
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
                    case kitty alacritty konsole zellij tmux
                        set -f terminal (path resolve /proc/$ppid/exe)
                        break
                    case '*'
                end

                test $ppid -gt 1; or break # Can not be process 0 or 1
            end

            printf '%sterminal%s:     ' $b $reset
            if set -q terminal
                printf '%s%s%s\n' (set_color $fish_color_command) $terminal $reset
            else
                printf '%s UNKNOWN %s\n' (set_color --background brred '#000000') $reset
            end
        end

        # IDEA: it must be possible to list which fds the process has open or which files it has mmapped into its virtual memory
        # UPDATE: not possible, as the file is closed after reading it
        # printf '%sconfig.toml%s:  todo\n' $b $reset
        begin
            set -l start_time (string split ' ' --fields=22 </proc/$pid/stat)
            set -l start_time_sec (math "$start_time / $CLK_TCK")
            set -l elapsed_time_sec (math "$uptime - $start_time_sec")

            # set -l sec (math "round($elapsed_time_sec)")
            # set -l milli (math "$elapsed_time_sec - $sec")
            # # Compute elapsed time in seconds
            # elapsed_time_sec=$(echo "$current_time - ($start_time / $HERTZ)" | bc)

            # # Convert elapsed time to milliseconds
            # elapsed_time_ms=$(echo "$elapsed_time_sec * 1000" | bc)

            #             echo "Elapsed time: $elapsed_time_ms ms"

            set -l color $reset
            if test $elapsed_time_sec -gt 86400
                set color $red
            else if test $elapsed_time_sec -gt 3600
                set color $yellow
            end

            printf '%setime%s:        ' $b $reset
            if functions -q peopletime
                printf '%s%s%s' $color (peopletime (math "round($elapsed_time_sec * 1000)")) $reset
            else
                printf '%s%s%s %sseconds%s' $color $elapsed_time_sec $reset $dim $reset
            end
            echo
        end

        begin
            # TODO: I do not know if the final filter is reliable, maybe check if $HELIX_RUNTIME is defined and use that
            set -l loaded_grammars (cat /proc/$pid/maps | string match --regex --groups-only '\s+(/\S+)' | uniq | string match '*grammars*')
            printf '%sloaded ts grammars%s:\n' $b $reset
            for f in $loaded_grammars
                printf ' - %s%s%s/%s%s%s\n' $dim (path dirname $f) $reset $cyan (path basename $f) $reset
            end
            # printf ' - %s\n' $mmapped_files
        end

        # begin
        #     set -l mmapped_files (cat /proc/$pid/maps | string match --regex --groups-only '\s+(/\S+)' | uniq)
        #     printf '%smmapped *.so%s:\n' $b $reset
        #     for f in $mmapped_files
        #         printf ' - %s%s%s/%s%s%s\n' $dim (path dirname $f) $reset $cyan (path basename $f) $reset
        #     end
        #     # printf ' - %s\n' $mmapped_files
        # end


        # IDEA: look at some env vars that might be related to helix
        # (string split0 </proc/$pid/environ)
        # Found by searching for `std::env::var` in github.com/helix-editor/helix codebase tir 27 aug 00:10:22 CEST 2024
        # - HELIX_RUNTIME
        # - HELIX_LOG_LEVEL # https://github.com/helix-editor/helix/blob/af7a1fd20c0a2915e0dae1b5bea7cb6bde6c2746/helix-term/src/application.rs#L81
        # - COLORTERM # https://github.com/helix-editor/helix/blob/af7a1fd20c0a2915e0dae1b5bea7cb6bde6c2746/helix-term/src/lib.rs#L31
        # Since `hx` is a rust program maybe also look for relavant rust env vars like `RUST_BACKTRACE`
        printf '%senv%s:          todo\n' $b $reset

        # cat /proc/[PID]/cgroup
        printf '%scgroup%s:       todo\n' $b $reset
        # cat /proc/[PID]/io
        begin
            # string match --regex --groups-only '(\d+)' </proc/$pid/io | read --line rchar wchar syscr syscw read_bytes write_bytes cancelled_write_bytes
            string split ': ' --fields=2 </proc/$pid/io | read --line rchar wchar syscr syscw read_bytes write_bytes cancelled_write_bytes

            printf '%sio%s:           todo\n' $b $reset
        end
        # ls /proc/[PID]/task
        printf '%sthreads%s:      todo\n' $b $reset
        begin
            string split0 </proc/$pid/loginuid | read uid
            # TODO: lookup username using `getenv password $uid`
            # TODO: color uid depending on being root $uid=0, or user being
            printf '%suid%s:          %d\n' $b $reset $uid
            # printf '%suser%s:         todo\n' $b $reset
        end
        # TODO: color the state accordingly, i.e. green or red or ..
        # cat /proc/[PID]/status | grep State
        begin
            # https://www.baeldung.com/linux/process-states
            set -l state (string match --regex --groups-only '^State:[^\(]+\((\w+)\)' </proc/$pid/status)
            set -l color
            # State: D (disk sleep)
            # State: I (idle)
            # State: R (running)
            # State: S (sleeping)
            # State: T (stopped)
            switch $state
                case stopped
                    set color $red
                case sleeping
                    set color $dim
                case running
                    set color $green
                case idle
                    set color $blue
                case 'disk sleep'
                    set color $magenta
            end
            printf '%sstate%s:        %s%s%s\n' $b $reset $color $state $reset

        end
        # TODO: Look at open fds to get an idea of which files are open

        # echo
        if test (count $hx_pids) -ge 2
            set_color --dim
            string repeat --count $COLUMNS -
            set_color normal
        end
    end
end
