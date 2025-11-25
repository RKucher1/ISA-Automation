#!/bin/bash

#You can change the value of this variable to something other than 'yes' if you do not want to use the pause points incorporated in this script.
pause=no

#You can change this variable to 'y' if you have a shared folder setup with the name 'Kali Scans'. This will copy over all ISA data to your windows machine automatically.
filecopy=y

#Check if the script is being run as root.
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi
cd /root

figlet -c -f slant "ISA"
echo "                 ==============================================="
echo "                        Bash Script for Automating ISAs"
echo "                                      v2.5"
echo "                 ==============================================="
echo ""

# Function to sanitize client name for use in directory names
sanitize_client_name() {
	local name="$1"
	# Remove leading/trailing whitespace
	name=$(echo "$name" | xargs)
	# Replace spaces with hyphens
	name="${name// /-}"
	# Remove special characters except hyphens and underscores
	name=$(echo "$name" | sed 's/[^a-zA-Z0-9_-]//g')
	# Convert to uppercase for consistency
	name=$(echo "$name" | tr '[:lower:]' '[:upper:]')
	echo "$name"
}

# Prompt for client/company name
echo ""
echo "Enter the client or company name for this assessment."
echo "This will be used to create the folder as 'CLIENT-ISA' (e.g., ACME-ISA)"
echo ""
while true; do
	read -p "Client/Company Name: " client_name_raw
	if [ -z "$client_name_raw" ]; then
		echo "Error: Client name cannot be empty. Please try again."
		continue
	fi

	# Sanitize the name
	client_name=$(sanitize_client_name "$client_name_raw")

	if [ -z "$client_name" ]; then
		echo "Error: Client name contains only invalid characters. Please use letters, numbers, spaces, hyphens, or underscores."
		continue
	fi

	# Show sanitized name and confirm
	echo ""
	echo "Folder will be created as: ${client_name}-ISA"
	read -p "Is this correct? (y/n): " confirm_client

	if [[ "$confirm_client" == "y" ]]; then
		break
	fi
done

# Set the base directory for all ISA operations
ISA_BASE_DIR="/root/Desktop/${client_name}-ISA"
ISA_OLD_DIR="/root/Desktop/${client_name}-ISAold"

echo ""
echo "Assessment will be saved to: $ISA_BASE_DIR"
echo ""

#Immediately starts Responder in a separate terminal window.
gnome-terminal --geometry=200x45 -- bash -c "sudo responder -I eth0 -vwF; echo''; bash" & disown

#Creates the folder structure for organizational purposes. Removes old directory if already exists.
if [ -d "$ISA_BASE_DIR" ]; then
	if [ -d "$ISA_OLD_DIR" ]; then
		rm -r "$ISA_OLD_DIR"
		echo "Deleted the ${client_name}-ISAold directory to make room for a more recent copy..."
	fi
	mkdir "$ISA_OLD_DIR"
	mv "$ISA_BASE_DIR" "$ISA_OLD_DIR"
	echo "Moved the ${client_name}-ISA directory into the ${client_name}-ISAold directory..."
	wait
	mkdir -p "$ISA_BASE_DIR"/Scans/{Armitage,EyeWitness,Network,Nmap,ShareScan,SNMP,SQLping,Versions,Vulnerability,Wifi,Wireshark}
	mkdir -p "$ISA_BASE_DIR"/Screenshots/{"Default Passwords","DNS Zone Transfer","Outbound Connections","RDP to DC","SMTP Relay",telnet,WebFiltering,WPAD}
	mkdir -p "$ISA_BASE_DIR"/{isp,netaudit}
	echo "Created a new ${client_name}-ISA directory structure on the desktop..."
else
	mkdir -p "$ISA_BASE_DIR"/Scans/{Armitage,EyeWitness,Network,Nmap,ShareScan,SNMP,SQLping,Versions,Vulnerability,Wifi,Wireshark}
	mkdir -p "$ISA_BASE_DIR"/Screenshots/{"Default Passwords","DNS Zone Transfer","Outbound Connections","RDP to DC","SMTP Relay",telnet,WebFiltering,WPAD}
	mkdir -p "$ISA_BASE_DIR"/{isp,netaudit}
	echo "Created the ${client_name}-ISA directory structure on the desktop..."
fi

#Function that creates a spinning graphic to let you know the script is still working when no terminal output is seen
spinner() {
local pid=$!
local delay=0.75
local spinstr='|/-\'
	while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
	local temp=${spinstr#?}
	printf " [%c]  " "$spinstr"
	local spinstr=$temp${spinstr%"$temp"}
	sleep $delay
	printf "\b\b\b\b\b\b"
done
printf "    \b\b\b\b"
}

# Function to validate IPv4 address format for netaudit
is_valid_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        stat=0
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                stat=1
                break
            fi
        done
    fi
    return $stat
}

#Function to pause the script to connect to hash rig if necessary
pause_for_continue() {
	local input=""
	while [ "$input" != "c" ]; do
		read -p "Type 'c' to continue: " input
		if [ "$input" != "c" ]; then
			echo "Invalid input. Please type 'c' to continue."
		fi
	done
}

#Function that confirms user inputs as either 'y' or 'n'
validate_confirmation() {
	local input=$1
	if [[ "$input" == "y" || "$input" == "n" ]]; then
		return 0  # Valid
	else
		return 1  # Invalid
	fi
}

