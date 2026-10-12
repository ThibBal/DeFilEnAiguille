# Questionnaires

Les questionnaires sont dans `Sources/Resources/quizzes.json` (clés AAAA-MM-JJ, plus un questionnaire de repli utilisé pour aujourd'hui quand la date n'a pas le sien).

Format d'un questionnaire : `thread` (le « fil du jour », révélé à la fin) et 5 `questions`, chacune avec `question`, `options` (4), `answer` (index de la bonne réponse), `short` (mot affiché dans le fil récapitulatif) et `explanation`. Les 5 questions s'enchaînent par association d'idées, de la plus simple à la plus difficile.

## Octobre 2026

Chaque jour part d'une des 10 pages les plus vues de Wikipédia en français ce jour-là (statistiques Wikimédia, API `metrics/pageviews/top`), en écartant la page d'accueil et les pages « Spécial ».

| Jour | Page Wikipédia | Fil |
|---|---|---|
| 1 | Cristiano Ronaldo | De Ronaldo au Greco |
| 2 | Zinédine Zidane | De Zidane à Thulé |
| 3 | Usual Suspects | De Usual Suspects au Masque de fer |
| 4 | Le Pont de la rivière Kwaï (film) | De la rivière Kwaï à la Planète des singes |
| 5 | Police Python 357 | D'Orléans à Castillon |
| 6 | Parti québécois | Du Québec au lac Michigan |
| 7 | Charles X | De Charles X à Guernesey |
| 8 | Édouard Philippe | Du Havre à Nadar |
| 9 | Lionel Messi | De Rosario à Montevideo |
| 10 | Europe (groupe) | De la Suède à la dynamite |
| 11 | (exemple, sans page) | De l'obélisque à l'Etna |

Les statistiques du jour ne sont publiées qu'avec un décalage : le 11 octobre n'avait pas encore de données.
