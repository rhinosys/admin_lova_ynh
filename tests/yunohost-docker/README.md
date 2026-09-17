# Validation locale YunoHost 12.1.41.2

Environnement de test uniquement : Debian 12 ARM64 sous Docker Desktop macOS,
avec systemd PID 1. Docker n'est pas une cible officiellement prise en charge
par l'installateur YunoHost. Ce test ne remplace pas un test VM/LXC ou serveur.

## Création du conteneur

```sh
docker build -t lova-yunohost-test:bookworm tests/yunohost-docker
docker run -d --name lova-ynh-validation --hostname lova-test \
  --privileged --cgroupns=private --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
  -p 127.0.0.1:18080:80 -p 127.0.0.1:18443:443 \
  lova-yunohost-test:bookworm
```

Installer via https://install.yunohost.org avec `-a -f`, puis effectuer la
post-installation pour `lova.test`. Vérifier `yunohost --version` : la version
attendue est exactement 12.1.41.2 (stable). Le test effectué le 17 septembre
2026 utilise une préférence APT pour cette version.

Adaptations Docker réalisées uniquement dans le conteneur :

- retirer `/usr/sbin/policy-rc.d` fourni par l'image Debian, qui interdit le
  démarrage des services ;
- copier `/etc/resolv.conf`, démonter ce fichier monté par Docker, puis remettre
  la copie avant l'installation de resolvconf ;
- débloquer un cycle de démarrage dnsmasq/postfix en annulant les jobs de reload
  postfix en attente (`systemctl list-jobs`, puis `systemctl cancel ID...`) ;
- démarrer fail2ban avant l'installation d'application.

Ces adaptations ne font pas partie du package de production.

## Installation du package

Copier le dépôt dans `/root/admin_lova_ynh`. Les arguments d'installation sont
stockés dans `/root/lova-install-args` avec permissions 0600, sous forme URL-encodée :
`domain=lova.test`, `path=/chat`, `init_main_permission=visitors`,
`ollama_base_url=undefined`, et la clé Mistral réelle lue depuis le `.env` local.
Ne pas enregistrer cette clé dans git ou dans ce document.

```sh
docker exec lova-ynh-validation bash -c \
  'yunohost app install /root/admin_lova_ynh --args "$(cat /root/lova-install-args)" --force --no-remove-on-failure'
curl -ksS -H 'Host: lova.test' https://127.0.0.1:18443/chat/api/health
docker exec lova-ynh-validation env -i PATH=/usr/bin:/bin \
  /etc/cron.weekly/admin_lova-rag-refresh
```

Le conteneur conserve des données de test et une clé API : il reste local.
Le mot de passe administrateur aléatoire est dans `/root/lova-test-admin-password`.
Les journaux de cette session sont dans `/tmp/lova-ynh-docker` sur l'hôte.

## Résultats du 17 septembre 2026

- Installation complète réussie, Node 22.23.2, Next.js 15.5.25.
- Entrée Ollama `undefined` normalisée vers `http://127.0.0.1:11434`.
- Migration PostgreSQL exécutée.
- Accès HTTP via nginx : `/chat/api/health` répond `status: ok`.
- Chat Mistral en streaming testé via nginx, messages enregistrés en PostgreSQL.
- RAG initial : 74 pages et 383 fragments indexés avec Mistral.
- Cron exécuté avec un environnement minimal après correction du PATH.
- Sauvegarde YunoHost réussie, incluant un dump PostgreSQL.
- Premier cycle de restauration : les deux messages de test reviennent ;
  rechargement nginx manquant identifié et ajouté au script restore.
- Second cycle avec le script corrigé : restauration réussie, deux messages
  conservés, service actif et HTTP `status: ok` sans intervention manuelle.

Les scénarios upgrade et change_url ne sont pas couverts par cette session.

Limite applicative observée : `/chat/api/health/ready` répond unhealthy parce
qu'il contrôle Ollama même lorsque seul Mistral est utilisé. PostgreSQL et
Mistral répondent healthy. La correction de ce contrôle appartient à lovAssistant.

