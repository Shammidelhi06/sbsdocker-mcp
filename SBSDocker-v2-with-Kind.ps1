Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1

# Check if the script is running as administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentDirectory = Get-Location
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Sopra Desktop must be run as an administrator. Please run in administrator mode." -ForegroundColor Red
    exit
}

# Get the current date and time
$currentDateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Define the log file path
$logFilePath = "SBSDocker_${currentDateTime}.log"

# Delete the log file if it already exists
if (Test-Path $logFilePath) {
    Remove-Item $logFilePath -Force
}

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFilePath -Append
}

# Define the minimum required free space in bytes (2 GB for Kind)
$minFreeSpace = 2GB

# Get the free space of the C: drive
$drive = Get-PSDrive -Name C

# Check if the free space is greater than or equal to the minimum required free space
if ($drive.Free -le $minFreeSpace) {
    Log-Message "The C: drive should have minimum 2GB free space for Docker + Kubernetes. Please add some space and execute again."
    exit
}

# Function to run a command and log its output
function Run-Command {
    param (
        [string]$command
    )
    Log-Message "Executing command: $command"
   
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "cmd.exe"
    $processInfo.Arguments = "/c $command"
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::Start($processInfo)
    $standardOutput = $process.StandardOutput.ReadToEnd()
    $standardError = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    Log-Message $standardOutput
    Log-Message $standardError
}

