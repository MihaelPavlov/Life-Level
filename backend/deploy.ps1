# Deploy Life-Level API to Docker Hub
# Usage: .\deploy.ps1

$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$version = "latest.$timestamp"

Write-Host "Building..."
docker build -t life-level-api -f Dockerfile .

Write-Host "Tagging..."
docker tag life-level-api mpavlov9905/life-level-api:$version

Write-Host "Pushing..."
docker push mpavlov9905/life-level-api:$version

Write-Host "Done! Image: mpavlov9905/life-level-api:$version"
Write-Host "Set this in Render and redeploy."
