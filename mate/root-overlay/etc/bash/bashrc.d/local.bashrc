# are we an interactive shell?
if [ "$PS1" ]; then
    shopt -s cdspell checkwinsize histappend no_empty_cmd_completion dotglob
    shopt -u huponexit
fi

# Show effective user in prompts and terminal titles
USER=`id -un`

alias psa='ps a'
# handy Perl one-liner for calculations: calc 5*12+5/8^2
alias calc='perl -e '\''$_="@ARGV";s/\^/**/g;y/x/*/;print eval $_, "\n"'\'''
# Replace all spaces in current directory's filenames with underscores
alias nospaces='i=0; for f in *\ *; do mv ./"$f" `echo "$f" | sed s/\ /_/g` ; let i++ ; done ; echo $i file\(s\) renamed'
# Same with parentheses
alias noparentheses='i=0; for f in *\(*; do mv ./"$f" `echo "$f" | sed s/\(//g | sed s/\)//g` ; let i++; done; echo $i file\(s\) renamed'
alias rot13='tr A-Za-z N-ZA-Mn-za-m'
alias rot47='tr !-~ P-~!-O'

# Virtualbox in dark themes is ugly with every QT_STYLE_OVERRIDE setting except kvantum-dark
alias VirtualBox='QT_STYLE_OVERRIDE=kvantum-dark virtualbox'
alias virtualbox='QT_STYLE_OVERRIDE=kvantum-dark virtualbox'

# No clobber, use >| instead of >
set -C

# Users generally won't see annoyng core files
ulimit -c 0
[ "${EUID}" = "0" ] && ulimit -S -c 1000000 > /dev/null 2>&1

# Make a nice prompt
[ "${EUID}" = "0" ] && export PS1="\[\033[1;32;40m\]\h\[\033[0;37;40m\]:\[\033[34;40m\][\[\033[1;31;40m\]\u\[\033[0;34;40m\]]\[\033[0;37;40m\]:\[\033[35;40m\]\w\[\033[1;33;40m\]#\[\033[0m\] " \
                    || export PS1="\[\033[1;32;40m\]\h\[\033[0;37;40m\]:\[\033[31;40m\][\[\033[1;34;40m\]\u\[\033[0;31;40m\]]\[\033[0;37;40m\]:\[\033[35;40m\]\w\[\033[1;33;40m\]%\[\033[0m\] "

echo
