param(
  [switch]$NoBrowser
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDir '..\..\..'))
$logDir = Join-Path $repoRoot '.codex-run'
$serveScript = Join-Path $scriptDir 'serve-board.ps1'
$boardUrl = 'http://127.0.0.1:8099/design-mockup/project-board.html'
$chromePath = 'C:\Program Files\Google\Chrome\Application\chrome.exe'

function Test-BoardServer {
  try {
    $response = Invoke-WebRequest -UseBasicParsing -Uri $boardUrl -TimeoutSec 2
    return $response.StatusCode -eq 200
  } catch {
    return $false
  }
}

if (-not (Test-Path $logDir)) {
  New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

if (-not (Test-BoardServer)) {
  Start-Process -FilePath 'powershell.exe' `
    -ArgumentList @('-ExecutionPolicy', 'Bypass', '-File', $serveScript) `
    -WorkingDirectory $repoRoot `
    -WindowStyle Hidden

  $started = $false
  for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 250
    if (Test-BoardServer) {
      $started = $true
      break
    }
  }

  if (-not $started) {
    throw "Board server did not start on $boardUrl"
  }
}

if (-not $NoBrowser) {
  Start-Process -FilePath $chromePath -ArgumentList @('--new-window', $boardUrl)
}

Write-Host "Board ready at $boardUrl"
