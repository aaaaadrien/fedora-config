#! /usr/bin/env bash

#################
### VARIABLES ###
#################

# Fichier de log
LOGFILE="/tmp/config-progress.log"

# Détection DNF version
DNFVERSION="$(readlink $(which dnf))"

# Version FEDORA
FC0=$(rpm -E %fedora)

# Version Enterprise Linux
EL0=$(rpm -E %{rhel})

# Version RHEL
RH0=$(rpm -E %{rhel})

# Version Alma Linux
AL0=$(rpm -E %{?almalinux})

# Détection Fedora
if [[ $FC0 =~ ^[0-9]+$ ]]
then
    ISFC=1
else
    ISFC=0
fi

# Détection Enterprise Linux
if [[ $EL0 =~ ^[0-9]+$ ]]
then
    ISEL=1
else
    ISEL=0
fi

# Détection RHEL
if [[ $RH0 =~ ^[0-9]+$ && -z $AL0 ]]
then
    ISRH=1
else
    ISRH=0
fi

# Détection Alma Linux
if [[ $AL0 =~ ^[0-9]+$ ]]
then
    ISAL=1
else
    ISAL=0
fi

# Version Fedora suivante 
if [[ $ISFC -eq 1 ]]
then
	FC1=$(($FC0 + 1))
fi

# Définition du fichier reposextra.list
if [[ $ISFC -eq 1 ]]
then
	RPELIST="reposextra-fc.list"
fi
if [[ $ISEL -eq 1 ]]
then
	RPELIST="reposextra-el.list"
fi

# Définition du fichier codec.list
if [[ $ISFC -eq 1 ]]
then
	CDCLIST="codec-fc.list"
fi
if [[ $ISEL -eq 1 ]]
then
	CDCLIST="codec-el.list"
fi

# Définition du fichier packages.list
if [[ $ISFC -eq 1 ]]
then
	PKGLIST="packages-fc.list"
fi
if [[ $ISEL -eq 1 ]]
then
	PKGLIST="packages-el.list"
fi

# Définition du fichier flatpak.list
if [[ $ISFC -eq 1 ]]
then
	FPKLIST="flatpak-fc.list"
fi
if [[ $ISEL -eq 1 ]]
then
	FPKLIST="flatpak-el.list"
fi

# Définition du fichier gnome.list
if [[ $ISFC -eq 1 ]]
then
	GNMLIST="gnome-fc.list"
fi
if [[ $ISEL -eq 1 ]]
then
	GNMLIST="gnome-el.list"
fi

# Définition RPM Fusion
if [[ $ISFC -eq 1 ]]
then
	RPMFUSIONCOMP="rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted"
fi
if [[ $ISEL -eq 1 ]]
then
	RPMFUSIONCOMP=""
fi

# Définition GNOME
if [[ $ISFC -eq 1 ]]
then
	if rpm -q fedora-release-workstation &> /dev/null
	then
		ISGNOME=1	
	fi
fi
if [[ $ISEL -eq 1 ]]
then
	if rpm -q gnome-shell &> /dev/null
	then
		ISGNOME=1	
	fi
fi

#####################
### FIN VARIABLES ###
#####################


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

