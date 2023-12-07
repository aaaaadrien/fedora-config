#!/bin/bash

#################
### VARIABLES ###
#################
RPMFUSIONCOMP="rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted"
CODEC="gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-good-extras gstreamer1-plugins-bad-free-extras gstreamer1-plugins-ugly-free gstreamer1-plugin-libav gstreamer1-plugins-ugly libdvdcss gstreamer1-plugin-openh264"
GNOMECOMP="gnome-extensions-app gnome-shell-extension-dash-to-dock gnome-shell-extension-appindicator adwaita-qt5 adwaita-qt6 qgnomeplatform-qt5 qgnomeplatform-qt6"
LOGFILE="/tmp/config-fedora.log"
#####################
### FIN VARIABLES ###
#####################


####################
### DEBUT SCRIPT ###
####################
echo -e "\033[36m"
echo "Pour suivre la progression : tail -f $LOGFILE"
echo -e "\033[0m"

# Date dans le log
echo '-------------------' >> "$LOGFILE"
date >> "$LOGFILE"

# Tester si root
if [[ $(id -u) -ne "0" ]]
then
	echo -e "\033[31mERREUR\033[0m Lancer le script avec les droits root (su - root ou sudo)"
	exit 1;
fi

#################
### FONCTIONS ###
#################

check_cmd()
{
if [[ $? -eq 0 ]]
then
    	echo -e "\033[32mOK\033[0m"
else
    	echo -e "\033[31mERREUR\033[0m"
fi
}


check_repo_file()
{
	if [[ -e "/etc/yum.repos.d/$1" ]]
	then
		return 0
	else
		return 1
	fi
}

check_pkg()
{
	rpm -q "$1" > /dev/null
}
add_pkg()
{
	dnf install -y --nogpgcheck "$1" > /dev/null
}

del_pkg()
{
	dnf autoremove -y "$1" > /dev/null
}
swap_pkg()
{
	dnf swap -y "$1" "$2" --allowerasing > /dev/null 2>&1
}
check_flatpak()
{
	flatpak info "$1" > /dev/null 2>&1
}
add_flatpak()
{
	flatpak install flathub --noninteractive -y "$1" > /dev/null 2>&1
}
del_flatpak()
{
	flatpak uninstall --noninteractive -y "$1" > /dev/null && flatpak uninstall --unused  --noninteractive -y > /dev/null
}

refresh_cache()
{
	dnf check-update fedora-release > /dev/null 2>&1
}
check_updates_rpm()
{
	yes n | dnf upgrade
}
check_updates_flatpak()
{
	yes n | flatpak update
}
need_reboot()
{
	needs-restarting -r >> "$LOGFILE" 2>&1
}
#####################
### FIN FONCTIONS ###
#####################


#################
### PROGRAMME ###
#################
ICI=$(dirname "$0")


## CAS CHECK-UPDATES
if [[ "$1" = "check" ]]
then
	echo -n "01- - Refresh du cache : "
	refresh_cache
	check_cmd

	echo "02- - Mises à jour disponibles RPM : "
	echo -e "\033[36m"
	check_updates_rpm
	echo -e "\033[0m"

	echo "03- - Mises à jour disponibles FLATPAK : "
	echo -e "\033[36m"
	check_updates_flatpak
	echo -e "\033[0m"

	exit;
fi


### CONF DNF
echo "01- Vérification configuration DNF"
if [[ $(grep -c 'fastestmirror=' /etc/dnf/dnf.conf) -lt 1 ]]
then
	echo -n "- - - Correction miroirs rapides : "
	echo "fastestmirror=true" >> /etc/dnf/dnf.conf
	check_cmd
fi
if [[ $(grep -c 'max_parallel_downloads=' /etc/dnf/dnf.conf) -lt 1 ]]
then
	echo -n "- - - Correction téléchargements parallèles : "
	echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
	check_cmd