#Function to check if an IP address is a valid private IP for the IP exclusions.
is_private_ip() {
	local ip=$1
	# Regex to match private IP ranges (10.x.x.x, 172.16.x.x - 172.31.x.x, 192.168.x.x)
	if [[ "$ip" =~ ^10\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]] ||
	[[ "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[01])\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]] ||
	[[ "$ip" =~ ^192\.168\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
		return 0  # Valid private IP
	else
		return 1  # Invalid IP
	fi
}

#Function to check if an IP address is valid
is_valid_ip() {
local ip=$1
local IFS='.'
local -a octets=($ip)

#Function that checks if the IP address has 4 octets
if [ ${#octets[@]} -ne 4 ]; then
	return 1
fi

#Function that checks if each octet is between 0 and 255
for octet in "${octets[@]}"; do
	if ! [[ $octet =~ ^[0-9]+$ ]] || [ $octet -lt 0 ] || [ $octet -gt 255 ]; then
	return 1
	fi
done
return 0
}

#Function to check if an IP address is within the private range
is_private_ip() {
local ip=$1
local IFS='.'
local -a octets=($ip)
if [[ ${octets[0]} -eq 10 ]]; then
	return 0
	elif [[ ${octets[0]} -eq 172 ]] && [[ ${octets[1]} -ge 16 ]] && [[ ${octets[1]} -le 31 ]]; then
	return 0
	elif [[ ${octets[0]} -eq 192 ]] && [[ ${octets[1]} -eq 168 ]]; then
	return 0
fi
return 1
}

#Function to convert an IP address to a number for comparison
ip_to_number() {
local ip=$1
local IFS='.'
local -a octets=($ip)
echo $(( (${octets[0]} * 256 ** 3) + (${octets[1]} * 256 ** 2) + (${octets[2]} * 256) + ${octets[3]} ))
}

#Function to check if the IP range format is valid
is_valid_ip_range() {
local range=$1
local IFS=' '
local -a ips=($range)

#Function that checks if the range has exactly two IP addresses
if [ ${#ips[@]} -ne 2 ]; then
	return 1
fi

#Check if both IP addresses are valid and within the private range
is_valid_ip "${ips[0]}" && is_private_ip "${ips[0]}" && is_valid_ip "${ips[1]}" && is_private_ip "${ips[1]}"
if [ $? -ne 0 ]; then
	return 1
fi

#Function that checks if the number of IP addresses in the range is within the limit
local start_ip_num=$(ip_to_number "${ips[0]}")
local end_ip_num=$(ip_to_number "${ips[1]}")
local ip_count=$(( end_ip_num - start_ip_num + 1 ))

#Function that defines the maximum number of IPs in private range (e.g., 192.168.0.1 - 192.168.255.255 is 65280 IPs)
local max_ips=$(( 256 * 256 ))
if [ $ip_count -le 0 ] || [ $ip_count -gt $max_ips ]; then
	return 1
fi
return 0
}

# Function to log errors
log_error_and_exit() {
	echo "[ERROR] $1"
}

# Function to open GNOME terminal
open_gnome_terminal() {
	gnome-terminal -- bash -c "$1" &
	local pid=$!
	echo $pid
}

# ============================================================================
# CHECKPOINT AND RESUME FUNCTIONALITY
# ============================================================================

# Checkpoint state file and config file
CHECKPOINT_FILE="$ISA_BASE_DIR/.checkpoint_state"
CONFIG_FILE="$ISA_BASE_DIR/.resume_config"

# Define all checkpoints in order
declare -a CHECKPOINTS=(
    "INIT:Initial Setup and User Inputs"
    "PACKET_CAPTURE:Network Packet Capture (Tshark)"
    "PING_SWEEPS:Network Discovery (Ping Sweeps)"
    "NMAP:Nmap Vulnerability Scanning"
    "ZONE_TRANSFER:DNS Zone Transfer"
    "ANON_ENUM:Anonymous Enumeration"
    "METASPLOIT:Metasploit Vulnerability Tests"
    "SHARES_SNMP:SMB Shares and SNMP Enumeration"
    "OS_VERSIONS:OS Version Detection"
    "SQL:SQL Server Testing"
    "TELNET:Telnet Service Testing"
    "SMTP:SMTP Relay Testing"
    "OUTBOUND:Outbound Connection Testing"
    "WEBFILTER:Web Filtering Tests"
    "GOWITNESS:Gowitness Web Screenshots"
    "DEFAULTHTTP:Default HTTP Credentials"
    "ISP:ISP Information Gathering"
    "GOWITNESS_SERVER:Gowitness Server Startup"
    "NETAUDIT_PREP:NetAudit Preparation"
    "NETAUDIT:NetAudit Execution"
)

# Function to save a checkpoint
save_checkpoint() {
    local checkpoint_name="$1"
    echo "$checkpoint_name" > "$CHECKPOINT_FILE"
    echo "[CHECKPOINT] Saved: $checkpoint_name at $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$ISA_BASE_DIR/script.log"
}

# Function to load the last checkpoint
load_last_checkpoint() {
    if [ -f "$CHECKPOINT_FILE" ]; then
        cat "$CHECKPOINT_FILE"
    else
        echo ""
    fi
}

# Function to save configuration
save_config() {
    cat > "$CONFIG_FILE" << 'CONFIGEOF'
client_name="$client_name"
ISA_BASE_DIR="$ISA_BASE_DIR"
ISA_OLD_DIR="$ISA_OLD_DIR"
dhcp_answer="$dhcp_answer"
windows="$windows"
cuemail="$cuemail"
cgemail="$cgemail"
SKIP_PSWEEPS="$SKIP_PSWEEPS"
SKIP_NMAP="$SKIP_NMAP"
confirm4="$confirm4"
confirm7="$confirm7"
confirm11="$confirm11"
netaudit="${netaudit:-0}"
netaudit_text="${netaudit_text:-}"
filecopy="$filecopy"
pause="$pause"
ldap="${ldap:-false}"
kaliIP="${kaliIP:-}"
cudomain="${cudomain:-}"
ip_addressna="${ip_addressna:-}"
CONFIGEOF
    echo "[CONFIG] Configuration saved" | tee -a "$ISA_BASE_DIR/script.log"
}

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "[CONFIG] Configuration loaded from previous run"
        return 0
    else
        return 1
    fi
}

# Function to display resume menu
show_resume_menu() {
    local last_checkpoint="$1"
    echo ""
    echo "======================================================================="
    echo "                    RESUME FROM CHECKPOINT"
    echo "======================================================================="
    echo ""
    echo "A previous run was detected. Last completed checkpoint:"
    echo "  -> $last_checkpoint"
    echo ""
    echo "Select where to resume from:"
    echo ""

    local index=1
    local found_last=false
    for checkpoint in "${CHECKPOINTS[@]}"; do
        IFS=':' read -r name desc <<< "$checkpoint"

        if [ "$name" = "$last_checkpoint" ]; then
            found_last=true
            echo "  $index) $desc [LAST COMPLETED]"
        elif $found_last; then
            echo "  $index) $desc"
        else
            echo "  $index) $desc [COMPLETED]"
        fi
        ((index++))
    done

    echo ""
    echo "  0) Start fresh (delete all checkpoints)"
    echo "  q) Quit"
    echo ""
}

# Function to get checkpoint by index
get_checkpoint_by_index() {
    local index="$1"
    if [ "$index" -ge 1 ] && [ "$index" -le "${#CHECKPOINTS[@]}" ]; then
        local checkpoint="${CHECKPOINTS[$((index-1))]}"
        IFS=':' read -r name desc <<< "$checkpoint"
        echo "$name"
        return 0
    fi
    return 1
}

# Function to get index of checkpoint
get_checkpoint_index() {
    local target="$1"
    local index=1
    for checkpoint in "${CHECKPOINTS[@]}"; do
        IFS=':' read -r name desc <<< "$checkpoint"
        if [ "$name" = "$target" ]; then
            echo "$index"
            return 0
        fi
        ((index++))
    done
    echo "0"
}

# Function to check if we should skip a section
should_skip_section() {
    local current_section="$1"
    local resume_from="$2"

    if [ -z "$resume_from" ]; then
        return 1  # Don't skip, no resume point
    fi

    local current_index=$(get_checkpoint_index "$current_section")
    local resume_index=$(get_checkpoint_index "$resume_from")

    if [ "$current_index" -lt "$resume_index" ]; then
        return 0  # Skip this section
    else
        return 1  # Don't skip
    fi
}

# Function to extract subnets from old network.txt file
extract_subnets_from_old_network() {
    local old_network_file="$1"
    local output_file="$ISA_BASE_DIR/Scans/Network/ips.txt"

    echo "[INFO] Processing old network.txt file..."
    echo "[INFO] Extracting unique /16 subnets..."

    # Read IPs and extract unique /16 subnets (first two octets)
    declare -A subnets
    while IFS= read -r ip; do
        # Skip empty lines and comments
        [[ -z "$ip" || "$ip" =~ ^#.*$ ]] && continue

        # Validate IP format
        if [[ $ip =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
            local octet1="${BASH_REMATCH[1]}"
            local octet2="${BASH_REMATCH[2]}"

            # Check if it's a private IP
            if [[ ($octet1 -eq 10) ||
                  ($octet1 -eq 172 && $octet2 -ge 16 && $octet2 -le 31) ||
                  ($octet1 -eq 192 && $octet2 -eq 168) ]]; then
                # Store unique /16 subnet
                subnets["${octet1}.${octet2}"]=1
            fi
        fi
    done < "$old_network_file"

    # Convert subnets to ranges and write to file
    local count=0
    for subnet in "${!subnets[@]}"; do
        echo "${subnet}.0.1 ${subnet}.255.255" >> "$output_file"
        echo "  -> Added subnet: ${subnet}.0.0/16"
        ((count++))
    done

    echo "[INFO] Added $count subnet ranges from old network file"
    echo ""
}

# Check for resume capability at script start
RESUME_FROM=""
LAST_CHECKPOINT=$(load_last_checkpoint)

if [ -n "$LAST_CHECKPOINT" ]; then
    show_resume_menu "$LAST_CHECKPOINT"
    while true; do
        read -p "Enter your choice: " resume_choice

        if [ "$resume_choice" = "q" ] || [ "$resume_choice" = "Q" ]; then
            echo "Exiting script."
            exit 0
        elif [ "$resume_choice" = "0" ]; then
            echo "Starting fresh..."
            rm -f "$CHECKPOINT_FILE" "$CONFIG_FILE"
            RESUME_FROM=""
            break
        elif [[ "$resume_choice" =~ ^[0-9]+$ ]]; then
            CHECKPOINT_NAME=$(get_checkpoint_by_index "$resume_choice")
            if [ -n "$CHECKPOINT_NAME" ]; then
                RESUME_FROM="$CHECKPOINT_NAME"
                echo "Resuming from: $CHECKPOINT_NAME"
                load_config
                break
            else
                echo "Invalid choice. Please try again."
            fi
        else
            echo "Invalid input. Please enter a number, 0, or q."
        fi
    done
fi

#Initial user inputs for the script to function properly
confirm1=""
confirm2=""
confirm3=""
confirm4=n
confirm5=y
confirm6=n
confirm7=n
confirm8=""
confirm9=n
confirm10=n
confirm11=""
SKIP_PSWEEPS=n
SKIP_NMAP=n
#!/bin/bash

# ============= CHECKPOINT: INIT =============
if ! should_skip_section "INIT" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Initial Setup and User Inputs ==="
    echo "=========================================="
    echo ""

while true; do
    read -p "Are you on DHCP? (y/n): " dhcp_answer
    case "${dhcp_answer,,}" in
        y|n)
            while true; do
                read -p "You entered '$dhcp_answer'. Is this correct? (y/n): " confirm
                case "${confirm,,}" in
                    y)
                        echo "Confirmed: $dhcp_answer"
                        break 2
                        ;;
                    n)
                        echo "Let's try again."
                        break
                        ;;
                    *)
                        echo "Please answer with 'y' or 'n'."
                        ;;
                esac
            done
            ;;
        *)
            echo "Invalid input. Please enter 'y' or 'n'."
            ;;
    esac
done
if [ "$dhcp_answer" == "y" ]; then
	echo "You will be asked what the IP address of the netaudit machine just before this script finishes."
	echo ""
	netaudit=0
	echo "How long do you want NetAudit to run? This script will grab most high profile IPs and then 300 random IPs. Lately it has been taking about an hour to complete the NetAudit scan."
	echo "15 minutes     (1)"
	echo "1 hour         (2)"
	echo "2 hours        (3)"
	echo "3 hours        (4)"
	echo "4 hours        (5)"
	echo "Until Finished (6)"
	while ! [[ "$netaudit" =~ ^[1-6]$ ]]; do
		read -p "How long do you want NetAudit to run? (1-6): " netaudit
		if ! [[ "$netaudit" =~ ^[1-6]$ ]]; then
			echo "Invalid input. Please enter a number between 1 and 6."
		fi
	done

	case $netaudit in
		1)
			netaudit_text="15 mins"
			;;
		2)
			netaudit_text="1 hour"
			;;
		3)
			netaudit_text="2 hours"
			;;
		4)
			netaudit_text="3 hours"
			;;
		5)
			netaudit_text="4 hours"
			;;
		6)
			netaudit_text="Until Finished"
			;;
	esac
	echo ""
	echo "NetAudit will run for: $netaudit_text"
