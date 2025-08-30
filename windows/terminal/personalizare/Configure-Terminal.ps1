<#
.SYNOPSIS
    Script pentru configurarea sigură și non-distructivă a Windows Terminal.

.DESCRIPTION
    Acest script instalează software-ul și modulele necesare, inclusiv fonta
    JetBrains Mono Nerd Font. Verifică componentele existente și adaugă 
    setările lipsă fără a suprascrie configurațiile curente.
    Necesită drepturi de administrator pentru a rula.

.NOTES
    Autor: Gemini
    Versiune: 1.2 - JetBrains Mono
#>

# Pasul 0: Verificarea drepturilor de Administrator
Write-Host "Verificare drepturi de administrator..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "EROARE: Acest script necesită drepturi de administrator." -ForegroundColor Red
    Write-Host "Te rog, rulează scriptul într-o fereastră PowerShell deschisă ca Administrator." -ForegroundColor Cyan
    Read-Host "Apasă Enter pentru a ieși."
    exit
}
Write-Host "Drepturi de administrator confirmate." -ForegroundColor Green

# Pasul 1: Informare despre politica de execuție
Write-Host "`n------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "Informații despre Politica de Execuție (Execution Policy)" -ForegroundColor Cyan
Write-Host "Dacă execuția scriptului eșuează, deschide o consolă PowerShell ca Administrator și rulează comanda:"
Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
Write-Host "------------------------------------------------------------`n" -ForegroundColor Magenta
Start-Sleep -Seconds 2

# Pasul 2: Instalarea software-ului necesar cu Winget
Write-Host "Pasul 1: Verificarea și instalarea aplicațiilor necesare..." -ForegroundColor Yellow
$packages = @(
    @{ Name = "Oh My Posh"; Id = "JanDeDobbeleer.OhMyPosh" },
    @{ Name = "Neovim"; Id = "Neovim.Neovim" },
    @{ Name = "JetBrains Mono Nerd Font"; Id = "NerdFonts.JetBrainsMono" } # FONT ACTUALIZAT
)

# Actualizează sursele winget (fără parametrul --silent pentru compatibilitate)
Write-Host "Actualizare surse winget..." -ForegroundColor Cyan
winget source update
Write-Host "Surse actualizate." -ForegroundColor Green

foreach ($pkg in $packages) {
    Write-Host "Verificare $($pkg.Name)..."
    winget list --id $pkg.Id --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$($pkg.Name) este deja instalat. Se omite." -ForegroundColor Cyan
    } else {
        Write-Host "Instalare $($pkg.Name)..."
        winget install --id $pkg.Id --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "A eșuat instalarea $($pkg.Name)." -ForegroundColor Red
        } else {
            Write-Host "$($pkg.Name) a fost instalat cu succes." -ForegroundColor Green
        }
    }
}

# Pasul 3: Instalarea modulelor PowerShell
Write-Host "`nPasul 2: Verificarea și instalarea modulelor PowerShell..." -ForegroundColor Yellow
$psModules = @("Terminal-Icons", "z", "PSReadLine")

foreach ($mod in $psModules) {
    Write-Host "Verificare modul $mod..."
    if (Get-Module -ListAvailable -Name $mod) {
        Write-Host "Modulul $mod este deja instalat. Se omite." -ForegroundColor Cyan
    } else {
        Write-Host "Instalare modul $mod..."
        Install-Module -Name $mod -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
        Write-Host "Modulul $mod a fost instalat." -ForegroundColor Green
    }
}

# Pasul 4: Crearea fișierelor de configurare (non-distructiv)
Write-Host "`nPasul 3: Crearea fișierelor de configurare (doar dacă lipsesc)..." -ForegroundColor Yellow

# Definim calea pentru tema Oh My Posh
$poshThemesPath = "$HOME\.poshthemes"
if (-not (Test-Path $poshThemesPath)) {
    New-Item -Path $poshThemesPath -ItemType Directory | Out-Null
}
$themeFilePath = Join-Path $poshThemesPath "myprofile.omp.json"