fi
if [[ $(grep -c 'countme=' /etc/dnf/dnf.conf) -lt 1 ]]
then
	echo -n "- - - Correction statistiques : "
	echo "countme=false" >> /etc/dnf/dnf.conf
	check_cmd
fi
if [[ $(grep -c 'deltarpm=' /etc/dnf/dnf.conf) -lt 1 ]]
then
        echo -n "- - - Correction deltarpm désactivés : "
        echo "deltarpm=false" >> /etc/dnf/dnf.conf
        check_cmd
fi
if ! check_pkg "dnf-utils"
then
	echo -n "- - - Installation dnf-utils : "
	add_pkg "dnf-utils"
	check_cmd
fi


### MAJ RPM
echo -n "02- Mise à jour du système DNF : "
dnf update -y >> "$LOGFILE" 2>&1
check_cmd

### MAJ FP
echo -n "03- Mise à jour du système FLATPAK : "
flatpak update --noninteractive >> "$LOGFILE"  2>&1
check_cmd

### CONFIG DEPOTS
echo "04- Vérification configuration des dépôts"
## RPMFUSION
if ! check_pkg rpmfusion-free-release
then
	echo -n "- - - Installation RPM Fusion Free : "
	add_pkg "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
	check_cmd
fi
if ! check_pkg rpmfusion-nonfree-release
then
	echo -n "- - - Installation RPM Fusion Nonfree : "
	add_pkg "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
	check_cmd
fi

## VIVALDI
if ! check_repo_file vivaldi.repo
then
	echo -n "- - - Installation Vivaldi Repo : "
	echo "[vivaldi]
	name=vivaldi
	baseurl=https://repo.vivaldi.com/archive/rpm/x86_64
	enabled=1
	gpgcheck=1
	gpgkey=http://repo.vivaldi.com/archive/linux_signing_key.pub" 2>/dev/null > /etc/yum.repos.d/vivaldi.repo
	check_cmd
	sed -e 's/\t//g' -i /etc/yum.repos.d/vivaldi.repo
fi

## GOOGLE CHROME
if [[ -e /etc/yum.repos.d/google-chrome.repo &&  $(grep -c 'enabled=0' /etc/yum.repos.d/google-chrome.repo) -eq 1 ]]
then
	rm -f /etc/yum.repos.d/google-chrome.repo
fi
if ! check_repo_file google-chrome.repo
then
	echo -n "- - - Installation Google Chrome Repo : "
	echo "[google-chrome]
	name=google-chrome
	baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
	enabled=1
	gpgcheck=1
	gpgkey=https://dl.google.com/linux/linux_signing_key.pub" 2>/dev/null > /etc/yum.repos.d/google-chrome.repo
	check_cmd
	sed -e 's/\t//g' -i /etc/yum.repos.d/google-chrome.repo
fi

## FLATHUB
if [[ $(flatpak remotes | grep -c flathub) -ne 1 ]]
then
	echo -n "- - - Installation Flathub : "
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null
	check_cmd
fi

## COMPOSANTS RPM FUSION
echo "05- Vérification composants RPM Fusion"
for p in $RPMFUSIONCOMP
do
	if ! check_pkg "$p"
	then
		echo -n "- - - Installation composant RPM Fusion $p : "
		add_pkg "$p"
		check_cmd
	fi
done

### SWAPPING DES SOFT 
echo "06- Vérification swapping des composants"

## FFMPEG
if check_pkg "ffmpeg-free"
then
	echo -n "- - - Swapping ffmpeg : "
	swap_pkg "ffmpeg-free" "ffmpeg" 
	check_cmd
fi

## MESA-VA
#if check_pkg "mesa-va-drivers"
#then
#	echo -n "- - - Swapping MESA VAAPI : "
#	swap_pkg "mesa-va-drivers" "mesa-va-drivers-freeworld"
#	check_cmd
#fi

