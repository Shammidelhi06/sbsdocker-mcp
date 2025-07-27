# SBSDesktop Professional Edition v3.0

A comprehensive Docker and Kubernetes management suite for Windows, providing automated installation, configuration, and management of containerization tools.

## 🚀 Overview

SBSDesktop v3.0 is a complete Docker and Kubernetes installation and management solution designed for Windows environments. It combines Docker Engine running in WSL2 with a full Kubernetes development stack, featuring an intuitive GUI for easy operations management.

## ✨ Features

### Docker Operations
- **WSL2 Integration**: Docker Engine running in Ubuntu WSL2 distribution
- **Docker CLI**: Windows Docker client with full compatibility
- **Docker Compose**: Container orchestration support
- **LazyDocker UI**: Terminal-based Docker management interface
- **Automated Configuration**: DNS, proxy, and daemon settings
- **Desktop Shortcuts**: Quick access to Docker operations

### Kubernetes Operations
- **kubectl Client**: Command-line Kubernetes management (Windows & WSL)
- **kind**: Lightweight Kubernetes clusters in Docker
- **Helm**: Kubernetes package manager
- **k9s Dashboard**: Interactive Kubernetes cluster management
- **Multi-node Clusters**: Automated test cluster creation
- **Desktop Integration**: Start/stop shortcuts and scripts

## 📋 Prerequisites

- Windows 10/11 with Administrator privileges
- Minimum 1GB free disk space on C: drive
- WSL2 and Virtual Machine Platform features (auto-enabled if needed)
- Internet connection for downloads

## 🔧 Installation

### Quick Start
1. **Run as Administrator**: Right-click `SBSDesktop.ps1` → "Run as Administrator"
2. **Choose Components**: Use the GUI to install Docker, Kubernetes, or both
3. **Follow Prompts**: Select installation drive and wait for completion
4. **Use Desktop Shortcuts**: Access installed tools via desktop shortcuts

### Docker Installation Process
```powershell
# Automated steps performed by SBSDesktop:
1. Enable WSL2 and Virtual Machine Platform features
2. Install and configure Ubuntu WSL2 distribution
3. Install Docker Engine in WSL2
4. Download and configure Docker CLI for Windows
5. Install Docker Compose
6. Configure proxy and DNS settings
7. Install LazyDocker UI
8. Create desktop shortcuts and scripts
```

### Kubernetes Installation Process
```powershell
# Automated steps performed by SBSDesktop:
1. Verify Docker prerequisites
2. Install kubectl client (Windows & WSL)
3. Install kind (Kubernetes in Docker)
4. Install Helm package manager
5. Install k9s dashboard
6. Create multi-node test cluster
7. Configure kubeconfig files
8. Create management shortcuts and scripts
```

## 🖥️ GUI Interface

The SBSDesktop GUI provides four main operations:

### Operations Center
- **Install Docker**: Full Docker stack installation
- **Uninstall Docker**: Complete Docker removal
- **Install Kubernetes**: Kubernetes tools and cluster setup
- **Uninstall Kubernetes**: Kubernetes components removal

### Progress Tracking
- **Real-time Progress Bar**: Visual installation progress
- **Operation Log**: Detailed system messages and status
- **Error Handling**: Clear error messages and recovery options

## 📁 File Structure

```
SBSDesktop-lazydocker-gui/
├── SBSDesktop.ps1              # Main application script
├── README.md                   # This documentation
├── donotdelete.txt             # Installation path storage (created during installation)
├── SBSDesktop_v3.0_*.log      # Operation logs (timestamped)
└── Desktop Shortcuts/          # Created shortcuts
    ├── Start SBSDocker.lnk
    ├── SBSDocker UI.lnk
    ├── SBSDocker IP.lnk
    ├── Start SBSKubernetes.lnk
    └── SBSKubernetes Dashboard.lnk
```

## 🛠️ Configuration Details

### Docker Configuration
- **WSL Distribution**: Ubuntu (jammy-server-cloudimg)
- **Docker Daemon**: Listening on unix socket and TCP port 2375
- **DNS Servers**: 8.8.8.8, 1.1.1.1, corporate DNS
- **Proxy Settings**: Corporate proxy configuration included
- **Environment Variables**: DOCKER_HOST automatically configured

