# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH"

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,exports,aliases,functions,bash_prompt,extra}; do
	[ -r "$file" ] && source "$file"
done
unset file

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null
done

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults

# Add `killall` tab completion for common apps
#complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall

# If possible, add tab completion for many more commands
[ -f /etc/bash_completion ] && source /etc/bash_completion
[ -f /opt/local/etc/bash_completion ] && source /opt/local/etc/bash_completion

export SSH_CMD=$(which ssh)
if [ -e $HOME/.local_dev_box ] ; then
    function ssh_scr {
        $SSH_CMD $@ -t 'bash -i -c "screen -xRR \$USER"'
    }

    export function ssh_scr;
else
    screen_cmd=$(which screen)
    function screen {
        if [ -x "$HOME/.ssh_capture_session" ] ; then
            $HOME/.ssh_capture_session
        fi
        $screen_cmd "$@"
    }
    export screen

    function ssh_scr {
        ssh_session_var_file="$HOME/.ssh/.ssh_session_vars.rc"
        if [ -e $ssh_session_var_file ] ; then
            source $ssh_session_var_file
        fi

        $SSH_CMD $@
    }

    export function ssh_scr;
fi

export CLICOLOR=1
