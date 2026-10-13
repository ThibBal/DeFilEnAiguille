# Questionnaires

Les questionnaires sont dans `content/quizzes/`, un fichier par jour (`AAAA-MM-JJ.json`). Ils sont publiés sur GitHub Pages et l'app les récupère à distance (`QuizStore`), les garde sur l'appareil, et ne dépend d'Internet que pour les nouveaux jours. `Sources/Resources/quizzes.json` reste embarqué dans l'app comme secours hors ligne. Il n'y a pas de questionnaire de repli : si celui du jour n'est pas là, l'onglet « Aujourd'hui » l'annonce et renvoie vers l'historique.

## Publication

- `scripts/publier_contenu.py` valide chaque fichier (5 questions, 4 options distinctes, `answer` entre 0 et 3, `hint` présent et sans la réponse, `link` présent dans le texte à partir de la 2e question, pas de réponse dans sa propre question). Lancer `python3 scripts/publier_contenu.py` avant de commit.
- `.github/workflows/contenu.yml` valide à chaque PR, et publie à chaque push sur `main` qui touche `content/`.
- Le site publié contient `index.json` (`{"dates": [...]}`, généré par le script, pas versionné) et `quizzes/AAAA-MM-JJ.json`. Adresse : `https://thibbal.github.io/DeFilEnAiguille/`.
- Mise en place unique : dans les réglages du dépôt GitHub, Pages → Source : « GitHub Actions ».
- Ajouter un jour : créer `content/quizzes/AAAA-MM-JJ.json`, valider, commit, push.

Format d'un questionnaire : `thread` (le « fil du jour », révélé à la fin) et 5 `questions`, chacune avec `question`, `options` (4), `answer` (index de la bonne réponse, à varier), `short` (mot affiché dans le fil récapitulatif), `accept` (facultatif : autres écritures acceptées en saisie libre), `hint` (indice sur la réponse, qui ne la donne pas), `explanation` et, à partir de la 2e question, `link`. Les 5 questions s'enchaînent par association d'idées, de plus en plus difficiles : la dernière est la plus difficile, mais reste à la portée d'un joueur cultivé aidé de son indice (pas de question d'érudit).

**Règle du fil :** chaque question (à partir de la 2e) reprend explicitement la bonne réponse de la précédente dans son texte, et `link` est l'extrait exact de la question qui la reprend (par exemple « Louxor » ou « Cette année-là »). C'est le mot que la bonne réponse rejoint dans l'animation « le fil passe ». Une question ne doit jamais contenir sa propre réponse.

**Saisie libre.** Le joueur tape sa réponse. Sont acceptés `options[answer]`, `short` et les entrées de `accept`, sans tenir compte des accents, de la casse, de la ponctuation ni des articles, avec 1 faute de frappe (mots de 4 à 8 lettres) ou 2 (9 lettres et plus). Une saisie plus proche d'une mauvaise proposition que de la bonne est refusée. Ajouter dans `accept` les écritures courantes que la tolérance ne couvre pas : le nom de famille seul (« Simenon »), un chiffre arabe (« Louis 18 »), un autre nom (« Myanmar »). `scripts/tester_reponses.sh` vérifie tous les questionnaires : variantes acceptées, mauvaises propositions refusées.

## Choix du thème

Chaque jour part d'une des 10 pages les plus vues de Wikipédia en français **la veille** (statistiques Wikimédia, API `metrics/pageviews/top`), en écartant la page d'accueil, les pages « Spécial » et les pages de listes ou d'élections en cours. Les statistiques d'un jour sont disponibles le lendemain.

## Octobre 2026

Le 13 et le 14 s'appuient tous deux sur les statistiques du 12 (celles du 13 n'étaient pas encore publiées).

| Jour | Page Wikipédia (vue la veille) | Fil |
|---|---|---|
| 1 | Lizzie Borden | De Lizzie Borden à Yale |
| 2 | Cristiano Ronaldo | De Ronaldo à Degas |
| 3 | Monsieur Hire | De Monsieur Hire à Bastogne |
| 4 | Amanda Lear | D'Amanda Lear à Berlin |
| 5 | Le Pont de la rivière Kwaï (film) | De la rivière Kwaï à la Boat Race |
| 6 | Police Python 357 | D'Orléans à l'île de la Cité |
| 7 | Parti québécois | Du Québec à Anish Kapoor |
| 8 | Charles X | De Charles X à Lépante |
| 9 | Édouard Philippe | Du Havre à la Floride de Jules Verne |
| 10 | Navanethem Pillay | De Navanethem Pillay à Wellington |
| 11 | Europe (groupe) | D'Europe au chat de Schrödinger |
| 12 | Shutter Island (film) | De Shutter Island à Moctezuma |
| 13 | Marché des Enfants-Rouges | Des Enfants-Rouges aux Offices |
| 14 | RJ Mitte | De RJ Mitte à Princeton |

Après une modification, `python3 scripts/publier_contenu.py --embarquer` régénère `Sources/Resources/quizzes.json` à partir de `content/`.
