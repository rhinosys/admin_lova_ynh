# admin_lova_ynh

Package YunoHost pour l'Assistant IA Fablab (AdminLova) — voir
[doc/DESCRIPTION.md](doc/DESCRIPTION.md) pour la description fonctionnelle,
et le fichier
[docs/superpowers/specs/2026-09-16-yunohost-package-design.md](https://github.com/rhinosys/lovAssistant/blob/master/docs/superpowers/specs/2026-09-16-yunohost-package-design.md)
du dépôt lovAssistant (AdminLova) pour le design complet.

## Installer sur une instance YunoHost de test

```bash
yunohost app install https://github.com/rhinosys/admin_lova_ynh --debug
```

## Après l'installation (Framateam)

1. Se connecter au portail avec un compte du groupe `admins` (ou ajouter le
   groupe voulu à la permission « admin » de l'application).
2. Ouvrir `https://<domaine><chemin>/admin/framateam`, saisir le compte
   Framateam (de préférence un compte dédié sans double authentification),
   tester la connexion, cocher les canaux à indexer / où le bot répond, puis
   « Synchroniser maintenant ».
3. Le service `admin_lova-framateam` (journal `/var/log/admin_lova/framateam.log`)
   prend la configuration en compte sans redémarrage.

La clé `APP_ENCRYPTION_KEY` qui chiffre le mot de passe Framateam est générée à
l'installation (ou à la première mise à jour) et conservée dans les réglages de
l'application ; elle fait partie des sauvegardes.

## Périmètre

Usage personnel / LOV. Ne vise pas (pour l'instant) le catalogue officiel
YunoHost — pas de CI YunoHost, pas de tests multi-architecture.
