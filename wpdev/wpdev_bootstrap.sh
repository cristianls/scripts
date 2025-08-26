#!/usr/bin/env bash
# bootstrap-wpdev.sh
# Script general pentru setup WordPress Development cu Docker
# Funcționează pe Debian și necesită configurare interactivă
#
# Caracteristici:
# - Creează rețeaua 'pubnet' (ipvlan) pe interfața specificată
# - Creează interfața host→container (opțional)
# - Ridică stack-ul wpdev: db + wordpress (php-fpm) + nginx
# - Montează directoarele și configurează logurile
# - Instalează WP (wp-cli) pe domeniul specificat
# - Configurare anti-cache completă (nginx + php.ini + php-fpm + MU plugin)
#
# Rulare:
#   sudo bash ./bootstrap-wpdev.sh

set -euo pipefail

### === CULORI ȘI UTILITĂȚI ===
GREEN=$'\033[1;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[1;31m'; BLUE=$'\033[1;34m'; NC=$'\033[0m'
ok(){ printf "%s[+]%s %s\n" "$GREEN" "$NC" "$*"; }
warn(){ printf "%s[!]%s %s\n" "$YELLOW" "$NC" "$*"; }
die(){ printf "%s[✗]%s %s\n" "$RED" "$NC" "$*"; exit 1; }
info(){ printf "%s[i]%s %s\n" "$BLUE" "$NC" "$*"; }

need(){ command -v "$1" >/dev/null 2>&1 || die "Lipsește utilitarul '$1'. Instalează-l și reîncearcă."; }
dc(){ if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi; }

ask_yes() {
    local prompt="$1"
    local response
    while true; do
        read -rp "$prompt (yes/no): " response
        case "$response" in
            yes|YES|Yes) return 0 ;;
            no|NO|No) return 1 ;;
            *) echo "Te rog răspunde cu 'yes' sau 'no'" ;;
        esac
    done
}

confirm_command() {
    local cmd="$1"
    local description="$2"
    
    echo
    info "$description"
    echo "Comandă de executat:"
    printf "%s%s%s\n" "$YELLOW" "$cmd" "$NC"
    echo
    
    if ask_yes "Ai executat această comandă și a funcționat corect?"; then
        return 0
    else
        die "Te rog execută comanda mai sus și reîncearcă scriptul."
    fi
}

### === VERIFICĂRI PRELIMINARE ===
[[ $EUID -eq 0 ]] || die "Rulează ca root (sudo)."

info "Verificăm dacă suntem pe Debian..."
if ! grep -qi debian /etc/os-release 2>/dev/null; then
    warn "Acest script este optimizat pentru Debian. Continuăm pe riscul tău..."
fi

need docker
if ! command -v visudo >/dev/null 2>&1; then 
    die "Lipsește 'visudo' (pachetul sudo). Instalează 'sudo' cu: apt-get update && apt-get install -y sudo"
fi

DC=$(dc)

### === CONFIGURARE INTERACTIVĂ ===
echo
echo "==========================================="
echo "  CONFIGURARE WORDPRESS DEVELOPMENT"  
echo "==========================================="
echo

# Detectare interfețe de rețea
info "Interfețe de rețea disponibile:"
ip -o link show | awk -F': ' '{print "  " $2}' | grep -v lo | head -10

echo
read -rp "Introdu numele interfeței de rețea (ex: eth0, ens18, enp0s3): " PARENT_IF
ip -o link show "$PARENT_IF" >/dev/null 2>&1 || die "Interfața $PARENT_IF nu există."

# Informații de rețea
echo
read -rp "Introdu subrețeaua LAN în format CIDR (ex: 192.168.1.0/24): " SUBNET_CIDR
read -rp "Introdu adresa IP a gateway-ului (ex: 192.168.1.1): " GATEWAY_IP
read -rp "Introdu IP-ul PUBLIC pentru containerul Nginx (ex: 192.168.1.100): " CONTAINER_IP
read -rp "Introdu IP-ul pentru interfața host (ex: 192.168.1.99): " HOST_SIDE_IP