fi
echo ""
while true; do
	read -p "Enter the Windows IP Address: " windows
	while ! validate_confirmation "$confirm1"; do
		read -p "Is $windows correct? (y/n): " confirm1
		if [[ "$confirm1" == "n" ]]; then
			echo "Please re-enter the Windows IP address."
			break
		    elif [[ "$confirm1" == "y" ]]; then
			break
		fi
	done
	if [[ "$confirm1" == "y" ]]; then
		break
	fi
done
echo ""
while true; do
	read -p "Enter the credit union related email address you would like to use for anonymous SMTP relay: " cuemail
	confirm2=""
	while ! validate_confirmation "$confirm2"; do
		read -p "Is $cuemail correct? (y/n): " confirm2
		if [[ "$confirm2" == "n" ]]; then
			echo "Please re-enter the credit union email address."
			break  # Exit inner while loop, ask for email again
		    elif [[ "$confirm2" == "y" ]]; then
			break  # Exit inner while loop, email is confirmed
		fi
	done
	if [[ "$confirm2" == "y" ]]; then
		break
	fi
done
echo ""
while true; do
	read -p "Enter your CastleGarde email address you would like to use for anonymous SMTP relay: " cgemail
	while ! validate_confirmation "$confirm3"; do
		read -p "Is $cgemail correct? (y/n): " confirm3
		if [[ "$confirm3" == "n" ]]; then
			echo "Please re-enter the CastleGarde email address."
			break
		    elif [[ "$confirm3" == "y" ]]; then
			break
		fi
	done
	if [[ "$confirm3" == "y" ]]; then
		break
	fi
done
echo ""


# Ensure valid input for SKIP_PSWEEPS (y/n)
while true; do
	read -p "Do you want to skip the ping sweeps?    ==> *** CAUTION *** <==    This is for very specific use cases. 99% of the time, this will be 'n'. (y/n): " SKIP_PSWEEPS
	if [[ "$SKIP_PSWEEPS" == "y" || "$SKIP_PSWEEPS" == "n" ]]; then
		if [[ "$SKIP_PSWEEPS" == "y" ]]; then
			read -p "You have chosen to skip the ping sweeps. Are you sure? (y/n): " confirm_psweeps
			if [[ "$confirm_psweeps" == "y" ]]; then
				echo "Ping sweeps will be skipped."
				break
			    elif [[ "$confirm_psweeps" == "n" ]]; then
					echo "Ping sweeps will not be skipped."
					break
			else
				echo "Invalid input. Please enter 'y' or 'n'."
			fi
		else
			echo "Ping sweeps will not be skipped."
			break
		fi
	else
		echo "Invalid input. Please enter 'y' or 'n'."
	fi
done
echo ""

# Ensure valid input for SKIP_NMAP (y/n)
while true; do
	read -p "Do you want to skip nmap?    ==> *** CAUTION *** <==    This is for very specific use cases. 99% of the time, this will be 'n'. (y/n): " SKIP_NMAP
	if [[ "$SKIP_NMAP" == "y" || "$SKIP_NMAP" == "n" ]]; then
		if [[ "$SKIP_NMAP" == "y" ]]; then
			read -p "You have chosen to skip nmap. Are you sure? (y/n): " confirm_nmap
			if [[ "$confirm_nmap" == "y" ]]; then
				echo "Nmap will be skipped."
				# Pause until the user decides to continue
				read -p "Make sure that your nmap.xml file has been pasted into $ISA_BASE_DIR/nmap. Press any key to continue when ready..." continue_nmap
				# Confirm if they want to continue
				read -p "Did you paste your nmap.xml file into $ISA_BASE_DIR/nmap? (y/n): " continue_confirm
				if [[ "$continue_confirm" == "y" ]]; then
					break
				else
					echo "Process halted. Please paste nmap.xml into $ISA_BASE_DIR/nmap."
					break
				fi
				elif [[ "$confirm_nmap" == "n" ]]; then
					echo "Nmap will not be skipped."
					break
				else
					echo "Invalid input. Please enter 'y' or 'n'."
				fi
			else
				echo "Nmap will not be skipped."
				break
		fi
	else
		echo "Invalid input. Please enter 'y' or 'n'."
	fi
done
echo ""

# Save config and checkpoint after init
save_config
save_checkpoint "INIT"

else
    echo "[SKIP] Skipping Initial Setup (already completed)"
    echo "[INFO] Loading previous configuration..."
fi

# ============= CHECKPOINT: PACKET_CAPTURE =============
if ! should_skip_section "PACKET_CAPTURE" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Network Packet Capture (Tshark) ==="
    echo "=========================================="
    echo ""

    # Check if tshark is installed
    if ! command -v tshark &> /dev/null; then
        echo "[WARNING] tshark is not installed. Skipping packet capture."
        echo "[INFO] Install with: apt-get install tshark"
    else
        # Get the network interface
        interface="eth0"

        # Check if interface exists
        if ! ip link show "$interface" &> /dev/null; then
            echo "[WARNING] Interface $interface not found. Attempting to detect active interface..."
            interface=$(ip route | grep default | awk '{print $5}' | head -n 1)
            if [ -z "$interface" ]; then
                echo "[ERROR] Could not detect active network interface. Skipping packet capture."
                interface=""
            else
                echo "[INFO] Using detected interface: $interface"
            fi
        fi

        if [ -n "$interface" ]; then
            # Generate filename with timestamp
            timestamp=$(date +%Y%m%d_%H%M%S)
            pcap_file="$ISA_BASE_DIR/Scans/Wireshark/capture_${timestamp}.pcap"

            echo "[INFO] Starting packet capture on interface: $interface"
            echo "[INFO] Capturing 10,000 packets..."
            echo "[INFO] Output file: $pcap_file"
            echo "[INFO] This may take a few minutes depending on network activity..."
            echo ""

            # Capture 10,000 packets with tshark
            # -i: interface
            # -c: packet count
            # -w: output file
            # -q: quiet mode (less verbose)
            tshark -i "$interface" -c 10000 -w "$pcap_file" -q 2>&1 | tee -a $ISA_BASE_DIR/Scans/Wireshark/capture.log

            if [ -f "$pcap_file" ]; then
                # Get file size in human-readable format
                file_size=$(du -h "$pcap_file" | cut -f1)
                packet_count=$(tshark -r "$pcap_file" -q -z io,stat,0 2>&1 | grep "Frames" | awk '{print $4}' | head -n1)

                echo ""
                echo "[SUCCESS] Packet capture completed!"
                echo "[INFO] File: $pcap_file"
                echo "[INFO] Size: $file_size"
                echo "[INFO] Packets captured: ${packet_count:-10000}"
                echo "[INFO] You can analyze this with: wireshark $pcap_file"
                echo ""
            else
                echo "[ERROR] Packet capture failed. File not created."
                echo "[INFO] Check permissions and network interface status."
            fi
        fi
    fi

    # Save checkpoint after packet capture
    save_checkpoint "PACKET_CAPTURE"

else
    echo "[SKIP] Skipping Packet Capture (already completed)"
fi

# ============= CHECKPOINT: PING_SWEEPS =============
if ! should_skip_section "PING_SWEEPS" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Network Discovery (Ping Sweeps) ==="
    echo "=========================================="
    echo ""

if [ $SKIP_PSWEEPS = "y" ]; then
	echo "Skipping ping sweeps and creating a blank network.txt file."
	touch $ISA_BASE_DIR/Scans/Network/network.txt
	echo ""
	echo "The network.txt file will open shortly. Make the necessary changes to the network.txt file and then save it."
	sleep 3
	mousepad $ISA_BASE_DIR/Scans/Network/network.txt &
	mousepad_pid=$!
	while true; do
		if ! ps -p $mousepad_pid > /dev/null; then
			read -p "If you are seeing this, you should have made the changes, saved the network.txt file, and closed it. (y/n)?: " confirm8
			if [ "$confirm8" = "y" ]; then
				echo ""
				break
			else
				echo "You must enter 'y' to proceed. Please confirm once the changes are made and saved."
			fi
		fi
		sleep 1
	done
