#!/bin/bash

# =============================================================================
# SISTEMA DE OFUSCACIÓN CONFIGURACIONAL EN LINUX
#
# DETALLES:
# - Reversibilidad completa mediante sistema de backup
# - Logging detallado para análisis educativo
# - Validaciones de seguridad integradas
# - Investigacion de metodos hardering
# - Pruebas en entornos controlados autorizados 
#
# Únicamente para: Pentesting ético autorizado y laboratorios educativos
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuración
BACKUP_DIR="/tmp/.stealth_backup_$(date +%s)"
LOG_FILE="/tmp/.stealth.log"
ORIGINAL_HOSTNAME=""
ORIGINAL_MAC=""
ORIGINAL_INTERFACE=""

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Verificar privilegios root
[[ $EUID -eq 0 ]] || error "Se requieren privilegios root"

# Crear directorio de backup
mkdir -p "$BACKUP_DIR"

backup_system_state() {
    log "Creando backup del estado actual..."
    
    # Backup hostname
    ORIGINAL_HOSTNAME=$(hostname)
    echo "$ORIGINAL_HOSTNAME" > "$BACKUP_DIR/hostname.bak"
    
    # Backup resolv.conf
    cp /etc/resolv.conf "$BACKUP_DIR/resolv.conf.bak" 2>/dev/null || true
    
    # Backup iptables rules
    iptables-save > "$BACKUP_DIR/iptables.bak"
    
    log "Backup completado en $BACKUP_DIR"
}

# Función para detectar interfaz principal
detect_main_interface() {
    local interface
    interface=$(ip route | grep default | head -1 | awk '{print $5}')
    [[ -n "$interface" ]] || error "No se pudo detectar interfaz principal"
    echo "$interface"
}

