WP-Dev-Docker: Mediu de Dezvoltare WordPress Automatizat cu IPVLAN
Acest script Bash automatizează complet procesul de configurare a unui mediu de dezvoltare WordPress pe un server Debian, utilizând Docker. Caracteristica sa principală este crearea unei rețele Docker de tip ipvlan, care alocă containerului Nginx o adresă IP unică în rețeaua locală (LAN). Astfel, site-ul devine accesibil de pe orice dispozitiv din rețea, ca și cum ar fi o mașină fizică separată.

Scriptul a fost creat ca parte a unui tutorial detaliat publicat pe blogul CLSB.net. Vă recomandăm să citiți articolul pentru a înțelege pe deplin toți pașii și conceptele din spatele acestei configurații.

Caracteristici Principale
✨ Configurare interactivă completă: Scriptul solicită la început toate informațiile necesare (interfață de rețea, IP-uri, domenii, credențiale), eliminând necesitatea de a edita fișiere manual.
✅ Validări automate: Verifică existența interfețelor de rețea și dacă IP-urile alese sunt deja în uz.
👨‍🏫 Comenzi preliminare ghidate: Afișează comenzile critice (update, instalare dependențe) și așteaptă confirmarea utilizatorului înainte de a continua.
🛡️ Avertizări integrate: Informează activ utilizatorul despre configurările cheie cu implicații de securitate, cum ar fi accesul sudo fără parolă.
🐧 Compatibilitate Debian: Optimizat și testat pentru a funcționa pe sistemele de operare Debian.
🇷🇴 Comentarii și mesaje în română: Toate explicațiile și interacțiunile din script sunt în limba română.
📊 Raportare detaliată: La final, afișează un rezumat complet cu toate detaliile configurației (IP-uri, directoare, credențiale, comenzi utile).
⚡ Optimizat pentru Dezvoltare: Toate straturile de cache (Nginx, PHP OPCache, WordPress) sunt complet dezactivate pentru a reflecta instantaneu orice modificare în cod.

Cum Funcționează?
Scriptul urmează un proces logic pentru a asigura o instalare corectă și transparentă:

Verificări preliminare: Se asigură că este rulat ca root, detectează dacă sistemul este Debian și verifică existența utilitarelor esențiale precum docker.

Configurare interactivă: Colectează toate datele necesare de la utilizator.

Ghidaj pentru comenzi preliminare: Instruiește utilizatorul să actualizeze sistemul, să instaleze dependențele (docker, acl, etc.) și să pornească serviciul Docker.

Setup automat:

Creează directoarele necesare (/opt/wpdev, /srv/docker-data/wordpress).

Configurează un utilizator de dezvoltare cu acces sudo fără parolă și opțional adaugă cheia SSH.

Setează permisiuni flexibile folosind acl.

Creează rețeaua Docker pubnet de tip ipvlan.

Generează toate fișierele de configurare: docker-compose.yml, nginx.conf, php.ini etc.

Pornește stack-ul de containere (Nginx, WordPress/PHP-FPM, MariaDB).

Instalare WordPress: Folosește wp-cli pentru a instala și configura automat instanța WordPress.

Teste finale: Efectuează teste de conectivitate curl pentru a verifica dacă serverul web răspunde corect.

Afișare rezumat: Prezintă un sumar clar al întregii configurații.

Cerințe
Un server (fizic sau virtual) cu o versiune recentă de Debian (10, 11, 12).

Acces root sau un utilizator cu privilegii sudo.

Conexiune la internet pentru a descărca pachetele și imaginile Docker.

Utilizare
Procesul de instalare este complet ghidat.

Bash

# 1. Descarcă scriptul
wget -O bootstrap-wpdev.sh [URL-ul-raw-al-scriptului-pe-GitHub]

# 2. Fă-l executabil
chmod +x bootstrap-wpdev.sh

# 3. Rulează-l ca root
sudo ./bootstrap-wpdev.sh
Urmați instrucțiunile afișate în terminal. Scriptul vă va cere toate informațiile necesare și vă va ghida pas cu pas.

După Instalare
La finalul execuției, scriptul va afișa un sumar detaliat. Cel mai important pas pe care trebuie să-l faci este pe computerul tău local (client), nu pe server:

Adaugă următoarea linie în fișierul tău hosts (/etc/hosts pe Linux/macOS sau C:\Windows\System32\drivers\etc\hosts pe Windows):

192.168.1.100  wp.test
(Înlocuiește 192.168.1.100 și wp.test cu IP-ul containerului și domeniul pe care le-ai configurat în timpul instalării).

Acum poți accesa site-ul direct din browser la adresa http://wp.test.

Comenzi Utile
Pentru a gestiona mediul de dezvoltare, folosește comenzile de mai jos din directorul proiectului (/opt/wpdev):

Bash

# Intră în directorul proiectului
cd /opt/wpdev

# Verifică statusul containerelor
docker compose ps

# Vizualizează logurile în timp real
docker compose logs -f

# Repornește toate serviciile
docker compose restart

# Oprește și șterge containerele
docker compose down

# Pornește serviciile în background
docker compose up -d
Pentru o analiză completă a fiecărei linii de cod și a conceptelor folosite, vizitați articolul de pe CLSB.net.