# Validare IP-uri
if ip -4 addr | grep -qE "\\b${CONTAINER_IP}/" 2>/dev/null; then
    die "IP-ul ${CONTAINER_IP} este deja configurat pe host. Alege alt IP."
fi

if ping -c1 -W2 "$CONTAINER_IP" >/dev/null 2>&1; then
    warn "IP-ul ${CONTAINER_IP} răspunde în LAN. Dacă nu este containerul tău, alege alt IP."
    ask_yes "Continuă oricum?" || exit 1
fi

# Configurații de bază
echo
read -rp "Introdu domeniul pentru WordPress (ex: wp.test): " DOMAIN
read -rp "Introdu numele utilizatorului pentru dezvoltare (ex: dev): " DEV_USER
read -rp "Introdu numele utilizatorului admin WordPress (ex: admin): " WP_ADMIN_USER
read -rp "Introdu parola admin WordPress (ex: admin): " WP_ADMIN_PASS
read -rp "Introdu email-ul admin WordPress (ex: admin@example.test): " WP_ADMIN_EMAIL

# Configurare chei SSH
echo
if ask_yes "Vrei să configurezi chei SSH pentru utilizatorul de dezvoltare?"; then
    read -rp "Introdu calea către cheia publică SSH (ex: /root/.ssh/id_ed25519.pub): " PUBKEY_FILE
    if [[ ! -f "$PUBKEY_FILE" ]]; then
        warn "Fișierul $PUBKEY_FILE nu există. Va fi ignorat."
        PUBKEY_FILE=""
    fi
else
    PUBKEY_FILE=""
fi

### === CONFIGURARE CONSTANTE ===
PROJECT_NAME="wpdev"
COMPOSE_DIR="/opt/${PROJECT_NAME}"
DATA_DIR="/srv/docker-data/wordpress"
HTML_DIR="${DATA_DIR}/html"
LOGS_DIR="${DATA_DIR}/logs"
MYSQL_LOG_DIR="${LOGS_DIR}/mysql"
CREATE_PUBIPV=true

### === COMENZI PRELIMINARE PENTRU UTILIZATOR ===
echo
echo "==========================================="
echo "  COMENZI PRELIMINARE DE EXECUTAT"
echo "==========================================="
echo

# 1. Actualizare sistem
confirm_command "apt-get update && apt-get upgrade -y" \
    "Actualizează sistemul Debian"

# 2. Instalare dependențe
confirm_command "apt-get install -y docker.io docker-compose curl acl sudo wget" \
    "Instalează dependențele necesare"

# 3. Pornire Docker
confirm_command "systemctl enable docker && systemctl start docker" \
    "Activează și pornește serviciul Docker"

# 4. Verificare Docker
confirm_command "docker --version && docker compose version" \
    "Verifică că Docker și Docker Compose funcționează"

# 5. Configurare /etc/hosts pe client
echo
info "IMPORTANT: Pe computerul tău client (nu pe server), adaugă în /etc/hosts:"
echo "$CONTAINER_IP  $DOMAIN"
echo
confirm_command "echo '$CONTAINER_IP  $DOMAIN' >> /etc/hosts" \
    "Adaugă intrarea în /etc/hosts pe COMPUTERUL CLIENT (nu pe server)"

### === CREARE DIRECTOARE ȘI PERMISIUNI ===
ok "Creez directoarele necesare..."
mkdir -p "$COMPOSE_DIR" "$HTML_DIR" "$MYSQL_LOG_DIR" "$LOGS_DIR"
chown -R 33:33 "$DATA_DIR"  # www-data

### === CONFIGURARE UTILIZATOR DE DEZVOLTARE ===
ok "Configurez utilizatorul de dezvoltare: $DEV_USER"
if id -u "$DEV_USER" >/dev/null 2>&1; then
    usermod -a -G www-data,sudo "$DEV_USER"
