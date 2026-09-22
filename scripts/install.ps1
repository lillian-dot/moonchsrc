param(
  [string]$Version = $(if ($env:MOONCHSRC_VERSION) { $env:MOONCHSRC_VERSION } else { "latest" }),
  [string]$InstallDir = $(if ($env:MOONCHSRC_INSTALL_DIR) { $env:MOONCHSRC_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "Programs\moonchsrc" })
)

$ErrorActionPreference = "Stop"
$repo = "trail-it/moonchsrc"
$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()

if ($architecture -ne "X64") {
  throw "moonchsrc: unsupported Windows architecture: $architecture (0.1.0 provides Windows x64)"
}

$asset = "moonchsrc-x86_64-windows.exe"
if ($Version -eq "latest") {
  $baseUrl = "https://github.com/$repo/releases/latest/download"
} else {
  $tag = if ($Version.StartsWith("v")) { $Version } else { "v$Version" }
  $baseUrl = "https://github.com/$repo/releases/download/$tag"
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("moonchsrc-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
  $download = Join-Path $tempDir $asset
  $checksums = Join-Path $tempDir "SHA256SUMS"
  Write-Host "Downloading $asset..."
  Invoke-WebRequest -Uri "$baseUrl/$asset" -OutFile $download
  Invoke-WebRequest -Uri "$baseUrl/SHA256SUMS" -OutFile $checksums

  $line = Get-Content $checksums | Where-Object { $_ -match "^[0-9a-fA-F]{64}\s+$([regex]::Escape($asset))$" } | Select-Object -First 1
  if (-not $line) {
    throw "moonchsrc: checksum for $asset is missing"
  }
  $expected = ($line -split "\s+")[0].ToLowerInvariant()
  $actual = (Get-FileHash -Algorithm SHA256 $download).Hash.ToLowerInvariant()
  if ($actual -ne $expected) {
    throw "moonchsrc: checksum verification failed"
  }

  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  $destination = Join-Path $InstallDir "moonchsrc.exe"
  Copy-Item -Force $download $destination

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $pathEntries = @($userPath -split ";" | Where-Object { $_ })
  if ($InstallDir -notin $pathEntries) {
    $newPath = (@($pathEntries) + $InstallDir) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added $InstallDir to your user PATH. Open a new terminal to use it."
  }
  Write-Host "Installed moonchsrc to $destination"
} finally {
  Remove-Item -Recurse -Force -LiteralPath $tempDir -ErrorAction SilentlyContinue
}