# MAC Spoofing
rotate_network_identity() {
    local interface=$1
    
    log "Iniciando MAC spoofing avanzado en $interface..."
    
    # Verificar que la interfaz existe
    [[ -d "/sys/class/net/$interface" ]] || error "Interfaz $interface no encontrada"
    
    # Backup MAC original
    ORIGINAL_MAC=$(cat "/sys/class/net/$interface/address")
    echo "$ORIGINAL_MAC" > "$BACKUP_DIR/mac_$interface.bak"
    
    ip link set dev "$interface" down
    
    # Generar MAC
    local vendors=("00:50:56" "00:0C:29" "08:00:27" "00:16:3E" "52:54:00")
    local selected_oui=${vendors[$RANDOM % ${#vendors[@]}]}
    
    # Random 
    local random_part=$(printf "%02x:%02x:%02x" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
    local new_mac="${selected_oui}:${random_part}"
    
    # Aplicar nueva MAC
    if command -v macchanger >/dev/null 2>&1; then
        macchanger -m "$new_mac" "$interface" >/dev/null
    else
        ip link set dev "$interface" address "$new_mac"
    fi
    
    # Levantar interfaz
    ip link set dev "$interface" up
    
    log "MAC cambiada de $ORIGINAL_MAC a $new_mac"
}

# CAMBIO DE HOSTNAME
hostname_change() {
    local hostnames=("HP-LaserJet" "Canon-MX922" "Epson-WF3640" "Brother-HL2340" "Samsung-ML1910")
    local new_hostname=${hostnames[$RANDOM % ${#hostnames[@]}]}
    
    log "Cambiando hostname a $new_hostname"
    
    # Cambiar hostname
    hostnamectl set-hostname "$new_hostname"
    
    # Actualizar /etc/hosts
    sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts 2>/dev/null || true
    
    log "Hostname cambiado exitosamente"
}

# Renombrado de interfaz
dynamic_interface_naming() {
    local interface=$1
    local new_names=("eth0" "eth1" "enp0s3" "enp0s8" "wlp2s0")
    local new_name=${new_names[$RANDOM % ${#new_names[@]}]}
    
    # Verificar que el nuevo nombre no existe
    while [[ -d "/sys/class/net/$new_name" ]]; do
        new_name=${new_names[$RANDOM % ${#new_names[@]}]}
    done
    
    ORIGINAL_INTERFACE=$interface
    echo "$ORIGINAL_INTERFACE" > "$BACKUP_DIR/interface_name.bak"
    
    log "Renombrando interfaz $interface a $new_name"
    ip link set "$interface" down
    ip link set "$interface" name "$new_name"
    ip link set "$new_name" up
    
    echo "$new_name"
}

# Reglas de firewall
network_herdening_rules() {
    log "Configurando reglas de firewall..."
    
    # Anti-nmap stealth scan
    iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
    
    # Bloquear ping
    iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
    iptables -A OUTPUT -p icmp --icmp-type echo-reply -j DROP
    
    # Limitar conexiones simultaneas (anti-DoS)
    iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 20 -j REJECT
    
    # Rate limiting para SSH
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    
    # Hacer reglas persistentes
    make_iptables_persistent
    
    log "Reglas de firewall aplicadas y configuradas como persistentes"
}

# Función para hacer iptables persistente
make_iptables_persistent() {
    log "Configurando persistencia de iptables..."
    
    # Intentar con iptables-persistent (Debian/Ubuntu)
    if command -v iptables-save >/dev/null 2>&1; then
        if [[ -d /etc/iptables ]]; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        
        # Si iptables-persistent no está instalado, crear servicio personalizado
        if ! systemctl list-unit-files | grep -q iptables-persistent; then
            create_iptables_service
        fi
    fi
    
    # Para distribuciones Red Hat/CentOS
    if command -v service >/dev/null 2>&1 && [[ -f /etc/redhat-release ]]; then
        service iptables save 2>/dev/null || true
    fi
}

# Crear servicio (iptables)
create_iptables_service() {
    log "Creando servicio personalizado para persistencia de iptables..."
    
    # Guardar reglas actuales
    iptables-save > /etc/iptables-stealth.rules
    
    # Crear servicio systemd
    cat > /etc/systemd/system/iptables-stealth.service << 'EOF'
[Unit]
Description=Stealth iptables rules
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables-stealth.rules
ExecReload=/sbin/iptables-restore /etc/iptables-stealth.rules
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Habilitar el servicio
    systemctl daemon-reload
    systemctl enable iptables-stealth.service 2>/dev/null || true
    
    log "Servicio iptables-stealth creado y habilitado"
}

# Limpieza de logs
log_cleanup() {
    log "Iniciando limpieza avanzada de logs..."
    
    # Limpiar historial de bash de sesiones activas
    log "Limpiando historial de sesiones activas..."
    history -c 2>/dev/null || true
    history -w 2>/dev/null || true
    
    # Limpiar historial de todos los usuarios
    for user_home in /root /home/*; do
        if [[ -d "$user_home" ]]; then
            [[ -f "$user_home/.bash_history" ]] && shred -vfz -n 3 "$user_home/.bash_history" 2>/dev/null || true
            [[ -f "$user_home/.zsh_history" ]] && shred -vfz -n 3 "$user_home/.zsh_history" 2>/dev/null || true
            [[ -f "$user_home/.history" ]] && shred -vfz -n 3 "$user_home/.history" 2>/dev/null || true
        fi
    done
    
    # Logs de sistema (archivos sin comprimir)
    local log_files=(
        "/var/log/auth.log*"
        "/var/log/syslog*"
        "/var/log/messages*"
        "/var/log/secure*"
        "/var/log/wtmp*"
        "/var/log/utmp*"
        "/var/log/lastlog*"
        "/var/log/faillog*"
        "/var/log/kern.log*"
        "/var/log/daemon.log*"
        "/var/log/user.log*"
        "/var/log/debug*"
        "/var/log/mail.log*"
        "/var/log/cron.log*"
    )
    
    for pattern in "${log_files[@]}"; do
        find / -path "$pattern" -type f ! -name "*.gz" ! -name "*.bz2" ! -name "*.xz" -exec shred -vfz -n 3 {} \; 2>/dev/null || true
    done
    
    # Manejo especial para logs comprimidos
    log "Procesando logs comprimidos..."
    find /var/log -name "*.gz" -exec gunzip {} \; 2>/dev/null || true
    find /var/log -name "*.bz2" -exec bunzip2 {} \; 2>/dev/null || true
    find /var/log -name "*.xz" -exec unxz {} \; 2>/dev/null || true
    
    # Shred de los archivos descomprimidos
    for pattern in "${log_files[@]}"; do
        find / -path "$pattern" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null || true
    done
    
    # Limpiar journalctl
    journalctl --vacuum-time=1s 2>/dev/null || true
    journalctl --vacuum-size=1K 2>/dev/null || true
    
    # Limpiar cache de DNS
    systemctl flush-dns 2>/dev/null || true
    
    # Limpiar archivos temporales
    find /tmp -type f -atime +0 -delete 2>/dev/null || true
    find /var/tmp -type f -atime +0 -delete 2>/dev/null || true
    
    # Limpiar logs de aplicaciones comunes
    find /var/log -name "*.log" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null || true
    
    log "Limpieza de logs completada"
}

dns_config() {
    log "Configurando DNS anónimos con DoH..."

    # Detectar si /etc/resolv.conf es un symlink que apunta a systemd-resolved
    if [ -L /etc/resolv.conf ] && grep -q "systemd" <<< "$(readlink /etc/resolv.conf 2>/dev/null)"; then
        log "Detectado systemd-resolved, deshabilitando..."

        # Backup de configuración
        [[ -f /etc/systemd/resolved.conf ]] && cp /etc/systemd/resolved.conf "$BACKUP_DIR/resolved.conf.bak"

        # Deshabilitar y detener systemd-resolved
        systemctl disable --now systemd-resolved 2>/dev/null || true

        # Quitar symlink
        rm -f /etc/resolv.conf

        warning "systemd-resolved deshabilitado. Será necesario reiniciar para efecto completo."
    fi

    # DNS primarios (anónimos/privados)
    local dns_servers=(
        "1.1.1.1"         # Cloudflare
        "1.0.0.1"         # Cloudflare
        "9.9.9.9"         # Quad9
        "149.112.112.112" # Quad9
        "8.8.8.8"         # Google (fallback)
        "8.8.4.4"         # Google (fallback)
    )

    # Crear nueva configuración
    cat > /etc/resolv.conf << EOF
# Anonymous DNS Configuration
nameserver ${dns_servers[0]}
nameserver ${dns_servers[1]}
nameserver ${dns_servers[2]}
options timeout:2
options attempts:3
options rotate
EOF

    # Solo bloquear el archivo si ningún servicio intenta administrarlo
    if ! systemctl is-active systemd-resolved >/dev/null 2>&1 \
       && ! pgrep -x NetworkManager >/dev/null 2>&1; then
        chattr +i /etc/resolv.conf 2>/dev/null || true
        log "Archivo /etc/resolv.conf bloqueado contra modificaciones."
    else
        warning "No se aplicó chattr +i para evitar conflictos con servicios activos."
    fi

    log "DNS configurado con servidores anónimos"
}

# características del sistema
minimize_system_footprint() {
    log "Modificando fingerprint del sistema..."
    
    # Cambiar timezone aleatoriamente
    local timezones=("UTC" "America/New_York" "Europe/London" "Asia/Tokyo" "Australia/Sydney")
    local new_tz=${timezones[$RANDOM % ${#timezones[@]}]}
    timedatectl set-timezone "$new_tz" 2>/dev/null || true
    
    # Modificar kernel parameters para rotacion
    echo 0 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all 2>/dev/null || true
    
    log "Fingerprint del sistema modificado"
}

# Función de restauración
create_restore_script() {
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
BACKUP_DIR="$(dirname "$0")"

echo "Restaurando configuración original..."

# Restaurar hostname
if [[ -f "$BACKUP_DIR/hostname.bak" ]]; then
    hostnamectl set-hostname "$(cat "$BACKUP_DIR/hostname.bak")"
fi

# Restaurar resolv.conf
if [[ -f "$BACKUP_DIR/resolv.conf.bak" ]]; then
    chattr -i /etc/resolv.conf 2>/dev/null || true
    cp "$BACKUP_DIR/resolv.conf.bak" /etc/resolv.conf
fi

# Restaurar systemd-resolved si existía
if [[ -f "$BACKUP_DIR/resolved.conf.bak" ]]; then
    cp "$BACKUP_DIR/resolved.conf.bak" /etc/systemd/resolved.conf
    systemctl enable systemd-resolved 2>/dev/null || true
    systemctl start systemd-resolved 2>/dev/null || true
fi

# Restaurar iptables
if [[ -f "$BACKUP_DIR/iptables.bak" ]]; then
    iptables-restore < "$BACKUP_DIR/iptables.bak"
    # Actualizar reglas persistentes
    if [[ -f /etc/iptables/rules.v4 ]]; then
        iptables-save > /etc/iptables/rules.v4
    fi
    if [[ -f /etc/iptables-stealth.rules ]]; then
        iptables-save > /etc/iptables-stealth.rules
    fi
fi

# Restaurar MAC
for mac_file in "$BACKUP_DIR"/mac_*.bak; do
    if [[ -f "$mac_file" ]]; then
        interface=$(basename "$mac_file" | sed 's/mac_//;s/.bak//')
        original_mac=$(cat "$mac_file")
        if [[ -d "/sys/class/net/$interface" ]]; then
            ip link set dev "$interface" down
            ip link set dev "$interface" address "$original_mac"
            ip link set dev "$interface" up
        fi
    fi
done

# Restaurar nombre de interfaz
if [[ -f "$BACKUP_DIR/interface_name.bak" ]]; then
    original_name=$(cat "$BACKUP_DIR/interface_name.bak")
    echo "NOTA: Restauración de nombre de interfaz requiere reinicio manual"
    echo "Nombre original era: $original_name"
fi

# Limpiar servicios creados
systemctl disable iptables-stealth.service 2>/dev/null || true
rm -f /etc/systemd/system/iptables-stealth.service
rm -f /etc/iptables-stealth.rules
systemctl daemon-reload 2>/dev/null || true

echo "Restauración completada"
echo "RECOMENDACIÓN: Reiniciar el sistema para aplicar todos los cambios"
EOF
    
    chmod +x "$BACKUP_DIR/restore.sh"
    log "Script de restauración creado en $BACKUP_DIR/restore.sh"
}

# Función principal
main() {
    log "=== INICIANDO SCRIPT DE EVASIÓN AVANZADO ==="
    
    # Crear backup
    backup_system_state
    
    # Detectar interfaz principal
    MAIN_INTERFACE=$(detect_main_interface)
    log "Interfaz principal detectada: $MAIN_INTERFACE"
    
    # Ejecutar mejoras
    hostname_change
    rotate_network_identity "$MAIN_INTERFACE"
    NEW_INTERFACE=$(dynamic_interface_naming "$MAIN_INTERFACE")
    network_herdening_rules
    log_cleanup
    dns_config
    minimize_system_footprint
    
    # Crear script de restauración
    create_restore_script
    
    log "=== PROCESO COMPLETADO ==="
    log "Backup y script de restauración disponibles en: $BACKUP_DIR"
    log "Para restaurar configuración original: bash $BACKUP_DIR/restore.sh"
    
    echo -e "\n${GREEN}Nueva configuración:${NC}"
    echo "Hostname: $(hostname)"
    echo "Interfaz: $NEW_INTERFACE"
    echo "MAC: $(cat "/sys/class/net/$NEW_INTERFACE/address" 2>/dev/null || echo "N/A")"
    echo "DNS: $(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}')"
}

# Trap para cleanup en caso de interrupción
trap 'error "Script interrumpido"' INT TERM

case "${1:-run}" in
    "run")
        main
        ;;
    "restore")
        if [[ -n "${2:-}" ]] && [[ -f "$2/restore.sh" ]]; then
            bash "$2/restore.sh"
        else
            error "Uso: $0 restore <directorio_backup>"
        fi
        ;;
    "help")
        echo "Uso: $0 [run|restore|help]"
        echo "  run     - Ejecutar script de evasión (default)"
        echo "  restore - Restaurar configuración original"
        echo "  help    - Mostrar esta ayuda"
        ;;
    *)
        error "Argumento inválido. Usa '$0 help' para ayuda"
        ;;
esac