#!/bin/bash
#
# Script de Tri de Fichiers par Types
# Version 1.3 du 16 novembre 2023
#
# Description:
# Ce script Bash permet de trier les fichiers d'un répertoire en fonction de leurs types.
# Il offre des options pour spécifier les répertoires d'entrée et de sortie, choisir entre le déplacement et la copie des fichiers,
# choisir d'écraser les fichiers déjà existant ou de les renommer, activer le mode simulation pour évaluer les actions,
# effectuer le traitement silencieusement, sortir les logs dans un fichier de log externe et afficher une aide.
# 
# Utilisation:
#   Utilisation: script.sh [-i repertoire_entree] [-o repertoire_sortie] [-m] [-e] [-s] [-n] [-l repertoire_logs] [-h]
#
# Options:
#   -i : Chemin du répertoire d'entrée
#   -o : Chemin du répertoire de sortie
#   -e : Ecrase les fichier de destintations s'ils existent déjà
#   -m : Déplacer les fichiers au lieu de les copier
#   -s : Mode simulation (évalue les actions sans les exécuter)
#   -n : (no log) Execute silencieusement
#   -l : Rediriger les logs dans un dossier externe
#   -h : Afficher ce message d'aide
#
# Exemple:
#   script.sh -mei /chemin/vers/repertoire_entree -o /chemin/vers/repertoire_sortie -l ./vers/logs
#
# Auteur:
#   Simon Bourlier
#

set -euo pipefail

###########################
# Variables et constantes #
###########################
RED="\033[0;31m"
RESET_COLOR="\033[0m"

myself=$(basename "$0") # Nom du script
no_logs=false
move=false
overwrite=false
simulate=false
logs_dir=""
input_dir="."                                                  # Prend par défaut le dossier dans lequel a été appelé le script
output_dir="output_$(printf '%x\n' "$(date '+%Y%m%d%H%M%S')")" # Créer un dossier unique en sortie si celui-ci n'est pas renseigné
show_usage=false

#############################
# Déclaration des fonctions #
#############################
display() {
    if [ "$no_logs" == false ]; then
        [ -n "$logs_dir" ] && printf -- "$(date '+[%d/%m/%Y-%H:%M:%S]') %s\n" "$1" || printf -- "%s\n" "$1"
    fi
}

error() {
    [ -n "$logs_dir" ] && >&2 printf -- "$(date '+[%d/%m/%Y-%H:%M:%S]') Error: %s\n" "$1" || >&2 printf -- "%Error: s\n" "$1"
    exit "$2"
}

warning() {
    if [ "$no_logs" == false ]; then
        [ -n "$logs_dir" ] && >&2 printf "$(date '+[%d/%m/%Y-%H:%M:%S]') $RED%s\n$RESET_COLOR" "$1" || >&2 printf "$RED%s\n$RESET_COLOR" "$1"
    fi
}

usage() {
    if ! $show_usage; then
        cat <<-EOF
    Utilisation: $myself [-i repertoire_entree] [-o repertoire_sortie] [-m] [-e] [-s] [-n] [-l repertoire_logs] [-h]

    Options:
        -i : Chemin du répertoire d'entrée
        -o : Chemin du répertoire de sortie
        -m : Déplacer les fichiers au lieu de les copier
        -e : Ecrase les fichier de destintations s'ils existent déjà
        -s : Mode simulation (évalue les actions sans les exécuter)
        -n : (no log) Execute silencieusement
        -l : Rediriger les logs dans un dossier externe ("" pour prendre .logs/ par défaut)
        -h : Afficher ce message d'aide

    Exemple:
        $myself -mei /chemin/vers/repertoire_entree -o /chemin/vers/repertoire_sortie -l ./vers/logs

		EOF
        show_usage=true
    fi
}

