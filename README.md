# vigilant-potato

Suite de ofuscación sistemática con backup integrado y reversibilidad. Modifica MAC, hostname, DNS, interfaces y firewall mientras mantiene capacidad de restauración. **Fines educativos solamente.**

## Características Técnicas

### Sistema de Backup y Restauración
- **Backup automático** de configuración original
- **Script de restauración** integrado
- **Logging detallado** de todas las operaciones

### Anonimización de Red
- **MAC Address Spoofing**: Generación de direcciones MAC con OUI legítimos
- **Renombrado de Interfaces**: Cambio de nombres de interfaces de red
- **DNS Anónimo**: Configuración con servidores privados y DoH
- **Reglas Firewall Avanzadas**: Protección contra scanning y fingerprinting

### Hardening de Sistema
- **Limpieza de Logs**: Eliminación segura de artifacts del sistema
- **Cambio de Hostname**: Ofuscación del nombre del sistema
- **Evasión de Fingerprinting**: Modificación de características identificables
- **Protección Persistente**: Configuración que sobrevive reinicios

### Características de Implementación
- Validación de privilegios y pre-requisitos
- Manejo de errores y interrupciones
- Soporte para múltiples distribuciones Linux
- Sistema de logging con colores y timestamp

## Instalación

### Paquetes Necesarios

```bash
sudo apt install macchanger iptables-persistent

# Sistemas basados en RHEL/CentOS
sudo yum install macchanger iptables-services
```

### Descarga e Instalación

```bash
git clone https://github.com/Mejtar/vigilant-potato
cd vigilant-potato

chmod 711 configuration_manager.sh
```

## Guía de Uso

### Ejecución Principal

```bash
#requiere root
sudo ./configuration_manager.sh run
```

### Restauración del Sistema

```bash
sudo /tmp/.stealth_backup_YYYYMMDD_HHMMSS/restore.sh

# O mediante el script principal
sudo ./stealth_script.sh restore /tmp/.stealth_backup_YYYYMMDD_HHMMSS
```

> **Nota**: El timestamp (YYYYMMDD_HHMMSS) se genera automáticamente al crear el backup.

## ⚙️ Personalización

### Configuración de Vendors OUI

```bash
vendors=("00:50:56" "00:0C:29" "08:00:27")
```

### Hostnames Disponibles

```bash
hostnames=("HP-LaserJet" "Canon-MX922" "Epson-WF3640")
```

### Servidores DNS

```bash
# Servidores
dns_servers=("1.1.1.1" "9.9.9.9" "8.8.8.8")
```

## Logging y Monitoreo

El script genera logs detallados en `/tmp/.stealth.log` si hay permisos. En distribuciones más estrictas, se utiliza `configure_log_file()` para cambiar a `/var/log` o `/$HOME`.

**Información registrada:**
- Timestamp de todas las operaciones
- Estados de éxito/error de cada función
- Configuraciones anteriores y nuevas
- Advertencias y validaciones

## Limitaciones Conocidas

- Algunas características requieren reinicio para efecto completo
- La persistencia de iptables varía entre distribuciones
- Systemd-resolved puede requerir configuración manual adicional
- El renombrado de interfaces puede afectar configuraciones de red existentes

## Contribución

Las contribuciones son bienvenidas bajo estas condiciones:

- **Solo se aceptan mejoras** con propósito educativo
- **Deben mantener** la funcionalidad de restauración
- **Deben incluir** validaciones de seguridad apropiadas
- **No deben facilitar** usos maliciosos

### Reporte de Vulnerabilidades

Para reportar vulnerabilidades o problemas:

- **No abra issues públicos** para problemas de seguridad
- **Contacte directamente** al maintainer
- **Provea detalles** del entorno y pasos para reproducir

## Información del Proyecto

- **Última actualización**: 28/08/2025
- **Mantenedor**: mejtar
- **Versión**: 1.0.0

## Licencia y Disclaimer

Este proyecto se distribuye bajo la **licencia APACHE 2.0** con la adición explícita de que está **prohibido su uso para actividades ilegales**. Ver archivo [DISCLAIMER](Legal/DISCLAIMER.md) para detalles.

**Use bajo su propia responsabilidad y solo en entornos autorizados.**