# claude-code-history

Projekt-Gedächtnis für **Claude Code**. Der Ordner `.claude` lässt sich in jedes beliebige Projekt kopieren — danach funktioniert alles automatisch über Claude-Hooks. Es ist keine weitere Konfiguration nötig.

## Was es macht

Claude Code vergisst standardmäßig nach jeder Sitzung alles. Dieses Projekt hält ein laufendes Protokoll aller Sitzungen in `specs/history/history.md`, sodass Claude in jeder neuen Sitzung weiß, was im Projekt schon gemacht wurde, welche Schwierigkeiten aufgetreten sind und welche Entscheidungen getroffen wurden.

## Installation

Kopiere den Ordner `.claude` in das Wurzelverzeichnis deines Projekts. Fertig.

```text
dein-projekt/
└── .claude/
    ├── hooks/
    └── settings.json
```

## Funktionsweise

Zwei Claude-Hooks erledigen die gesamte Arbeit:

### 1. `SessionEnd` — beim Schließen einer Sitzung

Beim Schließen eines Chatfensters in VS Code oder eines Terminalfensters wird die Sitzung von einem LLM zusammengefasst und als neue Zeile an `specs/history/history.md` angehängt.

- Jede Zeile beginnt mit einem Zeitstempel.
- Die Zusammenfassung ist auf **maximal 300 Zeichen** begrenzt.
- Die Ordner und die Datei werden beim ersten Auslösen automatisch erstellt.
- Die Zusammenfassung dauert ca. **1–2 Minuten** und läuft im Hintergrund.

### 2. `SessionStart` — beim Öffnen einer neuen Sitzung

Beim Öffnen eines neuen Chatfensters oder Terminals wird der Inhalt von `specs/history/history.md` automatisch in den Kontext geladen. Claude kennt damit von der ersten Nachricht an die gesamte Projekt-Historie.

## Aufbau des Projekts

```text
.claude/
├── hooks/
│   ├── sitzungsstart-history-laden.ps1        # SessionStart-Hook
│   ├── sitzungsende-zusammenfassung.ps1       # SessionEnd-Hook (Trigger)
│   └── sitzungsende-zusammenfassung-worker.ps1 # Hintergrund-Worker
└── settings.json                               # Hook-Registrierung
```

## Beispiel-Gedächtnis

Damit du sofort sehen kannst, wie das Gedächtnis aussieht, enthält dieses Projekt eine Beispieldatei unter [specs/history/history.md](specs/history/history.md). Dort siehst du das Format, in dem die Sitzungen Zeile für Zeile mit Zeitstempel und Kurzzusammenfassung gespeichert werden.
