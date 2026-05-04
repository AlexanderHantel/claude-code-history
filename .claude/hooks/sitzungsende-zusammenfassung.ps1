# SessionEnd-Trigger-Skript fuer Claude Code.
# Laeuft synchron, parst stdin (transcript_path), startet das Worker-Skript
# detached im Hintergrund und kehrt sofort zurueck, damit das Schliessen
# der Sitzung nicht blockiert wird.

$ErrorActionPreference = "Stop"

# Endlosschleifen-Schutz: Wenn dieser Hook aus einem von uns selbst
# gestarteten "claude -p"-Sub-Prozess kommt, nichts tun.
if ($env:CLAUDE_HISTORY_HOOK_INTERN -eq "1") {
    exit 0
}

$transcriptPfad = ""
$stdinText = [Console]::In.ReadToEnd()
if ($stdinText) {
    try {
        $eingangsdaten = $stdinText | ConvertFrom-Json -ErrorAction Stop
        if ($eingangsdaten.transcript_path) {
            $transcriptPfad = [string]$eingangsdaten.transcript_path
        }
    } catch {
        $transcriptPfad = ""
    }
}

$projektVerzeichnis = $env:CLAUDE_PROJECT_DIR
if (-not $projektVerzeichnis) {
    $projektVerzeichnis = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$workerSkript = Join-Path $PSScriptRoot "sitzungsende-zusammenfassung-worker.ps1"
if (-not (Test-Path $workerSkript)) {
    exit 0
}

# Umgebungsvariable fuer den Sub-Prozess: verhindert, dass der spaeter im
# Worker eingebettete "claude -p"-Aufruf die Hooks dieses Projekts erneut
# ausloest und so eine Endlosschleife erzeugt.
$env:CLAUDE_HISTORY_HOOK_INTERN = "1"

$argumentListe = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $workerSkript,
    "-TranscriptPfad", $transcriptPfad,
    "-ProjektVerzeichnis", $projektVerzeichnis
)

Start-Process -FilePath "powershell.exe" `
    -ArgumentList $argumentListe `
    -WindowStyle Hidden | Out-Null

exit 0