else
	while true; do
		read -p "Do you want to exclude any IP addresses? (y/n): " confirm10

		# Validate first input (confirm10) is 'y' or 'n'
		if [[ "$confirm10" != "y" && "$confirm10" != "n" ]]; then
			echo "Invalid input. Please enter 'y' or 'n'."
			continue
		fi

		# If the first input is 'n', ask the user to confirm again
		if [[ "$confirm10" != "y" ]]; then
			while true; do
				read -p "Please enter $confirm10 again to confirm (y/n): " confirm11

				# Validate second input (confirm11) is 'y' or 'n'
				if [[ "$confirm11" != "y" && "$confirm11" != "n" ]]; then
					echo "Invalid input. Please enter 'y' or 'n'."
					continue
				fi

				# If the second input is not the same as the first, restart the process
					if [[ "$confirm11" != "$confirm10" ]]; then
					echo "The inputs do not match. Restarting the process."
					break
				fi

				# If the second input matches the first, proceed
				if [[ "$confirm11" == "n" ]]; then
					echo "No IP addresses will be excluded."
					break
				fi
			done
		fi

		# Exit the outer loop if the process completes
		break
	done

	#Creates IP exclusion file if necessary.
	if [ "$confirm11" != 'n' ]; then
		while true; do
			echo "Please paste your IP addresses, then press Ctrl+D when done: "
			ip_list=$(cat)
			normalized_ip_list=$(echo "$ip_list" | tr ' ' '\n' | tr -s '\n')
			echo "You have entered the following IP addresses:"
			echo "$normalized_ip_list"
			all_valid=true
			for ip in $normalized_ip_list; do
				if ! is_private_ip "$ip"; then
					echo "Invalid private IP address detected: $ip"
					all_valid=false
					break
				fi
			done
			if [ "$all_valid" = true ]; then
				read -p "Do you want to exclude these IP addresses? y/n: " confirm
				if [ "$confirm" == "y" ]; then
					echo "$normalized_ip_list" | tee -a $ISA_BASE_DIR/Scans/Network/ipexclusions.txt
					echo "The IP addresses have been excluded."
					break
				else
					echo "No IP addresses were excluded. Please review and confirm again."
					echo ""
				fi
			else
				echo "Please enter valid private IP addresses only."
				echo ""
			fi
		done
	fi
	echo ""

	#Import old network.txt file to automatically determine subnets
	echo "======================================================================="
	echo "           IMPORT OLD NETWORK.TXT FILE (OPTIONAL)"
	echo "======================================================================="
	echo ""
	echo "If you have a previous network.txt file from a prior assessment,"
	echo "you can import it to automatically determine which subnets to scan."
	echo "This will extract all unique /16 subnets from your old scan results."
	echo ""

	while true; do
		read -p "Do you have an old network.txt file to import? (y/n): " import_old_network
		import_old_network=$(echo "$import_old_network" | tr '[:upper:]' '[:lower:]')
		if [[ "$import_old_network" == "y" || "$import_old_network" == "n" ]]; then
			break
		else
			echo "Invalid input. Please enter 'y' or 'n'."
		fi
	done

	if [ "$import_old_network" == "y" ]; then
		while true; do
			read -p "Enter the full path to your old network.txt file: " old_network_path

			# Check if file exists
			if [ ! -f "$old_network_path" ]; then
				echo "[ERROR] File not found: $old_network_path"
				read -p "Try again? (y/n): " retry
				if [[ "$retry" != "y" ]]; then
					echo "Skipping old network import."
					break
				fi
				continue
			fi

			# Check if file is readable
			if [ ! -r "$old_network_path" ]; then
				echo "[ERROR] File is not readable: $old_network_path"
				read -p "Try again? (y/n): " retry
				if [[ "$retry" != "y" ]]; then
					echo "Skipping old network import."
					break
				fi
				continue
			fi

			# Show file preview
			echo ""
			echo "Preview of file (first 10 lines):"
			echo "-----------------------------------"
			head -n 10 "$old_network_path"
			echo "-----------------------------------"
			echo ""

			read -p "Is this the correct file? (y/n): " confirm_file
			if [[ "$confirm_file" == "y" ]]; then
				extract_subnets_from_old_network "$old_network_path"
				echo "[SUCCESS] Subnets extracted and added to scan list!"
				break
			else
				read -p "Try again? (y/n): " retry
				if [[ "$retry" != "y" ]]; then
					echo "Skipping old network import."
					break
				fi
			fi
		done
	fi
	echo ""

	#Angry IP scanner. Accepts user input ranges. Verifies that the range contains only private IP addresses. Limits the amount of IP addresses in the range 65536
	echo "These ranges will automatically be scanned regardless of user input:"
	echo "----10.0.0.1 - 10.0.255.255----"
	echo "----10.1.0.1 - 10.1.255.255----"
	echo "---10.10.0.1 - 10.10.255.255---"
	echo "--10.100.0.1 - 10.100.255.255--"
	echo "--172.16.0.1 - 172.16.255.255--"
	echo "--172.31.0.1 - 172.31.255.255--"
	echo "-192.168.0.1 - 192.168.255.255-"
	while true; do
		read -p "Would you like to scan additional subnets manually? y/n: " confirm4
		confirm4=$(echo "$confirm4" | tr '[:upper:]' '[:lower:]')
		if [[ "$confirm4" == "y" || "$confirm4" == "n" ]]; then
			echo ""
			break
		else
			echo "Invalid input. Please enter 'y' or 'n'."
		fi
	done
	echo ""
	if [ $confirm4 == 'y' ]; then
		while true; do
			while true; do
				read -p "Enter a valid internal IP address range (e.g., 10.2.0.1 10.2.255.255): " ip_range
				if is_valid_ip_range "$ip_range"; then
					echo "This IP address range will be scanned:"
					echo "$ip_range" | tee -a $ISA_BASE_DIR/Scans/Network/ips.txt
					echo ""
					break
				else
					echo ""
					echo "Invalid IP address range format or too many IP addresses in the range. Please try again."
					echo ""
				fi
			done
			read -p "Do you want to input another range? (y/n): " continue_input
			if [[ $continue_input != "y" ]]; then
				break
			fi
		done
	else
		echo "No other ranges will be scanned."
		echo ""
		echo "Starting ping sweeps. Do not leave your cursor hovering over the taskbar as it will cause issues when the ping sweeps complete..."
	fi
	wait
	if [ $confirm4 == 'y' ]; then
		while read line1; do
			filename=$(echo "$line1" | sed 's/\([0-9]\+\.[0-9]\+\)\.[0-9]\+\.[0-9]\+.*/\1/')
			ipscan -sq -f:range $line1 -o "$ISA_BASE_DIR/Scans/Network/$filename.txt" > /dev/null 2>&1 &
		done < '$ISA_BASE_DIR/Scans/Network/ips.txt'
		spinner
		wait
		for line1 in $(cat '$ISA_BASE_DIR/Scans/Network/ips.txt'); do
			filename=$(echo "$line1" | sed 's/\([0-9]\+\.[0-9]\+\)\.[0-9]\+\.[0-9]\+.*/\1/')
			sed '1,7d' "$ISA_BASE_DIR/Scans/Network/$filename.txt" | awk '{print $1}' | sort | uniq | tee -a $ISA_BASE_DIR/Scans/Network/userinput.txt
		done
	fi
	wait
	echo ""
	echo "Finished with user input scans. Starting default scans. Do not leave you cursor hovering over the taskbar as it will cause issues when the ping sweeps complete..."
	ipscan -sq -f:range 10.0.0.1 10.0.255.255 -o $ISA_BASE_DIR/Scans/Network/10.0.txt > /dev/null 2>&1 &
	ipscan -sq -f:range 10.1.0.1 10.1.255.255 -o $ISA_BASE_DIR/Scans/Network/10.1.txt > /dev/null 2>&1 &
	ipscan -sq -f:range 10.10.0.1 10.10.255.255 -o $ISA_BASE_DIR/Scans/Network/10.10.txt > /dev/null 2>&1 &
	ipscan -sq -f:range 10.100.0.1 10.100.255.255 -o $ISA_BASE_DIR/Scans/Network/10.100.txt > /dev/null 2>&1 &
	ipscan -sq -f:range 172.16.0.1 172.16.255.255 -o $ISA_BASE_DIR/Scans/Network/172.16.txt > /dev/null 2>&1 &
	ipscan -sq -f:range 172.31.0.1 172.31.255.255 -o $ISA_BASE_DIR/Scans/Network/172.31.txt > /dev/null 2>&1 &
	ipscan -sq -f:range 192.168.0.1 192.168.255.255 -o $ISA_BASE_DIR/Scans/Network/192.168.txt > /dev/null 2>&1 &
	spinner
	wait
	echo ""

	#Variable that gets VM ip address for removal in network.txt file
	kaliIP="$(ip -4 -o address show dev eth0 | awk '{print $4}' | sed -e 's/[/].*//g')"

	#Creates network.txt file and removes the the 192.168.56.1, windows, kali, and excluded IP addresses. Makes a .bak file if already exists. Also open the network.txt file for final confirmation.
	echo "Creating network.txt..."
	sed '1,7d' $ISA_BASE_DIR/Scans/Network/10.0.txt | awk '{print $1}' |tee -a $ISA_BASE_DIR/Scans/Network/default.txt &&
	sed '1,7d' $ISA_BASE_DIR/Scans/Network/10.1.txt | awk '{print $1}' |tee -a $ISA_BASE_DIR/Scans/Network/default.txt &&
	sed '1,7d' $ISA_BASE_DIR/Scans/Network/10.10.txt | awk '{print $1}' |tee -a $ISA_BASE_DIR/Scans/Network/default.txt &&
	sed '1,7d' $ISA_BASE_DIR/Scans/Network/10.100.txt | awk '{print $1}' |tee -a $ISA_BASE_DIR/Scans/Network/default.txt &&
	sed '1,7d' $ISA_BASE_DIR/Scans/Network/172.16.txt | awk '{print $1}' | tee -a $ISA_BASE_DIR/Scans/Network/default.txt &&
	sed '1,7d' $ISA_BASE_DIR/Scans/Network/172.31.txt | awk '{print $1}' | tee -a $ISA_BASE_DIR/Scans/Network/default.txt &&
	sed '1,7d' $ISA_BASE_DIR/Scans/Network/192.168.txt | awk '{print $1}' | tee -a $ISA_BASE_DIR/Scans/Network/default.txt
	cat $ISA_BASE_DIR/Scans/Network/userinput.txt $ISA_BASE_DIR/Scans/Network/default.txt > $ISA_BASE_DIR/Scans/Network/draft.txt
	if [ "$confirm11" != 'n' ]; then
		while IFS= read -r ip; do
			sed -i "/$ip/d" $ISA_BASE_DIR/Scans/Network/draft.txt
		done < $ISA_BASE_DIR/Scans/Network/ipexclusions.txt
	fi
	wait
	sed -e 's/192.168.56.1//g' -e "s/$kaliIP//g" -e "s/$windows//g" $ISA_BASE_DIR/Scans/Network/draft.txt | sort | uniq | awk 'NF' > $ISA_BASE_DIR/Scans/Network/network.txt &&
	wait
	echo ""
	echo "The IP addresses printed to the terminal above are not the final network.txt file. Please confirm by opening the network.txt file below or by navigating to the $ISA_BASE_DIR/network directory..."
	echo ""
	read -p "Do you want to open the network.txt file to manually exclude any final IP addresses before the nmap scan? y/n " confirm7;
	if [ "$confirm7" != "n" ]; then
		echo ""
		echo "The network.txt file will open shortly. Make the necessary changes to the network.txt file and then save it."
		sleep 3
		mousepad $ISA_BASE_DIR/Scans/Network/network.txt &
		mousepad_pid=$!
		while true; do
			if ! ps -p $mousepad_pid > /dev/null; then
				read -p "If you are seeing this, you should have made the changes, saved the network.txt file, and closed it. (y/n)?: " confirm8
				if [ "$confirm8" = "y" ]; then
					echo ""
					break
				else
					echo "You must enter 'y' to proceed. Please confirm once the changes are made and saved."
				fi
			fi
			sleep 1
		done
	fi
