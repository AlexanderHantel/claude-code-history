# SessionStart-Hook: laedt specs/history/history.md als additionalContext, damit
# Claude die Zusammenfassungen frueherer Sitzungen kennt.

$ErrorActionPreference = "Continue"

# Endlosschleifen-Schutz: aus einem von uns selbst gestarteten "claude -p"
# soll der Hook nichts laden.
if ($env:RENTENAUSKUNFT_HOOK_INTERN -eq "1") {
    exit 0
}

$projektVerzeichnis = $env:CLAUDE_PROJECT_DIR
if (-not $projektVerzeichnis) {
    $projektVerzeichnis = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$historyDatei = Join-Path $projektVerzeichnis "specs\history\history.md"
if (-not (Test-Path $historyDatei)) {
    exit 0
}

# [System.IO.File]::ReadAllText liefert eine reine String-Instanz ohne
# PSObject-Metadaten (PSPath, PSProvider, ReadCount), die sonst beim
# ConvertTo-Json mitserialisiert wuerden.
$historyInhalt = [System.IO.File]::ReadAllText($historyDatei, [System.Text.Encoding]::UTF8)

$kontext = "# Letzte Sitzungs-Zusammenfassungen (specs/history/history.md)`r`n`r`n" + $historyInhalt

$ausgabe = [PSCustomObject]@{
    hookSpecificOutput = [PSCustomObject]@{
        hookEventName     = "SessionStart"
        additionalContext = $kontext
    }
}

$ausgabe | ConvertTo-Json -Depth 5 -Compress
exit 0
