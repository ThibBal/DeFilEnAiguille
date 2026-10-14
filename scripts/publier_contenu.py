#!/usr/bin/env python3
"""Valide les questionnaires de content/quizzes/ et prépare le site publié.

Usage : python3 scripts/publier_contenu.py [dossier_de_sortie] [--embarquer]

Sans option, valide seulement. Avec un dossier, y copie les questionnaires et
écrit index.json (liste triée des dates disponibles), plus les pages de
content/site/ (confidentialité, assistance) et les polices qu'elles utilisent. Avec --embarquer,
régénère Sources/Resources/quizzes.json (le secours embarqué dans l'app) à
partir de content/. Code de sortie 1 si un questionnaire est invalide.
"""
import json
import re
import shutil
import sys
from datetime import date
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
QUIZZES = RACINE / "content" / "quizzes"
SITE = RACINE / "content" / "site"
POLICES = RACINE / "Sources" / "Resources" / "Fonts"
EMBARQUE = RACINE / "Sources" / "Resources" / "quizzes.json"


def norm(texte):
    return texte.replace("’", "'").lower()


def verifier(nom, quiz):
    erreurs = []
    if not str(quiz.get("thread", "")).strip():
        erreurs.append("thread vide")
    questions = quiz.get("questions")
    if not isinstance(questions, list) or len(questions) != 5:
        return erreurs + ["il faut exactement 5 questions"]
    for i, q in enumerate(questions, 1):
        p = f"question {i} : "
        for champ in ("question", "short", "hint", "explanation"):
            if not str(q.get(champ, "")).strip():
                erreurs.append(p + f"{champ} vide")
        options = q.get("options")
        if not isinstance(options, list) or len(options) != 4 or len(set(options)) != 4:
            erreurs.append(p + "4 options distinctes attendues")
            continue
        reponse = q.get("answer")
        if not isinstance(reponse, int) or not 0 <= reponse < 4:
            erreurs.append(p + "answer doit être un index entre 0 et 3")
            continue
        accept = q.get("accept")
        if accept is not None and (
                not isinstance(accept, list)
                or not all(isinstance(a, str) and a.strip() for a in accept)):
            erreurs.append(p + "accept doit être une liste de textes non vides")
        link = q.get("link")
        if i == 1:
            if link:
                erreurs.append(p + "pas de link sur la première question")
        elif not link:
            erreurs.append(p + "link manquant")
        elif link not in q["question"]:
            erreurs.append(p + f"link « {link} » absent du texte de la question")
        elif link == q["question"]:
            erreurs.append(p + "link ne peut pas être la question entière")
        bonne = norm(options[reponse])
        if bonne in norm(q["question"]):
            erreurs.append(p + "la question contient sa propre réponse")
        if bonne in norm(q.get("hint", "")):
            erreurs.append(p + "l'indice contient la réponse")
    return erreurs


def main():
    args = sys.argv[1:]
    embarquer = "--embarquer" in args
    args = [a for a in args if a != "--embarquer"]
    sortie = Path(args[0]) if args else None
    fichiers = sorted(QUIZZES.glob("*.json"))
    echec = False
    dates = []
    for f in fichiers:
        try:
            date.fromisoformat(f.stem)
            assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", f.stem)
            quiz = json.loads(f.read_text(encoding="utf-8"))
        except (ValueError, AssertionError):
            print(f"{f.name} : nom (AAAA-MM-JJ.json) ou JSON invalide")
            echec = True
            continue
        for e in verifier(f.name, quiz):
            print(f"{f.name} : {e}")
            echec = True
        dates.append(f.stem)
    if echec:
        sys.exit(1)
    if not dates:
        sys.exit("Aucun questionnaire dans content/quizzes/")
    print(f"{len(dates)} questionnaires valides ({dates[0]} → {dates[-1]})")
    if sortie:
        (sortie / "quizzes").mkdir(parents=True, exist_ok=True)
        for f in fichiers:
            shutil.copy(f, sortie / "quizzes" / f.name)
        (sortie / "index.json").write_text(
            json.dumps({"dates": dates}, indent=2) + "\n", encoding="utf-8")
        shutil.copytree(SITE, sortie, dirs_exist_ok=True)
        (sortie / "fonts").mkdir(exist_ok=True)
        for police in POLICES.glob("*.ttf"):
            shutil.copy(police, sortie / "fonts" / police.name)
        print(f"Site écrit dans {sortie}")
    if embarquer:
        catalogue = {"quizzes": {
            f.stem: json.loads(f.read_text(encoding="utf-8")) for f in fichiers}}
        EMBARQUE.write_text(
            json.dumps(catalogue, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Secours embarqué écrit dans {EMBARQUE.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