fi

# Save checkpoint after ping sweeps
save_config
save_checkpoint "PING_SWEEPS"

else
    echo "[SKIP] Skipping Ping Sweeps (already completed)"
fi

# ============= CHECKPOINT: NMAP =============
if ! should_skip_section "NMAP" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Nmap Vulnerability Scanning ==="
    echo "=========================================="
    echo ""

#Pause point if user defined the pause variable as 'yes'
if [ $pause == 'yes' ]; then
	echo "Nmap is next..."
	pause_for_continue
	echo "Continuing with nmap..."
fi

#Creates the nmap.xml file and then opens it in zenmap. Checks to see if a nmap.xml is already present and if so, creates a .bak file
if [ $SKIP_NMAP == 'y' ]; then
	echo "Skipping nmap. If a previous nmap file exists in $ISA_BASE_DIRold/nmap/ exists, it will be copied over and will be used for the remainder of this script."
	zenmap -f $ISA_BASE_DIR/Scans/Nmap/nmap.xml & disown
else
	echo "Running nmap on the network.txt file. Zenmap will open once complete..."
	if [ -f "$ISA_BASE_DIR/Scans/Nmap/nmap.xml" ]; then
		mv $ISA_BASE_DIR/Scans/Nmap/nmap.xml $ISA_BASE_DIR/Scans/Nmap/nmap.bak
	fi
	wait
	nmap -sV -T4 -O -v -F -iL $ISA_BASE_DIR/Scans/Network/network.txt -Pn --randomize-hosts --version-light " --exclude-ports 9100" -oX $ISA_BASE_DIR/Scans/Nmap/nmap.xml &&
	wait
	zenmap -f $ISA_BASE_DIR/Scans/Nmap/nmap.xml & disown
	wait
	sleep 5
fi
echo ""

# Save checkpoint after nmap
save_checkpoint "NMAP"

else
    echo "[SKIP] Skipping Nmap (already completed)"
fi

# ============= CHECKPOINT: ZONE_TRANSFER =============
if ! should_skip_section "ZONE_TRANSFER" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: DNS Zone Transfer ==="
    echo "=========================================="
    echo ""

#Pause point if user defined the pause variable as 'yes'
if [ $pause == 'yes' ]; then
	echo "Zone transfer, anonymous enumeration, metasploit modules, versions, telnets, smtp relay, and webfiltering are next..."
	pause_for_continue
	echo "Continuing..."
fi

#Tries to perform a DNS zone transfer. nobruteforce.txt does not exist so as to make sure no brute forcing takes place.
echo "Trying zone transfer. Will not bruteforce..."
echo ""
ldap=false
if /root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service ldap; then
	ldap=true
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service ldap | sed 's/0\.$//' > $ISA_BASE_DIR/Scans/Vulnerability/DC_IPs.txt
        cudomain=$(grep 'Domain:' $ISA_BASE_DIR/Scans/Nmap/nmap.xml | sed -n 's/.*Domain: \([^,]*\).*/\1/p' | sed 's/0\.$//' | sort | uniq)
        wait
        script -q $ISA_BASE_DIR/Screenshots/DNS Zone Transfer/zonetransfer.txt -c "dnsenum -t 10 --nocolor --file nobruteforce.txt $cudomain"
        wait
else
	echo "LDAP service not discovered. Anonymous enumeration and RDP to DC will also be skipped..."
fi
echo ""

# Save checkpoint after zone transfer
save_checkpoint "ZONE_TRANSFER"

else
    echo "[SKIP] Skipping Zone Transfer (already completed)"
fi

# ============= CHECKPOINT: ANON_ENUM =============
if ! should_skip_section "ANON_ENUM" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Anonymous Enumeration ==="
    echo "=========================================="
    echo ""

#Anonymous Enumeration
if [ "$ldap" == true ]; then
	echo "Trying anonymous enumeration..."
	while read IP; do
		# Remove port if it exists (e.g., converts 192.168.1.1:445 to 192.168.1.1)
		IP=$(echo "$IP" | cut -d: -f1)

		echo "Running Anonymous Enumeration on $IP"
		nmap -Pn -T4 -sS -p139,445 --script=smb-enum-users "$IP"
		bash -c "echo 'enumdomusers' | rpcclient $IP -U%"
		bash -c "echo 'enumdomusers' | rpcclient $IP -U%" | cut -d[ -f2 | cut -d] -f1 > "$ISA_BASE_DIR/Scans/Vulnerability/$IP-users.txt"
		echo "Completed for IP: $IP"
		echo "-----------------------------------"
	done < $ISA_BASE_DIR/Scans/Vulnerability/DC_IPs.txt
fi

# Save checkpoint after anon enum
save_checkpoint "ANON_ENUM"

else
    echo "[SKIP] Skipping Anonymous Enumeration (already completed)"
fi

# ============= CHECKPOINT: METASPLOIT =============
if ! should_skip_section "METASPLOIT" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Metasploit Vulnerability Tests ==="
    echo "=========================================="
    echo ""

#Anonymous FTP, Bluekeep, Eternal Blue, and Cipher Zero testing using Josh's armitage script.
echo "Running metasploit for anonymous FTP, bluekeep, eternal blue, and cipher zero..."
service postgresql start
wait
echo "Running MetaSploit to test for anonymous ftp, bluekeep, eternal blue, and cipher zero..."
echo '---Anonymous FTP---' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
msfconsole -q -x 'use auxiliary/scanner/ftp/anonymous; set RHOSTS "file://$ISA_BASE_DIR/Scans/Network/network.txt"; set THREADS 24; run; exit' 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt

echo '---BlueKeep---' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
msfconsole -q -x 'use auxiliary/scanner/rdp/cve_2019_0708_bluekeep; set RHOSTS "file://$ISA_BASE_DIR/Scans/Network/network.txt"; set THREADS 24; run; exit' 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '---Eternal Blue---' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
msfconsole -q -x 'use auxiliary/scanner/smb/smb_ms17_010; set RHOSTS "file://$ISA_BASE_DIR/Scans/Network/network.txt"; set THREADS 24; run; exit' 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '---Cipher Zero---' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
msfconsole -q -x 'use auxiliary/scanner/ipmi/ipmi_cipher_zero; set RHOSTS "file://$ISA_BASE_DIR/Scans/Network/network.txt"; set THREADS 24; run; exit' 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo '---Successful---' |  tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
grep '[+]' $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt | tee -a $ISA_BASE_DIR/Scans/Armitage/metasploit_logs.txt
echo ""

# Save checkpoint after metasploit
save_checkpoint "METASPLOIT"

else
    echo "[SKIP] Skipping Metasploit Tests (already completed)"
fi

# ============= CHECKPOINT: SHARES_SNMP =============
if ! should_skip_section "SHARES_SNMP" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: SMB Shares and SNMP Enumeration ==="
    echo "=========================================="
    echo ""

