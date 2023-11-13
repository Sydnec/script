# Script de Tri de Fichiers par Types
### Version 1.1 du 11 novembre 2023

---

## Description

Ce script Bash permet de trier les fichiers d'un répertoire en fonction de leurs types.
Il offre des options pour spécifier les répertoires d'entrée et de sortie, choisir entre le déplacement et la copie des fichiers,
activer le mode simulation pour évaluer les actions, effectuer le traitement silencieusement, et afficher une aide.

---

## Utilisation

```bash
./script.sh [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-n] [-l repertoire_logs] [-e] [-h]
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

Simon Bourlier