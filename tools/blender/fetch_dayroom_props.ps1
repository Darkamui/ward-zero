# Download the CC0 chair and verify the publisher's file checksums.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$assetRoot = Join-Path $projectRoot 'art-src/shared/models/painted_wooden_chair_01'
New-Item -ItemType Directory -Force -Path (Join-Path $assetRoot 'textures') | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $projectRoot 'art-src/.gdignore') | Out-Null
$asset = (Invoke-RestMethod -Uri 'https://api.polyhaven.com/files/painted_wooden_chair_01').gltf.'2k'.gltf
$files = @(@{name='painted_wooden_chair_01_2k.gltf'; data=$asset})
foreach ($entry in $asset.include.PSObject.Properties) {
    $files += @{name=$entry.Name; data=$entry.Value}
}
$records = foreach ($file in $files) {
    $destination = [IO.Path]::GetFullPath((Join-Path $assetRoot $file.name))
    if (-not $destination.StartsWith($assetRoot + [IO.Path]::DirectorySeparatorChar)) {
        throw "Download path escapes the asset directory: $destination"
    }
    if (-not (Test-Path -LiteralPath $destination)) {
        Invoke-WebRequest -Uri $file.data.url -OutFile $destination
    }
    $actual = (Get-FileHash -LiteralPath $destination -Algorithm MD5).Hash.ToLowerInvariant()
    if ($actual -ne $file.data.md5) { throw "Checksum mismatch: $destination" }
    @{path=$file.name; url=$file.data.url; md5=$actual;
      sha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()}
}
$source = @{
    asset='Painted Wooden Chair 01'; author='Kuutti Siitonen'; license='CC0-1.0';
    source='https://polyhaven.com/a/painted_wooden_chair_01';
    license_url='https://polyhaven.com/license'; files=@($records)
}
$json = $source | ConvertTo-Json -Depth 8
$json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $assetRoot 'source.json')
$reviewRoot = Join-Path $projectRoot 'production/art-review/g01_dayroom'
New-Item -ItemType Directory -Force -Path $reviewRoot | Out-Null
$json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $reviewRoot 'prop-sources.json')
Write-Output 'Verified Painted Wooden Chair 01 and its four dependencies.'