#Shares and SNMP
echo '---SMB Enumeration---' | tee -a $ISA_BASE_DIR/Scans/ShareScan/shares.txt
msfconsole -q -x 'use auxiliary/scanner/smb/smb_enumshares; set RHOSTS "file://$ISA_BASE_DIR/Scans/Network/network.txt"; set THREADS 24; run; exit' 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Scans/ShareScan/shares.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/ShareScan/shares.txt
echo '---Successful---' |  tee -a $ISA_BASE_DIR/Scans/ShareScan/shares.txt
grep '[+]' $ISA_BASE_DIR/Scans/ShareScan/shares.txt | tee -a $ISA_BASE_DIR/Scans/ShareScan/shares.txt
echo ""
echo '---SNMP Enumeration Public---' | tee -a $ISA_BASE_DIR/Scans/SNMP/snmp.txt
msfconsole -q -x 'use auxiliary/scanner/snmp/snmp_enum; set RHOSTS "file://$ISA_BASE_DIR/Scans/Network/network.txt"; set COMMUNITY public; set THREADS 24; run; exit' 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Scans/SNMP/snmp.txt
echo '' | tee -a $ISA_BASE_DIR/Scans/SNMP/snmp.txt
echo '---SNMP Enumeration Private---' | tee -a $ISA_BASE_DIR/Scans/SNMP/snmp.txt
msfconsole -q -x 'use auxiliary/scanner/snmp/snmp_enum; set RHOSTS "file://$ISA_BASE_DIR/Scans/Network/network.txt"; set COMMUNITY private; set THREADS 24; run; exit' 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Scans/SNMP/snmp.txt
wait
echo ""

# Save checkpoint after shares/snmp
save_checkpoint "SHARES_SNMP"

else
    echo "[SKIP] Skipping Shares/SNMP (already completed)"
fi

# ============= CHECKPOINT: OS_VERSIONS =============
if ! should_skip_section "OS_VERSIONS" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: OS Version Detection ==="
    echo "=========================================="
    echo ""

#OS Versions check.
echo "Checking the OS versions using the network.txt file..."
wait
nxc smb $ISA_BASE_DIR/Scans/Network/network.txt | tee -a $ISA_BASE_DIR/Scans/Versions/versions.txt
wait
echo ""
echo ""

# Save checkpoint after OS versions
save_checkpoint "OS_VERSIONS"

else
    echo "[SKIP] Skipping OS Versions (already completed)"
fi

# ============= CHECKPOINT: SQL =============
if ! should_skip_section "SQL" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: SQL Server Testing ==="
    echo "=========================================="
    echo ""

#SQLPing using metasploit
echo "Running SQL IPs with MetaSploit..."
/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service ms-sql-s | sed 's/:.*//' > $ISA_BASE_DIR/Scans/SQLping/SQL_IPs.txt
wait
if [ -s $ISA_BASE_DIR/Scans/SQLping/SQL_IPs.txt ]; then
	echo '---SQLPing---' | tee -a $ISA_BASE_DIR/Scans/SQLping/sqlping_logs.txt
	msfconsole -q -x 'use auxiliary/scanner/mssql/mssql_ping; set RHOSTS "file://$ISA_BASE_DIR/Scans/SQLping/SQL_IPs.txt"; set THREADS 24; run; exit' 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Scans/SQLping/sqlping_logs.txt
	echo '' | tee -a $ISA_BASE_DIR/Scans/SQLping/sqlping_logs.txt
	echo '---Possibly Successful---' |  tee -a $ISA_BASE_DIR/Scans/SQLping/sqlping_logs.txt
	grep '[+]' $ISA_BASE_DIR/Scans/SQLping/sqlping_logs.txt | tee -a $ISA_BASE_DIR/Scans/SQLping/sqlping_logs.txt
	wait
else
	echo "Ms-sql-s service not discovered..."
fi
echo ""
echo ""
wait

# Save checkpoint after SQL
save_checkpoint "SQL"

else
    echo "[SKIP] Skipping SQL Testing (already completed)"
fi

# ============= CHECKPOINT: TELNET =============
if ! should_skip_section "TELNET" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Telnet Service Testing ==="
    echo "=========================================="
    echo ""

#Telnets
echo "Testing Telnet connections with MetaSploit..."
/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service telnet > $ISA_BASE_DIR/Screenshots/telnet/telnet_IPs.txt
wait
if [ -s $ISA_BASE_DIR/Screenshots/telnet/telnet_IPs.txt ]; then
	echo '---Telnets---' | tee -a $ISA_BASE_DIR/Screenshots/telnet/telnet_logs.txt
	while IFS=: read -r ip port; do
		if [[ -n "$ip" && -n "$port" ]]; then
			msfconsole -q -x "use auxiliary/scanner/telnet/telnet_version; set RHOSTS $ip; set RPORT $port; set THREADS 24; run; exit" 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | tee -a $ISA_BASE_DIR/Screenshots/telnet/telnet_logs.txt
		fi
	done < $ISA_BASE_DIR/Screenshots/telnet/telnet_IPs.txt
	echo '' | tee -a $ISA_BASE_DIR/Screenshots/telnet/telnet_logs.txt
	echo '---Successful---' |  tee -a $ISA_BASE_DIR/Screenshots/telnet/telnet_logs.txt
	grep '[+]' $ISA_BASE_DIR/Screenshots/telnet/telnet_logs.txt | tee -a $ISA_BASE_DIR/Screenshots/telnet/telnet_logs.txt
	wait
else
	echo "Telnet service not discovered..."
fi
echo ""
echo ""
wait

# Save checkpoint after telnet
save_checkpoint "TELNET"

else
    echo "[SKIP] Skipping Telnet Testing (already completed)"
fi

# ============= CHECKPOINT: SMTP =============
if ! should_skip_section "SMTP" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: SMTP Relay Testing ==="
    echo "=========================================="
    echo ""

#Anonymous SMTP Relay
echo "Checking for active SMTP service..."
/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service smtp | sed 's/:.*//' | sort | uniq > $ISA_BASE_DIR/Screenshots/SMTP Relay/SMTP_IPs.txt
if [ -s $ISA_BASE_DIR/Screenshots/SMTP Relay/SMTP_IPs.txt ]; then
	echo "Anonymous SMTP Relay will be tested on these IP addresses:"
	cat $ISA_BASE_DIR/Screenshots/SMTP Relay/SMTP_IPs.txt
	while read smtp; do
		swaks -f $cuemail -t $cgemail -s $smtp --body "Hello Please Contact CastleGarde - SMTP Exploit" | tee -a $ISA_BASE_DIR/Screenshots/SMTP Relay/smtprelay.txt
		echo ""
		wait
	done < $ISA_BASE_DIR/Screenshots/SMTP Relay/SMTP_IPs.txt
else
	echo "SMTP Service not discovered. No further SMTP testing required."
fi
echo ""
echo ""

# Save checkpoint after SMTP
save_checkpoint "SMTP"

else
    echo "[SKIP] Skipping SMTP Testing (already completed)"
fi

# ============= CHECKPOINT: OUTBOUND =============
if ! should_skip_section "OUTBOUND" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Outbound Connection Testing ==="
    echo "=========================================="
    echo ""

# Testing Outbound Connections
ssh_destination="root@sdf.org"
ftp_server="speedtest.tele2.net"
screenshot_dir="$ISA_BASE_DIR/outbound"
mkdir -p "$screenshot_dir"

### SSH Test ###
echo "Testing SSH connection to $ssh_destination..."
ssh_terminal_pid=$(open_gnome_terminal "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $ssh_destination || echo 'SSH connection failed. Check credentials or network.'; sleep 5; bash")

# Wait for the SSH terminal to open
sleep 10

# Take a screenshot of the SSH session
ssh_screenshot="$screenshot_dir/ssh_test.png"
gnome-screenshot -w -f "$ssh_screenshot"
if [ $? -eq 0 ]; then
	echo "SSH session screenshot saved to: $ssh_screenshot"
else
	log_error_and_exit "Failed to capture SSH session screenshot."
fi

### FTP Test ###
echo "Testing FTP connection to $ftp_server..."
ftp_terminal_pid=$(open_gnome_terminal "ftp $ftp_server || echo 'FTP connection failed. Check server availability.'; sleep 5; bash")

# Wait for the FTP terminal to open
sleep 10

# Take a screenshot of the FTP session
ftp_screenshot="$screenshot_dir/ftp_test.png"
gnome-screenshot -w -f "$ftp_screenshot"
if [ $? -eq 0 ]; then
	echo "FTP connection screenshot saved to: $ftp_screenshot"
else
	log_error_and_exit "Failed to capture FTP connection screenshot."
fi

### RDP Test ###
TEMP_DIR="$ISA_BASE_DIR/Screenshots/Outbound Connections/rdp_screenshots"
mkdir -p "$TEMP_DIR"

# Get the screen resolution (for full screen)
SCREEN_GEOMETRY=$(xdotool getdisplaygeometry)

# Start recording video immediately after the gnome-terminal opens
VIDEO_FILE="$TEMP_DIR/rdp_video.mp4"
echo "Starting full-screen screen recording for 15 seconds..."

# Record the full screen for 15 seconds using ffmpeg
# The -f x11grab ensures that we're capturing from the X11 server
# The -video_size option captures the entire screen, and the -i specifies the screen to capture from
ffmpeg -f x11grab -video_size "$SCREEN_GEOMETRY" -i :0.0 -t 15 -vcodec libx264 "$VIDEO_FILE" &
RECORD_PID=$!