### Kubernetes Configuration
- **Default Cluster**: `sbs-cluster` (multi-node with kind)
- **kubectl Context**: Automatically configured for local cluster
- **Kubeconfig Location**: `%USERPROFILE%\.kube\config`
- **Cluster Nodes**: 1 control-plane + 2 worker nodes
- **Dashboard**: k9s for cluster visualization

## 📋 Usage Examples

### Docker Operations
```bash
# Start Docker (via desktop shortcut or command)
wsl -d Ubuntu -- /bin/bash -c "sudo /usr/local/bin/start_docker.sh"

# Use Docker CLI
docker ps
docker run hello-world
docker-compose up

# Access LazyDocker UI
lazydocker
```

### Kubernetes Operations
```bash
# Start Kubernetes cluster (via desktop shortcut)
wsl -u root -d Ubuntu -- /bin/bash -c "/usr/local/bin/start_kubernetes.sh"

# Use kubectl
kubectl get nodes
kubectl get pods --all-namespaces

# Access k9s dashboard
k9s

# Use Helm
helm list
helm repo add stable https://charts.helm.sh/stable
```

## 🚨 Troubleshooting

### Common Issues

#### Windows Features Not Enabled
- **Solution**: SBSDesktop automatically enables WSL2 and Virtual Machine Platform
- **Action Required**: System restart may be needed

#### Docker Not Responding
- **Symptoms**: `docker ps` fails or times out
- **Solution**: Click "Start SBSDocker" desktop shortcut
- **Command**: `wsl -d Ubuntu -- sudo /usr/local/bin/start_docker.sh`

#### kubectl Cannot Connect
- **Symptoms**: `kubectl cluster-info` fails
- **Solution**: Start Kubernetes cluster first
- **Command**: Click "Start SBSKubernetes" shortcut

#### Installation Fails
- **Check**: Administrator privileges are required
- **Verify**: Minimum 1GB free space on C: drive
- **Review**: Check log files for specific error messages

### Log Files
All operations are logged with timestamps:
- **Location**: Same directory as `SBSDesktop.ps1`
- **Format**: `SBSDesktop_v3.0_YYYY-MM-DD_HH-mm-ss.log`
- **Content**: Detailed installation steps and error messages

## 🔧 Advanced Configuration

### Custom Installation Drive
During Docker installation, you can specify a custom drive location for the WSL distribution and Docker files.


## 🗑️ Uninstallation

### Docker Uninstallation
- Removes Ubuntu WSL distribution
- Deletes all Docker containers and volumes
- Removes installation files and directories
- Cleans up desktop shortcuts
- Removes environment variables

### Kubernetes Uninstallation
- Deletes kind clusters
- Removes k9s dashboard
- Cleans up desktop shortcuts
- Removes start scripts
- Optionally removes kubectl client

## 📝 System Requirements

### Minimum Requirements
- **OS**: Windows 10 version 2004 or Windows 11
- **RAM**: 4GB (8GB recommended)
- **Disk**: 1GB free space (5GB recommended)
- **CPU**: 64-bit processor with virtualization support

### Recommended Requirements
- **RAM**: 8GB or more
- **Disk**: 10GB free space for containers and images
- **Network**: Stable internet connection for downloads

## 🤝 Support

### Getting Help
1. **Check Logs**: Review timestamped log files for detailed error information
2. **Verify Prerequisites**: Ensure administrator privileges and system requirements
3. **Clean Installation**: Use uninstall features before reinstalling
4. **WSL Reset**: `wsl --shutdown` and restart if needed

### Known Limitations
- Requires Windows 10/11 with WSL2 support
- Corporate proxy settings may need manual adjustment
- Some antivirus software may interfere with WSL2 operations
- Network connectivity required for initial setup

## 📄 License

This project is provided as-is for educational and development purposes. Please ensure compliance with your organization's policies when using in corporate environments.

## 🏷️ Version History

### v3.0 (Current)
- Combined Docker and Kubernetes management
- Enhanced GUI with operations center
- Multi-node Kubernetes cluster support
- Improved error handling and logging
- Desktop shortcuts and automation scripts

---

**Created by**: SBSDesktop Development Team  
**Version**: Professional Edition v3.0  
**Last Updated**: $(Get-Date -Format "MMMM yyyy")
