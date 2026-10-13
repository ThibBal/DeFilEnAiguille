#!/bin/sh
# Compile AnswerMatcher avec scripts/tester_reponses.swift et vérifie tous les questionnaires.
set -e
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
mkdir "$tmp/src"
cp Sources/Model/AnswerMatcher.swift "$tmp/src/AnswerMatcher.swift"
cp scripts/tester_reponses.swift "$tmp/src/main.swift"
swiftc -O "$tmp/src/AnswerMatcher.swift" "$tmp/src/main.swift" -o "$tmp/tester"
"$tmp/tester" content/quizzes