# Gestion des extensions non reconnue par la commande file
getExtension() {
    local FILE="$1"
    local TYPE=$(echo "$2" | awk -F'/' '{print $2}')
    local fileExt="$(file -b --extension $file | awk -F'/' '{print $1}' | sed -e 's/^ *//;s/ *$//')"
    # Tente de reconnaitre les extensions inconnues en fonction de son mime_type
    if [ "$fileExt" == "???" ]; then
        # Si le script est lancé depuis un linux, tente de chercher depuis le fichier /etc/mime.types
        if  [ -e "/etc/mime.types" ]; then
            fileExt=$(grep -m1 "$mime_type" /etc/mime.types | awk -F' ' '{print $2}')
            if [ -n "$fileExt" ]; then
                echo ".$fileExt"
                break
            else
                fileExt="???"
            fi
        fi
        # Sinon gère les quelques exceptions connus au cas par cas et affiche un warning s'il n'est pas trouvé
        if [ "$fileExt" == "???" ]; then
            case "$TYPE" in
                mpeg | zip | mp4 | html)
                    echo ".$TYPE"
                    ;;
                x-shellscript)
                    echo ".sh"
                    ;;
                x-m4a)
                    echo ".m4a"
                    ;;
                plain)
                    echo ".txt"
                    ;;
                *)
                    warning "Extension pour $file type $mime_type non reconnue"
                    echo ""
                    ;;
            esac
        fi
    else
        echo ".$fileExt"
    fi
}

#######################
# Lecture des options #
#######################
while getopts "i:o:mesnl:h" opt; do
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
        ;;
    h) # Afficher le message d'aide
        usage
        exit 0
        ;;
    \?)
        error "Utilisation: $myself [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-n] [-l repertoire_logs] [-e] [-h]"
        ;;
    esac
done

#################
# Vérifications #
#################
# Vérifier si le dossier d'entrée existe et créer le dossier de sortie
[ ! -d "$input_dir" ] && error "Le dossier spécifié n'existe pas." 1
# Vérifier si les commandes utiles sont disponibles sur le systeme
commands=("file" "awk" "sed" "mkdir" "cp" "mv" "realpath")
for cmd in "${commands[@]}"; do
    which "$cmd" >/dev/null 2>&1 || error "La commande '$cmd' est requise mais n'est pas installée. Abandon." 1
done

# Vérifier que le dossier n'est pas un parent du dossier de sortie
if [ "$simulate" == false ]; then
    mkdir -p "$output_dir"
    if [[ $(realpath "$output_dir") == $(realpath "$input_dir")* ]]; then
        if [ "$overwrite" == true ]; then
            error "$input_dir/ est un dossier parent de $output_dir/" 1
        else
            while true; do
                warning "$input_dir/ est un dossier parent de $output_dir/"
                read -p "Voulez-vous continuer ? [O/N]" choix
                case "$choix" in
                    [Oo])
                        break
                        ;;
                    [Nn])
                        error "Abandon" 0
                        break
                        ;;
                    *)
                        display "Choix non valide, Voulez-vous continuer ? [O/N]"
                        ;;
                esac
            done
        fi
    fi
fi

##############
# Traitement #
##############
# Créer le dossier de log et redirige les logs
[ -n "$logs_dir" ] && mkdir -p "$logs_dir" && exec > "$logs_dir/out.log" 2> "$logs_dir/error.log"

# Parcourir le dossier et ses sous-dossiers
files=$(find "$input_dir" -type f)
total_files=$(display "$files" | wc -l | sed -e 's/^ *//;s/ *$//')
longueur_format="%0${#total_files}d"
processed_files=0
# Parcourir les fichiers
for file in $files; do
    mime_type=$(file -b --mime-type "$file" | sed -e 's/^ *//;s/ *$//')
    file_name=$(basename "$file")
    if [[ "$file_name" == *.* ]]; then
        file_ext=".${file_name##*.}"
        file_name="${file_name%.*}"
    else
        file_ext=$(getExtension "$file" "$mime_type")
    fi

    # Récupérer les constantes utiles
    destination_dir="$output_dir/$mime_type"

    # Vérifier si le fichier de destination existe
    if [ "$overwrite" == false ] && [ -e "$destination_dir/$file_name$file_ext" ]; then
        # Renommer le fichier en ajoutant un compteur
        cpt=1
        while [ -e "$destination_dir/$file_name.$cpt$file_ext" ]; do
            ((cpt += 1))
        done
        file_name="$file_name.$cpt"
    fi

    # Logs
    [ "$move" == true ] && verb="Déplacement" || verb="Copie"
    ((processed_files += 1))
    display "[$(printf "$longueur_format" "$processed_files")/$total_files] ($file_ext) $verb de $file → $destination_dir/$file_name$file_ext" # Logs de deplacement/copie du fichier

    # Action
    if [ "$simulate" == false ]; then
        mkdir -p "$destination_dir" 
        [ "$move" == true ] && mv -f "$file" "$destination_dir/$file_name$file_ext" || cp -f "$file" "$destination_dir/$file_name$file_ext" # Déplacement/Copie du fichier
    fi
done

display "Traitement terminé."