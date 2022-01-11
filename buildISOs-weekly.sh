#!/bin/bash

# Automated ISO build script
# Builds select profiles / inits
# 2019-2021, nous

export TERM=xterm-256color
source /usr/share/makepkg/util/message.sh
colorize

WORKSPACE=/home/$USER/artools-workspace
PROFILES=${WORKSPACE}/iso-profiles
REPO=/srv/iso/weekly-iso
CWD=$PROFILES
DATE=$(date +"%Y%m%d")

mkdir -p ${PROFILES}/logs

cd $WORKSPACE
if [[ -d $PROFILES ]]; then
    cd $PROFILES
    git pull
else
    git clone https://gitea.artixlinux.org/artix/iso-profiles.git
fi

cd $PROFILES
all_profiles=($(find -maxdepth 1 -type d | sed 's|.*/||'| egrep -v "\.|common|linexa|git|logs|lowmem|anon|gnome|i3|community$" | sort))
all_inits=('openrc' 'runit' 's6' 'suite66' 'dinit')

usage() {
    echo
    echo -n "${BOLD}Usage:  "
    echo "$0 [-b stable|gremlins] -p <profile>[,profile,...]|[all] -i <init>[,init,...]|[all]${ALL_OFF}"
    echo
    echo -n "All profiles, all inits:  "
    echo "$0 -p all -i all"
    echo
    echo "Available branches: ${BOLD}stable (default, if omitted), gremlins${ALL_OFF}"
    echo "Available profiles: ${GREEN}${all_profiles[@]}${ALL_OFF}"
    echo "Available inits:    ${CYAN}${all_inits[@]} ${ALL_OFF}"
    echo
    echo "Example: $0 -p base,lxqt,lxde -i openrc,runit"
    echo "         $0 -b gremlins -p base -i s6"
    echo
    exit 1
}

timestamp() { date +"%Y/%m/%d-%H:%M:%S"; }

[[ $# -eq 0 ]] && usage

while getopts "b:p:i:" option; do
    case $option in
        b)
            _branch=$OPTARG
            [[ ${_branch} =~ (^$|stable|gremlins) ]] || { echo; echo "${RED}No valid branch selected!${ALL_OFF}"; echo; usage; }
            [[ ${_branch} == 'stable' || ${_branch} == '' ]] && { _branch='stable'; branch=''; }
            [[ ${_branch} == 'gremlins' ]] && branch='-gremlins'
            ;;
        p)
            _profile=$OPTARG
            for p in ${all_profiles[@]}; do
                [[ ${_profile} =~ $p ]] && profiles+=($p)
            done
            [[ ${_profile} == all ]]    && profiles=(${all_profiles[@]})
            ;;
        i)
            _init=$OPTARG
            for i in ${all_inits[@]}; do
                [[ ${_init} =~ $i ]] && inits+=($i)
            done
            [[ ${_init} == all ]]    && inits=(${all_inits[@]})
            ;;
    esac
done

[[ $branch ]] || { _branch='stable'; branch=''; }
[[ ${#profiles[@]} -eq 0 ]] && { echo; echo "${RED}No valid profiles selected!${ALL_OFF}"; echo; usage; }
[[ ${#inits[@]} -eq 0 ]]	&& { echo; echo "${RED}No valid inits selected!"${ALL_OFF}; echo; usage; }

echo "Building ISO(s):"
echo "		branch		${BOLD}${_branch}${ALL_OFF}"
echo "		profiles 	${GREEN}${profiles[@]}${ALL_OFF}"
echo "		inits		${CYAN}${inits[@]}${ALL_OFF}"


cd $PROFILES && git checkout master
for profile in ${profiles[@]}; do
    for init in ${inits[@]}; do
        logfile=$PROFILES/logs/buildiso-$DATE
        logfile_debug=$logfile-$profile-$init
        echo "#################################" >> ${logfile}.log
        stamp=$(timestamp)
        [[ $profile =~ 'community' ]] && [[ $init != 'openrc' ]] && \
            { echo "$stamp == ${YELLOW}Skipping building ${_branch} ${profile}-${init}${ALL_OFF}" >> $logfile.log; continue; }
        echo "$stamp == Begin building    ${_branch} ${profile}-${init}" >> $logfile.log
        [[ $init == 'openrc' ]] && cp ${WORKSPACE}/tweaks/rc.conf ${PROFILES}/$profile/root-overlay/etc/
        echo "VERSION_ID=$DATE" >| ${PROFILES}/$profile/root-overlay/etc/buildinfo
        echo "VARIANT=${profile}-${init}" >> ${PROFILES}/$profile/root-overlay/etc/buildinfo
        nice -n 20 buildiso${branch} -p $profile -i $init 2>&1 >> ${logfile_debug}.log
        res=$?
        stamp=$(timestamp)
        if [ $res == 0 ]; then
            echo "$stamp == ${GREEN}Finished building ${_branch} ${profile}-${init}${ALL_OFF}" >> $logfile.log
        else
            echo "$stamp == ${RED}Failed building   ${_branch} ${profile}-${init}${ALL_OFF}" >> $logfile.log
            echo "$stamp == ${RED}Retrying once     ${_branch} ${profile}-${init}${ALL_OFF}" >> $logfile.log
            echo "$stamp == Re-building       ${_branch} ${profile}-${init}" >> $logfile.log
            nice -n 20 buildiso${branch} -p $profile -i $init 2>&1 >> ${logfile_debug}.log
            res=$?
            stamp=$(timestamp)
            if [ $res == 0 ]; then
                { echo "$stamp == ${GREEN}Finished building ${_branch} ${profile}-${init}${ALL_OFF}" >> $logfile.log; } \
            else
                { echo "$stamp == ${RED}Failed building   ${_branch} ${profile}-${init}${ALL_OFF}" >> $logfile.log; continue; }
            fi
        fi
        rm -f ${PROFILES}/$profile/root-overlay/etc/{rc.conf,buildinfo}
        sudo rm -fr /var/lib/artools/buildiso/$profile
#        [[ $res == 0 ]]	&& { echo "$stamp == ${GREEN}Finished building ${_branch} ${profile}-${init}${ALL_OFF}" >> $logfile.log; } \
#                        || { echo "$stamp == ${RED}Failed building   ${_branch} ${profile}-${init}${ALL_OFF}" >> $logfile.log; continue; }
        mv -v ${WORKSPACE}/iso/$profile/artix-$profile-$init-*.iso ${REPO}/ 2>/dev/null
        cd $REPO && { sha256sum artix-*.iso > ${REPO}/sha256sums & }
    done
done
rm -f ${PROFILES}/*/root-overlay/etc/{rc.conf,buildinfo}
