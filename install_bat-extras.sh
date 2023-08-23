#!/bin/bash

# Base definitions
REPOSITORY="https://github.com/eth-p/bat-extras"
SUPPORTED_DISTROS=("arch" "debian" "rocky" "ubuntu")

# Check if launched as root
if [[ ! $EUID -eq 0 ]]
then
	echo "This script needs root privileges. Try sudo $0"
	exit
fi


# Get distro name
DISTRO_ID=$(grep -P ^ID=[\"]?\(.*\)[\"]? /etc/os-release | awk -F"=" '{print $2}' | tr -d '"') 
echo "-> Linux Distro detected: $DISTRO_ID"

# Set bat executable name based on distro
if [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "debian" ]]
then
	BAT_CMD="batcat"
else
	BAT_CMD="bat"
fi

echo "-> Bat command name: $BAT_CMD"


# Verify if bat is installed
function check_bat_installed() {
	if ! command -v $BAT_CMD &> /dev/null
	then
		echo "ERROR: $BAT_CMD command missing."
		exit
	else
		echo "-> $BAT_CMD command found: $(which $BAT_CMD)"
	fi
}


# Create symlink batcat -> bat (Ubuntu/Debian)
function symlink_batcat() {
	if ! command -v bat &> /dev/null
	then
		echo "-> Creating simlink /usr/local/bin/bat -> $(which $BAT_CMD)"
		ln -s $(which $BAT_CMD) /usr/local/bin/bat
	else
		echo "-> bat command or symlink already exists: $(which bat)"
	fi
}


function install_arch_dependencies() {
	
	dependencies="ripgrep entr"
	
        for package in $dependencies; do
		if [[ ! $(pacman -Ql $package 2> /dev/null ) ]]; then
                        echo "    -> Installing $package..."
                        pacman -Sy $package --noconfirm &> /dev/null
                        echo "       ... Done!"
                else
                        echo "    -> $package already installed!"
                fi
        done
}

function install_deb_dependencies() {

	dependencies="git shfmt ripgrep entr delta"

	echo "    -> Refeshing APT cache..."
	apt-get update &> /dev/null
	echo "       ... Done!"

	for package in $dependencies; do
		if [[ ! $(dpkg -l $package 2> /dev/null ) ]]; then
			echo "    -> Installing $package..."
			apt-get install -y $package &> /dev/null
			echo "       ... Done!"
		else
			echo "    -> $package already installed!"
		fi
	done
}


function install_rocky_dependencies () {
	
	dependencies="git"

	echo "    -> Refeshing DNF cache..."
        dnf makecache -y &> /dev/null
        echo "       ... Done!"

        for package in $dependencies; do
                if [[ ! $(rpm -qa | grep -i $package 2> /dev/null ) ]]; then
                        echo "    -> Installing $package..."
                        dnf install -yq $package &> /dev/null
                        echo "       ... Done!"
                else
                        echo "    -> $package already installed!"
                fi
        done

}


function install_dependencies() {
	echo "-> Installing dependencies..."
	if [[ $DISTRO_ID == "arch" ]]; then
		echo "   ... It's Arch! No need to worry about dependencies"
	elif [[ $DISTRO_ID == "ubuntu" ]]; then
		install_deb_dependencies
	elif [[ $DISTRO_ID == "debian" ]]; then
		install_deb_dependencies
	elif [[ $DISTRO_ID == "rocky" ]]; then
		install_rocky_dependencies
	else
                echo "[WARNING] Dependencies installation process for $DISTRO_ID not yet implemented"
        fi
}


function install_from_source() {
	echo "-> Installing from repository: $REPOSITORY"
	ORIGIN_DIR=$(pwd)
	TEMP_DIR=$(mktemp -d)
	cd $TEMP_DIR
	echo "    -> Cloning repository in $TEMP_DIR..."
	git clone -q $REPOSITORY
	echo "       ... Done!"
	cd bat-extras
	echo "    -> Building scripts..."
	bash build.sh --minify=all --compress --install &> /dev/null
	echo "       ... Done!"
	echo "    -> Cleaning temporary files..."
	cd $ORIGIN_DIR
	rm -Rf "$TEMP_DIR"
	echo "       ... Done!"	
}


function install_with_pacman() {
	package="bat-extras"
	echo "-> Installing package $package..."
	if [[ ! $(pacman -Ql $package 2> /dev/null ) ]]; then
		pacman -Sy $package --noconfirm &> /dev/null
		echo "   ... Done!"
	else
		echo "   ... $package already installed!"
	fi
}


function install_scripts() {
	if [[ $DISTRO_ID == "arch" ]]; then
		install_with_pacman
	elif [[ $DISTRO_ID == "debian" ]]; then
		install_from_source
	elif [[ $DISTRO_ID == "ubuntu" ]]; then
		install_from_source
	elif [[ $DISTRO_ID == "rocky" ]]; then
		install_from_source
	else
		echo "[WARNING] Installation process for $DISTRO_ID not yet implemented"
	fi
}


function install_bat_extras() {
	#if [[ ! ${SUPPORTED_DISTROS[@]} =~ ${DISTRO_ID} ]]; then
        #	echo "ERROR: This script does not support your distribution ... yet!"
        #	exit
	#fi
	for distro in ${SUPPORTED_DISTROS[@]}; do
		if [[ $distro == $DISTRO_ID ]]; then
		       IS_SUPPORTED=true
	        fi
 	done

	if [[ ! $IS_SUPPORTED ]]; then
		echo "ERROR: This script does not support your distribution ... yet!"
                exit
	fi
	check_bat_installed

	if [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "debian" ]]; then
        	symlink_batcat
	fi

	install_dependencies
	install_scripts

	echo "All Done!"
}


# Let's Go!
install_bat_extras