# Function to create a shortcut
function Create-Shortcut {
    param (
        [string]$ShortcutPath,
        [string]$TargetPath,
        [string]$WorkingDirectory,
        [string]$Description,
        [string]$Arguments = "",
        [string]$IconLocation = ""
    )
   
    # Create a new WScript.Shell COM object
    $WScriptShell = New-Object -ComObject WScript.Shell
   
    # Create a new shortcut
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
   
    # Set the shortcut properties
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.WorkingDirectory = $WorkingDirectory
    $Shortcut.Description = $Description
    if ($Arguments) {
        $Shortcut.Arguments = $Arguments
    }
    if ($IconLocation) {
        $Shortcut.IconLocation = $IconLocation
    }
   
    # Save the shortcut
    $Shortcut.Save()
   
    Write-Host "Shortcut '$ShortcutPath' created."
}
# Function to install SBSDocker with progress
function Install-SBSDocker {
    Write-Progress -Activity "Installing SBSDocker" -Status "Setting Execution Policy" -PercentComplete 0
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force > $null 2>&1

    Write-Progress -Activity "Installing SBSDocker" -Status "Enabling WSL, Chocolatey, and Virtual Machine Platform if not enabled" -PercentComplete 10
    # Check if the Microsoft-Windows-Subsystem-Linux feature is enabled
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
   
    # Check if the VirtualMachinePlatform feature is enabled
    $vmPlatformFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
   
    # Enable Microsoft-Windows-Subsystem-Linux feature if not already enabled
      if ($wslFeature.State -ne "Enabled" -or $vmPlatformFeature.State -ne "Enabled") {
    if ($wslFeature.State -ne "Enabled") {
        Run-Command "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
    }
   
    # Enable VirtualMachinePlatform feature if not already enabled
    if ($vmPlatformFeature.State -ne "Enabled") {
        Run-Command "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"
    }
    Write-Progress -Activity "Installing SBSDocker" -Status "Process Completed" -PercentComplete 100
 
    # Show a popup message to restart the system
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show('System will be restarted to enable WSL and Virtual Machine Platform effectively.', 'Restart Required', 'OK', 'Information') *>$null
      Start-Sleep -Seconds 5
      Restart-Computer -Force

    Exit

} else {          

    $ErrorActionPreference = "SilentlyContinue"
    Set-ExecutionPolicy Bypass -Scope Process -Force > $null 2>&1
    $ErrorActionPreference = "Continue"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $ErrorActionPreference = "SilentlyContinue"
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) *>$null
    $ErrorActionPreference = "Continue"

    Start-Sleep -Seconds 5

    Write-Progress -Activity "Installing SBSDocker" -Status "Installing WSL" -PercentComplete 20
    Run-Command "wsl --install --no-distribution"
    Run-Command "wsl --update"
    Run-Command "wsl --version"

    Write-Progress -Activity "Installing SBSDocker" -Status "Downloading Ubuntu" -PercentComplete 30

    # Prompt the user for the drive location
    do {
        $driveLocation = Read-Host -Prompt "Please enter the drive location where you want to install SBSDocker (e.g., C:\, D:\, etc.)"
        if ([string]::IsNullOrWhiteSpace($driveLocation)) {
            Write-Host "Drive location cannot be empty. Please try again."
        }
    } until (![string]::IsNullOrWhiteSpace($driveLocation))
   
    # Check if the drive exists
    if (-Not (Test-Path $driveLocation)) {
        Write-Host "$driveLocation does not exist. Try again with a valid drive."
        exit 1
    }
   
    # Define the folder name you want to create
    $folderName = "sbsdocker"
    $UbuntuFolder = "$folderName\Ubuntu"
   
    # Combine the drive location with the folder name to create the full path
      $importDocker = Join-Path -Path $driveLocation -ChildPath $folderName
    $importUbuntu = Join-Path -Path $driveLocation -ChildPath $UbuntuFolder
      
    # Check if the folder exists, and create it if it does not
    if (-Not (Test-Path -Path $importUbuntu)) {
        New-Item -Path $importUbuntu -ItemType Directory | Out-Null
    }
   
      # Define the URL of Ubuntu to download
      $url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-root.tar.xz"
      
      # Construct the file name from the URL
      $fileName = [System.IO.Path]::GetFileName($url)
      
      # Construct the full path of the downloaded file
      $filePath = Join-Path -Path $currentDirectory -ChildPath $fileName

    # Check if the Ubuntu binary file exists, if not download it
    if (-not (Test-Path $filePath)) {
        Invoke-WebRequest -Uri $url -OutFile $filePath
    }
   
    # Display progress
    Write-Progress -Activity "Installing SBSDocker" -Status "Importing Ubuntu" -PercentComplete 40
    wsl --import Ubuntu "$importUbuntu" "$filePath" > $null 2>&1
    Run-Command "wsl --set-default Ubuntu"
    Start-Sleep -Seconds 10

    Write-Progress -Activity "Installing SBSDocker" -Status "Updating Ubuntu" -PercentComplete 50
    Run-Command "wsl -u root -d Ubuntu -- /bin/bash -c 'DEBIAN_FRONTEND=noninteractive apt-get update -y'"

    Write-Progress -Activity "Installing SBSDocker" -Status "Installing Docker and Dependencies" -PercentComplete 60
    Run-Command "wsl -u root -d Ubuntu -- /bin/bash -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y libsecret-1-0 ca-certificates curl'"
    Run-Command "wsl -u root -d Ubuntu -- /bin/bash -c 'curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh'"
    Run-Command "wsl -u root -d Ubuntu -- /bin/bash -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y docker-compose'"

      # Define the URL of Docker client to download
      $dockerurl = "https://download.docker.com/win/static/stable/x86_64/docker-20.10.12.zip"
      
      # Construct the full path of the downloaded file
      $dockerOutputZip = Join-Path -Path $importDocker -ChildPath "docker-cli.zip"
      $dockerCliPath = Join-Path -Path $importDocker -ChildPath "docker"
      
      Write-Progress -Activity "Installing SBSDocker" -Status "Downloading Docker client" -PercentComplete 70
      # Download Docker client
      Invoke-WebRequest -Uri $dockerurl -OutFile $dockerOutputZip
      Expand-Archive -Path $dockerOutputZip -DestinationPath $importDocker > $null 2>&1

    # Fix ACL issue
    # Specify the permissions
    $permission = "Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
   
    # Create a new access rule object
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
   
    # Get the current ACL of the directory
    $acl = Get-Acl -Path $dockerCliPath
   
    # Add the access rule to the ACL
    $acl.SetAccessRule($accessRule)

      # Define the URL of Docker-compose client to download
      $composeurl = "https://github.com/docker/compose/releases/download/v2.5.1/docker-compose-Windows-x86_64.exe"
      
      # Construct the full path of the downloaded file
      $composeOutput = Join-Path -Path $dockerCliPath -ChildPath "docker-compose.exe"
      
      Write-Progress -Activity "Installing SBSDocker" -Status "Downloading Compose client" -PercentComplete 75
      # Download compose client
      Invoke-WebRequest -Uri $composeUrl -OutFile $composeOutput
      
      # Set Environment variable for docker and compose
    if ($env:Path -notmatch [regex]::Escape($dockerCliPath)) {
        $env:Path += ";$dockerCliPath"
        [System.Environment]::SetEnvironmentVariable("PATH", $env:Path, [System.EnvironmentVariableTarget]::Machine)
    }
      
      Run-Command "refreshenv"
    Start-Sleep -Seconds 5    
    Run-Command "docker.exe --version"
    Run-Command "docker-compose.exe --version"
 
    docker context create wsl --docker "host=tcp://localhost:2375" > $null 2>&1
    docker context use wsl > $null 2>&1
                                                                                                                          
    $fileName = "donotdelete.txt"
      $currentDirectory = Get-Location
    # Construct the full file path
    $filePath = Join-Path -Path $currentDirectory -ChildPath $fileName
    $driveLocation | Out-File -FilePath $filePath -Encoding UTF8
                  
    Write-Progress -Activity "Installing SBSDocker" -Status "Configuring Proxy Settings" -PercentComplete 85
    $proxySettings = @"
export http_proxy=http://noid.proxy.corp.sopra:8080
export https_proxy=http://noid.proxy.corp.sopra:8080
export no_proxy=localhost,127.0.0.1,.sopra,.ssg
"@
    wsl -u root -d Ubuntu -- /bin/bash -c "echo '$proxySettings' >> /root/.profile" > $null 2>&1
    wsl -u root -d Ubuntu -- /bin/bash -c "source /root/.profile" > $null 2>&1

    Write-Progress -Activity "Installing SBSDocker" -Status "Configuring DNS and Docker Daemon" -PercentComplete 90
      
          $wslConfContent = @"
[network]
generateResolvConf = false
"@

    $wslConfPath = "/etc/wsl.conf"
    $wslConfContent | wsl -u root -- sh -c "cat > $wslConfPath"
    wsl -u root -d Ubuntu --shutdown > $null 2>&1
    Start-Sleep -Seconds 10
      
    $resolvConf = @"
search noid.in.ssg ssg
nameserver 1.1.1.1
nameserver 10.7.13.13
nameserver 10.7.11.11
nameserver 172.22.16.1
"@
    $resolvConfPath = "resolv.conf"
    Set-Content -Path $resolvConfPath -Value $resolvConf
    wsl -u root -d Ubuntu -- cp $resolvConfPath /etc/resolv.conf > $null 2>&1
    wsl -u root -d Ubuntu -- cp $resolvConfPath /etc/test.conf > $null 2>&1   
    Remove-Item $resolvConfPath > $null 2>&1

    wsl -u root -d Ubuntu -- mkdir -p /etc/docker > $null 2>&1
    $daemonJson = @"
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://127.0.0.1:2375"]
}
"@
    $daemonJsonPath = "daemon.json"
    Set-Content -Path $daemonJsonPath -Value $daemonJson
    wsl -u root -d Ubuntu -- cp $daemonJsonPath /etc/docker/daemon.json > $null 2>&1
    Remove-Item $daemonJsonPath > $null 2>&1
                                            
    Write-Progress -Activity "Installing SBSDocker" -Status "Starting Docker Daemon" -PercentComplete 95
    wsl -u root -d Ubuntu -- /bin/bash -c "echo -e '#!/bin/bash\nsudo dockerd > /var/log/dockerd.log 2>&1 &' | sudo tee /usr/local/bin/start_docker.sh" > $null 2>&1
    wsl -u root -d Ubuntu -- /bin/bash -c "sudo chmod +x /usr/local/bin/start_docker.sh" > $null 2>&1
    wsl -u root -d Ubuntu -- /bin/bash -c "sudo /usr/local/bin/start_docker.sh" > $null 2>&1
    Start-Sleep -Seconds 10

    Write-Progress -Activity "Installing SBSDocker" -Status "Creating shortcuts" -PercentComplete 98
    Run-Command "choco install lazydocker -y"
    
    # LazyDocker shortcut properties
    $lazydockerShortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'SBSDocker UI.lnk')
    $lazydockerTargetPath = 'lazydocker'
    $lazydockerWorkingDirectory = [System.Environment]::GetFolderPath('UserProfile')
    $lazydockerDescription = 'Shortcut to SBSDocker UI'
   
    # Start Docker shortcut properties
    $startDockerShortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'Start SBSDocker.lnk')
    $startDockerTargetPath = "C:\Windows\System32\wsl.exe"
    $startDockerArguments = "-d Ubuntu -- /bin/bash -c `"sleep 5 && cp /etc/test.conf /etc/resolv.conf && sudo /usr/local/bin/start_docker.sh > /dev/null 2>&1`""
    $startDockerWorkingDirectory = [System.Environment]::GetFolderPath('Desktop')
    $startDockerIconLocation = "C:\Windows\System32\wsl.exe, 0"

    # Create the LazyDocker shortcut
    Create-Shortcut -ShortcutPath $lazydockerShortcutPath -TargetPath $lazydockerTargetPath -WorkingDirectory $lazydockerWorkingDirectory -Description $lazydockerDescription
   
    # Create the Start Docker shortcut
    Create-Shortcut -ShortcutPath $startDockerShortcutPath -TargetPath $startDockerTargetPath -WorkingDirectory $startDockerWorkingDirectory -Description "Start Docker" -Arguments $startDockerArguments -IconLocation $startDockerIconLocation
    
    Start-Sleep -Seconds 2
    Write-Host "SBSDocker has been installed successfully." -ForegroundColor Green
    Write-Progress -Activity "Installing SBSDocker" -Status "Completed" -Completed
    setx DOCKER_HOST "tcp://127.0.0.1:2375" > $null 2>&1
}
}

# Function to install Kind and Kubernetes tools
function Install-Kubernetes {
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Installing kubectl" -PercentComplete 10
    
    # Install kubectl via Chocolatey
    Run-Command "choco install kubernetes-cli -y"
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Installing Kind" -PercentComplete 20
    
    # Install Kind
    Run-Command "choco install kind -y"
    
    # Install additional useful tools
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Installing additional tools" -PercentComplete 30
    Run-Command "choco install kubernetes-helm -y"
    Run-Command "choco install k9s -y"
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Configuring proxy for Kind" -PercentComplete 40
    
    # Create Kind configuration with proxy settings for corporate environment
    $kindConfig = @"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: sbsdocker-cluster
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraEnvs:
      - name: HTTP_PROXY
        value: "http://noid.proxy.corp.sopra:8080"
      - name: HTTPS_PROXY
        value: "http://noid.proxy.corp.sopra:8080"
      - name: NO_PROXY
        value: "localhost,127.0.0.1,.sopra,.ssg,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
  - |
    kind: KubeletConfiguration
    serverTLSBootstrap: true
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
  - containerPort: 30002
    hostPort: 30002
    protocol: TCP
"@
    
    $kindConfigPath = "kind-config.yaml"
    Set-Content -Path $kindConfigPath -Value $kindConfig
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Setting up Docker context for Kind" -PercentComplete 50
    
    # Ensure Docker context is set correctly for Kind
    Run-Command "docker context use wsl"
    
    # Copy Kind config to WSL for access
    wsl -d Ubuntu -- mkdir -p /tmp > $null 2>&1
    wsl -d Ubuntu -- cp "/mnt/c/$(Get-Location | Split-Path -Leaf)/kind-config.yaml" /tmp/ > $null 2>&1
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Creating Kind cluster" -PercentComplete 60
    
    # Create Kind cluster from within WSL Ubuntu to ensure proper Docker connectivity
    wsl -d Ubuntu -- /bin/bash -c "export DOCKER_HOST=tcp://127.0.0.1:2375 && kind create cluster --config /tmp/kind-config.yaml --wait 300s"
    
    Start-Sleep -Seconds 10
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Configuring kubectl" -PercentComplete 75
    
    # Create .kube directory in Windows user profile
    $kubeDir = "$env:USERPROFILE\.kube"
    if (-not (Test-Path $kubeDir)) {
        New-Item -Path $kubeDir -ItemType Directory -Force > $null
    }
    
    # Get kubeconfig from Kind and save to Windows
    wsl -d Ubuntu -- /bin/bash -c "export DOCKER_HOST=tcp://127.0.0.1:2375 && kind get kubeconfig --name sbsdocker-cluster" | Out-File -FilePath "$kubeDir\config" -Encoding UTF8
    
    # Set KUBECONFIG environment variable
    [System.Environment]::SetEnvironmentVariable("KUBECONFIG", "$kubeDir\config", [System.EnvironmentVariableTarget]::User)
    $env:KUBECONFIG = "$kubeDir\config"
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Installing Kubernetes Dashboard" -PercentComplete 85
    
    # Install Kubernetes Dashboard
    Start-Sleep -Seconds 5
    Run-Command "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
    
    # Create admin user for dashboard
    $dashboardAdmin = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
"@
    
    $dashboardAdminPath = "dashboard-admin.yaml"
    Set-Content -Path $dashboardAdminPath -Value $dashboardAdmin
    Run-Command "kubectl apply -f $dashboardAdminPath"
    Remove-Item $dashboardAdminPath > $null 2>&1
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Creating shortcuts" -PercentComplete 90
    
    # Create shortcuts for Kubernetes tools
    Create-KubernetesShortcuts
    
    # Clean up
    Remove-Item $kindConfigPath > $null 2>&1
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Verifying installation" -PercentComplete 95
    
    # Verify installation
    Start-Sleep -Seconds 5
    Run-Command "kubectl cluster-info"
    Run-Command "kubectl get nodes"
    
    Write-Progress -Activity "Installing Kubernetes with Kind" -Status "Completed" -Completed
    Write-Host "Kubernetes with Kind has been installed successfully!" -ForegroundColor Green
    Write-Host "Cluster name: sbsdocker-cluster" -ForegroundColor Cyan
    Write-Host "Use 'kubectl get nodes' to verify the cluster" -ForegroundColor Cyan
    Write-Host "Use 'SBSDocker K8s Dashboard' shortcut to access the dashboard" -ForegroundColor Cyan
}

# Function to create Kubernetes-related shortcuts
function Create-KubernetesShortcuts {
    # K9s shortcut (Kubernetes terminal UI)
    $k9sShortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'SBSDocker K9s.lnk')
    $k9sTargetPath = 'k9s'
    $k9sWorkingDirectory = [System.Environment]::GetFolderPath('UserProfile')
    $k9sDescription = 'Kubernetes Terminal UI'
    
    Create-Shortcut -ShortcutPath $k9sShortcutPath -TargetPath $k9sTargetPath -WorkingDirectory $k9sWorkingDirectory -Description $k9sDescription
    
    # Kubernetes Dashboard shortcut
    $dashboardShortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'SBSDocker K8s Dashboard.lnk')
    $dashboardTargetPath = "C:\Windows\System32\cmd.exe"
    $dashboardArguments = "/k echo Starting Kubernetes Dashboard... && kubectl proxy --port=8001 && echo Dashboard available at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    
    Create-Shortcut -ShortcutPath $dashboardShortcutPath -TargetPath $dashboardTargetPath -WorkingDirectory $env:USERPROFILE -Description "Kubernetes Dashboard" -Arguments $dashboardArguments
    
    # Kind management shortcut
    $kindShortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'SBSDocker Kind Manager.lnk')
    $kindTargetPath = "C:\Windows\System32\wsl.exe"
    $kindArguments = "-d Ubuntu -- /bin/bash -c `"echo 'Kind Cluster Management' && echo 'Available commands:' && echo '  kind get clusters' && echo '  kind delete cluster --name sbsdocker-cluster' && echo '  kind create cluster --config /tmp/kind-config.yaml' && /bin/bash`""
    
    Create-Shortcut -ShortcutPath $kindShortcutPath -TargetPath $kindTargetPath -WorkingDirectory $env:USERPROFILE -Description "Kind Cluster Manager" -Arguments $kindArguments
}

