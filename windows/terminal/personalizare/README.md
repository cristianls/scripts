# **Configurare Automatizată pentru Windows Terminal**

Acest repository conține un script PowerShell pentru a automatiza configurarea unui mediu de dezvoltare modern, productiv și plăcut vizual în Windows Terminal. Scriptul instalează și configurează unelte esențiale precum Oh My Posh, Terminal Icons, și un font optimizat pentru programare.

**Prerechizite Obligatorii:**

Pentru ca scriptul să funcționeze corect, asigură-te că ai instalat și configurat în prealabil următoarele componente:

* [**Windows Terminal**](https://github.com/microsoft/terminal): Instalat din Microsoft Store și setat ca terminal implicit în Windows.  
* [**PowerShell 7+**](https://github.com/PowerShell/PowerShell): Recomandat să instalezi cea mai recentă versiune pentru compatibilitate maximă.  
* [**winget**](https://learn.microsoft.com/en-us/windows/package-manager/winget/): Asigură-te că managerul de pachete winget este actualizat la zi din Microsoft Store (caută "App Installer").  
* [**JetBrains Mono Nerd Font**](https://www.nerdfonts.com/font-downloads): Scriptul va încerca să instaleze acest font, dar este recomandat să-l ai deja instalat pentru a evita eventuale erori.

## **✨ Funcționalități**

Scriptul va configura următoarele:

* **🎨 Prompt Personalizat**: Instalează **Oh My Posh** și aplică o temă custom, curată și informativă, care afișează statusul Git, versiuni de limbaje de programare și altele.  
* **📁 Pictograme pentru Fișiere**: Instalează modulul **Terminal-Icons** pentru a afișa iconițe specifice pentru fișiere și directoare direct în terminal.  
* **🚀 Navigare Rapidă**: Adaugă modulul **z** care permite navigarea rapidă în directoarele frecvent utilizate.  
* **✍️ Editare Avansată în Linia de Comandă**: Configurează **PSReadLine** pentru o experiență îmbunătățită, incluzând autocompletare cu meniu (Tab), predicții bazate pe istoric și navigare eficientă.  
* **👓 Font Modern**: Instalează **JetBrains Mono Nerd Font**, un font optimizat pentru lizibilitate în cod și care conține toate pictogramele necesare.  
* **⚡ Aliasuri Utile**: Configurează aliasuri precum vim pentru nvim și open pentru Invoke-Item.

## **🚀 Utilizare**

Pentru a rula scriptul, urmează acești pași:

**1\. Descarcă Scriptul**

* Clonează acest repository sau descarcă fișierul Configure-Terminal.ps1 direct pe calculatorul tău.

**2\. Setează Politica de Execuție (dacă este necesar)**

* PowerShell are o politică de securitate care poate bloca rularea scripturilor locale. Pentru a permite execuția, deschide o consolă PowerShell **ca Administrator** și rulează următoarea comandă (o singură dată):  
  Set-ExecutionPolicy RemoteSigned \-Scope CurrentUser

**3\. Rulează Scriptul de Configurare**

* Navighează în directorul unde ai salvat scriptul.  
* Dă click dreapta pe fișierul Configure-Terminal.ps1 și selectează **"Run with PowerShell"**.  
* Scriptul va necesita drepturi de administrator pentru a instala uneltele necesare.

## **🔧 Configurare Manuală Finală (Obligatoriu)**

După ce scriptul finalizează execuția, mai este un singur pas manual de făcut:

1. Închide și redeschide complet Windows Terminal.  
2. Apasă Ctrl \+ , pentru a deschide **Settings** (Setări).  
3. În meniul din stânga, selectează profilul **Windows PowerShell**, apoi mergi la tabul **Appearance** (Aspect).  
4. În secțiunea Font face (Tip font), alege din listă **JetBrainsMono NF**.  
5. Apasă **Save** (Salvează).

## **🛡️ Siguranță la Rulare**

Scriptul este conceput pentru a fi **idempotent**, ceea ce înseamnă că este sigur de rulat de mai multe ori.

* **Nu va reinstala** aplicațiile și modulele care sunt deja prezente pe sistem.  
* **Nu va suprascrie** fișierele de configurare (myprofile.omp.json, Microsoft.PowerShell\_profile.ps1) dacă acestea există deja. Va adăuga doar setările lipsă, protejând astfel orice personalizare manuală pe care ai fi putut-o face.

\[\!NOTE\]  
Acest script a fost creat cu ocazia redactării articolului de pe blogul CLSB.net: https://clsb.net/configurare-terminal-windows/\.