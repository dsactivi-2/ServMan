Ops Scripts auf mgmt-01

1) System Health Snapshot
   /opt/management/shared/scripts/system-health.sh
   Zweck: CPU/RAM/Load, Disk, Prozesse, Uptime, offene Ports, Docker-Status
   Output: /opt/management/agent/logs/system-health-YYYYmmdd-HHMMSS.txt

2) Patch & Update
   /opt/management/shared/scripts/patch-update.sh
   Zweck: apt update/upgrade + Reboot-Check
   Modi:
   - Check-only Reboot: /opt/management/shared/scripts/patch-update.sh
   - Auto-Reboot wenn nötig: /opt/management/shared/scripts/patch-update.sh --reboot
   Output: /opt/management/agent/logs/patch-update-YYYYmmdd-HHMMSS.txt

3) Docker Operations (Semaphore Stack)
   /opt/management/shared/scripts/docker-ops.sh
   Aktionen:
   - status:  /opt/management/shared/scripts/docker-ops.sh status
   - pull:    /opt/management/shared/scripts/docker-ops.sh pull
   - restart: /opt/management/shared/scripts/docker-ops.sh restart
   - deploy:  /opt/management/shared/scripts/docker-ops.sh deploy
   - logs:    /opt/management/shared/scripts/docker-ops.sh logs
   - health:  /opt/management/shared/scripts/docker-ops.sh health

Standard-Stack-Pfad:
   /opt/management/semaphore