else
    useradd -m -s /bin/bash -G www-data,sudo "$DEV_USER"
fi

# Configurare sudo fără parolă
SUDO_FILE="/etc/sudoers.d/${DEV_USER}"
echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" > "$SUDO_FILE"
visudo -cf "$SUDO_FILE" >/dev/null || { rm -f "$SUDO_FILE"; die "Eroare validare sudoers pentru ${DEV_USER}"; }
chmod 440 "$SUDO_FILE"
warn "Utilizatorul '${DEV_USER}' a fost configurat cu acces 'sudo' fără parolă (NOPASSWD). Aceasta este o setare convenabilă pentru dezvoltare, dar fiți conștient de implicațiile de securitate."


# Configurare chei SSH
if [[ -n "$PUBKEY_FILE" && -f "$PUBKEY_FILE" ]]; then
    ok "Configurez cheia SSH pentru $DEV_USER"
    install -d -m 700 -o "$DEV_USER" -g "$DEV_USER" "/home/$DEV_USER/.ssh"
    install -m 600 -o "$DEV_USER" -g "$DEV_USER" /dev/null "/home/$DEV_USER/.ssh/authorized_keys"
    cat "$PUBKEY_FILE" >> "/home/$DEV_USER/.ssh/authorized_keys"
fi

# Configurare permisiuni pentru teme WordPress
THEMES_DIR="${HTML_DIR}/wp-content/themes"
mkdir -p "$THEMES_DIR"
chgrp -R www-data "$THEMES_DIR" || true
find "$THEMES_DIR" -type d -exec chmod 2775 {} + 2>/dev/null || true
find "$THEMES_DIR" -type f -exec chmod 0664 {} + 2>/dev/null || true
setfacl -R -m g:www-data:rwX "$THEMES_DIR" 2>/dev/null || true
setfacl -d -m g:www-data:rwx "$THEMES_DIR" 2>/dev/null || true  
setfacl -m u:"$DEV_USER":rwX "$THEMES_DIR" 2>/dev/null || true
setfacl -d -m u:"$DEV_USER":rwx "$THEMES_DIR" 2>/dev/null || true

### === CONFIGURARE INTERFAȚA HOST-SIDE ===
if $CREATE_PUBIPV; then
    ok "Configurez interfața pubipv=${HOST_SIDE_IP}/24 (parent=${PARENT_IF})"
    modprobe ipvlan 2>/dev/null || true
    
    # Șterge interfața existentă dacă există
    ip link show pubipv >/dev/null 2>&1 && ip link del pubipv 2>/dev/null || true
    
    # Creează interfața ipvlan
    ip link add pubipv link "$PARENT_IF" type ipvlan mode l2
    
    # Configurează IP-ul
    ip addr add "${HOST_SIDE_IP}/24" dev pubipv
    ip link set pubipv up
fi

### === CONFIGURARE REȚEA DOCKER ===
ok "Configurez rețeaua Docker 'pubnet' (ipvlan L2) pe ${PARENT_IF}"

# Șterge rețeaua existentă dacă există
docker network inspect pubnet >/dev/null 2>&1 && docker network rm pubnet 2>/dev/null || true

# Creează rețeaua nouă
docker network create -d ipvlan \
    --subnet="${SUBNET_CIDR}" \
    --gateway="${GATEWAY_IP}" \
    -o parent="${PARENT_IF}" \
    -o ipvlan_mode=l2 \
    pubnet

### === CREEARE FIȘIERE DE CONFIGURARE ===
cd "$COMPOSE_DIR"

ok "Creez fișierele de configurare..."

# nginx.conf - configurare anti-cache
cat > nginx.conf <<EOF
# Configurare Nginx pentru WordPress Development (fără cache)
access_log /var/www/html/logs/nginx-access.log;
error_log  /var/www/html/logs/nginx-error.log warn;

# Redirect implicit către domeniul principal
server { 
    listen 80 default_server; 
    server_name _; 
    return 301 http://${DOMAIN}\$request_uri; 
}

