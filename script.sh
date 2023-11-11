#! /usr/bin/env bash
#
# Script de Tri de Fichiers par Types
# Version 1.0 du 11 novembre 2023
#
# Description:
#   Ce script Bash permet de trier les fichiers d'un répertoire en fonction de leurs types.
#   Il offre des options pour spécifier les répertoires d'entrée et de sortie, choisir entre le déplacement
#   et la copie des fichiers, activer le mode simulation pour évaluer les actions, et afficher une aide.
#
# Utilisation:
#   script.sh [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-h]
#
# Options:
#   -i : Chemin du répertoire d'entrée
#   -o : Chemin du répertoire de sortie
#   -m : Déplacer les fichiers au lieu de les copier
#   -s : Mode simulation (évalue les actions sans les exécuter)
#   -h : Afficher ce message d'aide
#
# Exemple:
#   script.sh -i /chemin/vers/repertoire_entree -o /chemin/vers/repertoire_sortie -m
#
# Auteur:
#   Simon Bourlier
#

set -euo pipefail

myself=$(basename "$0")
dir=""
output_dir=""
move=false
simulation=false
show_usage=false

display() {
    printf -- "%s\n" "$1"
}

error() {
    printf "Error: %s\n" "$1" >&2
    exit "$2"
}

usage() {
    if ! $show_usage; then
    	cat <<- EOF
    Utilisation: $myself [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-h]

    Options:
        -i : Chemin du répertoire d'entrée
        -o : Chemin du répertoire de sortie
        -m : Déplacer les fichiers au lieu de les copier
        -s : Mode simulation (évalue les actions sans les exécuter)
        -h : Afficher ce message d'aide

    Exemple:
        $myself -i /chemin/vers/repertoire_entree -o /chemin/vers/repertoire_sortie -m

		EOF
		show_usage=true
    fi
}

# Traiter les options
while getopts "i:o:msh" opt; do
    case $opt in
        i) # Chemin du répertoire d'entrée
            dir="$OPTARG"
            ;;
        o) # Chemin du répertoire de sortie
            output_dir="$OPTARG"
            ;;
        m) # Déplacer les fichiers au lieu de les copier
            move=true
            ;;
        s) # Mode simulation (évalue les actions sans les exécuter)
            simulation=true
            ;;
        h) # Afficher le message d'aide
            usage
            exit 0;
            ;;
        \?)
            error "Utilisation: $myself [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-h]"
            ;;
    esac
done

# Si les dossier ne sont pas spécifiés, utiliser le dossier courant
[ -z "$dir" ] && dir=$(pwd)
[ -z "$output_dir" ] && output_dir=$(pwd)

# Vérifier si le dossier d'entrée existe
[ ! -d "$dir" ] && error "Le dossier scpécifié n'existe pas." 1

# Parcourir le dossier et ses sous-dossiers
find "$dir" -type f -print0 | xargs -0 file -i | while read -r mime_type; do
    # Récupérer les variables
    source_file=$(echo "$mime_type" | awk -F':' '{print $1}')
    fileName=$(basename "$source_file")
    fileExt=$(echo "$mime_type" | awk -F':' '{print $2}' | awk -F'/' '{print $2}' | awk -F';' '{print $1}')
    destination_dir="$output_dir/$(echo "$mime_type" | awk -F': ' '{print $2}' | awk -F'/' '{print $1}' | sed -e 's/^ *//;s/ *$//')"

    # Vérifier si le fichier de destination existe
    if [ -e "$destination_dir/$fileName.$fileExt" ]; then
        # Renommer le fichier en ajoutant un compteur
        cpt=1
        while [ -e "$destination_dir/$fileName.$cpt.$fileExt" ]; do
            ((cpt++))
        done
        fileName="$fileName.$cpt"
    fi

    # Logs
    [ ! -d "$destination_dir" ] && display "Création de \"$destination_dir\"" #Logs de création de dossier
    [ "$move"  == true ] && verb="Déplacement" || verb="Copie"
    display "$verb du fichier \"$source_file\" vers \"$destination_dir/$fileName.$fileExt\"" | sed 's#//*#/#g' #Logs de deplacement/copie du fichier

    # Action
    if [ "$simulation" == false ]; then
        mkdir -p "$destination_dir"  # Crée le dossier s'il n'existe pas
        [ "$move"  == true ] && mv "$source_file" "$destination_dir/$fileName.$fileExt" || cp "$source_file" "$destination_dir/$fileName.$fileExt" #Déplacement/Copie du fichier
    fi
done

display "Tri effectué avec succès."
