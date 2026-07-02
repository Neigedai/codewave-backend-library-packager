param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot,

  [Parameter(Mandatory = $true)]
  [string]$Version,

  [string]$FrontendDir,
  [string]$BackendLibraryDir,
  [string]$ServiceLibraryDir,
  [string]$JavaHome = $env:JAVA_HOME,
  [switch]$SkipFrontendBuild,
  [switch]$SkipServiceBuild,
  [switch]$SkipVersionUpdate
)

$ErrorActionPreference = "Stop"

function Resolve-RequiredPath([string]$Path, [string]$Label) {
  $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
  if (-not $resolved) { throw "未找到$Label：$Path" }
  return $resolved.Path
}

function Find-FirstDirByFile([string]$Root, [string]$RelativeFile, [string[]]$PreferredNames) {
  foreach ($name in $PreferredNames) {
    $candidate = Join-Path $Root $name
    if (Test-Path -LiteralPath (Join-Path $candidate $RelativeFile)) { return $candidate }
  }
  $matches = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter (Split-Path $RelativeFile -Leaf) |
    Where-Object { $_.FullName.EndsWith($RelativeFile, [StringComparison]::OrdinalIgnoreCase) } |
    Select-Object -First 1
  if ($matches) { return Split-Path -Parent $matches.FullName }
  return $null
}

function Find-MavenLibraryDir([string]$Root, [string[]]$PreferredNames) {
  foreach ($name in $PreferredNames) {
    $candidate = Join-Path $Root $name
    $pom = Join-Path $candidate "pom.xml"
    if (Test-Path -LiteralPath $pom) { return $candidate }
  }
  $poms = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter "pom.xml"
  foreach ($pom in $poms) {
    $text = Get-Content -LiteralPath $pom.FullName -Raw -Encoding UTF8
    if ($text -match "nasl-metadata-maven-plugin") { return Split-Path -Parent $pom.FullName }
  }
  return $null
}

function Set-ProjectVersion([string]$PomPath, [string]$NewVersion) {
  $pom = Get-Content -LiteralPath $PomPath -Raw -Encoding UTF8
  $pattern = [regex]::new("(?s)(<project\b.*?<version>)([^<]+)(</version>)")
  $updated = $pattern.Replace($pom, "`${1}$NewVersion`$3", 1)
  if ($updated -eq $pom) { throw "未能更新版本号：$PomPath" }
  Set-Content -LiteralPath $PomPath -Value $updated -Encoding UTF8
}

function Invoke-Step([string]$Title, [scriptblock]$Body) {
  Write-Host ""
  Write-Host "==> $Title"
  & $Body
}

function Test-Zip([string]$ZipPath) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
  try {
    $entries = $zip.Entries | ForEach-Object { $_.FullName }
    $hasAppHtml = $entries | Where-Object { $_ -match "static/app\.html$|app\.html$" } | Select-Object -First 1
    $badEntries = $entries | Where-Object {
      $_ -match "(^|/)node_modules/" -or
      $_ -match "(^|/)frontend/dist/" -or
      $_ -match "\.env($|\.)" -or
      $_ -match "\.zip$"
    }
    [pscustomobject]@{
      Zip = $ZipPath
      HasAppHtml = [bool]$hasAppHtml
      BadEntries = @($badEntries)
    }
  } finally {
    $zip.Dispose()
  }
}

$root = Resolve-RequiredPath $ProjectRoot "项目根目录"

if (-not $FrontendDir) {
  $FrontendDir = Find-FirstDirByFile -Root $root -RelativeFile "package.json" -PreferredNames @("frontend", "web", "client")
}
if (-not $BackendLibraryDir) {
  $BackendLibraryDir = Find-MavenLibraryDir -Root $root -PreferredNames @("backend-library", "backend", "server")
}
if (-not $ServiceLibraryDir) {
  $candidate = Join-Path $root "service-library"
  if (Test-Path -LiteralPath (Join-Path $candidate "pom.xml")) { $ServiceLibraryDir = $candidate }
}

$frontend = Resolve-RequiredPath $FrontendDir "前端目录"
$backend = Resolve-RequiredPath $BackendLibraryDir "后端依赖库目录"
$service = $null
if ($ServiceLibraryDir) { $service = Resolve-RequiredPath $ServiceLibraryDir "服务依赖库目录" }

$backendPom = Join-Path $backend "pom.xml"
$servicePom = if ($service) { Join-Path $service "pom.xml" } else { $null }
$distHtml = Join-Path $frontend "dist\index.html"
$appHtml = Join-Path $backend "src\main\resources\static\app.html"

if (-not (Test-Path -LiteralPath $backendPom)) { throw "后端依赖库缺少 pom.xml：$backendPom" }

if (-not $SkipVersionUpdate) {
  Invoke-Step "更新 Maven 版本号为 $Version" {
    if ($servicePom -and (Test-Path -LiteralPath $servicePom)) { Set-ProjectVersion -PomPath $servicePom -NewVersion $Version }
    Set-ProjectVersion -PomPath $backendPom -NewVersion $Version
  }
}

if (-not $SkipFrontendBuild) {
  Invoke-Step "构建前端" {
    Push-Location $frontend
    try {
      npm install
      npm run build
    } finally {
      Pop-Location
    }
  }
}

Invoke-Step "嵌入 app.html" {
  if (-not (Test-Path -LiteralPath $distHtml)) { throw "未找到前端构建产物：$distHtml" }
  $appDir = Split-Path -Parent $appHtml
  New-Item -ItemType Directory -Force -Path $appDir | Out-Null
  Copy-Item -LiteralPath $distHtml -Destination $appHtml -Force
  Write-Host "已复制到：$appHtml"
}

if ($JavaHome) {
  $env:JAVA_HOME = $JavaHome
  $env:Path = (Join-Path $JavaHome "bin") + ";" + $env:Path
}

if ($service -and -not $SkipServiceBuild) {
  Invoke-Step "构建服务依赖库" {
    Push-Location $service
    try { mvn -DskipTests clean package } finally { Pop-Location }
  }
}

Invoke-Step "构建后端依赖库" {
  Push-Location $backend
  try { mvn -DskipTests clean package } finally { Pop-Location }
}

Invoke-Step "检查 zip 产物" {
  $zips = @()
  if ($service) { $zips += Get-ChildItem -LiteralPath (Join-Path $service "target") -Filter "*.zip" -ErrorAction SilentlyContinue }
  $zips += Get-ChildItem -LiteralPath (Join-Path $backend "target") -Filter "*.zip" -ErrorAction SilentlyContinue
  if (-not $zips -or $zips.Count -eq 0) { throw "未找到依赖库 zip 产物" }

  foreach ($zip in $zips) {
    $result = Test-Zip -ZipPath $zip.FullName
    Write-Host "ZIP: $($result.Zip)"
    Write-Host "  包含 app.html: $($result.HasAppHtml)"
    if ($result.BadEntries.Count -gt 0) {
      Write-Host "  可疑条目:"
      $result.BadEntries | ForEach-Object { Write-Host "  - $_" }
    }
  }
}
