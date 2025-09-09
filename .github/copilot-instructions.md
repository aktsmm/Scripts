# Scripts Repository - Azure & Utility Scripts Collection

This repository contains a collection of utility scripts for Azure automation, desktop tools, and web services. Always follow these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Repository Structure

**CRITICAL: This is a script collection repository with NO BUILD SYSTEM.** Each script/project is self-contained and independent. Do not attempt to build the entire repository as a single project.

### Key Directories:
- `bash/` - Azure/Linux automation scripts (setup-squid-nginx.sh, AzCopy installers, etc.)
- `ps/` - PowerShell scripts for Azure operations (Azure CLI/PowerShell setup, VM management, etc.)
- `Python/` - Desktop automation utilities (mouse automation, screen capture, OCR)
- `node/` - Node.js web applications (client IP detection services)
- `AzPolicy/` - Azure Policy JSON definitions
- `mate/` - Documentation media files (GIFs)

## Working Effectively

### Environment Requirements
- **Node.js**: Version 18+ for Node.js applications
- **Python 3**: With pip3 for Python scripts
- **PowerShell 7**: Available at `/usr/bin/pwsh` (PowerShell 7.4.11+)
- **Bash**: For Linux automation scripts

### Testing Script Syntax
**NEVER CANCEL SYNTAX VALIDATION** - Always complete these checks:

```bash
# Test Bash script syntax (2-5 seconds)
bash -n /path/to/script.sh

# Test PowerShell script syntax (5-10 seconds)  
pwsh -Command "try { Get-Command 'script.ps1' -Syntax } catch { Write-Host 'Syntax Error:' \$_.Exception.Message }"

# Test Node.js project structure
cd /path/to/node/project && npm install && npm start
```

### Node.js Applications

**CRITICAL TIMING**: Node.js operations take 1-5 minutes. NEVER CANCEL.

```bash
# Install dependencies (30-120 seconds depending on network)
cd node/01_returnClientIP && npm install
cd node/02_returnClientIpShow && npm install

# Start applications 
cd node/01_returnClientIP && npm start  # INCOMPLETE - This is just a router module, not a full app
cd node/02_returnClientIpShow && npm start  # Starts on port 8080, shows client IP
```

**Validation Test:**
```bash
# Test the working Node.js application
cd node/02_returnClientIpShow && node bin/www &
sleep 3 && curl -s http://localhost:8080  # Should return HTML with client IP
```

**Known Issues:**
- Both Node.js projects have security vulnerabilities - run `npm audit` to see details
- These are utility/demo applications, not production services  
- First Node.js app (01_returnClientIP) is incomplete - just an Express router module
- Second app (02_returnClientIpShow) is fully functional and shows client IP addresses

### Python Scripts

**CRITICAL TIMING**: Python dependency installation takes 2-10 minutes. NEVER CANCEL.

```bash
# Install required dependencies (120-600 seconds)
pip3 install pyautogui

# Note: pyautogui installation may fail due to network timeouts
# If installation fails, document it as "pyautogui installation fails due to network limitations"
```

**Common Python Dependencies:**
- `pyautogui` - For mouse/keyboard automation (Movemouse script)
- Standard library modules for most other scripts

### PowerShell Scripts

**CRITICAL TIMING**: Azure PowerShell operations take 5-20 minutes. NEVER CANCEL.

```bash
# Test PowerShell availability
pwsh --version  # Should show PowerShell 7.4.11+

# Validate PowerShell script syntax (5-15 seconds)
pwsh -Command "
    try {
        \$scriptPath = '/path/to/script.ps1'
        \$ast = [System.Management.Automation.Language.Parser]::ParseFile(\$scriptPath, [ref]\$null, [ref]\$null)
        if (\$ast) { Write-Host 'PowerShell syntax: OK' } else { Write-Host 'PowerShell syntax: FAILED' }
    } catch { Write-Host 'PowerShell syntax error:' \$_.Exception.Message }
"
```

**Key PowerShell Scripts:**
- `ps/AzSetup-AzureTools/AzSetupAzureTools.ps1` - Azure CLI and PowerShell module installer
- `ps/AzAutoAzureDiskAttach/*.ps1` - Azure disk management automation

### Bash Scripts

**CRITICAL TIMING**: Linux setup scripts take 10-45 minutes. NEVER CANCEL.

```bash
# Validate bash syntax (1-3 seconds)
bash -n script.sh

# Key scripts require root/sudo privileges
sudo bash bash/Make_Squid_nginx_http\(s\)Srv/setup-squid-nginx.sh  # 10-20 minutes
```

**Important Bash Scripts:**
- `bash/Make_Squid_nginx_http(s)Srv/setup-squid-nginx.sh` - Sets up NGINX + Squid proxy environment
- `bash/Az_AzCopyInstaller/install_azcopy.sh` - Installs AzCopy for Linux