## Régression : boucle de redirection sur la page d'entrée

Le test de santé API seul ne couvre pas la page d'entrée. L'ancienne location
nginx `/chat/` provoquait un 301 de `/chat` vers `/chat/`, suivi du 308 Next.js
inverse. La location bornée `^/chat(?:/|$)` laisse Next.js normaliser l'URL.

Après correction, vérifications via nginx :

- `/chat` : HTTP 200 ;
- `/chat/` : HTTP 308 vers `/chat`, puis HTTP 200 ;
- `/chat/chat` (page conversation de l'app sous basePath `/chat`) : HTTP 200 ;
- les 10 ressources CSS/JavaScript référencées par cette page : HTTP 200 ;
- `/chat/api/health` : HTTP 200 ;
- `/chat-other` : HTTP 404, non capturé par la location de l'application.

Configuration validée avec `nginx -t` avant rechargement.

## Icône du portail

`conf/logo.png` est enregistré avec `yunohost user permission update --logo`
à l'installation, à la mise à jour et à la restauration. Le fichier est inclus
dans les fichiers de configuration du package, conservés par YunoHost.
La disponibilité de l'option est vérifiée pour les anciennes versions.
Testé sur 12.1.41.2 : permission avec `logo_hash`, PNG servi en HTTP 200,
et enregistrement depuis le chemin absolu utilisé lors de la restauration.

## Maintenance du RAG (0.1.0~ynh2)

Le package utilise `rag:refresh` pour l'initialisation et le cron : même verrou
et même statut que le bouton de l'interface. Le statut affiche les documents
réellement indexés et les fragments, avec la date du dernier index utilisable.
La permission `admin_lova.rag` réserve `/api/rag/refresh` aux administrateurs
YunoHost ; le statut `/api/rag` reste accessible selon les droits de l'app.
Se connecter au portail YunoHost comme administrateur pour lancer la mise à
jour depuis le chat. L'index précédent reste disponible durant le traitement.

Les sources sont désormais fixées à un commit avec son SHA256, plutôt qu'à
l'archive mutable de master.

Validation Docker du panneau RAG : upgrade 0.1.0~ynh2 réussi, API de statut
avec 74 documents / 383 fragments, POST accepté en 202, second POST refusé,
cron concurrent refusé par le même verrou. POST visiteur via nginx redirigé
vers l'authentification ; permission de maintenance limitée à admins.
Panneau inspecté dans le navigateur : compteurs visibles, étape « Collecte du
wiki… », bouton désactivé pendant le traitement.
La mise à jour réelle s'est terminée avec succès : nouvel horodatage d'index,
statut « À jour », 74 documents et 383 fragments, bouton réactivé sans recharger
la page. Tests applicatifs : suite de 73 tests passée, puis 6 tests ciblés de
maintenance passés après ajout du scénario de succès (74 tests au total).

## Fiabilité des réponses (0.1.0~ynh3)

Suppression des faux inventaires de secours YesWiki (Prusa MK3S+/laser) et des
valeurs de disponibilité/matériaux inventées. L'application vérifie désormais
les citations exactes avant affichage et n'affiche pas de prose factuelle
librement générée. Les messages système provenant du navigateur sont refusés.

Validation : 85 tests applicatifs réussis, vérification TypeScript, build
Next.js sous Node 22 dans le conteneur. Question réelle « liste les imprimantes
3D » testée avec Mistral : extraits de la page Impression 3D citant P1S, A1 mini,
Creality Ender et LulzBot TAZ Workhorse, sans inventer une Prusa ni un état actuel.
Les documents consultés ne constituent pas un inventaire exhaustif. Leur
exactitude et leur actualité restent celles du wiki ; voir la documentation
`docs/grounded-answers.md` dans le dépôt de l'application.

La liste des imprimantes est extraite directement des lignes de la page
Impression 3D, sans génération du modèle. Tests de fausse suggestion Prusa et
de demande de sa source : aucune confirmation fabriquée.
