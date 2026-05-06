#!/bin/bash

# ===== CORES =====
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ===== FUNÇÕES DE UI =====
show_loading() {
    local message="$1"
    local duration=${2:-2}
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    
    echo -ne "${YELLOW}$message ${NC}"
    
    # Converte para segundos inteiros (multiplica por 10 e usa décimos)
    local total_ticks=$(( duration * 10 ))
    local tick=0
    
    while [ $tick -lt $total_ticks ]; do
        local char_index=$(( tick % ${#chars} ))
        echo -ne "\r${YELLOW}$message ${chars:$char_index:1} ${NC}"
        sleep 0.1
        tick=$(( tick + 1 ))
    done
    echo -e "\r${GREEN}$message ✓${NC}"
}

draw_bar() {
    local percent=$1
    local width=${2:-30}
    
    # Converte para inteiro
    local int_percent=$(echo "$percent" | awk '{printf "%.0f", $1}')
    
    # Define cor baseado no uso
    local color=$GREEN
    if [ "$int_percent" -gt 80 ]; then
        color=$RED
    elif [ "$int_percent" -gt 50 ]; then
        color=$YELLOW
    fi
    
    # Calcula blocos
    local filled=$(( width * int_percent / 100 ))
    local empty=$(( width - filled ))
    
    # Desenha barra
    echo -ne "[${color}"
    for ((i=0; i<filled; i++)); do echo -ne "█"; done
    echo -ne "${NC}"
    for ((i=0; i<empty; i++)); do echo -ne "░"; done
    echo -ne "] ${int_percent}%"
}

print_header() {
    local title="$1"
    echo ""
    echo -e "${WHITE}┌─────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}  ${CYAN}$title${NC}"
    echo -e "${WHITE}└─────────────────────────────────────────┘${NC}"
}

# ===== LOADING SEQUENCE =====
loading_banner(){
    show_loading "Initializing data collection" 10    # 10 ticks = 1 segundo
    show_loading "Collecting CPU metrics" 15         # 15 ticks = 1.5 segundos
    show_loading "Collecting Memory metrics" 15      # 15 ticks = 1.5 segundos
    show_loading "Collecting Disk metrics" 10        # 10 ticks = 1 segundo
    show_loading "Analyzing processes" 20            # 20 ticks = 2 segundos
}

# ===== COLETORES DE DADOS =====
get_cpu_usage(){
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    
    print_header "CPU USAGE"
    echo -ne "  ${BLUE}Usage:  ${NC}"
    draw_bar "$cpu" 35
    echo ""
}

get_memory_usage(){
    local total_memory=$(free -h | grep Mem: | awk '{print $2}')
    local memory_used=$(free -h | grep Mem: | awk '{print $3}')
    local memory_percent=$(free | grep Mem: | awk '{printf "%.1f", $3/$2 * 100}')

    print_header "MEMORY USAGE"
    echo -ne "  ${BLUE}RAM:    ${NC}"
    draw_bar "$memory_percent" 35
    echo -e "\n  ${CYAN}Used: $memory_used / Total: $total_memory${NC}"
}

get_disk_usage(){
    local disk_size=$(df -h --total | grep total | awk '{print $2}')
    local disk_used=$(df -h --total | grep total | awk '{print $3}')
    local disk_available=$(df -h --total | grep total | awk '{print $4}')
    local disk_percent=$(df -h --total | grep total | awk '{print $5}' | sed 's/%//')

    print_header "DISK USAGE"
    echo -ne "  ${BLUE}Disk:   ${NC}"
    draw_bar "$disk_percent" 35
    echo -e "\n  ${CYAN}Size: $disk_size | Used: $disk_used | Available: $disk_available${NC}"
}

get_top_process_cpu(){
    print_header "TOP 5 PROCESSES - CPU"
    
    # Cabeçalho da tabela
    printf "  ${PURPLE}%-8s %-6s %-6s %-30s${NC}\n" "PID" "%CPU" "%MEM" "COMMAND"
    echo -e "  ${BLUE}──────────────────────────────────────────────${NC}"
    
    # Lista processos
    ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
        local pid=$(echo $line | awk '{print $2}')
        local cpu_p=$(echo $line | awk '{print $3}')
        local mem_p=$(echo $line | awk '{print $4}')
        local cmd=$(echo $line | awk '{for(i=11;i<=NF;i++) printf "%s ", $i}' | cut -c1-28)
        
        printf "  %-8s %-6s %-6s %-30s\n" "$pid" "$cpu_p" "$mem_p" "${cmd:0:28}"
    done
}

get_top_process_memory(){
    print_header "TOP 5 PROCESSES - MEMORY"
    
    # Cabeçalho da tabela
    printf "  ${PURPLE}%-8s %-8s %-6s %-6s %-25s${NC}\n" "PID" "PPID" "%MEM" "%CPU" "COMMAND"
    echo -e "  ${BLUE}─────────────────────────────────────────────────────${NC}"
    
    # Lista processos
    ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head -6 | tail -5 | while read line; do
        local pid=$(echo $line | awk '{print $1}')
        local ppid=$(echo $line | awk '{print $2}')
        local mem_p=$(echo $line | awk '{print $3}')
        local cpu_p=$(echo $line | awk '{print $4}')
        local cmd=$(echo $line | awk '{for(i=5;i<=NF;i++) printf "%s ", $i}' | cut -c1-23)
        
        printf "  %-8s %-8s %-6s %-6s %-25s\n" "$pid" "$ppid" "$mem_p" "$cpu_p" "${cmd:0:23}"
    done
}

# ===== EXIBIÇÃO DOS RESULTADOS =====
get_results(){
    get_cpu_usage
    get_memory_usage
    get_disk_usage
    get_top_process_cpu
    get_top_process_memory
}

# ===== MAIN =====
main(){
    clear
    
    # Banner de abertura
    echo ""
    echo -e "${GREEN}  ╔══════════════════════════════════╗${NC}"
    echo -e "${GREEN}     🖥️  Server Health Checker       ${NC}"
    echo -e "${GREEN}  ╚══════════════════════════════════╝${NC}"
    echo ""
    
    # Loading animation
    loading_banner
    
    # Resultados
    get_results
    
    # Footer
    echo ""
    echo -e "${GREEN}  ╔══════════════════════════════════╗${NC}"
    echo -e "${GREEN}        ✅ Analysis Complete        ${NC}"
    echo -e "${GREEN}  ╚══════════════════════════════════╝${NC}"
    echo ""
}

# Executa
main