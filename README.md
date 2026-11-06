# fedora-config
My fedora config (from Fedora Workstation). Configure & Update Fedora

**Works only with Fedora Workstation with GNOME desktop environment.**

*Works with Enterprise Linux, auto detection added (RHEL et Alma Linux)*

-----

Ma configuration de Fedora (base Fedora Workstation). Configure & Met à jour Fedora

**Ne fonctionne qu'avec Fedora Workstation disposant de l'environnement de bureau GNOME.**

*Fonctionne avec Entreprise Linux, détection auto ajoutée (RHEL et Alma Linux)*




# Manuel FRANÇAIS

## Liste des fichiers

 **config-fedora.sh** : Script principal 
 
 **reposextra-fc.list** : Fichier permettant d'installer des repos supplémentaires

 **gnome-fc.list** : Fichier de paquets à ajouter ou retirer pour personnaliser GNOME (thèmes et extensions)

 **packages-fc.list** : Fichier de paquets à ajouter ou retirer du système

 **flatpak-fc.list** : Fichier de flatpak à ajouter ou retirer du système

 **nvidia-fc.list** : Fichier optionnel de paquets NVIDIA à ajouter (Fedora uniquement)

*Il existe les mêmes fichiers avec "-el" utilisés pour Enterprise Linux*


## Fonctionnement

Les 4 fichiers mentionnés ci-dessus doivent être dans le même dossier.

Exécuter avec les droits de super-utilisateur le scipt principal :

    ./config.sh

Celui-ci peut être exécuté plusieurs fois de suite. Si des étapes sont déjà configurées, elles ne le seront pas à nouveau. De fait, le script peut être utilisé pour : 

 - Réaliser la configuration initiale du système
 - Mettre à jour la configuration du système
 - Effectuer les mises à jour des paquets

Il est possible de faire uniquement une vérification des mises à jour (listing des paquets et flatpak à mettre à jour sans appliquer de modifications) via l'option check : 

    ./config.sh check


Il est possible d'avoir un aperçu des mises à jour disponibles dans les dépôts "testing" via l'option testing (Dispo uniquement pour Fedora) : 

    ./config.sh testing



## Appliquer uniquement certaines listes

    sudo ./config.sh files fichier1.list fichier2.list

Seuls les fichiers indiqués sont traités, dans l'ordre donné. Tous sont vérifiés
avant installation. Les lignes `add:paquet` et `del:paquet`, les commentaires et
les lignes vides sont acceptés. Les listes dont le nom commence par `flatpak`
sont traitées avec Flatpak ; les autres sont des listes RPM.

Ce mode ne configure pas les dépôts, ne met pas à jour le système et n'applique
pas les réglages du lancement normal. Les dépôts nécessaires doivent déjà être
installés. Les dépendances des paquets restent gérées par DNF et Flatpak.
Une erreur arrête le traitement, sans annuler les installations précédentes.
Sans argument, le fonctionnement habituel est conservé.

## Opérations réalisées par le script

Le script lancé va effectuer les opérations suivantes : 

 1. Personnaliser la configuration de dnf
 2. Mettre à jour les paquets rpm
 3. Mettre à jour les paquets flatpak + *Proposition de redémarrage du système si nécessaire*
 4. Ajouter les dépôts additionnels au système
 5. Ajouter les composants utiles en provenance de RPM Fusion
 6. Permuter certains composants du système par ceux de RPM Fusion
 7. Ajouter tous les codec en provenance de RPM Fusion
 8. Ajouter les composants indispensables de GNOME
 9. Ajouter ou Supprimer les paquets rpm paramétrés dans le fichier packages.list
 10. Ajouter ou Supprimer les paquets flatpak paramétrés dans le fichier flatpak.list 
 11. Personnaliser la configuration du système + *Proposition de redémarrage du système si nécessaire*


## Pilote NVIDIA (Fedora uniquement)

L'installation est optionnelle : les lignes de `nvidia-fc.list` sont commentées
par défaut. Vérifier la compatibilité de la carte avec le pilote courant RPM
Fusion avant de décommenter les paquets souhaités. `add:akmod-nvidia` est obligatoire.
Les anciennes branches et Fedora Atomic ne sont pas gérées par cette option.

Pour appliquer uniquement cette liste :

    sudo ./config.sh files nvidia-fc.list

Ce mode nécessite RPM Fusion Free et Nonfree déjà installés. La liste est également
prise en compte lors du lancement normal, après la configuration de RPM Fusion.

Le script vérifie la présence d'une carte NVIDIA sur Fedora x86_64 et l'état de
Secure Boot. Si Secure Boot est actif, la clé akmods doit être préparée et enrôlée
au préalable, sinon le script s'arrête. `mokutil` est installé si nécessaire.
Voir https://rpmfusion.org/Howto/Secure%20Boot

Les paquets NVIDIA sont installés avec la vérification GPG activée. Avant la fin,
le script prépare les modules pour le noyau actif et le dernier installé (avec les
paquets `kernel-devel` nécessaires), vérifie leur version et reconstruit les images
de démarrage. En cas d'échec, consulter `/tmp/config-progress.log` et corriger le
problème avant de redémarrer. Aucun redémarrage n'est proposé par le mode `files`.

Après un redémarrage normal, vérifier le pilote avec `nvidia-smi` puis mettre à jour
les Flatpak. Les modes `check`, `testing`, `offline` et `upgrade` ne passent pas par
cette préparation NVIDIA. `scriptupdate` remplace le script par la version d'origine.
