Assistant IA de chat pour le FabLab de Villeurbanne (LOV), basé sur
Next.js et assistant-ui. Répond aux questions sur les machines et
procédures de l'atelier en s'appuyant sur :

- le wiki YesWiki actuel du LOV (interrogé en direct) ;
- les archives historiques du DokuWiki du LOV (indexées localement via
  un pipeline RAG : scraping, découpage en chunks, embeddings Mistral) ;
- les canaux publics Framateam choisis par un administrateur (fils de
  discussion anonymisés, cités par permalien).

Un bot Framateam (service `admin_lova-framateam`) répond dans les fils aux
messages commençant par `!lov`. La configuration (compte Framateam, canaux,
retraits RGPD) se fait dans `/admin/framateam`, réservé à la permission
« admin » de l'application (groupe `admins` par défaut).

Dictée vocale des questions via Mistral Voxtral.

Moteur de chat : Mistral AI Cloud par défaut, avec possibilité de
configurer un serveur Ollama local sur le réseau en complément.