server {
    listen 80;
    server_name ${DOMAIN};

    root /var/www/html;
    index index.php index.html;

    # Dezactivează complet cache-ul
    sendfile off; 
    open_file_cache off; 
    gzip off; 
    etag off; 
    last_modified off;
    
    # Headers anti-cache
    add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0, private" always;
    add_header Pragma "no-cache" always;
    add_header Expires "0" always;

    client_max_body_size 64m;

    # Configurare WordPress
    location / { 
        try_files \$uri \$uri/ /index.php?\$args; 
    }
    
    # Procesare PHP prin FastCGI
    location ~ \\.php\$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_pass wordpress:9000;
        
        # Dezactivează cache-ul FastCGI
        fastcgi_buffering off; 
        fastcgi_cache off; 
        fastcgi_no_cache 1; 
        fastcgi_cache_bypass 1;
    }
    
    # Ascunde fișierele dot
    location ~ /\\. { 
        deny all; 
    }
    
    # Assets statice fără cache
    location ~* \\.(?:css|js|jpg|jpeg|gif|png|webp|svg|ico|ttf|otf|woff|woff2)\$ {
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0, private" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        try_files \$uri =404;
    }
    
    # Service workers fără cache
    location = /service-worker.js { 
        add_header Cache-Control "no-store" always; 
        try_files \$uri =404; 
    }
    location = /sw.js { 
        add_header Cache-Control "no-store" always; 
        try_files \$uri =404; 
    }
}
EOF

# php.ini - dezactivează OPCache
cat > php.ini <<'EOF'
# Configurare PHP pentru dezvoltare (fără cache)
opcache.enable=0
opcache.enable_cli=0
opcache.jit=0
realpath_cache_size=0
realpath_cache_ttl=0
opcache.validate_timestamps=1

# Logging
log_errors=On
error_log=/var/www/html/logs/php-error.log
EOF

# php-fpm logging
cat > zz-php-fpm-logs.conf <<'EOF'
# Configurare logging pentru PHP-FPM
[global]
error_log = /var/www/html/logs/php-fpm.log

[www]
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /var/www/html/logs/php-error.log
request_slowlog_timeout = 2s
slowlog = /var/www/html/logs/php-fpm-slow.log
access.log = /var/www/html/logs/php-fpm-access.log
access.format = "%R - %u %t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"
catch_workers_output = yes
EOF

# MU-plugin pentru cache-bust
install -d -m 775 -o 33 -g 33 "${HTML_DIR}/wp-content/mu-plugins"
cat > "${HTML_DIR}/wp-content/mu-plugins/dev-no-cache.php" <<'EOF'
<?php
/*
Plugin Name: Dev No Cache
Description: Dezactivează complet cache-ul pentru dezvoltare
*/

if (!defined('ABSPATH')) exit;

// Headers anti-cache
add_action('send_headers', function () {
    header_remove('ETag');
    header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0, private', true);
    header('Pragma: no-cache', true);
    header('Expires: 0', true);
}, 0);

// Cache-bust pentru CSS și JS
$__bust = function ($src) {
    $src = remove_query_arg(['ver','v','dev'], $src);
    return add_query_arg('dev', time(), $src);
};

add_filter('style_loader_src', $__bust, 9999);
add_filter('script_loader_src', $__bust, 9999);
EOF

chown -R 33:33 "${HTML_DIR}/wp-content/mu-plugins"

# docker-compose.yml - serviciile de bază
cat > docker-compose.yml <<'EOF'
# Docker Compose pentru WordPress Development
name: wpdev

