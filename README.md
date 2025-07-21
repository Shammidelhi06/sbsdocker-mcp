# SBSDesktop v3.0

**Professional Docker & Kubernetes Management Suite**

A unified Windows GUI application that simplifies Docker and Kubernetes installation and management on Windows with WSL2 integration.

![SBSDesktop Interface](https://img.shields.io/badge/Platform-Windows-blue) ![Version](https://img.shields.io/badge/Version-3.0-green) ![WSL2](https://img.shields.io/badge/WSL2-Required-green) ![Admin Required](https://img.shields.io/badge/Admin-Required-red)

## 🚀 Features

### 🐳 Docker Operations
- **Complete Docker Setup**: Docker Engine, CLI, and Compose
- **Portainer Integration**: Web-based container management UI
- **WSL2 Integration**: Seamless Linux container support
- **Desktop Shortcuts**: Quick access to Docker services
- **Corporate Proxy Support**: Enterprise-friendly configuration

### ☸️ Kubernetes Operations
- **kubectl Client**: Windows and WSL installations
- **kind Clusters**: Local Kubernetes development clusters
- **Helm Package Manager**: Chart-based application deployment
- **k9s Dashboard**: Terminal-based cluster management
- **Multi-node Testing**: Production-like local environments

### 🎯 Unified Management
- **Single Interface**: Combined Docker and Kubernetes operations
- **Progress Tracking**: Real-time installation monitoring
- **Comprehensive Logging**: Detailed operation logs
- **Error Handling**: Intelligent troubleshooting guidance
- **Clean Uninstalls**: Complete component removal

## 🆕 What's New in v3.0

### **Visual Enhancements**
- **Version Display**: Prominent v3.0 label in top-right corner
- **Professional Branding**: Consistent v3.0 messaging throughout
- **Enhanced UI**: Improved button positioning and layout

### **Technical Improvements**
- **Enhanced Logging**: All operations now tagged with v3.0
- **Better Error Messages**: More specific troubleshooting guidance
- **Improved Stability**: Enhanced error handling and recovery
- **Updated Dependencies**: Latest versions of all tools and components

### **User Experience**
- **Clear Version Identification**: Always know which version you're running
- **Professional Interface**: Enterprise-ready appearance
- **Consistent Branding**: v3.0 identity across all operations

## 📋 Prerequisites

### System Requirements
- **OS**: Windows 10/11 (Build 19041 or higher)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space
- **Network**: Internet connection for downloads

### Required Windows Features
- Windows Subsystem for Linux (WSL2)
- Virtual Machine Platform
- Hyper-V (automatically enabled)

### Prerequisites
- Administrator privileges
- .NET Framework 4.7.2+

## 🛠️ Installation & Usage

### Quick Start

1. **Download** the SBSDesktop-GUI.exe v3.0 file
2. **Run as Administrator** by right-clicking → **Run as administrator**
3. **Choose your operation**:
   - Install Docker
   - Install Kubernetes
   - Uninstall components

*Version 3.0 displays prominently in the top-right corner of the interface*

### Step-by-Step Process

#### Docker Installation
```
# Run as Administrator
SBSDesktop-GUI.exe v3.0
# Click "INSTALL DOCKER"
# Follow the guided installation process
```

#### Kubernetes Installation
```
# Ensure Docker is installed first
# Run SBSDesktop-GUI.exe v3.0
# Click "INSTALL KUBERNETES"
# Wait for cluster creation and tool setup
```

### Post-Installation

#### Docker Access
- **Portainer Web UI**: http://localhost:9000
- **Desktop Shortcut**: "Start SBSDocker"
- **Command Line**: `docker ps`, `docker-compose up`

#### Kubernetes Access
- **k9s Dashboard**: Use "SBSKubernetes Dashboard" shortcut
- **kubectl**: `kubectl get nodes`, `kubectl get pods`
- **Helm**: `helm list`, `helm install`

## 🏗️ Architecture

### Components Installed

#### Docker Stack
```
┌─────────────────┐    ┌──────────────────┐
│   Windows Host  │    │    WSL2 Ubuntu   │
│                 │    │                  │
│ Docker CLI      │◄──►│ Docker Engine    │
│ Docker Compose  │    │ Portainer        │
│ Portainer UI    │    │ Container Runtime│
└─────────────────┘    └──────────────────┘
```

#### Kubernetes Stack
```
┌─────────────────┐    ┌──────────────────┐
│   Windows Host  │    │    WSL2 Ubuntu   │
│                 │    │                  │
│ kubectl CLI     │    │ kubectl          │
│ Helm            │◄──►│ kind cluster     │
│ k9s Dashboard   │    │ Helm             │
└─────────────────┘    └──────────────────┘
```

### Network Configuration
- **Docker**: TCP/2375 for API access
- **Portainer**: HTTP/9000 for web interface
- **Kubernetes**: Standard kubeconfig setup
- **DNS**: Custom resolver configuration

## 🔧 Configuration

### Corporate Environment
The application automatically configures:
- HTTP/HTTPS proxy settings
- Corporate DNS servers
- Network routing for WSL2

### Customization
Edit these files for advanced configuration:
- `/etc/docker/daemon.json` (Docker settings)
- `~/.kube/config` (Kubernetes access)
- `/etc/wsl.conf` (WSL configuration)

## 🐛 Troubleshooting

### Common Issues

#### WSL2 Not Working
```powershell
# Enable WSL features
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# Restart computer
```

#### Docker Connection Failed
```bash
# In WSL2
sudo /usr/local/bin/start_docker.sh
# Check status
docker ps
```

#### Kubernetes Cluster Issues
```bash
# Restart kind cluster
kind delete cluster --name=sbs-cluster
kind create cluster --name=sbs-cluster
```

#### Network Connectivity
```powershell
# Test connectivity
Test-NetConnection github.com -Port 443
# Check proxy settings
```

### Log Files
- Main log: `SBSDesktop_v3.0_YYYY-MM-DD_HH-mm-ss.log`
- Docker logs: `/var/log/dockerd.log` (in WSL)
- Kubernetes logs: `kubectl logs` commands

### Support
1. Check the log files for detailed error messages
2. Verify all prerequisites are met
3. Try running individual components manually
4. Restart WSL2: `wsl --shutdown` then relaunch

## 📁 File Structure

```
SBSDocker-v1/
├── SBSDesktop-GUI.exe               # Main application executable (v3.0)
└── README.md                        # This file (v3.0 updated)
```

## 🎯 Use Cases

### Development Environment
- **Local Docker development** with Portainer management
- **Kubernetes testing** with kind clusters
- **Helm chart development** and testing
- **Container debugging** with k9s

### Learning & Training
- **Docker fundamentals** with visual management
- **Kubernetes concepts** with local clusters
- **DevOps practices** with complete toolchain
- **Container orchestration** hands-on experience

### Enterprise Testing
- **Application containerization** validation
- **Kubernetes migration** planning
- **CI/CD pipeline** development
- **Multi-environment** configuration testing

## 🔄 Upgrade Path

### From Individual Scripts
If you're using SBSDocker-portainer-GUI.ps1 or SBSKubernetes-GUI.ps1:
1. **Backup** your current installations
2. **Uninstall** using the old scripts
3. **Install** using SBSDesktop-GUI.exe v3.0
4. **Restore** any custom configurations

### Version Updates
1. **Download** the latest SBSDesktop-GUI.exe v3.0
2. **Backup** your installation marker (`donotdelete.txt`)
3. **Run** the new executable as Administrator
4. **Verify** all components work correctly

### From v1.0/v2.0 to v3.0
- **Enhanced Interface**: Version display in top-right corner
- **Improved Logging**: v3.0 branding throughout log messages
- **Better Error Handling**: Enhanced troubleshooting guidance
- **Updated Dependencies**: Latest tool versions and security patches

## 🤝 Contributing

### Development
- **Source**: PowerShell 5.1+ (SBSDesktop-GUI.ps1 v3.0)
- **Distribution**: Compiled executable (SBSDesktop-GUI.exe v3.0)
- **Framework**: Windows Forms
- **Architecture**: Modular functions
- **Testing**: Manual GUI testing
- **Version**: 3.0 with enhanced UI and branding

### Guidelines
1. **Maintain** administrator requirement checks
2. **Follow** existing error handling patterns
3. **Update** progress tracking for new features
4. **Document** all configuration changes
5. **Test** on clean Windows installations

## 📝 License

This project is provided as-is for educational and development purposes. Please ensure compliance with all component licenses:
- Docker: Apache License 2.0
- Kubernetes: Apache License 2.0
- Helm: Apache License 2.0
- WSL2: Microsoft Software License

## 🙏 Acknowledgments

- **Docker Team** for containerization technology
- **Kubernetes Team** for orchestration platform
- **Microsoft** for WSL2 integration
- **Portainer** for container management UI
- **k9s Team** for terminal-based cluster management
- **kind Team** for local Kubernetes clusters

## 📞 Support

For issues and questions:
1. Check troubleshooting section above
2. Review log files for specific errors
3. Verify system requirements are met
4. Test individual components separately

---

**SBSDesktop v3.0 - Built with ❤️ for the Docker and Kubernetes community**

*Professional Docker & Kubernetes Management Suite - Now with enhanced v3.0 interface*