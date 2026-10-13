# De fil en aiguille

Application iOS (SwiftUI, iOS seul pour le moment) de questionnaires quotidiens en français : 5 questions par jour, reliées entre elles par association d'idées (« de fil en aiguille »), et un historique de tous les questionnaires.

## Stack

- SwiftUI, Swift 5, cible iOS 17. Stockage local avec SwiftData. Aucune dépendance externe.
- Projet Xcode généré par **XcodeGen** depuis `project.yml` (`brew install xcodegen`, puis `xcodegen generate` à la racine). Ne pas éditer `DeFilEnAiguille.xcodeproj` à la main : modifier `project.yml` et régénérer.
- Identifiant `fr.thibbal.defilenaiguille`, équipe Apple `LU5WXR422M`, signature automatique.

## Commandes

```bash
xcodegen generate                      # régénère le projet Xcode après un changement de project.yml
open DeFilEnAiguille.xcodeproj         # puis ▶ dans Xcode (simulateur ou iPhone branché)
xcodebuild -project DeFilEnAiguille.xcodeproj -scheme DeFilEnAiguille \
  -destination 'id=<UDID du simulateur>' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

L'app est autonome : pas de serveur à lancer. Avant de dire qu'une tâche est finie : compiler avec `xcodebuild` et regarder le résultat dans le simulateur.

## Structure

```
project.yml                         configuration XcodeGen (cible, réglages, polices embarquées)
Sources/
  DeFilEnAiguilleApp.swift          point d'entrée, barre d'onglets, état partagé (AppState, Route)
  Theme.swift                       Palette (clair/sombre) et AppFont
  Model/                            Quiz (modèles), AnswerMatcher (saisie libre), QuizStore (questionnaires : embarqués + téléchargés), Play (SwiftData) + Historique, DateKey (dates en français)
  Components/                       Thread (nœuds et fil), UI (étiquette, boutons, points de score, lien retour)
  Views/                            RootView, TodayView, QuizView, HistoryView, ReviewView
  Resources/quizzes.json            les questionnaires (clés AAAA-MM-JJ + questionnaire de repli)
  Resources/Fonts/                  Instrument Serif et Hanken Grotesk
  Assets.xcassets/                  icône de l'app (aiguille et fil vert)
content/quizzes/                    un questionnaire par jour (AAAA-MM-JJ.json), publié sur GitHub Pages
scripts/publier_contenu.py          valide les questionnaires et prépare le site (index.json)
scripts/tester_reponses.sh          vérifie la saisie libre sur tous les questionnaires (variantes, fautes, mauvaises propositions)
.github/workflows/contenu.yml       validation sur PR, publication Pages sur main
design/                             maquettes d'origine (.dc.html) et source SVG de l'icône, pour référence
docs/questionnaires.md              format des questionnaires et page Wikipédia de chaque jour
```

## Fonctionnement

- **Aujourd'hui** (`TodayView` → `QuizView`) : le questionnaire de la date du jour. S'il a déjà été joué, l'écran affiche directement le résultat. S'il n'est pas disponible, l'écran annonce qu'il arrive bientôt et propose de parcourir l'historique (pas de questionnaire de repli).
- **Historique** (`HistoryView`) : tous les jours qui ont un questionnaire, par mois, jusqu'à aujourd'hui. Un jour joué ouvre sa revue (`ReviewView`, avec « Rejouer »), un jour « À jouer » ouvre le questionnaire (`QuizView` avec retour vers l'historique).
- **Réponse libre, indice, propositions** (`QuizView`) : on tape la réponse (`AnswerMatcher` : sans accents ni casse ni articles, 1 à 2 fautes de frappe tolérées, refusée si elle ressemble plus à une mauvaise proposition ; variantes dans `accept`). Une erreur affiche l'indice (`hint`) ; au deuxième échec, ou via le bouton, les 4 propositions apparaissent. Le bouton « Indice » est disponible d'emblée.
- **Score** (`Scoring`, `Outcome`) : par question, 5 points sans indice, 3 avec l'indice, 1 avec les propositions, 0 sinon : 25 au maximum. `Play.pointsByQuestion` les enregistre ; les parties anciennes (sans ce champ) valent 5 points par bonne réponse.
- **Parties** : modèle SwiftData `Play`, une par date (`date` unique). Rejouer remplace la partie précédente.
- **Questionnaires** : `QuizStore` (injecté dans l'environnement) part de `quizzes.json` embarqué (secours hors ligne), le complète avec les fichiers du cache (`Application Support/Quizzes/`), puis `refresh()` télécharge `index.json` et `quizzes/AAAA-MM-JJ.json` depuis GitHub Pages (au lancement et au retour au premier plan) : les dates manquantes, plus celles d'aujourd'hui et à venir pour prendre en compte une correction. Une date absente n'a pas de questionnaire.
- **Animation « le fil passe »** (`QuizView.next` / `runFlight`, `Components/QuestionText.swift`) : au passage à la question suivante, la bonne réponse devient une pastille qui suit un fil vert jusqu'au mot repris (`link`), qui s'allume puis reste souligné. Durée ≈ 1,2 s (constante `flightSpeed` pour la ralentir en test). Sans `link`, ou avec « Réduire les animations », transition simple. Les questions sont affichées mot par mot (`FlowLayout`) pour pouvoir viser le mot repris.
- **Hauteur de ligne exacte** (`exactLineHeight`) : disponible à partir d'iOS 26, sinon interligne par défaut.

## Design (à respecter)

Direction : épuré, papier crème et encre sombre, un accent vert (bonne réponse, fil) et un rouge pour les mauvaises réponses.

- Polices : **Instrument Serif** (titres, chiffres, questions ; italique pour la signature et les titres de fil) et **Hanken Grotesk** (texte, boutons, étiquettes). Pas de police système sauf pour les icônes SF Symbols.
- Couleurs : uniquement via `Palette` (`Theme.swift`), jamais de valeur en dur. Le mode clair/sombre suit le réglage du système.
- Motif central : le **fil** — une rangée de 5 nœuds reliés (progression), et une colonne verticale nœud + fil dans les récapitulatifs. Nœud plein vert = bonne réponse, plein rouge = mauvaise, anneau = question en cours, creux = à venir.
- Les réponses ne reposent jamais sur la couleur seule : icône coche/croix, bordure en tirets pour une mauvaise réponse, texte « Votre réponse / Bonne réponse ».
- Zones tactiles d'au moins 44 pt, boutons principaux de 56 pt, rayon 16.
- Pas d'emoji dans l'interface, pas de fausse barre d'état.
- Textes en français, ton sobre, pas de contenu de remplissage.

## À faire

1. Notification quotidienne (UserNotifications) et widget iOS (WidgetKit).
2. Écran de démarrage définitif, puis distribution (TestFlight / App Store, compte Apple Developer payant).
