# vigilant-potato
Suite de ofuscación sistemática con backup integrado y reversibilidad. Modifica MAC, hostname, DNS, interfaces y firewall mientras mantiene capacidad de restauración. Fines educativos solamente.
System Privacy Enhancement Toolkit

### Características Técnicas
El script implementa las siguientes funcionalidades:

### Sistema de Backup y Restauración
Backup automático de configuración original

Script de restauración integrado

Logging detallado de todas las operaciones
---
### Anonimización de Red
MAC Address Spoofing: Generación de direcciones MAC con OUI legítimos

Renombrado de Interfaces: Cambio de nombres de interfaces de red

DNS Anónimo: Configuración con servidores privados y DoH

Reglas Firewall Avanzadas: Protección contra scanning y fingerprinting
---

### Hardening de Sistema
Limpieza de Logs: Eliminación segura de artifacts del sistema

Cambio de Hostname: Ofuscación del nombre del sistema

Evasión de Fingerprinting: Modificación de características identificables

Protección Persistente: Configuración que sobrevive reinicios
---

### Características de Implementación
Validación de privilegios y pre-requisitos

Manejo de errores y interrupciones

Soporte para múltiples distribuciones Linux

Sistema de logging con colores y timestamp

### Paquetes necesarios
# Sistemas basados en Debian/Ubuntu
sudo apt install macchanger iptables-persistent

# Sistemas basados en RHEL/CentOS
sudo yum install macchanger iptables-services
---
### Guia de uso
# Descargar el script
git clone https://github.com/Mejtar/vigilant-potato
cd system-privacy-toolkit

# Dar permisos de ejecución
chmod +x stealth_script.sh

# Ejecutar (requiere root)
sudo ./stealth_script.sh run
---
### Backup
# Usar el script de restauración automático
sudo /ruta/al/backup/restore.sh

# O mediante el script principal
sudo ./stealth_script.sh restore /ruta/al/backup
---
### Personalizacion
# Vendors OUI para MAC spoofing
vendors=("00:50:56" "00:0C:29" "08:00:27")

# Hostnames para ofuscación
hostnames=("HP-LaserJet" "Canon-MX922" "Epson-WF3640")

# Servidores DNS alternativos
dns_servers=("1.1.1.1" "9.9.9.9" "8.8.8.8")
---

Logging y Monitoreo
El script genera logs detallados en /tmp/.stealth.log que incluyen:

Timestamp de todas las operaciones

Estados de éxito/error de cada función

Configuraciones anteriores y nuevas

Advertencias y validaciones

### Limitaciones Conocidas
Algunas características requieren reinicio para efecto completo

La persistencia de iptables varía entre distribuciones

Systemd-resolved puede requerir configuración manual adicional

El renombrado de interfaces puede afectar configuraciones de red existentes

### Contribución
Las contribuciones son bienvenidas bajo estas condiciones:

 -Solo se aceptan mejoras con propósito educativo

 -Deben mantener la funcionalidad de restauración

 -Deben incluir validaciones de seguridad apropiadas

 -No deben facilitar usos maliciosos
---
Para reportar vulnerabilidades o problemas:

 -No abra issues públicos para problemas de seguridad

 -Contacte directamente al maintainer

 -Provea detalles del entorno y pasos para reproducir
---

Última actualización: 28/08/2025
Mantenedor: mejtar
Versión: 1.0.0

Este proyecto se distribuye bajo la licencia MIT con la adición explícita de que está prohibido su uso para actividades ilegales. Ver archivo [DISCLAIMER](Legal/DISCLAIMER.md) para detalles.
Use bajo su propia responsabilidad y solo en entornos autorizados.
