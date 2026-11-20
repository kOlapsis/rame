# Balade à la rame

Balade en 3D pilotée par un rameur Bluetooth (protocole FTMS, testé pour Merach R28).
Tout est servi localement (Three.js 0.170 inclus), aucune ressource externe.

## Dans l'appli

- **Décors** : six ambiances (lac alpin, rivière d'automne sous une pluie fine, lagon, fjord, canal de Provence, nuit d'été) avec nuages, roselières, nénuphars, prés fleuris, villages, vaches, feuilles qui tombent. En mode « Balade », le décor change tous les 1,5 km.
- **Vue** (bouton « Vue ») : *À bord* (vue subjective, face à la proue, par défaut), *Poursuite* (derrière la yole), *Barreur* (assis à la poupe, face au rameur) ou *Rameur* (dos à la marche, comme en vrai).
- **Rameur animé** : attaque, propulsion jambes → dos → bras, dégagé, retour sur la coulisse, calés sur ta cadence.
- **Son** : tout est synthétisé dans le navigateur (aucun fichier audio).

## Publication

GitHub Actions (`.github/workflows/docker.yml`) construit l'image amd64 + arm64 et la pousse sur ghcr.io :

| Événement | Tags de l'image |
|---|---|
| Release `v1.4.2` publiée | `1.4.2`, `1.4`, `1`, `latest` |
| Push sur `main` | `edge`, `sha-abc1234` |
| Pull request | build seul, rien n'est poussé |

Le numéro de version de la release s'affiche aussi dans l'appli (écran d'accueil).
Crée la release avec un tag au format `vX.Y.Z` (ex. `gh release create v1.0.0 --generate-notes`).

## Lancer

1. Dans `docker-compose.yml`, mettre ton compte GitHub dans le nom de l'image et ton domaine à la place de `rame.example.com`.
2. Si le dépôt est privé, le paquet ghcr l'est aussi : `docker login ghcr.io` sur le serveur, ou rends le paquet public dans GitHub.
3. `docker compose pull && docker compose up -d`
4. Ouvrir `https://ton-domaine` dans Chrome ou Edge, téléphone en paysage de préférence.

En local : `docker build -t balade-rame . && docker run -p 8080:80 balade-rame` (le Bluetooth web exige HTTPS, sauf sur `localhost`).

## Contenu

- `index.html` : l'application
- `three.module.min.js`, `Water.js`, `Sky.js` : Three.js r170 (licence MIT)
- `Dockerfile`, `.github/workflows/docker.yml` : image et CI
- `nginx.conf` : en-têtes Permissions-Policy pour le Bluetooth et le maintien d'écran
