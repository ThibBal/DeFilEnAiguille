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
  Model/                            Quiz (questionnaires), Play (SwiftData) + Historique, DateKey (dates en français)
  Components/                       Thread (nœuds et fil), UI (étiquette, boutons, points de score, lien retour)
  Views/                            RootView, TodayView, QuizView, HistoryView, ReviewView
  Resources/quizzes.json            les questionnaires (clés AAAA-MM-JJ + questionnaire de repli)
  Resources/Fonts/                  Instrument Serif et Hanken Grotesk
  Assets.xcassets/                  icône de l'app (aiguille et fil vert)
design/                             maquettes d'origine (.dc.html) et source SVG de l'icône, pour référence
docs/questionnaires.md              format des questionnaires et page Wikipédia de chaque jour
```

## Fonctionnement

- **Aujourd'hui** (`TodayView` → `QuizView`) : le questionnaire de la date du jour. S'il a déjà été joué, l'écran affiche directement le résultat.
- **Historique** (`HistoryView`) : tous les jours qui ont un questionnaire, par mois, jusqu'à aujourd'hui. Un jour joué ouvre sa revue (`ReviewView`, avec « Rejouer »), un jour « À jouer » ouvre le questionnaire (`QuizView` avec retour vers l'historique).
- **Parties** : modèle SwiftData `Play`, une par date (`date` unique). Rejouer remplace la partie précédente.
- **Questionnaires** : `QuizCatalog` lit `quizzes.json`. Pour une date absente, seul aujourd'hui reçoit le questionnaire de repli.
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

1. Choisir la source des questionnaires (API, fichier par jour, back-office) à la place de `quizzes.json`, qui ne couvre que les 1er au 11 octobre 2026.
2. Notification quotidienne (UserNotifications) et widget iOS (WidgetKit).
3. Écran de démarrage définitif, puis distribution (TestFlight / App Store, compte Apple Developer payant).