check_repo_dnf()
{
	if [[ $(dnf repolist | grep -c $1) -eq 0 ]]
	then
		return 1
	else
		return 0
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
enable_repo()
{
	dnf config-manager --set-enabled "$1" > /dev/null
}
check_pkg()
{
	rpm -q "$1" > /dev/null
}
add_pkg()
{
	dnf install -y --nogpgcheck "$1" >> "$LOGFILE" 2>&1
}

del_pkg()
{
	if [[ "${DNFVERSION}" == "dnf-3" ]]
	then
		dnf autoremove -y "$1" >> "$LOGFILE" 2>&1
	fi
	if [[ "${DNFVERSION}" == "dnf5" ]]
	then
		dnf remove -y "$1" >> "$LOGFILE" 2>&1
	fi
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
check_copr()
{
	if [[ ${DNFVERSION} == "dnf-3" ]]
	then
		COPR_ENABLED=$(dnf copr list --enabled | grep -c "$1")
	fi
	if [[ ${DNFVERSION} == "dnf5" ]]
	then
		COPR_ENABLED=$(dnf copr list | grep -v '(disabled)' | grep -c "$1")
	fi
	return $COPR_ENABLED
}
add_copr()
{
	dnf copr enable -y "$1" > /dev/null 2>&1
}

refresh_cache()
{
	dnf check-update --refresh systemd > /dev/null 2>&1
}
refresh_cache_testing()
{
	dnf check-update --enablerepo=*updates-testing systemd > /dev/null 2>&1
}
check_updates_rpm()
{
	yes n | dnf upgrade
}
check_updates_testing_rpm()
{
	yes n | dnf upgrade --enablerepo=*updates-testing
}
check_updates_flatpak()
{
	yes n | flatpak update
}
need_reboot()
{
	if [[ ${DNFVERSION} == "dnf-3" ]]
	then
		needs-restarting -r >> "$LOGFILE" 2>&1
		NEEDRESTART="$?"
	fi
	if [[ ${DNFVERSION} == "dnf5" ]]
	then
		dnf needs-restarting -r >> "$LOGFILE" 2>&1
		NEEDRESTART="$?"
	fi
	return $NEEDRESTART
}
ask_reboot()
{
	echo -n -e "\033[5;33m/\ REDÉMARRAGE NÉCESSAIRE\033[0m\033[33m : Voulez-vous redémarrer le système maintenant ? [y/N] : \033[0m"
	read rebootuser
	rebootuser=${rebootuser:-n}
	if [[ ${rebootuser,,} == "y" ]]
	then
		echo -e "\n\033[0;35m Reboot via systemd ... \033[0m"
		sleep 2
		systemctl reboot
		exit
	fi
	if [[ ${rebootuser,,} == "k" ]]
	then
		kexec_reboot
	fi
}

kexec_reboot()
{
	echo -e "\n\033[1;4;31mEXPERIMENTAL :\033[0;35m Reboot via kexec ... \033[0m"	
	LASTKERNEL=$(rpm -q kernel --qf "%{INSTALLTIME} %{VERSION}-%{RELEASE}.%{ARCH}\n" | sort -nr | awk 'NR==1 {print $2}')
	kexec -l /boot/vmlinuz-$LASTKERNEL --initrd=/boot/initramfs-$LASTKERNEL.img --reuse-cmdline
	sleep 0.5
	# kexec -e
	systemctl kexec
	exit
}


ask_maj()
{
	echo -n -e "\n\033[36mVoulez-vous lancer les MàJ maintenant ? [y/offline/N] : \033[0m"
	read startupdate
	startupdate=${startupdate:-n}
	echo ""
	if [[ ${startupdate,,} == "y" ]]
	then
		bash "$0"
	fi
	if [[ ${startupdate,,} == "offline" ]]
	then
		bash "$0" offline
	fi
}

offline_dl()
{
	dnf upgrade -y --offline >> "$LOGFILE" 2>&1
}

offline_ask()
{
	echo -n -e "\n\033[36mVoulez-vous rebooter (r) ou arrêter (s) pour appliquer les MàJ maintenant ? [r/s/N] : \033[0m"
	read offlineupgrade
	offlineupgrade=${offlineupgrade:-n}
	if [[ ${offlineupgrade,,} == "r" ]]
	then
		dnf offline reboot
		exit
	fi
	if [[ ${offlineupgrade,,} == "s" ]]
	then
		dnf offline reboot --poweroff
		exit
	fi

	echo -n -e "\n\033[33mPour appliquer les MàJ plus tard : dnf offline reboot\033[0m \n"
}

upgrade_fc()
{
	CHECKFCRELEASE="https://dl.fedoraproject.org/pub/fedora/linux/releases"
	if [[ "$1" = "beta" ]]
	then
		CHECKFCRELEASE="https://dl.fedoraproject.org/pub/fedora/linux/development"
	fi

	if curl --fail -s --output /dev/null $CHECKFCRELEASE/$FC1
	then
		echo "Lancement de l'upgrade $FC0 -> $FC1"
		if dnf system-upgrade --releasever=$FC1 download
		then
			dnf system-upgrade reboot
		else
			echo -e "\033[31mERREUR lors de la phase préparatoire. Abandon! \033[0m"
			exit 3;
		fi
	else
		echo -e "\033[33mLa version $FC1 n'est pas notée stable. Abandon! \033[0m"
		exit 4;
	fi
}

#####################
### FIN FONCTIONS ###
#####################


####################
### DEBUT SCRIPT ###
####################

# Verif option
if [[ -z "$1" ]]
then
	echo "OK" > /dev/null
elif [[ "$1" == "coffee" ]] || [[ "$1" == "check" ]] || [[ "$1" == "testing" ]] || [[ "$1" == "upgrade" ]] || [[ "$1" == "scriptupdate" ]] || [[ "$1" == "offline" ]]
then
	echo "OK" > /dev/null
else
	echo "Usage incorrect du script :"
	echo "- $(basename $0)                : Lance la config et/ou les mises à jour"
	echo "- $(basename $0) check          : Vérifie les mises à jour disponibles et propose de les lancer"
	echo "- $(basename $0) testing        : Vérifie les mises à jour disponibles en test (Fedora uniquement)"
	echo "- $(basename $0) upgrade        : Lance la mise à niveau de Fedora vers la version suivante"
	echo "- $(basename $0) offline        : Met à jour les RPM en mode offline"
	echo "- $(basename $0) scriptupdate   : Met à jour le script depuis Github"
	exit 1;
fi

# Easter Egg
if [[ "$1" = "coffee" ]]
then
	echo "Oui ce script fait aussi le café !"
	echo ""
	echo '    (  )   (   )  )'
	echo '     ) (   )  (  ('
	echo '     ( )  (    ) )'
	echo '     _____________'
	echo '    <_____________> ___'
	echo '    |             |/ _ \'
	echo '    |               | | |'
	echo '    |               |_| |'
	echo ' ___|             |\___/'
	echo '/    \___________/    \'
	echo '\_____________________/'
	echo ""
	echo "Impressionnant n'est ce pas !?"

	exit 0;
fi

# Upgrade Fedora
if [[ "$1" = "upgrade" ]]
then
	if [[ $ISFC -eq 1 ]]
	then
		upgrade_fc $2
	else
		echo -e "\033[31mERREUR\033[0m Fedora non détectée"
		exit 1;
	fi
fi

# Script Update
if [[ "$1" = "scriptupdate" ]]
then
	echo $0
	wget -O- https://raw.githubusercontent.com/aaaaadrien/fedora-config/refs/heads/main/config.sh > "$0"
	chmod +x "$0"

	wget -O- -q https://raw.githubusercontent.com/aaaaadrien/fedora-config/refs/heads/main/CHANGELOG.txt | head

	exit 0;
fi

# Tester si root
if [[ $(id -u) -ne "0" ]]
then
	echo -e "\033[31mERREUR\033[0m Lancer le script avec les droits root (su - root ou sudo)"
	exit 1;
fi

# Tester si bien Fedora Workstation
#if [[ $ISFC -eq 1 ]]
#then
#	if ! check_pkg fedora-release-workstation
#	then
#		echo -e "\033[31mERREUR\033[0m Seule Fedora Workstation (GNOME) est supportée !"
#		exit 2;
#	fi
#fi


# Infos fichier log
echo -e "\033[36m"
echo "Pour suivre la progression des mises à jour : tail -f $LOGFILE"
echo -e "\033[0m"

# Date dans le log
echo '-------------------' >> "$LOGFILE"
date >> "$LOGFILE"


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
	check_updates_rpm

	echo "03- - Mises à jour disponibles FLATPAK : "
	check_updates_flatpak

	ask_maj

	exit;
fi

## CAS CHECK-UPDATES-TESTING
if [[ "$1" == "testing" && $ISFC -eq 1 ]]
then
	echo -n "01- - Refresh du cache : "
	refresh_cache_testing
	check_cmd
	
	echo "02- - Mises à jour disponibles RPM TESTING : "
	check_updates_testing_rpm

	echo -e "\n \033[36mRAPPEL : Pas de MàJ testing gérée par le script ! Pour upgrader un paquet en testing : " 
	echo -e "         dnf upgrade --enablerepo=*updates-testing paquet1 paquet2 \033[0m \n"

	exit;
fi

## CAS OFFLINE UPGRADE
if [[ "$1" = "offline" ]]
then
	echo -n "01- - Refresh du cache : "
	refresh_cache
	check_cmd

	echo -n "02- - Téléchargement des RPM Pour MàJ Offline : "
	offline_dl
	check_cmd

	offline_ask

	exit;
fi

### CONF DNF
echo "01- Vérification configuration DNF"
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

echo -n "- - - Refresh du cache : "
refresh_cache
check_cmd

if [[ $ISFC -eq 1 ]]
then
	if ! check_pkg "dnf-utils"
	then
		echo -n "- - - Installation dnf-utils : "
		add_pkg "dnf-utils"
		check_cmd
	fi
fi
if [[ $ISEL -eq 1 ]]
then
	if ! check_pkg "yum-utils"
	then
		echo -n "- - - Installation yum-utils : "
		add_pkg "yum-utils"
		check_cmd
	fi
fi

### MAJ RPM
echo -n "02- Mise à jour du système DNF : "
dnf update -y >> "$LOGFILE" 2>&1
check_cmd


### MAJ FP
echo -n "03- Mise à jour du système FLATPAK : "
flatpak update --noninteractive >> "$LOGFILE"  2>&1
check_cmd

# Verif si reboot nécessaire
if ! need_reboot
then
	ask_reboot
fi

### CONFIG DEPOTS
echo "04- Vérification configuration des dépôts"
## EPEL
if [[ $ISEL -eq 1 ]]
then
	if ! check_pkg epel-release
	then
		echo -n "- - - Installation EPEL : "
		add_pkg "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm"
		check_cmd
	fi
fi

# CRB
if [[ $ISEL -eq 1 ]]
then
	if [[ $ISRH -eq 1 ]]
	then
		if ! check_repo_dnf "codeready-builder-for-rhel-$RH0-x86_64-rpms" 
		then
			echo -n "- - - Activation Code Ready Builder : "
			enable_repo "codeready-builder-for-rhel-$RH0-x86_64-rpms"
			check_cmd
		fi
	fi
	if [[ $ISAL -eq 1 ]]
	then
		if ! check_repo_dnf "crb"
		then
			echo -n "- - - Activation Code Ready Builder : "
			enable_repo "crb"
			check_cmd
		fi
	fi
fi

## COPR PERSO
if [[ $ISFC -eq 1 ]]
then
	if check_copr 'adriend/fedora-apps'
		then
		echo -n "- - - Activation COPR adriend/fedora-apps : "
		add_copr "adriend/fedora-apps"
		check_cmd
	fi
fi
if [[ $ISEL -eq 1 ]]
then
	if check_copr 'adriend/el-apps'
		then
		echo -n "- - - Activation COPR adriend/el-apps : "
		add_copr "adriend/el-apps"
		check_cmd
	fi
fi

## RPMFUSION
if [[ $ISFC -eq 1 ]]
then
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
fi

if [[ $ISEL -eq 1 ]]
then
	if ! check_pkg rpmfusion-free-release
	then
		echo -n "- - - Installation RPM Fusion Free : "
		add_pkg "https://download1.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm"
		check_cmd
	fi
	if ! check_pkg rpmfusion-nonfree-release
	then
		echo -n "- - - Installation RPM Fusion Nonfree : "
		add_pkg "https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm"
		check_cmd
	fi
fi

## VIVALDI
if [[ $(grep -c 'vivaldi:on' $ICI/$RPELIST) == "1" ]]
then
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
fi

## GOOGLE CHROME
if [[ $(grep -c 'googlechrome:on' $ICI/$RPELIST) == "1" ]]
then
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
fi

## MICROSOFT
if [[ $(grep -c 'microsoft:on' $ICI/$RPELIST) == "1" ]]
then
	if ! check_repo_file microsoft-prod.repo
	then
		if [[ $ISEL -eq 1 ]]
		then
			MSPRODOS="rhel/$RH0"
		fi
		if [[ $ISFC -eq 1 ]]
		then
			MSPRODOS="fedora/\$releasever"
		fi

		echo -n "- - - Installation Microsoft Prod Repo : "
		echo "[packages-microsoft-com-pro]
		name=Microsoft Production
		baseurl=https://packages.microsoft.com/$MSPRODOS/prod/
		enabled=1
		gpgcheck=1
		gpgkey=https://packages.microsoft.com/keys/microsoft.asc" 2>/dev/null > /etc/yum.repos.d/microsoft-prod.repo
		check_cmd
		sed -e 's/\t//g' -i /etc/yum.repos.d/microsoft-prod.repo
	fi
fi

# BRAVE
if [[ $(grep -c 'brave:on' $ICI/$RPELIST) == "1" ]]
then
	if [[ -e /etc/yum.repos.d/brave-browser.repo &&  $(grep -c 'enabled=0' /etc/yum.repos.d/brave-browser.repo) -eq 1 ]]
	then
		rm -f /etc/yum.repos.d/brave-browser.repo
	fi
	if ! check_repo_file brave-browser.repo
	then
		echo -n "- - - Installation Brave Repo : "
		echo "[brave-browser]
		name=Brave Browser
		enabled=1
		gpgcheck=1
		gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
		baseurl=https://brave-browser-rpm-release.s3.brave.com/\$basearch" 2>/dev/null > /etc/yum.repos.d/google-chrome.repo
		check_cmd
		sed -e 's/\t//g' -i /etc/yum.repos.d/brave-browser.repo
	fi
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
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_pkg "$p"
		then
			echo -n "- - - Installation CoDec $p : "
			add_pkg "$p"
			check_cmd
		fi
	fi
	
	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_pkg "$p"
		then
			echo -n "- - - Suppression CoDec $p : "
			del_pkg "$p"
			check_cmd
		fi
	fi
done < "$ICI/$CDCLIST"

### INSTALL OUTILS GNOME
if [[ $ISGNOME -eq 1 ]]
then
	echo "08- Vérification composants GNOME"
	while read -r line
	do
		if [[ "$line" == add:* ]]
		then
			p=${line#add:}
			if ! check_pkg "$p"
			then
				echo -n "- - - Installation composant GNOME $p : "
				add_pkg "$p"
				check_cmd
			fi
		fi
		
		if [[ "$line" == del:* ]]
		then
			p=${line#del:}
			if check_pkg "$p"
			then
				echo -n "- - - Suppression composant GNOME $p : "
				del_pkg "$p"
				check_cmd
			fi
		fi
	done < "$ICI/$GNMLIST"
else
	echo "08- Vérification composants ENVIRONNEMENT BUREAU"
fi

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
done < "$ICI/$PKGLIST"

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
done < "$ICI/$FPKLIST"

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
	echo -n "- - - Définition du swapiness à 2 : "
	echo "vm.swappiness = 2" >> "$SYSCTLFIC"
	check_cmd
fi
if [[ $(grep -c 'kernel.sysrq' "$SYSCTLFIC") -lt 1 ]]
then
	echo -n "- - - Définition des sysrq à 1 : "
	echo "kernel.sysrq = 1" >> "$SYSCTLFIC"
	check_cmd
fi

#PROFILEFIC="/etc/profile.d/adrien.sh"
#if [[ ! -e "$PROFILEFIC" ]]
#then
#        echo -n "- - - Création du fichier $PROFILEFIC : "
#        touch "$PROFILEFIC"
#        check_cmd
#fi
#if [[ $(grep -c 'QT_QPA_PLATFORMTHEME=' "$PROFILEFIC") -lt 1 ]]
#then
#	echo -n "- - - Définition du thème des applis KDE à gnome : "
#	echo "export QT_QPA_PLATFORMTHEME=gnome" >> "$PROFILEFIC"
#	check_cmd
#fi
#if [[ $(grep -c 'QT_QPA_PLATFORM=' "$PROFILEFIC") -lt 1 ]]
#then
#	echo -n "- - - Fix du décalage des menus des applis Qt sous Wayland : "
#	echo "export QT_QPA_PLATFORM=xcb" >> "$PROFILEFIC"
#	check_cmd
#fi

if ! check_pkg "pigz"
then
	echo -n "- - - Installation pigz : "
	add_pkg "pigz"
	check_cmd
fi
if [[ ! -e /usr/local/bin/gzip ]]
then
	echo -n "- - - Configuration gzip multithread : "
	ln -s /usr/bin/pigz /usr/local/bin/gzip
	check_cmd
fi
if [[ ! -e /usr/local/bin/gunzip ]]
then
	echo -n "- - - Configuration gunzip multithread : "
	ln -s /usr/local/bin/gzip /usr/local/bin/gunzip
	check_cmd
fi
if [[ ! -e /usr/local/bin/zcat ]]
then
	echo -n "- - - Configuration zcat multithread : "
	ln -s /usr/local/bin/gzip /usr/local/bin/zcat
	check_cmd
fi


if ! check_pkg "pbzip2"
then
	echo -n "- - - Installation pbzip2 : "
	add_pkg "pbzip2"
	check_cmd
fi
if [[ ! -e /usr/local/bin/bzip2 || $(readlink -f /usr/local/bin/bzip2) == "/usr/bin/lbzip2" ]]
then
	echo -n "- - - Configuration bzip2 multithread : "
	ln -sf /usr/bin/pbzip2 /usr/local/bin/bzip2
	check_cmd
fi
if [[ ! -e /usr/local/bin/bunzip2 ]]
then
	echo -n "- - - Configuration bunzip2 multithread : "
	ln -s /usr/local/bin/bzip2 /usr/local/bin/bunzip2
	check_cmd
fi
if [[ ! -e /usr/local/bin/bzcat ]]
then
	echo -n "- - - Configuration bzcat multithread : "
	ln -s /usr/local/bin/bzip2 /usr/local/bin/bzcat
	check_cmd
fi

# Verif si reboot nécessaire
if ! need_reboot
then
	ask_reboot
fi
