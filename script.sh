#!/bin/bash
#
# Script de Tri de Fichiers par Types
# Version 1.1 du 11 novembre 2023
#
# Description:
#   Ce script Bash permet de trier les fichiers d'un répertoire en fonction de leurs types.
#   Il offre des options pour spécifier les répertoires d'entrée et de sortie, choisir entre le déplacement
#   et la copie des fichiers, activer le mode simulation pour évaluer les actions, et afficher une aide.
#
# Utilisation:
#   Utilisation: script.sh [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-n] [-l repertoire_logs] [-e] [-h]
#
# Options:
#   -i : Chemin du répertoire d'entrée
#   -o : Chemin du répertoire de sortie
#   -m : Déplacer les fichiers au lieu de les copier
#   -s : Mode simulation (évalue les actions sans les exécuter)
#   -n : (no log) Execute silencieusement
#   -l : Rediriger les logs dans un dossier externe
#   -e : Ecrase les fichier de destintations s'ils existent déjà
#   -h : Afficher ce message d'aide
#
# Exemple:
#   script.sh -i /chemin/vers/repertoire_entree -o /chemin/vers/repertoire_sortie -m
#
# Auteur:
#   Simon Bourlier
#

set -euo pipefail

# Déclaration des variables
myself=$(basename "$0") # Nom du script
no_logs=false
move=false
overwrite=false
simulate=false
show_usage=false
logs_dir=""
input_dir="." # Prend par défaut le dossier dans lequel a été appelé le script
# Créer un dossier unique en sortie si celui-ci n'est pas renseigné
output_dir="output_$(printf '%x\n' "$(date '+%Y%m%d%H%M%S')")"


# Déclaration des fonctions
display() {
    if [ "$no_logs" == false ]; then
        [ -n "$logs_dir" ] && printf -- "$(date '+[%Y/%m/%d-%H:%M:%S]') %s\n" "$1" || printf -- "%s\n" "$1"
    fi
}

error() {
    if [ "$2" == -1 ]; then # Erreur non bloquante
        [ -n "$logs_dir" ] && printf "\033[0;31m$(date '+[%Y/%m/%d-%H:%M:%S]') Error: %s\n\033[0m" "$1" >&2
    else                    # Erreur bloquante
        [ -n "$logs_dir" ] && printf "$(date '+[%Y/%m/%d-%H:%M:%S]') Error: %s\n" "$1" >&2
        exit "$2"
    fi
}

usage() {
    if ! $show_usage; then
        cat <<- EOF
    Utilisation: $myself [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-n] [-l repertoire_logs] [-e] [-h]

    Options:
        -i : Chemin du répertoire d'entrée
        -o : Chemin du répertoire de sortie
        -m : Déplacer les fichiers au lieu de les copier
        -s : Mode simulation (évalue les actions sans les exécuter)
        -n : (no log) Execute silencieusement
        -l : Rediriger les logs dans un dossier externe ("" pour prendre .logs/ par défaut)
        -e : Ecrase les fichier de destintations s'ils existent déjà
        -h : Afficher ce message d'aide

    Exemple:
        $myself -mei /chemin/vers/repertoire_entree -o /chemin/vers/repertoire_sortie -l /chemin/vers/logs

		EOF
        show_usage=true
    fi
}

# Gestion des extensions non reconnue par la commande file
unknown_mime_type() { 
    local type=$(echo "$1" | awk -F'/' '{print $2}')
    case "$type" in
        mpeg | zip | mp4 | html)
            echo "$type"
            ;;
        x-shellscript)
            echo "sh"
            ;;
        x-m4a)
            echo "m4a"
            ;;
        plain)
            echo "txt"
            ;;
        *)
            echo "???"
            ;;
    esac
}

# Traiter les options
while getopts "i:o:l:meshn" opt; do
    case "$opt" in
        i) # Chemin du répertoire d'entrée
            input_dir="$OPTARG"
            ;;
        o) # Chemin du répertoire de sortie
            output_dir="$OPTARG"
            ;;
        m) # Déplacer les fichiers au lieu de les copier
            move=true
            ;;
        e) # Ecrase les fichier de destintations s'ils existent déjà
            overwrite=true
            ;;
        s) # Mode simulation (évalue les actions sans les exécuter)
            simulate=true
            ;;
        n) # no logs
            no_logs=true
            ;;
        l) # Rediriger les logs dans un dossier externe
            [ -n "$OPTARG" ] && logs_dir="$OPTARG" || logs_dir=".logs"
            mkdir -p "$logs_dir"
            exec > >(tee -a "$logs_dir/out.log") 2> >(tee -a "$logs_dir/error.log")
            ;;
        h) # Afficher le message d'aide
            usage
            exit 0;
            ;;
        \?)
            error "Utilisation: $myself [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-n] [-l repertoire_logs] [-e] [-h]"
            ;;
    esac
done

# Vérifier si le dossier d'entrée existe
[ ! -d "$input_dir" ] && error "Le dossier spécifié n'existe pas." 1

# Parcourir le dossier et ses sous-dossiers
files=$(find "$input_dir" -type f)
total_files=$(display "$files" | wc -l | sed -e 's/^ *//;s/ *$//')
longueurFormat="%0${#total_files}d"
processed_files=0
# Traiter les fichiers
for file in $files; do
    mime_type=$(file -b --mime-type $file | sed -e 's/^ *//;s/ *$//')
    fileExt="$(file -b --extension $file | awk -F'/' '{print $1}' | sed -e 's/^ *//;s/ *$//')"
    # Gestion des extensions inconnus par file
    [ $fileExt == "???" ] && fileExt="$(unknown_mime_type "$mime_type")" && [ $fileExt == "???" ] && error "Extension pour $file type $mime_type non reconnue" -1 &&  fileExt="" || fileExt=".$fileExt"
    # Récupérer les variables utiles
    fileName=$(basename "$file")
    destination_dir="$output_dir/$mime_type"

    # Vérifier si le fichier de destination existe
    if [ "$overwrite" == false ] && [ -e "$destination_dir/$fileName$fileExt" ]; then
        # Renommer le fichier en ajoutant un compteur
        cpt=1
        while [ -e "$destination_dir/$fileName.$cpt$fileExt" ]; do
            ((cpt += 1))
        done
        fileName="$fileName.$cpt"
    fi
    
    # Logs
    [ "$move"  == true ] && verb="Déplacement" || verb="Copie"
    ((processed_files += 1))
    display "[$(printf $longueurFormat $processed_files)/$total_files] ($fileExt) $verb de \"$file\" → \"$destination_dir/$fileName$fileExt\"" # Logs de deplacement/copie du fichier

    # Action
    if [ "$simulate" == false ]; then
        mkdir -p "$destination_dir"
        [ "$move"  == true ] && mv -f "$file" "$destination_dir/$fileName$fileExt" || cp -f "$file" "$destination_dir/$fileName$fileExt" # Déplacement/Copie du fichier
    fi
done

display "Tri effectué avec succès."