services:
  # Baza de date MariaDB
  db:
    image: mariadb:10.11
    command: --default-authentication-plugin=mysql_native_password --log-error=/var/log/mysql/error.log
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wp
      MYSQL_PASSWORD: wp
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - db_data:/var/lib/mysql
      - /srv/docker-data/wordpress/logs/mysql:/var/log/mysql
    networks: 
      - wpnet
    restart: unless-stopped

  # WordPress cu PHP-FPM
  wordpress:
    image: wordpress:php8.2-fpm
    depends_on: 
      - db
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wp
      WORDPRESS_DB_PASSWORD: wp
      WORDPRESS_DB_NAME: wordpress
      # Configurări extra pentru dezvoltare
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_CACHE', false);
        define('WP_ENVIRONMENT_TYPE', 'development');
        define('WP_DEBUG', true);
        define('WP_DEBUG_LOG', '/var/www/html/logs/wp-debug.log');
        define('SCRIPT_DEBUG', true);
        define('CONCATENATE_SCRIPTS', false);
        define('COMPRESS_SCRIPTS', false);
        define('COMPRESS_CSS', false);
        @ini_set('log_errors', 'On');
        @ini_set('error_log', '/var/www/html/logs/php-error.log');
        @ini_set('zlib.output_compression', 0);
    volumes:
      - /srv/docker-data/wordpress/html:/var/w
      ww/html
      - /srv/docker-data/wordpress/logs:/var/www/html/logs
      - ./php.ini:/usr/local/etc/php/conf.d/opcache-off.ini:ro
      - ./zz-php-fpm-logs.conf:/usr/local/etc/php-fpm.d/zz-logs.conf:ro
    networks: 
      - wpnet
    restart: unless-stopped

volumes:
  db_data:

networks:
  wpnet: {}
EOF

# docker-compose.override.yml - Nginx cu IP public
cat > docker-compose.override.yml <<EOF
# Override pentru Nginx cu IP public
services:
  nginx:
    image: nginx:1.27-alpine
    depends_on: 
      - wordpress
    volumes:
      - ${HTML_DIR}:/var/www/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ${LOGS_DIR}:/var/www/html/logs
    networks:
      wpnet: {}
      pubnet:
        ipv4_address: ${CONTAINER_IP}
    restart: unless-stopped

networks:
  pubnet:
    external: true
EOF

### === PORNIRE STACK ===
ok "Pornesc stack-ul WordPress..."
$DC -p "$PROJECT_NAME" up -d --force-recreate
$DC -p "$PROJECT_NAME" ps

# Așteaptă ca baza de date să fie gata
ok "Aștept ca baza de date să fie gata..."
tries=0; max=90
until $DC -p "$PROJECT_NAME" exec -T db mysqladmin ping -proot --host=127.0.0.1 --silent >/dev/null 2>&1; do
    ((tries++))
    if ((tries > max)); then
        die "Baza de date nu este gata în ${max} secunde."
    fi
    sleep 1
    printf "."
done
echo
ok "Baza de date este gata!"

### === INSTALARE WORDPRESS ===
NET_NAME="${PROJECT_NAME}_wpnet"

# Verifică dacă WordPress este deja instalat
if docker run --rm --network "$NET_NAME" -v "${HTML_DIR}:/var/www/html" \
    -e WORDPRESS_DB_HOST=db:3306 -e WORDPRESS_DB_USER=wp -e WORDPRESS_DB_PASSWORD=wp -e WORDPRESS_DB_NAME=wordpress \
    wordpress:cli wp core is-installed --path=/var/www/html >/dev/null 2>&1; then
    ok "WordPress este deja instalat - actualizez doar URL-urile"
else
    ok "Instalez WordPress pe http://${DOMAIN}"
    docker run --rm --network "$NET_NAME" -v "${HTML_DIR}:/var/www/html" \
        -e WORDPRESS_DB_HOST=db:3306 -e WORDPRESS_DB_USER=wp -e WORDPRESS_DB_PASSWORD=wp -e WORDPRESS_DB_NAME=wordpress \
        wordpress:cli wp core install \
            --url="http://${DOMAIN}" \
            --title='WordPress Development' \
            --admin_user="${WP_ADMIN_USER}" \
            --admin_password="${WP_ADMIN_PASS}" \
            --admin_email="${WP_ADMIN_EMAIL}" \
            --path=/var/www/html
fi