## MESA-VDPAU
#if check_pkg "mesa-vdpau-drivers"
#then
#	echo -n "- - - Swapping MESA VDPAU : "
#	swap_pkg "mesa-vdpau-drivers" "mesa-vdpau-drivers-freeworld"
#	check_cmd
#fi

## INSTALL CODECS
echo "07- Vérification CoDec"
for p in $CODEC
do
	if ! check_pkg "$p"
	then
		echo -n "- - - Installation CoDec $p : "
		add_pkg "$p"
		check_cmd
	fi
done

### INSTALL OUTILS GNOME
echo "08- Vérification composants GNOME"
for p in $GNOMECOMP
do
	if ! check_pkg "$p"
	then
		echo -n "- - - Installation composant GNOME $p : "
		add_pkg "$p"
		check_cmd
	fi
done

### INSTALL/SUPPRESSION RPMS SELON LISTE
echo "09- Gestion des paquets RPM"
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_pkg "$p"
		then
			echo -n "- - - Installation paquet $p : "
			add_pkg "$p"
			check_cmd
		fi
	fi
	
	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_pkg "$p"
		then
			echo -n "- - - Suppression paquet $p : "
			del_pkg "$p"
			check_cmd
		fi
	fi
done < "$ICI/packages.list"

### INSTALL/SUPPRESSION FLATPAK SELON LISTE
echo "10- Gestion des paquets FLATPAK"
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_flatpak "$p"
		then
			echo -n "- - - Installation flatpak $p : "
			add_flatpak "$p"
			check_cmd
		fi
	fi
	
	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_flatpak "$p"
		then
			echo -n "- - - Suppression flatpak $p : "
			del_flatpak "$p"
			check_cmd
		fi
	fi
done < "$ICI/flatpak.list"

### Vérif configuration système
echo "11- Configuration personnalisée du système"
SYSCTLFIC="/etc/sysctl.d/adrien.conf"
if [[ ! -e "$SYSCTLFIC" ]]
then
	echo -n "- - - Création du fichier $SYSCTLFIC : "
	touch "$SYSCTLFIC"
	check_cmd
fi
if [[ $(grep -c 'vm.swappiness' "$SYSCTLFIC") -lt 1 ]]
then
	echo -n "- - - Définition du swapiness à 10 : "
	echo "vm.swappiness = 10" >> "$SYSCTLFIC"
	check_cmd
fi
if [[ $(grep -c 'kernel.sysrq' "$SYSCTLFIC") -lt 1 ]]
then
	echo -n "- - - Définition des sysrq à 1 : "
	echo "kernel.sysrq = 1" >> "$SYSCTLFIC"
	check_cmd
fi

PROFILEFIC="/etc/profile.d/adrien.sh"
if [[ ! -e "$PROFILEFIC" ]]
then
        echo -n "- - - Création du fichier $PROFILEFIC : "
        touch "$PROFILEFIC"
        check_cmd
fi
if [[ $(grep -c 'QT_QPA_PLATFORMTHEME=' "$PROFILEFIC") -lt 1 ]]
then
	echo -n "- - - Définition du thème des applis KDE à gnome : "
	echo "export QT_QPA_PLATFORMTHEME=gnome" >> "$PROFILEFIC"
	check_cmd
fi
if [[ $(grep -c 'QT_QPA_PLATFORM=' "$PROFILEFIC") -lt 1 ]]
then
	echo -n "- - - Fix du décalage des menus des applis Qt sous Wayland : "
	echo "export QT_QPA_PLATFORM=xcb" >> "$PROFILEFIC"
	check_cmd
fi

# Fin des actions automatisées
echo ""

# Verif si reboot nécessaire
if ! need_reboot
then
	echo -n -e "\033[43m/\ REDÉMARRAGE NÉCESSAIRE\033[0m\033[33m : Voulez-vous redémarrer le système maintenant ? [y/N] : "
	read rebootuser
	rebootuser=${rebootuser:-n}
	echo "$rebootuser"
	if [[ ${rebootuser,,} == "y" ]]
	then
		systemctl reboot
	fi
fi
