$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDir '..\..\..'))
$port = 8099

function Get-ContentType($path) {
  switch ([System.IO.Path]::GetExtension($path).ToLowerInvariant()) {
    '.html' { return 'text/html; charset=utf-8' }
    '.md' { return 'text/markdown; charset=utf-8' }
    '.js' { return 'application/javascript; charset=utf-8' }
    '.css' { return 'text/css; charset=utf-8' }
    '.json' { return 'application/json; charset=utf-8' }
    '.png' { return 'image/png' }
    '.jpg' { return 'image/jpeg' }
    '.jpeg' { return 'image/jpeg' }
    '.svg' { return 'image/svg+xml' }
    default { return 'application/octet-stream' }
  }
}

function Write-Response($stream, $statusCode, $statusText, $bodyBytes, $contentType) {
  $header = "HTTP/1.1 $statusCode $statusText`r`n" +
    "Content-Type: $contentType`r`n" +
    "Content-Length: $($bodyBytes.Length)`r`n" +
    "Cache-Control: no-store`r`n" +
    "Connection: close`r`n`r`n"
  $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
  $stream.Write($headerBytes, 0, $headerBytes.Length)
  $stream.Write($bodyBytes, 0, $bodyBytes.Length)
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
$listener.Start()
Write-Host "LifeLevel board server listening on http://127.0.0.1:$port/"

while ($true) {
  $client = $listener.AcceptTcpClient()
  try {
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
    $requestLine = $reader.ReadLine()
    if ([string]::IsNullOrWhiteSpace($requestLine)) {
      $client.Close()
      continue
    }

    do {
      $line = $reader.ReadLine()
    } while ($line -ne '')

    $parts = $requestLine.Split(' ')
    if ($parts.Length -lt 2) {
      $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes('Bad request')
      Write-Response $stream 400 'Bad Request' $bodyBytes 'text/plain; charset=utf-8'
      $client.Close()
      continue
    }

    $rawPath = [Uri]::UnescapeDataString($parts[1].Split('?')[0])
    if ($rawPath -eq '/') {
      $rawPath = '/design-mockup/project-board.html'
    }

    $relativePath = $rawPath.TrimStart('/') -replace '/', '\'
    $fullPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $relativePath))

    if (-not $fullPath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path $fullPath -PathType Leaf)) {
      $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes('Not found')
      Write-Response $stream 404 'Not Found' $bodyBytes 'text/plain; charset=utf-8'
      $client.Close()
      continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    Write-Response $stream 200 'OK' $bytes (Get-ContentType $fullPath)
  } catch {
    try {
      $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes('Server error')
      Write-Response $stream 500 'Internal Server Error' $bodyBytes 'text/plain; charset=utf-8'
    } catch {}
  } finally {
    $client.Close()
  }
}
