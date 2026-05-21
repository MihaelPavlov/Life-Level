param(
    [string]$DockerUser = "mpavlov9905",
    [string]$ImageName = "life-level-api"
)

$ErrorActionPreference = "Stop"

$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$version = "latest.$timestamp"
$localImage = $ImageName
$remoteImage = "$DockerUser/$ImageName`:$version"

function Invoke-Docker {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & docker @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "docker $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

Write-Host "Building Life-Level API image..."
Invoke-Docker -Arguments @("build", "-t", $localImage, "-f", "backend/Dockerfile", "backend")

Write-Host "Tagging image as $remoteImage..."
Invoke-Docker -Arguments @("tag", $localImage, $remoteImage)

Write-Host "Pushing $remoteImage..."
Invoke-Docker -Arguments @("push", $remoteImage)

Write-Host "Latest tag pushed: $version"
Write-Host "Render image URL: docker.io/$remoteImage"
