# Script de Tri de Fichiers par Types
### Version 1.2 du 16 novembre 2023

---

## Description

Ce script Bash permet de trier les fichiers d'un répertoire en fonction de leurs types.
Il offre des options pour spécifier les répertoires d'entrée et de sortie, choisir entre le déplacement et la copie des fichiers,
choisir d'écraser les fichiers déjà existant ou de les renommer, activer le mode simulation pour évaluer les actions,
effectuer le traitement silencieusement, sortir les logs dans un fichier de log externe et afficher une aide.

---

## Utilisation

```
./script.sh [-i repertoire_entree] [-o repertoire_sortie] [-m] [-e] [-s] [-n] [-l repertoire_logs] [-h]
    -i : Chemin du répertoire d'entrée
    -o : Chemin du répertoire de sortie
    -m : Déplacer les fichiers au lieu de les copier
    -e : Ecrase les fichiers de destination s'ils existent déjà
    -s : Mode simulation (évalue les actions sans les exécuter)
    -n : (no logs) Exécute silencieusement
    -l : Rediriger les logs dans un dossier externe
    -h : Afficher ce message d'aide
```

---

## Exemple

```bash
./script.sh -mei /chemin/vers/repertoire_entree -o /chemin/vers/repertoire_sortie -l ./vers/logs
```

---

## Auteur

Sydnec