# Crează fișierul temei doar dacă nu există
if (-not (Test-Path $themeFilePath)) {
    Write-Host "Fișierul temei nu există. Se crează: $themeFilePath" -ForegroundColor Green
    $jsonThemeContent = @'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [ { "type": "prompt", "alignment": "left", "segments": [ { "type": "os", "style": "powerline", "foreground": "cyan", "template": "{{ if .WSL }}WSL at {{ end }}{{.Icon}}" }, { "type": "path", "style": "plain", "foreground": "cyan", "properties": { "style": "full" }, "template": " {{ .Path }} " }, { "type": "git", "style": "plain", "foreground": "#F1502F", "properties": { "fetch_status": true }, "template": ":: {{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }} " } ] }, { "type": "prompt", "alignment": "right", "segments": [ { "type": "root", "style": "plain", "foreground": "red", "template": "| root " }, { "type": "dart", "style": "powerline", "foreground": "#06A4CE", "template": "| \ue798 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} " }, { "type": "node", "style": "powerline", "foreground": "#6CA35E", "template": "| \ue718 {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }} " }, { "type": "python", "style": "plain", "foreground": "#4584b6", "properties": { "display_mode": "context", "fetch_virtual_env": true }, "template": "| \ue235 {{ .Venv }} " }, { "type": "battery", "style": "powerline", "invert_powerline": true, "foreground_templates": [ "{{if eq \"Charging\" .State.String}}#4caf50{{end}}", "{{if eq \"Discharging\" .State.String}}#40c4ff{{end}}", "{{if eq \"Full\" .State.String}}#ff0000{{end}}" ], "properties": { "charged_icon": "\uf00d ", "charging_icon": "\ue234 " }, "template": "| {{ if not .Error }}{{ .Icon }}{{ .Percentage }}{{ end }}{{ .Error }} \uf295 " }, { "type": "time", "style": "plain", "foreground": "lightGreen", "template": "| {{ .CurrentDate | date .Format }} " } ] }, { "type": "prompt", "alignment": "left", "newline": true, "segments": [ { "type": "status", "style": "powerline", "foreground": "lightGreen", "foreground_templates": [ "{{ if gt .Code 0 }}red{{ end }}" ], "properties": { "always_enabled": true }, "template": "\u279c " } ] } ],
  "version": 2
}
'@
    $jsonThemeContent | Out-File -FilePath $themeFilePath -Encoding utf8
} else {
    Write-Host "Fișierul temei există deja. Se omite crearea." -ForegroundColor Cyan
}

# Adaugă setările la profilul PowerShell doar dacă lipsesc
Write-Host "`nVerificare profil PowerShell: $PROFILE"
# Asigură-te că fișierul de profil există
if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    Write-Host "Fișierul de profil a fost creat."
}
$currentProfileContent = Get-Content $PROFILE -Raw

# Bloc de cod pentru Oh My Posh
$ompBlock = @"
# OhMyPosh - Inițializează promptul personalizat
oh-my-posh init pwsh --config '$themeFilePath' | Invoke-Expression
"@
if ($currentProfileContent -notlike "*oh-my-posh init pwsh*") {
    Write-Host "Se adaugă configurația Oh My Posh la profil..." -ForegroundColor Green
    $ompBlock | Add-Content -Path $PROFILE
}

# Bloc de cod pentru module
$modulesBlock = @"
# Terminal-Icons - Afișează pictograme pentru fișiere și foldere
Import-Module -Name Terminal-Icons

# z - Navigare rapidă în directoare
Import-Module -Name z
"@
if ($currentProfileContent -notlike "*Import-Module -Name Terminal-Icons*") {
     Write-Host "Se adaugă importul modulelor la profil..." -ForegroundColor Green
    $modulesBlock | Add-Content -Path $PROFILE
}

# Bloc de cod pentru PSReadLine și aliasuri
$settingsBlock = @"
# PSReadLine & Aliasuri
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -PredictionSource History
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -Colors @{ InlinePrediction = '#565f89'}
Set-PSReadLineKeyHandler -Chord "Ctrl+RightArrow" -Function ForwardWord
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -PredictionViewStyle ListView
New-Alias open Invoke-Item
Set-Alias vim nvim
"@
if ($currentProfileContent -notlike "*Set-PSReadlineKeyHandler -Key Tab*") {
     Write-Host "Se adaugă setările PSReadLine și aliasurile la profil..." -ForegroundColor Green
    $settingsBlock | Add-Content -Path $PROFILE
}

Write-Host "`nProfilul PowerShell a fost verificat și actualizat cu setările lipsă." -ForegroundColor Green


Write-Host "`n`n------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "✅ Configurare finalizată cu succes!" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "PASUL FINAL - ACȚIUNE MANUALĂ NECESARĂ:" -ForegroundColor Yellow
Write-Host "1. Închide și redeschide complet Windows Terminal."
Write-Host "2. Deschide setările (apasă 'Ctrl' + ',')."
Write-Host "3. Mergi la profilul 'Windows PowerShell' -> 'Appearance' (Aspect)."
Write-Host "4. În secțiunea 'Font face' (Tip font), selectează 'JetBrainsMono NF' din listă."
Write-Host "5. Salvează setările."
Write-Host "------------------------------------------------------------`n"
Read-Host "Apasă Enter pentru a închide scriptul."