# Function to uninstall Kubernetes components
function Uninstall-Kubernetes {
    Write-Progress -Activity "Uninstalling Kubernetes" -Status "Deleting Kind cluster" -PercentComplete 20
    
    # Delete Kind cluster
    wsl -d Ubuntu -- /bin/bash -c "export DOCKER_HOST=tcp://127.0.0.1:2375 && kind delete cluster --name sbsdocker-cluster" > $null 2>&1
    
    Write-Progress -Activity "Uninstalling Kubernetes" -Status "Removing tools" -PercentComplete 50
    
    # Uninstall Kubernetes tools
    Run-Command "choco uninstall kubernetes-cli -y"
    Run-Command "choco uninstall kind -y"
    Run-Command "choco uninstall kubernetes-helm -y"
    Run-Command "choco uninstall k9s -y"
    
    Write-Progress -Activity "Uninstalling Kubernetes" -Status "Removing shortcuts" -PercentComplete 80
    
    # Remove Kubernetes shortcuts
    $shortcuts = @(
        'SBSDocker K9s.lnk',
        'SBSDocker K8s Dashboard.lnk',
        'SBSDocker Kind Manager.lnk'
    )
    
    foreach ($shortcut in $shortcuts) {
        $shortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), $shortcut)
        if (Test-Path $shortcutPath) {
            Remove-Item $shortcutPath -Force > $null 2>&1
        }
    }
    
    # Remove kubeconfig
    $kubeDir = "$env:USERPROFILE\.kube"
    if (Test-Path $kubeDir) {
        Remove-Item $kubeDir -Recurse -Force > $null 2>&1
    }
    
    # Remove KUBECONFIG environment variable
    [System.Environment]::SetEnvironmentVariable("KUBECONFIG", $null, [System.EnvironmentVariableTarget]::User)
    
    Write-Progress -Activity "Uninstalling Kubernetes" -Status "Completed" -PercentComplete 100
    Write-Host "Kubernetes components removed successfully!" -ForegroundColor Green
}