## Validation Requirements

**MANUAL VALIDATION REQUIREMENT**: After making changes, you MUST test actual functionality:

### Node.js Validation Scenarios
1. **Install and test the working application:**
   ```bash
   cd node/02_returnClientIpShow && npm install
   node bin/www &
   sleep 3 && curl -s http://localhost:8080
   ```
2. **Verify client IP detection functionality** - should return HTML showing "your IP address and port No. is" with IP
3. **Note:** First Node.js project is incomplete - only contains an Express router module

### Python Validation Scenarios
1. **Test dependency availability:**
   ```bash
   python3 -c "
   try:
       import pyautogui
       print('pyautogui available')
   except ImportError:
       print('pyautogui NOT available - installation required')
   "
   ```
2. **Test simple script execution:** `python3 Python/Movemouse/mousemove.py` (requires display)
3. **Note:** pyautogui installation may fail due to network timeouts - this is expected

### PowerShell Validation Scenarios
1. Test Azure PowerShell module availability
2. Validate script parameters and syntax
3. Test with `-WhatIf` flag where applicable

### Bash Validation Scenarios
1. Validate script syntax with `bash -n`
2. Check for required system packages
3. For setup scripts, verify they complete without errors in a test environment

## Common Issues and Workarounds

### Network and Installation Issues
- **pyautogui installation fails**: Document as "pyautogui installation fails due to network limitations"
- **npm audit shows vulnerabilities**: Expected - these are utility scripts, not production services
- **PowerShell Azure modules missing**: Use the setup script in `ps/AzSetup-AzureTools/`

### Script-Specific Notes
- **All PowerShell scripts**: Require `-RunAsAdministrator` on Windows
- **Bash setup scripts**: Require sudo/root privileges on Linux
- **Python GUI scripts**: Require display environment (X11) - may not work in headless environments
- **Node.js apps**: May have security vulnerabilities - acceptable for utility/demo purposes

## File Organization Best Practices

- Each subdirectory is independent - no cross-dependencies
- README files in each subdirectory contain specific usage instructions
- Scripts are organized by platform/language, not by functionality
- No centralized configuration or build system

## Time Expectations

**NEVER CANCEL THESE OPERATIONS - SET APPROPRIATE TIMEOUTS:**

- **Node.js npm install**: 30-120 seconds - Set timeout to 180+ seconds
- **Python pip install**: 120-600 seconds - Set timeout to 900+ seconds  
- **PowerShell Azure setup**: 300-1200 seconds - Set timeout to 1800+ seconds
- **Bash system setup**: 600-2700 seconds - Set timeout to 3600+ seconds
- **Script syntax validation**: 1-15 seconds - Set timeout to 30+ seconds

## Repository-Specific Commands

```bash
# Get repository overview
ls -la /home/runner/work/Scripts/Scripts/

# Check script syntax across the repository
find . -name "*.sh" -exec bash -n {} \; -print

# Find PowerShell scripts (excluding node_modules)
find . -name "*.ps1" -not -path "./node/*/node_modules/*" | head -10

# Test Node.js projects  
cd node/02_returnClientIpShow && npm install && node bin/www &
sleep 3 && curl -s http://localhost:8080 | head -2 && pkill -f "node bin/www"

# Test Python dependencies
python3 -c "
try:
    import pyautogui
    print('pyautogui: available')
except ImportError:
    print('pyautogui: NOT available - install with: pip3 install pyautogui')
except Exception as e:
    print(f'pyautogui: error - {e}')
"
```

## Complete Validation Workflow

**Run this complete validation to ensure all script types work correctly:**

```bash
# 1. Repository structure validation (5 seconds)
cd /home/runner/work/Scripts/Scripts && ls -la

# 2. Bash script syntax validation (10-30 seconds)  
find . -name "*.sh" -exec bash -n {} \; && echo "All bash scripts: syntax OK"

# 3. PowerShell availability check (5 seconds)
pwsh --version

# 4. Node.js application test (60-120 seconds total)
cd node/02_returnClientIpShow
npm install  # 30-90 seconds
node bin/www &
sleep 3 
curl -s http://localhost:8080 | head -1  # Should show HTML with client IP
pkill -f "node bin/www"

# 5. Python dependency check (5 seconds)
python3 -c "
try:
    import pyautogui
    print('SUCCESS: pyautogui available')
except ImportError:
    print('INFO: pyautogui needs installation - pip3 install pyautogui')
except Exception as e:
    print(f'WARNING: pyautogui error - {e}')
"

echo "Repository validation complete"
```

**Expected Results:**
- Bash scripts: All should pass syntax validation  
- PowerShell: Version 7.4.11+ available
- Node.js: IP detection app responds with HTML containing client IP
- Python: pyautogui may need installation (network timeouts expected)

Remember: This is a utility script collection, not a single application. Test and validate each script independently based on its specific requirements and platform.