echo "Starting RDP session..."
# Open the gnome-terminal running xfreerdp and store its PID
rdp_terminal_pid=$(open_gnome_terminal 'xfreerdp /v:54.220.223.143 /u:SimCloudTest /p:SimTest!PSWD; echo "RDP session ended."; bash')
# Wait for the video recording to finish
wait $RECORD_PID

# Check if the video was successfully created
if [ -f "$VIDEO_FILE" ]; then
	echo "Video recorded and saved to: $VIDEO_FILE"
else
	echo "[ERROR] Failed to record video."
fi
echo "RDP session video recording completed."
sleep 5

### RDP to DC ###
if [ "$ldap" == true ]; then
	IP_FILE="$ISA_BASE_DIR/Scans/Vulnerability/DC_IPs.txt"
	TEMP_DIR1="$ISA_BASE_DIR/DC_RDP"
	mkdir -p "$TEMP_DIR1"
	while read -r LINE; do
		if [[ -z "$LINE" || "$LINE" == \#* ]]; then
			continue
		fi
		IP="${LINE%%:*}"
		echo "Starting RDP session for IP: $IP"
		rdp_terminal_pid=$(open_gnome_terminal "xfreerdp /v:'$IP'; echo ''; bash")

		# Wait for the RDP session to start
		sleep 20

		# Capture RDP session screenshots
		cert_screenshot="$TEMP_DIR1/${IP}_certificate_screenshot.png"
		gnome-screenshot -w -f "$cert_screenshot"
		echo "Certificate screenshot saved: $cert_screenshot"
		echo "Session for IP: $IP finished."
	done < "$IP_FILE"
fi

echo "All tests completed. Screenshots saved in respective directories."

# Save checkpoint after outbound tests
save_checkpoint "OUTBOUND"

else
    echo "[SKIP] Skipping Outbound Testing (already completed)"
fi

# ============= CHECKPOINT: WEBFILTER =============
if ! should_skip_section "WEBFILTER" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Web Filtering Tests ==="
    echo "=========================================="
    echo ""

#Web Filtering.
echo "Running unauthenticated web filtering tests using these URLs with Gowitness:"
echo "http://www.hidester.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.hidemyass.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.soldierx.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.2600.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.exploit-db.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.thepiratebay.org" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.passthepopcorn.me" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.facebook.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.instagram.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.playboy.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.dropbox.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.pastebin.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.chatroulette.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.hangouts.google.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.hotmail.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.gmail.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "http://www.protonmail.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.hidester.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.hidemyass.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.soldierx.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.2600.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.exploit-db.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.thepiratebay.org" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.passthepopcorn.me" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.facebook.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.instagram.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.playboy.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.dropbox.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.pastebin.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.chatroulette.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.hangouts.google.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.hotmail.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.gmail.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
echo "https://www.protonmail.com" | tee -a $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt
wait
gowitness scan file -f $ISA_BASE_DIR/Screenshots/WebFiltering/websites.txt --screenshot-path $ISA_BASE_DIR/Screenshots/WebFiltering/webfiltering --delay 50 --timeout 70
echo "Double check screenshots..."
wait
echo ""
echo ""

# Save checkpoint after web filtering
save_checkpoint "WEBFILTER"

else
    echo "[SKIP] Skipping Web Filtering (already completed)"
fi

# ============= CHECKPOINT: GOWITNESS =============
if ! should_skip_section "GOWITNESS" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Gowitness Web Screenshots ==="
    echo "=========================================="
    echo ""

#Pause point if user defined the pause variable as 'yes'
if [ $pause == 'yes' ]; then
	echo "Gowitness on the network is next..."
	pause_for_continue
	echo "Continuing with Gowitness..."
fi

#Gowitness and defaulthttploginhunter scans for default passwords
echo "Running Gowitness for manual checking of default passwords and defaulthttploginhunter for auto checking of default passwords. This may take a while..."
echo ""
cd $ISA_BASE_DIR/gowitness
wait
gowitness scan nmap -f $ISA_BASE_DIR/Scans/Nmap/nmap.xml --open-only --service-contains http --write-db --screenshot-path $ISA_BASE_DIR/Screenshots/Default Passwords/screenshots
wait
cd /root
echo ""

# Save checkpoint after gowitness
save_checkpoint "GOWITNESS"

else
    echo "[SKIP] Skipping Gowitness (already completed)"
fi

# ============= CHECKPOINT: DEFAULTHTTP =============
if ! should_skip_section "DEFAULTHTTP" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Default HTTP Credentials Testing ==="
    echo "=========================================="
    echo ""

#Pause point if user defined the pause variable as 'yes'
if [ $pause == 'yes' ]; then
	echo "Defaulthttploginhunter is next..."
	pause_for_continue
	echo "Continuing with defaulthttploginhunter..."
fi
echo ""
all_checks_passed=true

# Strict connectivity tests
for check in \
  "nslookup github.com" \
  "ping -c 3 github.com" \
  "curl -sSf --tlsv1.2 --cacert /etc/ssl/certs/ca-certificates.crt https://github.com -o /dev/null" \
  "curl -sSf --tlsv1.2 --cacert /etc/ssl/certs/ca-certificates.crt https://raw.githubusercontent.com -o /dev/null"
do
    echo "Running: $check"
    if ! eval "$check" &>/dev/null; then
        echo "❌ Github connectivity test failed: $check"
        echo "⚠️  Running with database last updated on $lastupdate..."
        all_checks_passed=false
        break
    fi
    sleep 3
done


if $all_checks_passed; then
    echo "All checks passed. Updating password database..."
    /root/tools/default-http-login-hunter/default-http-login-hunter.sh update
fi

echo "Running defaulthttploginhunter on these IPs and ports: "
/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service http > $ISA_BASE_DIR/Screenshots/Default Passwords/parsed_xml.txt | cat
wait
echo ""
/root/tools/default-http-login-hunter/default-http-login-hunter.sh $ISA_BASE_DIR/Screenshots/Default Passwords/parsed_xml.txt | tee -a $ISA_BASE_DIR/Screenshots/Default Passwords/defaulthttp.txt
wait
echo "" | tee -a $ISA_BASE_DIR/Screenshots/Default Passwords/defaulthttp.txt
echo "---Successful Logins---" | tee -a $ISA_BASE_DIR/Screenshots/Default Passwords/defaulthttp.txt
grep -B 2 -P '_    (?!\(no)' $ISA_BASE_DIR/Screenshots/Default Passwords/defaulthttp.txt | tee -a $ISA_BASE_DIR/Screenshots/Default Passwords/defaulthttp.txt
wait
echo ""

# Save checkpoint after defaulthttp
save_checkpoint "DEFAULTHTTP"

else
    echo "[SKIP] Skipping Default HTTP Testing (already completed)"
fi

# ============= CHECKPOINT: ISP =============
if ! should_skip_section "ISP" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: ISP Information Gathering ==="
    echo "=========================================="
    echo ""

#ISP
echo "Checking Internet Service Provider."
gowitness scan single -u https://www.whatismyisp.com/ --screenshot-path $ISA_BASE_DIR/isp/isp
wait
echo ""

# Save checkpoint after ISP
save_checkpoint "ISP"

else
    echo "[SKIP] Skipping ISP Check (already completed)"
fi

# ============= CHECKPOINT: GOWITNESS_SERVER =============
if ! should_skip_section "GOWITNESS_SERVER" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: Gowitness Server Startup ==="
    echo "=========================================="
    echo ""

#Starts the Gowitness server
echo "Starting the Gowitness server..."
sleep 2
gnome-terminal --geometry=200x45 -- bash -c 'gowitness report server --db-uri "sqlite://$ISA_BASE_DIR/Screenshots/Default Passwords/gowitness.sqlite3" --screenshot-path $ISA_BASE_DIR/Screenshots/Default Passwords/screenshots/; echo''; bash' & disown
wait
firefox 127.0.0.1:7171 & disown

# Save checkpoint after gowitness server
save_checkpoint "GOWITNESS_SERVER"

else
    echo "[SKIP] Skipping Gowitness Server (already started)"
fi

# ============= CHECKPOINT: NETAUDIT_PREP =============
if ! should_skip_section "NETAUDIT_PREP" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: NetAudit Preparation ==="
    echo "=========================================="
    echo ""

#Removes printer IP addresses and then condenses down to 300 to autostart netaudit.
/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service printer | sed 's/:.*//' > $ISA_BASE_DIR/duplicateprinter_IPs.txt
cat $ISA_BASE_DIR/Scans/Network/network.txt | tee -a $ISA_BASE_DIR/duplicateprinter_IPs.txt
sort $ISA_BASE_DIR/duplicateprinter_IPs.txt | uniq > $ISA_BASE_DIR/printers_removed_for_netaudit.txt
echo ""
echo "Condensing IP list down to 300 IPs..."
input_file1="$ISA_BASE_DIR/printers_removed_for_netaudit.txt"
output_file1="$ISA_BASE_DIR/netauditIPsdraft.txt"
ip_count=$(wc -l < "$input_file1")
if [ "$ip_count" -gt 300 ]; then
	shuf "$input_file1" | head -n 300 > "$output_file1"
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service ldap | tee -a $output_file1
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service ms-sql-s | tee -a $output_file1
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service mysql | tee -a $output_file1
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service smtp | tee -a $output_file1
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service upnp | tee -a $output_file1
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service postgresql | tee -a $output_file1
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service IIS | tee -a $output_file1
	/root/tools/nmap-parse-output/nmap-parse-output $ISA_BASE_DIR/Scans/Nmap/nmap.xml service NFD-or-IIS | tee -a $output_file1
	wait
	sort $output_file1 | uniq > $ISA_BASE_DIR/naIPs.txt
	sed 's/:[0-9]\+$//' $ISA_BASE_DIR/naIPs.txt | sort | uniq > $ISA_BASE_DIR/naIPsFinal.txt
	echo "File trimmed to 300 IP addresses. Added high profile IPs with nmap-parse-output and saved to $ISA_BASE_DIR/naIPsFinal.txt"
else
	cp "$input_file1" "$ISA_BASE_DIR/naIPsFinal.txt"
	echo "The file was less than 300 IPs before adding high profile IPs. No removal was necessary."
fi
wait
echo ""

# Save config and checkpoint after netaudit prep
save_config
save_checkpoint "NETAUDIT_PREP"

else
    echo "[SKIP] Skipping NetAudit Prep (already completed)"
fi

# ============= CHECKPOINT: NETAUDIT =============
if ! should_skip_section "NETAUDIT" "$RESUME_FROM"; then
    echo ""
    echo "=========================================="
    echo "=== Starting: NetAudit Execution ==="
    echo "=========================================="
    echo ""

case "${dhcp_answer,,}" in
    y)
        while true; do
            read -p "Please enter the IP address of the netaudit machine: " ip_addressna
            if ! is_valid_ip "$ip_addressna"; then
                echo "Invalid IP address format. Please enter a valid IPv4 address."
                continue
            fi

            read -p "You entered IP '$ip_addressna'. Is this correct? (y/n): " confirm_ip
            case "${confirm_ip,,}" in
                y)
                    echo "IP address confirmed: $ip_addressna"
                    break
                    ;;
                n)
                    echo "Let's try entering the IP again."
                    ;;
                *)
                    echo "Please answer with 'y' or 'n'."
                    ;;
            esac
        done
        ;;
    n)
        echo "You are on static IP. Script will finish without running netaudit automatically."
        echo 'If you need to start the GoWitness server again, use this command:'
        echo 'gowitness report server --db-uri "sqlite://$ISA_BASE_DIR/Screenshots/Default Passwords/gowitness.sqlite3" --screenshot-path $ISA_BASE_DIR/Screenshots/Default Passwords/screenshots/'
        echo "Then open firefox and browse to 127.0.0.1:7171"
	if [ "$filecopy" == "y" ]; then
		echo 'Copying ISA files to host...'
		cp -r $ISA_BASE_DIR/ "/media/sf_Kali_Scans/$cudomain"
		echo 'Files copied to host.'
	else
		echo 'WARNING: A shared folder was not setup. Skipping file copy.'
	fi
	echo ""
	echo "Navigate to $ISA_BASE_DIR/naIPsFinal.txt for the IP addresses to use for netaudit."
        exit 0
        ;;

