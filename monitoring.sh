#!/bin/bash

# Скрипт мониторинга процесса test для Linux
LOG_FILE="/var/log/monitoring.log"
MONITORING_URL="https://test.com/monitoring/test/api"
PROCESS_NAME="test"
STATE_FILE="/var/lib/monitoring/previous_pid.txt"

# Создаем необходимые директории и файл лога
mkdir -p /var/lib/monitoring
mkdir -p /var/log
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"
chown root:root "$LOG_FILE"
touch "$STATE_FILE" 2>/dev/null || true
chmod 644 "$STATE_FILE"
chown root:root "$STATE_FILE"

# Функция для логирования
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Функция проверки процесса
check_process() {
    pgrep -x "$PROCESS_NAME" 2>/dev/null
}

# Функция проверки URL
check_url() {
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "$MONITORING_URL" 2>/dev/null)
    
    if [ "$response_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Функция определения перезапуска
check_restart() {
    local current_pid="$1"
    local previous_pid
    
    if [ -f "$STATE_FILE" ]; then
        previous_pid=$(cat "$STATE_FILE" 2>/dev/null)
    else
        previous_pid=""
    fi
    
    echo "$current_pid" > "$STATE_FILE"
    
    if [ -n "$previous_pid" ] && [ -n "$current_pid" ] && [ "$previous_pid" != "$current_pid" ]; then
        return 0
    else
        return 1
    fi
}

# Основная логика
main() {
    local current_pid
    current_pid=$(check_process)
    
    if [ -n "$current_pid" ]; then
        if check_restart "$current_pid"; then
            log_message "RESTART: Process $PROCESS_NAME was restarted"
        fi
        
        if check_url; then
            log_message "SUCCESS: Process $PROCESS_NAME is running and monitoring URL is accessible"
        else
            log_message "ERROR: Process $PROCESS_NAME is running but monitoring URL is not accessible"
        fi
    else
        check_restart "" > /dev/null
    fi
}

main
