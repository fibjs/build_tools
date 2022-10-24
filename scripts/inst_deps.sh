# Arrays should return with newlines so we can do something like "${output##*$'\n'}" to get the last line
IFS=$'\n'

NONINTERACTIVE=true
PROCEED=0
OS=$( uname )
ARCH=$( uname -m )
SUDO_LOCATION=$( command -v sudo )

if [[ $OS == "Linux" ]]; then
    [[ ! -e /etc/os-release ]] && echo " - /etc/os-release not found! It seems you're attempting to use an unsupported Linux distribution." && exit 1
    . /etc/os-release
elif [[ $OS == "Darwin" ]]; then
    export NAME=$(sw_vers -productName)
    BREW_PATH=$( brew --prefix )
fi

APTGET=apt
YUM=yum
BREW=brew

if [[ $- == *i* ]]; then # Disable if the shell isn't interactive (avoids: tput: No value for $TERM and no -T specified)
  export COLOR_NC=$(tput sgr0) # No Color
  export COLOR_RED=$(tput setaf 1)
  export COLOR_GREEN=$(tput setaf 2)
  export COLOR_YELLOW=$(tput setaf 3)
  export COLOR_BLUE=$(tput setaf 4)
  export COLOR_MAGENTA=$(tput setaf 5)
  export COLOR_CYAN=$(tput setaf 6)
  export COLOR_WHITE=$(tput setaf 7)
fi

# Execution helpers; necessary for BATS testing and log output in buildkite

function execute() {
  echo "--- Executing: $@"
  "$@"
}

function execute_always() {
  ORIGINAL_DRYRUN=$DRYRUN
  DRYRUN=false
  execute "$@"
  DRYRUN=$ORIGINAL_DRYRUN
}

function set_system_vars() {
    if [[ $OS == "Darwin" ]]; then
        export OS_VER=$(sw_vers -productVersion)
        export OS_MAJ=$(echo "${OS_VER}" | cut -d'.' -f1)
        export OS_MIN=$(echo "${OS_VER}" | cut -d'.' -f2)
        export OS_PATCH=$(echo "${OS_VER}" | cut -d'.' -f3)
        export MEM_GIG=$(($(sysctl -in hw.memsize) / 1024 / 1024 /1024))
    else
        export MEM_GIG=$(( ( ( $(cat /proc/meminfo | grep MemTotal | awk '{print $2}') / 1000 ) / 1000 ) ))
    fi
    local IFS=' '
    set `df -k . | tail -1`
    export DISK_INSTALL=$1
    export DISK_TOTAL=$(($2 / 1024 / 1024))
    export DISK_AVAIL=$(($4 / 1024 / 1024))
    # For a basic hueristic here, let's require at least 2GB of available RAM per parallel job.
    # CPU_CORES is the number of logical cores available.
    export JOBS=${JOBS:-$(( MEM_GIG / 2 >= CPU_CORES ? CPU_CORES : MEM_GIG / 2 ))}
}

function install_package() {
  if [[ $OS == "Linux" ]]; then
    EXECUTION_FUNCTION="execute"
    [[ $2 == "WETRUN" ]] && EXECUTION_FUNCTION="execute_always"
    ( [[ $2 =~ "--" ]] || [[ $3 =~ "--" ]] ) && OPTIONS="${2}${3}"
    # Can't use $SUDO_COMMAND: https://askubuntu.com/questions/953485/where-do-i-find-the-sudo-command-environment-variable
    [[ $CURRENT_USER != "root" ]] && [[ ! -z $SUDO_LOCATION ]] && NEW_SUDO_COMMAND="$SUDO_LOCATION -E"
    ( [[ $NAME =~ "Amazon Linux" ]] || [[ $NAME =~ "CentOS" ]] || [[ $NAME =~ "Fedora" ]] ) && eval $EXECUTION_FUNCTION $NEW_SUDO_COMMAND $YUM $OPTIONS install -y $1
    ( [[ $NAME =~ "Ubuntu" ]] || [[ $NAME =~ "Debian" ]] ) && eval $EXECUTION_FUNCTION $NEW_SUDO_COMMAND $APTGET $OPTIONS install -y $1
  fi
  true # Required; Weird behavior without it
}

function ensure_homebrew() {
    echo "${COLOR_CYAN}[Ensuring HomeBrew installation]${COLOR_NC}"
    if ! BREW=$( command -v brew ); then
        while true; do
            [[ $NONINTERACTIVE == false ]] && printf "${COLOR_YELLOW}Do you wish to install HomeBrew? (y/n)?${COLOR_NC}" &&  read -p " " PROCEED
            echo ""
            case $PROCEED in
                "" ) echo "What would you like to do?";;
                0 | true | [Yy]* )
                    execute "${XCODESELECT}" --install 2>/dev/null || true
                    if ! execute "${RUBY}" -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; then
                        echo "${COLOR_RED}Unable to install HomeBrew!${COLOR_NC}" && exit 1;
                    else BREW=$( command -v brew ); fi
                break;;
                1 | false | [Nn]* ) echo "${COLOR_RED} - User aborted required HomeBrew installation.${COLOR_NC}"; exit 1;;
                * ) echo "Please type 'y' for yes or 'n' for no.";;
            esac
        done
    else
        echo " - HomeBrew installation found @ ${BREW}"
    fi
}

