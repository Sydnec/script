# Script de Tri de Fichiers par Types
### Version 1.0 du 11 novembre 2023

---

## Description

Ce script Bash permet de trier les fichiers d'un répertoire en fonction de leurs types.
Il offre des options pour spécifier les répertoires d'entrée et de sortie, choisir entre le déplacement et la copie des fichiers, activer le mode simulation pour évaluer les actions, effectuer le traitement silencieusement, et afficher une aide.

---

## Utilisation
```
./script.sh [-i repertoire_entree] [-o repertoire_sortie] [-m] [-s] [-n] [-h]
    -i : Chemin du répertoire d'entrée
    -o : Chemin du répertoire de sortie
    -m : Déplacer les fichiers au lieu de les copier
    -s : Mode simulation (évalue les actions sans les exécuter)
    -n : (no logs) Execute silencieusement
    -h : Afficher ce message d'aide
```
---

## Exemple

```bash
./script.sh -i /chemin/vers/repertoire_entree -o /chemin/vers/repertoire_sortie -m
```

---

## Auteur

Simon Bourlier