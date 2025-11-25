# ISA-Automation

A comprehensive Bash script for automating Information Security Assessment (ISA) tasks on Kali Linux.

## Overview

This script automates the process of conducting information security assessments by orchestrating multiple security testing tools and generating organized reports. It's designed for authorized penetration testing, security audits, and vulnerability assessments.

## Features

- **Network Discovery**: Automated ping sweeps across multiple subnet ranges
- **Vulnerability Scanning**: Comprehensive nmap scans with service version detection
- **DNS Testing**: Zone transfer attempts and DNS enumeration
- **Anonymous Enumeration**: SMB and domain user enumeration
- **Exploit Testing**: Automated checks for:
  - BlueKeep (CVE-2019-0708)
  - EternalBlue (MS17-010)
  - Anonymous FTP access
  - IPMI Cipher Zero vulnerability
- **Service Testing**:
  - SMTP relay testing
  - SQL server discovery
  - Telnet service enumeration
  - SNMP enumeration
- **Web Analysis**:
  - Web filtering verification
  - Screenshot capture with Gowitness
  - Default credential testing
- **Network Auditing**: Integration with NetAudit for comprehensive host analysis
- **Outbound Testing**: SSH, FTP, and RDP connectivity checks
- **Automated Reporting**: Organized output structure with detailed logs

## Requirements

### System Requirements
- Kali Linux (or similar penetration testing distribution)
- Root privileges
- Network connectivity

### Required Tools
- nmap / zenmap
- Responder
- ipscan (Angry IP Scanner)
- Metasploit Framework
- NetCracker (nxc)
- Gowitness
- swaks
- rpcclient
- dnsenum
- xfreerdp
- ffmpeg
- puppeteer (Node.js)
- figlet
- mousepad

### Optional
- NetAudit server (for full functionality)
- Shared folder setup for automatic file copying

## Installation

1. Clone this repository:
```bash
git clone https://github.com/RKucher1/ISA-Automation.git
cd ISA-Automation
```

2. Ensure the script is executable:
```bash
chmod +x isa-automation.sh
```

3. Verify all required tools are installed on your Kali system.

## Usage

### Standard Version

Run the script as root:

```bash
sudo ./isa-automation.sh
```

### Resume-Enabled Version (New!)

Use the checkpoint/resume version for long-running assessments:

```bash
sudo ./isa-automation-resume.sh
```

Both scripts will interactively prompt you for:
- DHCP/Static IP configuration
- Windows machine IP address
- Email addresses for SMTP testing
- IP exclusion preferences
- Subnet ranges to scan
- Various scanning options

### Checkpoint/Resume Functionality

The `isa-automation-resume.sh` script includes checkpoint functionality that allows you to:

**Resume from any point if interrupted:**
- Script saves progress after each major section
- If script is interrupted or encounters an error, simply restart it
- You'll see a menu showing completed and pending sections
- Select which checkpoint to resume from

**Import Old Network Files:**
- Speed up repeat assessments by importing previous network.txt files
- Automatically extracts unique /16 subnets from old scan results
- Converts IPs into subnet ranges for Angry IP Scanner
- Example: IPs like 10.2.45.123, 10.2.67.89, 10.3.12.45 become subnets 10.2.0.0/16, 10.3.0.0/16
- Significantly reduces manual subnet entry for repeat assessments

**Available Checkpoints:**
1. Initial Setup and User Inputs
2. Network Discovery (Ping Sweeps)
3. Nmap Vulnerability Scanning
4. DNS Zone Transfer
5. Anonymous Enumeration
6. Metasploit Vulnerability Tests
7. SMB Shares and SNMP Enumeration
8. OS Version Detection
9. SQL Server Testing
10. Telnet Service Testing
11. SMTP Relay Testing
12. Outbound Connection Testing
13. Web Filtering Tests
14. Gowitness Web Screenshots
15. Default HTTP Credentials
16. ISP Information Gathering
17. Gowitness Server Startup
18. NetAudit Preparation
19. NetAudit Execution

**Checkpoint Files:**
- State: `/root/Desktop/ISA/.checkpoint_state`
- Config: `/root/Desktop/ISA/.resume_config`

**Resume Menu Options:**
- Select 1-19 to resume from that checkpoint
- Select 0 to start fresh (deletes all checkpoints)
- Select q to quit

## Configuration

You can modify these variables at the top of the script:

- `pause`: Set to `yes` to enable pause points between major operations
- `filecopy`: Set to `y` if you have a shared folder named "Kali Scans" for automatic file transfer

## Output Structure

All results are saved to `/root/Desktop/ISA/` with the following structure:

```
ISA/
├── network/          # Network discovery results
├── nmap/            # Nmap scan outputs
├── zonetransfer/    # DNS zone transfer attempts
├── anonymousenum/   # Anonymous enumeration results
├── armitage/        # Metasploit module outputs
├── versions/        # OS version information
├── sql/             # SQL server findings
├── telnets/         # Telnet service results
├── smtprelay/       # SMTP relay test results
├── webfiltering/    # Web filtering test results
├── gowitness/       # Web screenshots and reports
├── isp/             # ISP information
├── netaudit/        # NetAudit results
├── outbound/        # Outbound connection tests
├── snmp/            # SNMP enumeration results
├── shares/          # SMB share enumeration
└── DC_RDP/          # Domain controller RDP tests
```

## Security Considerations

**IMPORTANT**: This tool is designed for authorized security testing only. You must have explicit permission to test any systems targeted by this script.

- Only use on networks and systems you have permission to test
- Ensure proper authorization documentation is in place
- Be aware of the legal implications of security testing
- Some tests may trigger security alerts or IDS/IPS systems
- Certain operations may impact network performance

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This tool is provided for educational and professional security assessment purposes only. The authors are not responsible for any misuse or damage caused by this script. Always ensure you have proper authorization before conducting security assessments.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Version

Current version: 2.5

## Acknowledgments

This script integrates and orchestrates various open-source security tools. Credit goes to the maintainers and contributors of:
- Nmap Project
- Metasploit Framework
- Gowitness
- And all other tools utilized by this script
