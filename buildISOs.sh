#!/bin/bash

# Automated ISO build script
# 2019-2020, nous

source /usr/share/makepkg/util/message.sh
colorize

WORKSPACE=/home/$USER/artools-workspace
PROFILES=${WORKSPACE}/iso-profiles
REPO=/srv/iso/testing-iso
CWD=`pwd`

cd $PROFILES
all_profiles=($(find -maxdepth 1 -type d | sed 's|.*/||'| egrep -v "\.|common|linexa|git" | sort))
all_inits=('openrc' 'runit' 's6')

usage() {
    echo
    echo -n "${BOLD}Usage:  "
    echo "$0 [-b stable|gremlins] -p <profile>[,profile][,profile] -i <init>[,init][,init]${ALL_OFF}"
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
            [[ ${_init} =~ (openrc|runit|s6) ]] || { echo; echo "${RED}No valid branch selected!${ALL_OFF}"; echo; usage; }
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

exit 1
mkdir -p ${PROFILES}
#rm -fr ${PROFILES}

cd $WORKSPACE
if [[ -d $PROFILES ]]; then
    cd $PROFILES
    git pull
else
    git clone https://gitea.artixlinux.org/artix/iso-profiles.git
fi

cd $PROFILES && git checkout refactor
echo "#################################" >>$CWD/ISO_build.log
for profile in ${profiles[@]}; do
    for init in ${inits[@]}; do
        [[ $init == 'openrc' ]] && cp ${WORKSPACE}/rc.conf ${PROFILES}/$profile/root-overlay/etc/
        stamp=$(timestamp)
        echo "$stamp == Begin building    ${_branch} $profile ISO with $init" >> $CWD/ISO_build.log
        nice -n 20 buildiso${branch} -p $profile -i $init
        stamp=$(timestamp)
        [[ $? ]] && echo "$stamp == ${GREEN}Finished building ${_branch} $profile ISO with $init${ALL_OFF}" >> $CWD/ISO_build.log || echo "$stamp == ${RED}Failed building   ${_branch} $profile ISO with $init${ALL_OFF}" >> $CWD/ISO_build.log
        rm -f ${PROFILES}/$profile/root-overlay/etc/rc.conf
        mv -v ${WORKSPACE}/iso/$profile/artix-$profile-$init-*.iso ${REPO}/
        cd $REPO && sha256sum artix-*.iso > ${REPO}/sha256sums &
    done
done
