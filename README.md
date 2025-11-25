# ISA Automation Script

## Overview

The ISA (Internal Security Assessment) Automation Script is a comprehensive bash script designed for Kali Linux to automate security assessments. This script streamlines the process of network discovery, vulnerability scanning, and security testing for internal network environments.

**Version:** 2.5

## Features

### Network Discovery & Enumeration
- Automated ping sweeps across multiple private IP ranges (10.x.x.x, 172.16-31.x.x, 192.168.x.x)
- Custom subnet scanning with IP exclusion capabilities
- Automated responder for credential capture
- NetAudit integration for comprehensive network analysis

### Vulnerability Scanning
- **Nmap**: Full service detection and OS fingerprinting
- **Metasploit Modules**:
  - Anonymous FTP detection
  - BlueKeep (CVE-2019-0708) vulnerability testing
  - EternalBlue (MS17-010) detection
  - Cipher Zero IPMI vulnerability testing
- **SQL Testing**: MS SQL Server discovery and ping testing
- **Telnet Enumeration**: Service detection and version checking

### Security Testing
- DNS zone transfer attempts
- Anonymous LDAP/SMB enumeration
- Anonymous SMTP relay testing
- SMB share enumeration
- SNMP enumeration (public/private communities)
- Default HTTP login testing
- Web filtering validation

### Documentation & Reporting
- Automated screenshot capture with Gowitness
- Organized folder structure for all findings
- RDP session recording and screenshots
- ISP detection
- Outbound connection testing (SSH, FTP, RDP)
- NetAudit CSV report generation

## Prerequisites

### Required Tools
The following tools must be installed on your Kali Linux system:

- **Core Tools**: figlet, nmap, zenmap, ipscan
- **Metasploit Framework**: msfconsole, postgresql
- **Network Tools**: responder, dnsenum, rpcclient, swaks
- **Screenshot Tools**: gowitness, gnome-screenshot, ffmpeg, xdotool
- **Utilities**: mousepad, firefox, xfreerdp, puppeteer (Node.js)
- **Additional**: nmap-parse-output, default-http-login-hunter, NetCracker (nxc)

### Installation Paths
Ensure the following tools are installed in `/root/tools/`:
- `nmap-parse-output`
- `default-http-login-hunter`

### System Requirements
- **OS**: Kali Linux (with GNOME desktop environment)
- **Permissions**: Must be run as root
- **Network Interface**: eth0 (configurable in script)
- **Optional**: VirtualBox shared folder named "Kali_Scans" for automatic file copying

## Configuration

### Script Variables
Edit these variables at the top of the script to customize behavior:

```bash
# Enable pause points between major operations
pause=no  # Change to 'yes' to enable manual pauses

# Enable automatic file copying to Windows host via shared folder
filecopy=y  # Change to 'n' to disable
```

### Network Configuration
The script will prompt for:
- DHCP or static IP configuration
- Windows machine IP address (for exclusions)
- Credit union email address (for SMTP testing)
- CastleGarde email address (for SMTP testing)
- Optional IP exclusions
- Optional additional subnet ranges

## Usage

### Basic Execution

1. Make the script executable:
```bash
chmod +x isa.sh
```

2. Run as root:
```bash
sudo ./isa.sh
```

### Interactive Prompts

The script will guide you through configuration with prompts for:

1. **DHCP Status**: Whether you're on DHCP (y/n)
2. **NetAudit Duration**: How long to run NetAudit (15 min to "Until Finished")
3. **IP Addresses**: Windows IP, emails for SMTP testing
4. **Scan Options**: Skip ping sweeps or nmap (99% of time answer 'n')
5. **IP Exclusions**: IPs to exclude from scanning
6. **Additional Subnets**: Custom IP ranges to scan

### Output Structure

All results are saved to `/root/Desktop/ISA/` with the following structure:

```
/root/Desktop/ISA/
├── network/           # Ping sweep results and network.txt
├── nmap/              # Nmap XML output
├── zonetransfer/      # DNS zone transfer attempts
├── anonymousenum/     # Anonymous enumeration results
├── armitage/          # Metasploit module outputs
├── versions/          # OS version detection
├── sql/               # SQL server enumeration
├── telnets/           # Telnet service detection
├── smtprelay/         # SMTP relay testing results
├── webfiltering/      # Web filtering test screenshots
├── gowitness/         # HTTP service screenshots and database
├── isp/               # ISP detection
├── netaudit/          # NetAudit reports
├── outbound/          # Outbound connection tests
├── snmp/              # SNMP enumeration
├── shares/            # SMB share enumeration
└── DC_RDP/            # Domain Controller RDP screenshots
```

## Important Notes

### Security Considerations

⚠️ **AUTHORIZED USE ONLY**: This script performs active security testing and should only be used on networks where you have explicit authorization. Unauthorized use may be illegal.

### Best Practices

1. **Backup Previous Scans**: The script automatically moves old ISA folders to ISAold
2. **Review network.txt**: Always review the generated network.txt before nmap scanning
3. **IP Exclusions**: Exclude critical infrastructure (like your Kali VM, Windows host, etc.)
4. **NetAudit Monitoring**: Do NOT delete scans from NetAudit interface until completion
5. **Shared Folder**: Setup VirtualBox shared folder for automatic file copying to host

### Known Issues

- Cursor hovering over taskbar during ping sweeps may cause issues
- GitHub connectivity required for default-http-login-hunter database updates
- RDP testing includes hardcoded test server (54.220.223.143) - modify as needed

### Pause Points

If `pause=yes` is set, the script will pause at key points:
- Before nmap scanning
- Before zone transfer/enumeration tests
- Before Gowitness network scanning
- Before default login hunter

Type 'c' to continue when paused.

## Advanced Features

### Skip Options

The script allows skipping major operations (use with caution):

- **Skip Ping Sweeps**: Manually create network.txt file
- **Skip Nmap**: Use existing nmap.xml file from previous scan

### NetAudit Integration

For DHCP environments, the script can automatically:
1. Select high-priority IPs (domain controllers, SQL servers, etc.)
2. Add 300 random IPs from the network
3. Start NetAudit scan via API
4. Monitor completion and auto-download CSV report

### File Copying

With `filecopy=y` and a VirtualBox shared folder:
- All ISA results are automatically copied to `/media/sf_Kali_Scans/[domain]/`
- Requires shared folder named "Kali_Scans"

## Troubleshooting

### Script Won't Run
- Verify running as root: `sudo ./isa.sh`
- Check permissions: `chmod +x isa.sh`

### Tools Not Found
- Install missing tools via apt: `sudo apt install [tool-name]`
- Verify paths in script match your installation

### Network Discovery Issues
- Verify eth0 is correct interface: `ip addr`
- Check network connectivity: `ping -c 3 8.8.8.8`

### NetAudit Fails
- Verify NetAudit machine IP is correct
- Check NetAudit service is running on port 5000
- Ensure network connectivity between Kali and NetAudit machine

## Version History

- **v2.5** (Current): Full automation with NetAudit integration
  - Added automated NetAudit scanning and report download
  - Enhanced RDP testing with video recording
  - Improved IP validation and exclusion handling
  - Added outbound connection testing

## Support

For issues or questions:
- Review the script output for error messages
- Check `/root/Desktop/ISA/` folders for detailed logs
- Verify all prerequisites are installed

## License

This script is provided as-is for authorized security assessment purposes only.

## Disclaimer

This tool is intended for legal, authorized security assessments only. Users are responsible for ensuring they have proper authorization before scanning any network. The authors assume no liability for misuse or damage caused by this script.
