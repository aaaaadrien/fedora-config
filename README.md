# fedora-config
My fedora config (from Fedora Workstation). Configure & Update Fedora

**Works only with Fedora Workstation with GNOME desktop environment.**


Ma configuration de Fedora (base Fedora Workstation). Configure & Met à jour Fedora

**Ne fonctionne qu'avec Fedora Workstation disposant de l'environnement de bureau GNOME.**



# Manuel FRANÇAIS

## Liste des fichiers

 **config-fedora.sh** : Script principal 
 
 **gnome.list** : Fichier de paquets à ajouter ou retirer pour personnaliser GNOME (thèmes et extensions)

 **packages.list** : Fichier de paquets à ajouter ou retirer du système

 **flatpak.list** : Fichier de flatpak à ajouter ou retirer du système


## Fonctionnement

Les 4 fichiers mentionnés ci-dessus doivent être dans le même dossier.

Exécuter avec les droits de super-utilisateur le scipt principal :

    ./config-fedora.sh

Celui-ci peut être exécuté plusieurs fois de suite. Si des étapes sont déjà configurées, elles ne le seront pas à nouveau. De fait, le script peut être utilisé pour : 

 - Réaliser la configuration initiale du système
 - Mettre à jour la configuration du système
 - Effectuer les mises à jour des paquets

Il est possible de faire uniquement une vérification des mises à jour (listing des paquets et flatpak à mettre à jour sans appliquer de modifications) via l'option check : 

    ./config-fedora.sh check


Il est possible d'avoir un aperçu des mises à jour disponibles dans les dépôts "testing" via l'option testing : 

    ./config-fedora.sh testing



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