# Function to uninstall SBSDocker with progress
function Uninstall-SBSDocker {
    Write-Progress -Activity "Uninstalling SBSDocker" -Status "Stopping Docker" -PercentComplete 0

    $fileName = "donotdelete.txt"
    $currentDirectory = Get-Location
    $filePath = Join-Path -Path $currentDirectory -ChildPath $fileName

    if (Test-Path -Path $filePath) {
        $sbspath = Get-Content -Path $filePath
        Remove-Item -Path $filePath -Force > $null 2>&1

        Run-Command "wsl --unregister Ubuntu"

        Write-Progress -Activity "Uninstalling SBSDocker" -Status "Deleting Shortcut and clients" -PercentComplete 95 
        Run-Command "choco uninstall lazydocker -y"
        
        # Delete sbsdirectory
        $folderPath = Join-Path -Path $sbspath -ChildPath "sbsdocker"
        Remove-Item -Path $folderPath -Recurse -Force > $null 2>&1

        $lazydockerShortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'SBSDocker UI.lnk')
       
        if (Test-Path $lazydockerShortcutPath) {
            Remove-Item $lazydockerShortcutPath -Force
        }
       
        $startDockerShortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), 'Start SBSDocker.lnk')
       
        if (Test-Path $startDockerShortcutPath) {
            Remove-Item $startDockerShortcutPath -Force
        }

        Write-Progress -Activity "Uninstalling SBSDocker" -Status "Completed" -PercentComplete 100
        Write-Host "SBSDocker has been uninstalled" -ForegroundColor Green
        # Show a popup message to restart the system
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show('System will be restarted to revert all changes.', 'Restart Required', 'OK', 'Information') > $null 2>&1
        Start-Sleep -Seconds 5
        # Restart-Computer -Force
    } else {
        Write-Host "SBSDocker not yet installed." -ForegroundColor Yellow
    }
}

# Updated main menu function
function Show-MainMenu {
    $actionPrompt = @"
Select the action you want to perform:
1. Install Docker Only
2. Install Docker + Kubernetes (Kind)
3. Uninstall All
4. Uninstall Kubernetes Only (keep Docker)
"@
    
    $action = Read-Host $actionPrompt
    
    switch ($action) {
        1 {
            Install-SBSDocker
        }
        2 {
            Install-SBSDocker
            Install-Kubernetes
        }
        3 {
            Uninstall-Kubernetes
            Uninstall-SBSDocker
        }
        4 {
            Uninstall-Kubernetes
        }
        default {
            Write-Host "Invalid selection. Exiting script." -ForegroundColor Red
            exit
        }
    }
}

# Run the main menu
Show-MainMenu