# Actualizează URL-urile în baza de date
ok "Actualizez URL-urile WordPress în baza de date..."
$DC -p "$PROJECT_NAME" exec -T db mysql -uroot -proot wordpress \
    -e "UPDATE wp_options SET option_value='http://${DOMAIN}' WHERE option_name IN ('siteurl','home');" || true

# Verifică și adaugă constantele de dezvoltare în wp-config.php
WP_CFG="${HTML_DIR}/wp-config.php"
if [[ -f "$WP_CFG" ]]; then
    if ! grep -q "SCRIPT_DEBUG" "$WP_CFG" 2>/dev/null; then
        ok "Adaug constantele de dezvoltare în wp-config.php"
        sed -i "/stop editing/i define('WP_CACHE', false);\ndefine('WP_ENVIRONMENT_TYPE','development');\ndefine('WP_DEBUG', true);\ndefine('WP_DEBUG_LOG','/var/www/html/logs/wp-debug.log');\ndefine('SCRIPT_DEBUG', true);\ndefine('CONCATENATE_SCRIPTS', false);\ndefine('COMPRESS_SCRIPTS', false);\ndefine('COMPRESS_CSS', false);\n" "$WP_CFG" || true
    fi
fi

### === TESTE DE FUNCȚIONARE ===
ok "Testez conectivitatea HTTP..."
sleep 5

echo "Test 1: HTTP direct pe IP ${CONTAINER_IP}"
if curl -sI -m 10 "http://${CONTAINER_IP}/" | head -1; then
    ok "✓ HTTP direct funcționează"
else
    warn "✗ HTTP direct nu răspunde"
fi

echo "Test 2: HTTP cu Host header pentru ${DOMAIN}"
if curl -sI -m 10 -H "Host: ${DOMAIN}" "http://${CONTAINER_IP}/" | head -1; then
    ok "✓ HTTP cu Host header funcționează"
else
    warn "✗ HTTP cu Host header nu răspunde"
fi

### === REZULTAT FINAL ===
ok "INSTALAREA S-A FINALIZAT CU SUCCES!"

cat <<EOF

=========================================== 
           REZUMAT CONFIGURARE
=========================================== 

🌐 REȚEA:
   Rețea Docker: pubnet (ipvlan L2 pe ${PARENT_IF})
   IP Nginx:     ${CONTAINER_IP}
   Host IP:      ${HOST_SIDE_IP}/24
   Gateway:      ${GATEWAY_IP}

📁 DIRECTOARE:
   Root site:    ${HTML_DIR}
   Loguri:       ${LOGS_DIR}
   Compose:      ${COMPOSE_DIR}

🖥️  WORDPRESS:
   URL:          http://${DOMAIN}
   Admin user:   ${WP_ADMIN_USER}
   Admin pass:   ${WP_ADMIN_PASS}
   Admin email:  ${WP_ADMIN_EMAIL}

👤 UTILIZATOR DEZVOLTARE:
   Nume:         ${DEV_USER}
   Grup:         www-data, sudo
   SSH:          $(if [[ -n "$PUBKEY_FILE" ]]; then echo "configurat"; else echo "nu este configurat"; fi)

🔧 COMENZI UTILE:
   Status:       cd ${COMPOSE_DIR} && docker compose ps
   Loguri:       cd ${COMPOSE_DIR} && docker compose logs -f
   Restart:      cd ${COMPOSE_DIR} && docker compose restart
   Stop:         cd ${COMPOSE_DIR} && docker compose down
   Start:        cd ${COMPOSE_DIR} && docker compose up -d

📋 TESTE:
   curl -I http://${CONTAINER_IP}/
   curl -I -H 'Host: ${DOMAIN}' http://${CONTAINER_IP}/

⚠️  IMPORTANT:
   Pe computerul CLIENT adaugă în /etc/hosts:
   ${CONTAINER_IP}  ${DOMAIN}

   Apoi accesează: http://${DOMAIN}

===========================================

WordPress Development Environment este gata de utilizare!

EOF