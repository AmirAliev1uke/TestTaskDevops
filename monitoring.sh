#!/bin/bash

# Скрипт мониторинга процесса test для Linux
LOG_FILE="/var/log/monitoring.log"
MONITORING_URL="https://test.com/monitoring/test/api"
PROCESS_NAME="test"
STATE_FILE="/var/lib/monitoring/previous_state.txt"

# Создаем необходимые директории и файл лога
mkdir -p /var/lib/monitoring
mkdir -p /var/log
touch "$LOG_FILE"

# Функция для логирования
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Функция проверки процесса
check_process() {
    if pgrep -f "$PROCESS_NAME" > /dev/null 2>&1; then
        echo "running"
    else
        echo "stopped"
    fi
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
    local current_state="$1"
    local previous_state
    
    if [ -f "$STATE_FILE" ]; then
        previous_state=$(cat "$STATE_FILE")
    else
        previous_state="unknown"
    fi
    
    echo "$current_state" > "$STATE_FILE"
    
    if [ "$previous_state" = "stopped" ] && [ "$current_state" = "running" ]; then
        return 0
    else
        return 1
    fi
}

# Основная логика
main() {
    local process_state
    process_state=$(check_process)
    
    case "$process_state" in
        "running")
            if check_restart "$process_state"; then
                log_message "RESTART: Process $PROCESS_NAME was restarted"
            fi
            
            if check_url; then
                log_message "SUCCESS: Process $PROCESS_NAME is running and monitoring URL is accessible"
            else
                log_message "ERROR: Process $PROCESS_NAME is running but monitoring URL is not accessible"
            fi
            ;;
        "stopped")
            check_restart "$process_state" > /dev/null
            ;;
    esac
}

main
