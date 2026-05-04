# Worker-Skript fuer SessionEnd. Laeuft im Hintergrund, ruft "claude -p"
# auf, um eine 300-Zeichen-Zusammenfassung der Sitzung zu erzeugen, und
# haengt sie an specs/history/history.md im Format "{Datum und Zeit} - {Text}" an.

param(
    [string]$TranscriptPfad = "",
    [Parameter(Mandatory = $true)][string]$ProjektVerzeichnis
)

$ErrorActionPreference = "Continue"

# Native-Command-Stdout (hier "claude -p") als UTF-8 lesen. Ohne diese
# Zeile dekodiert PowerShell 5.1 mit der OEM-Codepage (CP850 auf
# deutschem Windows), wodurch UTF-8-Sequenzen wie 0xC3 0xBC ("ue") zu
# Mojibake werden ("├╝"). Betrifft nur die laufende PS-Sitzung.
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false

# Sicherstellen, dass das eingebettete "claude -p" die Hooks dieses
# Projekts nicht erneut triggert.
$env:CLAUDE_HISTORY_HOOK_INTERN = "1"

$historyVerzeichnis = Join-Path $ProjektVerzeichnis "specs\history"
$historyDatei = Join-Path $historyVerzeichnis "history.md"

if (-not (Test-Path $historyVerzeichnis)) {
    New-Item -ItemType Directory -Path $historyVerzeichnis -Force | Out-Null
}

function Schreibehistoryeintrag {
    param([string]$Zusammenfassungstext)

    if (-not $Zusammenfassungstext) {
        $Zusammenfassungstext = "(keine Zusammenfassung verfuegbar)"
    }

    # Mehrzeilige Antworten zu einer Zeile zusammenziehen.
    $einzeilig = $Zusammenfassungstext -replace "`r?`n", " "
    $einzeilig = $einzeilig.Trim()

    # Defensiv auf 300 Zeichen kuerzen, falls "claude -p" die Vorgabe
    # missachtet.
    if ($einzeilig.Length -gt 300) {
        $einzeilig = $einzeilig.Substring(0, 300)
    }

    $zeitstempel = Get-Date -Format "yyyy-MM-dd HH:mm"
    $zeile = "$zeitstempel - $einzeilig"
    Add-Content -Path $historyDatei -Value $zeile -Encoding UTF8
}

if (-not $TranscriptPfad -or -not (Test-Path $TranscriptPfad)) {
    Schreibehistoryeintrag "(Sitzung beendet - keine Transcript-Datei gefunden)"
    exit 0
}

$prompt = 'Lies die Transcript-Datei "' + $TranscriptPfad + '" (Claude-Code-JSONL-Format) und schreibe eine deutsche Zusammenfassung dieser Sitzung in MAXIMAL 300 Zeichen. Pflichtangaben falls vorhanden: gefundene Probleme und ihre Loesungen, getroffene technische Entscheidungen. Antworte NUR mit dem reinen Zusammenfassungstext, ohne Anführungszeichen, ohne Präfix, ohne Zeilenumbrüche.'

$zusammenfassung = ""
try {
    $rohausgabe = & claude -p $prompt 2>$null
    if ($rohausgabe -is [array]) {
        $zusammenfassung = ($rohausgabe -join " ")
    } else {
        $zusammenfassung = [string]$rohausgabe
    }
    $zusammenfassung = $zusammenfassung.Trim()
} catch {
    $zusammenfassung = ""
}

if (-not $zusammenfassung) {
    Schreibehistoryeintrag "(automatische Zusammenfassung fehlgeschlagen)"
    exit 0
}

Schreibehistoryeintrag $zusammenfassung
exit 0