function ensure_yum_packages() {
    ( [[ -z "${1}" ]] || [[ ! -f "${1}" ]] ) && echo "\$1 must be the location of your dependency file!" && exit 1
    DEPS_FILE="${TEMP_DIR}/$(basename ${1})"
    # Create temp file so we can add to it
    cat $1 > $DEPS_FILE
    if [[ ! -z "${2}" ]]; then # Handle EXTRA_DEPS passed in and add them to temp DEPS_FILE
        printf "\n" >> $DEPS_FILE # Avoid needing a new line at the end of deps files
        OLDIFS="$IFS"; IFS=$''
        _2=("$(echo $2 | sed 's/-qa /-qa\n/g')")
        for ((i = 0; i < ${#_2[@]}; i++)); do echo "${_2[$i]}\n" | sed 's/-qa\\n/-qa/g' >> $DEPS_FILE; done
    fi
    while true; do
        [[ $NONINTERACTIVE == false ]] && printf "${COLOR_YELLOW}Do you wish to update YUM repositories? (y/n)?${COLOR_NC}" && read -p " " PROCEED
        echo ""
        case $PROCEED in
            "" ) echo "What would you like to do?";;
            0 | true | [Yy]* ) execute eval $( [[ $CURRENT_USER == "root" ]] || echo $SUDO_LOCATION -E ) $YUM -y update; break;;
            1 | false | [Nn]* ) echo " - Proceeding without update!"; break;;
            * ) echo "Please type 'y' for yes or 'n' for no.";;
        esac
    done
    echo "${COLOR_CYAN}[Ensuring package dependencies]${COLOR_NC}"
    OLDIFS="$IFS"; IFS=$','
    # || [[ -n "$testee" ]]; needed to see last line of deps file (https://stackoverflow.com/questions/12916352/shell-script-read-missing-last-line)
    while read -r testee tester || [[ -n "$testee" ]]; do
        if [[ ! -z $(eval $tester $testee) ]]; then
            echo " - ${testee} ${COLOR_GREEN}ok${COLOR_NC}"
        else
            DEPS=$DEPS"${testee} "
            echo " - ${testee} ${COLOR_RED}NOT${COLOR_NC} found!"
            (( COUNT+=1 ))
        fi
    done < $DEPS_FILE
    IFS=$OLDIFS
    OLDIFS="$IFS"; IFS=$' '
    echo ""
    if [[ $COUNT > 0 ]]; then
        while true; do
            [[ $NONINTERACTIVE == false ]] && printf "${COLOR_YELLOW}Do you wish to install missing dependencies? (y/n)?${COLOR_NC}" && read -p " " PROCEED
            echo ""
            case $PROCEED in
                "" ) echo "What would you like to do?";;
                0 | true | [Yy]* )
                    for DEP in $DEPS; do
                        install_package $DEP
                    done
                break;;
                1 | false | [Nn]* ) echo " ${COLOR_RED}- User aborted installation of required dependencies.${COLOR_NC}"; exit;;
                * ) echo "Please type 'y' for yes or 'n' for no.";;
            esac
        done
        echo ""
    else
        echo "${COLOR_GREEN} - No required package dependencies to install.${COLOR_NC}"
        echo ""
    fi
    IFS=$OLDIFS
}

