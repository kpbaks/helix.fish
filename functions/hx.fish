function hx
    # IDEA: ignore files mathing certain patterns, and files from .gitignore

    set -l hx hx
    # if test -f ~/clones/helix/target/release/hx
    #     set hx ~/clones/helix/target/release/hx
    # end
    if test (count $argv) -eq 0
        if test -d .git
            # TODO: discard non text files like pngs
            set -l most_recent_modified_file
            set -l most_recent_mtime 0

            for f in (command git ls-files)
                set -l mtime (path mtime $f)
                # `path mtime` fails if $f is a symlink
                test $status -eq 0; or continue
                if test $mtime -gt $most_recent_mtime
                    set most_recent_mtime $mtime
                    set most_recent_modified_file $f
                end
            end

            if test -z $most_recent_modified_file
                # no files tracked by git
                command $hx .
            end

            set -l reset (set_color normal)
            printf '%sinfo%s: opening the last modified text file %s%s%s' (set_color green) $reset (set_color blue) $most_recent_modified_file $reset >&2
            if functions --query peopletime
                set -l now (date +%s)
                set -l duration (math "$now - $most_recent_mtime")
                printf ' (last modified %s%s%s ago)' (set_color yellow) (peopletime (math "$duration * 1000")) $reset >&2
            end
            printf '\n' >&2
            command $hx $most_recent_modified_file
            return
        end

        if test (count ./*) -eq 1
            command $hx ./*
            return
        end
        if test -f Cargo.toml
            for f in ./src/{main,lib}.rs
                if test -f $f
                    command $hx $f
                    return
                end
            end
        else if test -f CMakeLists.txt
            for f in ./src/main.{cpp,c} main.{cpp,c}
                if test -f $f
                    command $hx $f
                    return
                end
            end
        end

        command $hx .
    else

        # set -l options h/help H-health t-tutor= g/grammar= c/config= v/verbose l-log= V/version S-vsplit P-hsplit w/working-dir=

        # argparse $options -- $argv


        # TODO: make dir the paths which do not exist
        # TODO: check if a hx process already exists, with the same file open
        # TODO: check if a hx backgruond job `jobs` exists

        command $hx $argv
    end
end
