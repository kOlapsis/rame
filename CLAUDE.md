# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

« Balade à la rame » : balade 3D dans le navigateur, pilotée par un rameur Bluetooth (FTMS, testé sur Merach R28). Site 100 % statique servi par nginx : pas de build, pas de gestionnaire de paquets, pas de tests ni de linter. Interface et textes en français.

## Commandes

- Servir en local : `python3 -m http.server 8080` puis `http://localhost:8080` (les modules ES exigent HTTP ; le Bluetooth web exige HTTPS ou `localhost`).
- Image : `docker build -t balade-rame . && docker run -p 8080:80 balade-rame`.
- Sans rameur : bouton « Mode démo » sur l'écran d'accueil, la cadence se règle au curseur.
- Console : `window.__balade` expose `{st, go, SC, A, PROG, pg, DB, center, dcenter}` (état, changement de décor `__balade.go(i)`, décors, audio, séances, profils, tracé de la rivière). Pour tester une séance sans attendre, avancer `st.time`.
- CI (`.github/workflows/docker.yml`) : push sur `main` → tags `edge` + `sha-xxxxxxx` ; release `vX.Y.Z` → semver + `latest`. Le build injecte la version via `ARG VERSION`, `sed` remplace `__VERSION__` dans `index.html` (en local, la chaîne reste telle quelle).

## Fichiers

- `index.html` : toute l'application (CSS, HTML, un seul `<script type="module">`).
- `three.module.min.js`, `Water.js`, `Sky.js` : Three.js r170 copié dans le dépôt, résolu par l'importmap (`"three": "./three.module.min.js"`). Aucune ressource externe ni CDN.
- `index-v0.1.0.html` : ancienne version, non copiée dans l'image.
- Le `Dockerfile` copie une liste explicite de fichiers : un nouveau fichier servi doit y être ajouté.
- `nginx.conf` : un `add_header` dans un bloc `location` annule ceux du bloc `server`, d'où la `Permissions-Policy` (Bluetooth, wake lock) répétée dans chaque `location`.

## Architecture de `index.html`

Le script est écrit en style compact (noms courts, une ligne par fonction) et découpé par des bannières `/* ===== … ===== */`.

- **Décors (`SC`)** : tableau d'objets de configuration, un par décor (ciel, brouillard, eau, largeur et sinuosité de la rivière, relief, couleurs, mélange de végétation `mix`, probabilités de village, pont, ponton, bateaux, canards, et liste d'ambiances sonores `amb` au format `'nom:arg'`). `S` est le décor courant. Ajouter un décor revient à ajouter une entrée ; chaque nom de `amb` doit correspondre à un `case` de `amb()`.
- **Repère** : on avance selon `-z`. `st.s` est l'abscisse le long de la rivière. `center(s)` donne l'axe (`bends(s)` alterne passages calmes et sinueux), `half(s)` la demi-largeur, `height(x,s)` le relief (bruit `fbm`/`ridge` initialisé par `SEED`). Les distances au bord se mesurent à `x` constant, pas perpendiculairement : dans un virage la rivière paraît plus étroite d'un facteur `cos θ`, d'où une pente gardée sous 40° environ.
- **Terrain par tronçons** : `NSLOT` = 8 maillages recyclés de `CH` = 150 m. `updateChunks` construit un tronçon par frame (tous d'un coup au changement de décor). La végétation et les maisons passent par un `InstancedMesh` par pièce de `TYPES`, chaque slot occupant la plage d'indices `slot*cap … slot*cap+cap-1`. Le contenu d'un tronçon est déterministe (`rng(ci, sIdx)`). Les objets ponctuels (ponts, bateaux, canards) sont dans `chunks[ci].objs` et leurs animations dans `anims`.
- **Ciel, eau, anneaux de montagnes** : ils suivent la caméra à chaque frame. La nuit (`S.night`) remplace `Sky` par une sphère en dégradé, des étoiles et une lune.
- **Modèle de mouvement (`frame`)** : `st.vT` (vitesse cible) est lissée en `st.vAvg`, puis modulée par la phase du coup `st.phase` (0→1 au rythme de `st.spm`). Le passage à 1 déclenche `onCatch` (attaque), 0.35 déclenche `onRelease` (dégagé). Le défilement visuel vaut `st.v * VIS` (1.35), la distance affichée reste en mètres réels (`st.dist`, ou distance du rameur si dispo). Après 4 s sans donnée Bluetooth, la vitesse retombe à 0. En mode tour, le décor change tous les 1500 m.
- **Bluetooth FTMS** : service `0x1826`, caractéristique Rower Data `0x2AD1` décodée selon ses drapeaux (`parseRower`), puis écriture sur le point de contrôle `0x2AD9` (`0` prise de contrôle, `7` départ). Ordre de repli pour la vitesse : delta de distance sur 6 s, puis allure, puis puissance (`cbrt(P/2.8)`), puis cadence × 0.15. Un incrément du compteur de coups resynchronise la phase. Reconnexion automatique après déconnexion. Le dernier rameur (`localStorage` `balade-dev`) est retrouvé sans sélecteur via `navigator.bluetooth.getDevices()` puis `watchAdvertisements()` ; Chrome n'expose ces API qu'avec le flag `enable-web-bluetooth-new-permissions-backend`.
- **Séances guidées (`PROG`)** : liste de segments `{d, n, a, b}` (durée en s, libellé, cadence cible min/max). La progression se lit sur `st.time`, qui n'avance que quand on rame, donc une pause fige la séance. `progTick` est appelé par `hud()` toutes les 250 ms.
- **Profils** : `localStorage` `balade-users` = `{cur, users:[{id, name, sex, h, w:[[iso, kg]], ses:[{d, dur, dist, kcal, p}]}]}`, validé par `validDB` au chargement et à l'import. La séance en cours est enregistrée toutes les 15 s et à la fermeture de la page, dès 60 s de rame. Calories : formule Concept2 ajustée au poids, `kcal/h = 3,44 × W + 3,78 × kg`, avec `W = 2,8 × v³` si le rameur ne donne pas la puissance.
- **Audio** : entièrement synthétisé en WebAudio, aucun fichier son. `A.master` alimente une réverbération à convolution régénérée par décor. Chaque décor crée un nouveau `A.ambBus` ; le compteur `A.gen` arrête les boucles `setTimeout` de l'ambiance précédente. Les sons de coup (`sCatch`, `sRelease`) et le glissement de l'eau (`audioTick`) dépendent de la vitesse.
- **Écran allumé** : Wake Lock API, avec en secours une vidéo muette en boucle (base64) et une relance périodique.