function ensure_brew_packages() {
    ( [[ -z "${1}" ]] || [[ ! -f "${1}" ]] ) && echo "\$1 must be the location of your dependency file!" && exit 1
    DEPS_FILE="${TEMP_DIR}/$(basename ${1})"
    # Create temp file so we can add to it
    cat $1 > $DEPS_FILE
    if [[ ! -z "${2}" ]]; then # Handle EXTRA_DEPS passed in and add them to temp DEPS_FILE
        printf "\n" >> $DEPS_FILE # Avoid needing a new line at the end of deps files
        OLDIFS="$IFS"; IFS=$''
        _2=("$(echo $2 | sed 's/-s /-s\n/g')")
        for ((i = 0; i < ${#_2[@]}; i++)); do echo "${_2[$i]}\n" | sed 's/-s\\n/-s/g' >> $DEPS_FILE; done
    fi
    echo "${COLOR_CYAN}[Ensuring HomeBrew dependencies]${COLOR_NC}"
    OLDIFS="$IFS"; IFS=$','
    # || [[ -n "$nmae" ]]; needed to see last line of deps file (https://stackoverflow.com/questions/12916352/shell-script-read-missing-last-line)
    while read -r name path || [[ -n "$name" ]]; do
        if [[ -f $BREW_PATH/$path ]] || [[ -d $BREW_PATH/$path ]]; then
            echo " - ${name} ${COLOR_GREEN}ok${COLOR_NC}"
            continue
        fi
        # resolve conflict with homebrew glibtool and apple/gnu installs of libtool
        if [[ "${testee}" == "/usr/local/bin/glibtool" ]]; then
            if [ "${tester}" "/usr/local/bin/libtool" ]; then
                echo " - ${name} ${COLOR_GREEN}ok${COLOR_NC}"
                continue
            fi
        fi
        DEPS=$DEPS"${name} "
        echo " - ${name} ${COLOR_RED}NOT${COLOR_NC} found!"
        (( COUNT+=1 ))
    done < $DEPS_FILE
    if [[ $COUNT > 0 ]]; then
        echo ""
        while true; do
            [[ $NONINTERACTIVE == false ]] && printf "${COLOR_YELLOW}Do you wish to install missing dependencies? (y/n)${COLOR_NC}" && read -p " " PROCEED
            echo ""
            case $PROCEED in
                "" ) echo "What would you like to do?";;
                0 | true | [Yy]* )
                    execute "${XCODESELECT}" --install 2>/dev/null || true
                    while true; do
                        [[ $NONINTERACTIVE == false ]] && printf "${COLOR_YELLOW}Do you wish to update HomeBrew packages first? (y/n)${COLOR_NC}" && read -p " " PROCEED
                        case $PROCEED in
                            "" ) echo "What would you like to do?";;
                            0 | true | [Yy]* ) echo "${COLOR_CYAN}[Updating HomeBrew]${COLOR_NC}" && execute brew update; break;;
                            1 | false | [Nn]* ) echo " - Proceeding without update!"; break;;
                            * ) echo "Please type 'y' for yes or 'n' for no.";;
                        esac
                    done
                    echo "${COLOR_CYAN}[Installing HomeBrew Dependencies]${COLOR_NC}"
                    execute eval $BREW install $DEPS
                    IFS="$OIFS"
                break;;
                1 | false | [Nn]* ) echo " ${COLOR_RED}- User aborted installation of required dependencies.${COLOR_NC}"; exit;;
                * ) echo "Please type 'y' for yes or 'n' for no.";;
            esac
        done
    else
        echo "${COLOR_GREEN} - No required package dependencies to install.${COLOR_NC}"
        echo ""
    fi
}

function ensure_apt_packages() {
    ( [[ -z "${1}" ]] || [[ ! -f "${1}" ]] ) && echo "\$1 must be the location of your dependency file!" && exit 1
    DEPS_FILE="${TEMP_DIR}/$(basename ${1})"
    # Create temp file so we can add to it
    cat $1 > $DEPS_FILE
    if [[ ! -z "${2}" ]]; then # Handle EXTRA_DEPS passed in and add them to temp DEPS_FILE
        printf "\n" >> $DEPS_FILE # Avoid needing a new line at the end of deps files
        OLDIFS="$IFS"; IFS=$''
        _2=("$(echo $2 | sed 's/-s /-s\n/g')")
        for ((i = 0; i < ${#_2[@]}; i++)); do echo "${_2[$i]}" >> $DEPS_FILE; done
    fi
    echo "${COLOR_CYAN}[Ensuring package dependencies]${COLOR_NC}"
    OLDIFS="$IFS"; IFS=$','
    # || [[ -n "$testee" ]]; needed to see last line of deps file (https://stackoverflow.com/questions/12916352/shell-script-read-missing-last-line)
    while read -r testee tester || [[ -n "$testee" ]]; do
        if [[ ! -z $(eval $tester $testee 2>/dev/null) ]]; then
            echo " - ${testee} ${COLOR_GREEN}ok${COLOR_NC}"
        else
            DEPS=$DEPS"${testee} "
            echo " - ${testee} ${COLOR_RED}NOT${COLOR_NC} found!"
            (( COUNT+=1 ))
        fi
    done < $DEPS_FILE
    IFS=$OLDIFS
    OLDIFS="$IFS"; IFS=$' '
    if [[ $COUNT > 0 ]]; then
        echo ""
        while true; do
            [[ $NONINTERACTIVE == false ]] && printf "${COLOR_YELLOW}Do you wish to install missing dependencies? (y/n)?${COLOR_NC}" && read -p " " PROCEED
            echo ""
            case $PROCEED in
                "" ) echo "What would you like to do?";;
                0 | true | [Yy]* )
                    for DEP in $DEPS; do
                        install_package $DEP
                    done
                break;;
                1 | false | [Nn]* ) echo " ${COLOR_RED}- User aborted installation of required dependencies.${COLOR_NC}"; exit;;
                * ) echo "Please type 'y' for yes or 'n' for no.";;
            esac
        done
    else
        echo "${COLOR_GREEN} - No required package dependencies to install.${COLOR_NC}"
        echo ""
    fi
    IFS=$OLDIFS
}
