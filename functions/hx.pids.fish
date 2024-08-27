function hx.pids
    set -l options j/jobs
    argparse $options -- $argv; or return 2

    if command -q pgrep
        set -f hx_pids (command pgrep hx)
    else
        # Walk /proc/ filesystem and search for all hx binaries
        set -f hx_pids

        for pid in /proc/*
            test -r $pid/exe
            and test (path resolve $pid/exe | path basename) = hx
            and set -a hx_pids (path basename $pid)
        end
    end

    if set -q _flag_jobs; and status is-interactive
        # Filter out those pids, which are not running in the background of the current fish interactive shell
        set -l job_pids (jobs --pid | string match --regex '\d+')
        # NOTE: go through list in reverse order, such that when we delete an element, it does not invalidate the index, into 
        # pids earlier in the list.
        for i in (seq (count $hx_pids) -1 1)
            if not contains -- $hx_pids[$i] $job_pids
                set --erase hx_pids[$i]
            end
        end
    end

    printf '%s\n' $hx_pids
end
