<#
  NileSky — go-live
  Run from the repo root in PowerShell:

      .\go-live.ps1            (defaults to GitHub user engkemo1)

  Does everything that doesn't need your Render password:
  safety checks -> local build -> create GitHub repo -> push -> open Render.
#>
param(
  [string]$GitHubUser = "engkemo1",
  [string]$RepoName = "nile_Sky",
  [switch]$Public
)

$ErrorActionPreference = "Stop"
function Step($n,$t){ Write-Host "`n[$n] $t" -ForegroundColor Yellow }
function Ok($t){ Write-Host "    $t" -ForegroundColor Green }

Write-Host "`n=== NileSky go-live ===" -ForegroundColor Cyan
if (-not (Test-Path ".\render.yaml")) { throw "Run this from the nilesky repo root." }

Step "0/6" "Checking git identity..."
if (-not (git config user.email)) {
  git config user.email "kemoeng40@gmail.com"
  Write-Host "    set user.email = kemoeng40@gmail.com (local to this repo)"
}
if (-not (git config user.name)) {
  git config user.name "engkemo1"
  Write-Host "    set user.name = engkemo1 (local to this repo)"
}
Ok "identity ready"

Step "1/6" "Re-applying .gitignore rules to tracked files..."
$tracked = git ls-files
if ($tracked) { git rm -r --cached . --quiet }
git add -A
Ok "done"

Step "2/6" "Blocking secrets and oversized files..."
$staged = git diff --cached --name-only
$bad = $staged | Where-Object { $_ -match '\.env|\.apk|\.aab|\.ipa|\.zip' }
if ($bad) {
  Write-Host "    ABORT - these must never be committed:" -ForegroundColor Red
  $bad | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
  throw "Fix .gitignore first."
}
$big = $staged | Where-Object { (Test-Path $_) -and ((Get-Item $_).Length -gt 50MB) }
if ($big) {
  Write-Host "    ABORT - over 50MB, GitHub will reject:" -ForegroundColor Red
  $big | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
  throw "Publish these via a GitHub Release instead."
}
Ok "clean - no secrets, nothing oversized"

Step "3/6" "Building backend locally (catches what Render would hit)..."
Push-Location backend
npm install --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "npm install failed." }
npm run build
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "Backend build FAILED - fix before deploying." }
Pop-Location
Ok "backend compiles clean"

Step "4/6" "Committing..."
if (git diff --cached --name-only) {
  git commit -m "NileSky: fix Render blueprint, API base URLs, seed password, ignore rules" --quiet
  Ok "committed"
} else {
  Ok "nothing new to commit - continuing"
}

Step "5/6" "Creating GitHub repo and pushing..."
$remote = "https://github.com/$GitHubUser/$RepoName.git"
$vis = if ($Public) { "--public" } else { "--private" }
if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh repo view "$GitHubUser/$RepoName" *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "    creating $GitHubUser/$RepoName ($vis)..."
    gh repo create "$GitHubUser/$RepoName" $vis --source=. --remote=origin
  }
} else {
  Write-Host "    (gh CLI not found - create the repo at github.com/new first)" -ForegroundColor DarkYellow
}
if (git remote | Select-String -Quiet "^origin$") { git remote set-url origin $remote }
else { git remote add origin $remote }
git branch -M main
git push -u origin main
if ($LASTEXITCODE -ne 0) {
  Write-Host "`n    PUSH FAILED." -ForegroundColor Red
  Write-Host "    Most likely cause: git has no GitHub credentials saved yet." -ForegroundColor Red
  Write-Host "    A browser or credential window normally pops up - if it did not," -ForegroundColor Red
  Write-Host "    install GitHub CLI (winget install GitHub.cli), run 'gh auth login'," -ForegroundColor Red
  Write-Host "    then run this script again." -ForegroundColor Red
  throw "push failed"
}
Ok "pushed to $remote"

Step "6/6" "Opening Render..."
$deploy = "https://render.com/deploy?repo=https://github.com/$GitHubUser/$RepoName"
Start-Process $deploy
Ok "browser opened"

Write-Host "`n=== Now, in the Render tab ===" -ForegroundColor Cyan
Write-Host "  Sign in, then click Apply. The blueprint creates BOTH the Postgres"
Write-Host "  database and the API, and wires DATABASE_URL between them - so there"
Write-Host "  is nothing to paste."
Write-Host "`n  Verify in ~5 min:  https://nilesky-api.onrender.com/api/docs`n"
