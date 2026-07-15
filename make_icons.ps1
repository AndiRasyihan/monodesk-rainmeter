# MonoDesk - ekstrak ikon aplikasi otomatis dari daftar AppNPath di Variables.inc
# Mendukung:
#   - File .exe / .bat / .cmd / .lnk (ikon asli file tersebut)
#   - Nama pendek App Paths seperti "chrome" / "winword" (cara kerja dialog Run)
#   - Aplikasi Microsoft Store via protokol, mis. "whatsapp:" (logo asli paketnya)
# Jalankan ulang skrip ini setiap kali kamu mengganti daftar aplikasi launcher:
#   powershell -ExecutionPolicy Bypass -File make_icons.ps1

Add-Type -AssemblyName System.Drawing

$vars = Join-Path $PSScriptRoot 'MonoDesk\@Resources\Variables.inc'
$iconDir = Join-Path $PSScriptRoot 'MonoDesk\@Resources\Icons'
New-Item -ItemType Directory -Force -Path $iconDir | Out-Null

$content = Get-Content $vars

function Resolve-AppPath([string]$p) {
    if (Test-Path $p) { return (Resolve-Path $p).Path }
    $cmd = Get-Command $p -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { return $cmd.Source }
    # Registry App Paths (yang dipakai dialog Run/start utk "chrome", "winword", dll)
    $exeName = $p
    if ($exeName -notmatch '\.exe$') { $exeName = "$p.exe" }
    foreach ($root in 'HKLM:', 'HKCU:') {
        $key = "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"
        if (Test-Path $key) {
            $val = (Get-ItemProperty $key -ErrorAction SilentlyContinue).'(default)'
            if ($val) {
                $val = $val.Trim('"')
                if (Test-Path $val) { return $val }
            }
        }
    }
    return $null
}

function Save-FallbackIcon([string]$out) {
    # Ikon "globe" putih sederhana bila ikon asli tidak bisa diambil
    $bmp = New-Object System.Drawing.Bitmap 48, 48
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 3
    $g.DrawEllipse($pen, 6, 6, 36, 36)
    $g.DrawLine($pen, 6, 24, 42, 24)
    $g.DrawEllipse($pen, 16, 6, 16, 36)
    $pen.Dispose()
    $g.Dispose()
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function Save-UwpIcon([string]$pattern, [string]$out) {
    # Ambil logo asli aplikasi Microsoft Store dari manifest paketnya
    try {
        $pkg = Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $pkg) { return $false }
        $manPath = Join-Path $pkg.InstallLocation 'AppxManifest.xml'
        if (-not (Test-Path $manPath)) { return $false }
        [xml]$man = Get-Content $manPath
        $logo = $man.Package.Applications.Application.VisualElements.Square44x44Logo
        if (-not $logo) { $logo = $man.Package.Properties.Logo }
        if (-not $logo) { return $false }
        if ($logo -is [array]) { $logo = $logo[0] }
        $base = Join-Path $pkg.InstallLocation $logo
        $dir = Split-Path $base
        $name = [IO.Path]::GetFileNameWithoutExtension($base)
        $cand = Get-ChildItem -Path $dir -Filter "$name*.png" -ErrorAction SilentlyContinue |
            Sort-Object Length -Descending | Select-Object -First 1
        if (-not $cand) { return $false }
        Copy-Item $cand.FullName $out -Force
        return $true
    }
    catch { return $false }
}

for ($i = 1; $i -le 6; $i++) {
    $out = Join-Path $iconDir "App$i.png"
    $line = $content | Where-Object { $_ -match "^App${i}Path=" } | Select-Object -First 1
    if (-not $line) {
        Save-FallbackIcon $out
        Write-Host "App$i : tidak ada di Variables.inc -> ikon fallback"
        continue
    }
    $path = ($line -replace "^App${i}Path=", '').Trim()

    # Protokol aplikasi Store (mis. whatsapp:) -> cari logo paket UWP-nya
    if ($path -match '^([A-Za-z][A-Za-z0-9+.-]*):' -and $path -notmatch '\\') {
        $proto = $Matches[1]
        if (Save-UwpIcon "*$proto*" $out) {
            Write-Host "App$i : logo Store untuk '$proto' -> OK"
            continue
        }
        Save-FallbackIcon $out
        Write-Host "App$i : protokol '$proto' tanpa logo -> ikon fallback"
        continue
    }

    $exe = Resolve-AppPath $path
    if ($exe -and $exe -match '\.(exe|bat|cmd|lnk)$') {
        try {
            $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exe)
            $bmp = $icon.ToBitmap()
            $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
            $icon.Dispose()
            Write-Host "App$i : $exe -> OK"
            continue
        }
        catch {
            Write-Host "App$i : gagal ekstrak, pakai fallback"
        }
    }
    Save-FallbackIcon $out
    Write-Host "App$i : tidak dikenali ($path) -> ikon fallback"
}

Write-Host "Selesai. Ikon tersimpan di: $iconDir"