esac


echo "Starting NetAudit"
input_file2="$ISA_BASE_DIR/naIPsFinal.txt"
output_file2="$ISA_BASE_DIR/ips_formatted_for_netaudit_autostart.txt"
wait
tr '\n' '\ ' < "$input_file2" > "$output_file2"
wait


curl -X POST http://$ip_addressna:5000/na/newScan \
-H "Content-Type: application/json;charset=UTF-8" \
-d "{\"parameter\":\"Normal\",\"tag4\":\"$netaudit_text\",\"title\":\"$cudomain\",\"targets\":\"$(cat "$output_file2")\"}" \
> $ISA_BASE_DIR/netaudit_post_request.txt


wait
sleep 5
idnumber=$(grep -o '"id":[0-9]\+' $ISA_BASE_DIR/netaudit_post_request.txt | sed 's/"id"://')
curl http://$ip_addressna:5000/na/startScan/$idnumber
echo ""
echo "NetAudit should have started. Firefox is opening to check..."
echo ""
firefox http://$ip_addressna:5000 & disown
echo 'If you need to start the GoWitness server again, use this command:   gowitness report server --db-uri "sqlite://$ISA_BASE_DIR/Screenshots/Default Passwords/gowitness.sqlite3" --screenshot-path $ISA_BASE_DIR/Screenshots/Default Passwords/screenshots/'
echo "Then open firefox and browse to  127.0.0.1:7171"
echo ""


#Netaudit Auto Download

# Export variables so they can be used in the GNOME terminal
export idnumber
export cudomain
export ip_addressna
export filecopy

# Start the GNOME terminal with the inline script
gnome-terminal -- bash -c "
# Directory to store temporary files
output_dir=\"$ISA_BASE_DIR/netaudit\"
mkdir -p \"\$output_dir\"
rendered_html_file=\"\$output_dir/webpage2.txt\"
temp_script=\"temp_puppeteer_script.js\"

# Ensure cleanup of temp file on script exit
trap 'rm -f \"\$temp_script\"' EXIT

# Function to fetch rendered HTML using Puppeteer
echo \"DO NOT CLOSE THIS WINDOW UNTIL FINISHED. Fetching rendered Netaudit HTML from http://\$ip_addressna:5000 to monitor progress. Checks every 10 seconds...\"
cat << EOF > \"\$temp_script\"
const puppeteer = require('puppeteer');

(async () => {
  try {
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();
    await page.goto('http://\$ip_addressna:5000');  // Fetch the remote webpage
    const html = await page.content();              // Get rendered HTML
    console.log(html);                              // Output to console
    await browser.close();
  } catch (error) {
    console.error(\"Error fetching rendered HTML:\", error);
    process.exit(1);
  }
})();
EOF

# Fetch the rendered HTML and store it in a file
if ! node \"\$temp_script\" > \"\$rendered_html_file\"; then
  echo \"Failed to fetch rendered HTML. Retrying...\"
  sleep 10
fi

# Ensure the HTML file is not empty
if [ ! -s \"\$rendered_html_file\" ]; then
  echo \"Error: \$rendered_html_file is empty or does not exist.\"
fi

# Monitor for an increase of exactly 1 in the number of \"Done, click me to load results\"
previous_count=0
while true; do
  # Re-fetch rendered HTML
  if ! node \"\$temp_script\" > \"\$rendered_html_file\"; then
    echo \"Failed to fetch rendered HTML. Retrying...\"
    sleep 10
    continue
  fi

  # Ensure the rendered HTML file exists and is non-empty before using grep
  if [ ! -s \"\$rendered_html_file\" ]; then
    echo \"Error: HTML file is empty or missing.\"
    sleep 10
    continue
  fi

  # Count how many instances of 'Done, click me to load results' are present in the HTML
  current_count=\$(grep -o 'Done, click me to load results' \"\$rendered_html_file\" | wc -l)

  # If the count has increased by exactly 1, a new instance has been added
  if [ \"\$current_count\" -eq \$((previous_count + 1)) ]; then
    echo \"New instance of 'Done, click me to load results' found! Total count: \$current_count\"
    break  # Exit the loop when the count increases by exactly 1
  fi

  # Update the previous count
  previous_count=\"\$current_count\"

  sleep 10  # Check every 10 seconds
done

# Run the wget command if the count has increased by 1 (i.e., the monitoring has finished)
echo 'Count increased by 1, Downloading netaudit report...'
sleep 10
wget --header=\"User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36\" \
     --header=\"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8\" \
     --header=\"Accept-Language: en-US,en;q=0.5\" \
     --header=\"Accept-Encoding: gzip, deflate, br\" \
     --header=\"Referer: http://\$ip_addressna:5000/\" \
     --header=\"Upgrade-Insecure-Requests: 1\" \
     --header=\"Sec-Fetch-Dest: document\" \
     --header=\"Sec-Fetch-Mode: navigate\" \
     --header=\"Sec-Fetch-Site: same-origin\" \
     --header=\"Sec-Fetch-User: ?1\" \
     --header=\"Connection: keep-alive\" \
     -O \"$ISA_BASE_DIR/netaudit/\$cudomain.csv\" \
     \"http://\$ip_addressna:5000/na/generateCsvReport/\$idnumber\"

echo ''
if [ \"\$filecopy\" == \"y\" ]; then
  echo 'Copying ISA files to host...'
  cp -r $ISA_BASE_DIR/ \"/media/sf_Kali_Scans/\$cudomain\"
  echo 'Files copied to host.'
else
  echo 'WARNING: A shared folder was not setup. Skipping file copy.'
fi
echo 'FINISHED'; echo ''; bash"


wait
echo "Script should have continued with netaudit in another terminal."
echo ""
echo "------------------------------------------------------------------------------------------------"
echo 'DO NOT DELETE ANY SCANS FROM THE NETAUDIT INTERFACE UNTIL THE NETAUDIT SCAN HAS COMPLETED!!!!!!!'
echo "------------------------------------------------------------------------------------------------"

# Save final checkpoint
save_checkpoint "NETAUDIT"
echo ""
echo "[SUCCESS] All checkpoints completed!"
echo "[INFO] To start fresh next time, delete: $CHECKPOINT_FILE and $CONFIG_FILE"

else
    echo "[SKIP] Skipping NetAudit (already completed)"
    echo "[INFO] All sections have been completed!"
fi

exit
