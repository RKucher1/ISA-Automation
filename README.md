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

Run the script as root:

```bash
sudo ./isa-automation.sh
```

The script will interactively prompt you for:
- DHCP/Static IP configuration
- Windows machine IP address
- Email addresses for SMTP testing
- IP exclusion preferences
- Subnet ranges to scan
- Various scanning options

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
