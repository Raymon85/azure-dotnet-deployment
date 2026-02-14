# Rayan - Azure .NET Web Application Deployment

A complete university project demonstrating how to deploy an ASP.NET Core MVC web application on an Azure Virtual Machine using Infrastructure as Code (Bicep), automated scripts, and proper security practices.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Project Structure](#project-structure)
5. [Step-by-Step Deployment Guide](#step-by-step-deployment-guide)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)
8. [Security Considerations](#security-considerations)
9. [Screenshots](#screenshots)

---

## Project Overview

| Component         | Technology              |
|-------------------|-------------------------|
| Web Application   | ASP.NET Core MVC (.NET 8) |
| Cloud Provider    | Microsoft Azure         |
| VM Operating System | Ubuntu 22.04 LTS      |
| Infrastructure    | Azure Bicep (IaC)       |
| Process Manager   | systemd                 |
| Version Control   | Git + GitHub            |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AZURE CLOUD                              │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Resource Group                            │  │
│  │                                                           │  │
│  │  ┌─────────────┐    ┌──────────────────────────────────┐  │  │
│  │  │  Public IP   │    │  Network Security Group (NSG)    │  │  │
│  │  │  (Static)    │    │                                  │  │  │
│  │  │              │    │  Inbound Rules:                  │  │  │
│  │  └──────┬───────┘    │  ├─ Port 22  (SSH)              │  │  │
│  │         │            │  ├─ Port 80  (HTTP)             │  │  │
│  │         │            │  └─ Port 5000 (App)             │  │  │
│  │         │            └──────────────────────────────────┘  │  │
│  │         │                                                  │  │
│  │  ┌──────▼──────────────────────────────────────────────┐   │  │
│  │  │  Virtual Network (10.0.0.0/16)                      │   │  │
│  │  │  ┌──────────────────────────────────────────────┐   │   │  │
│  │  │  │  Subnet (10.0.1.0/24)                        │   │   │  │
│  │  │  │  ┌──────────────────────────────────────┐    │   │   │  │
│  │  │  │  │  Ubuntu VM (Standard_B2s)            │    │   │   │  │
│  │  │  │  │                                      │    │   │   │  │
│  │  │  │  │  ┌──────────────────────────────┐    │    │   │   │  │
│  │  │  │  │  │  .NET 8 Runtime              │    │    │   │   │  │
│  │  │  │  │  │  ┌──────────────────────┐    │    │    │   │   │  │
│  │  │  │  │  │  │  Rayan Web App       │    │    │    │   │   │  │
│  │  │  │  │  │  │  (Kestrel :5000)     │    │    │    │   │   │  │
│  │  │  │  │  │  └──────────────────────┘    │    │    │   │   │  │
│  │  │  │  │  │  Managed by: systemd         │    │    │   │   │  │
│  │  │  │  │  └──────────────────────────────┘    │    │   │   │  │
│  │  │  │  └──────────────────────────────────────┘    │   │   │  │
│  │  │  └──────────────────────────────────────────────┘   │   │  │
│  │  └─────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

        ▲                                          ▲
        │  SSH (port 22)                           │  HTTP (port 5000/80)
        │                                          │
   ┌────┴────┐                               ┌────┴────┐
   │  Admin  │                               │  Users  │
   └─────────┘                               └─────────┘
```

---

## Prerequisites

Before starting, make sure you have the following installed on your **local machine**:

1. **Azure CLI** - [Install guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
   ```bash
   az --version
   ```

2. **.NET SDK 8.0+** - [Download](https://dotnet.microsoft.com/download)
   ```bash
   dotnet --version
   ```

3. **Git** - [Download](https://git-scm.com/downloads)
   ```bash
   git --version
   ```

4. **SSH key pair** - Generate if you don't have one:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
   ```

5. **Azure subscription** - A free student account works.

---

## Project Structure

```
azure-dotnet-deployment/
├── README.md                          # This file
├── SECURITY.md                        # Security documentation
├── .gitignore                         # Git ignore rules for .NET
├── src/
│   └── WebApp/                        # ASP.NET Core MVC application
│       ├── Controllers/
│       │   └── HomeController.cs
│       ├── Models/
│       │   └── ErrorViewModel.cs
│       ├── Views/
│       │   ├── Home/
│       │   │   ├── Index.cshtml       # Landing page (displays "Rayan")
│       │   │   └── Privacy.cshtml
│       │   └── Shared/
│       │       └── _Layout.cshtml     # Main layout template
│       ├── Program.cs                 # Application entry point
│       └── WebApp.csproj              # Project file
├── infrastructure/
│   ├── vm-template.bicep              # Azure Bicep template
│   └── vm-template.parameters.json    # Parameters for deployment
├── scripts/
│   ├── setup-dotnet.sh                # .NET Runtime installation
│   └── deploy-app.sh                  # Application deployment
├── config/
│   └── webapp.service                 # Systemd service definition
└── docs/
    └── screenshots/                   # Deployment screenshots
```

---

## Step-by-Step Deployment Guide

### Step 1: Clone the Repository

```bash
git clone https://github.com/<your-username>/azure-dotnet-deployment.git
cd azure-dotnet-deployment
```

### Step 2: Test the Application Locally

```bash
cd src/WebApp
dotnet run
```

Open your browser and go to `http://localhost:5033`. You should see the **Rayan** landing page.

### Step 3: Login to Azure

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### Step 4: Create a Resource Group

```bash
az group create \
    --name rayan-rg \
    --location northeurope
```

### Step 5: Deploy the VM with Bicep

First, edit the parameters file and add your SSH public key:

```bash
# View your public key
cat ~/.ssh/id_rsa.pub
```

Copy the key and paste it into `infrastructure/vm-template.parameters.json` replacing `<REPLACE_WITH_YOUR_SSH_PUBLIC_KEY>`.

Then deploy:

```bash
az deployment group create \
    --resource-group rayan-rg \
    --template-file infrastructure/vm-template.bicep \
    --parameters infrastructure/vm-template.parameters.json
```

Save the outputs (Public IP, FQDN) from the deployment.

### Step 6: Setup the VM

SSH into the VM and run the setup script:

```bash
# Get the VM's public IP from deployment output
VM_IP=$(az deployment group show \
    --resource-group rayan-rg \
    --name vm-template \
    --query 'properties.outputs.publicIpAddress.value' -o tsv)

echo "VM IP: $VM_IP"

# Copy and run the setup script
scp scripts/setup-dotnet.sh azureuser@$VM_IP:/tmp/
ssh azureuser@$VM_IP 'sudo bash /tmp/setup-dotnet.sh'
```

### Step 7: Deploy the Application

```bash
bash scripts/deploy-app.sh $VM_IP
```

This script will:
1. Build the .NET application for Linux
2. Transfer the files to the VM via SCP
3. Install the systemd service
4. Start the application
5. Verify it's running

### Step 8: Access the Application

Open your browser and navigate to:

```
http://<VM_IP>:5000
```

You should see the **Rayan** landing page running on Azure!

---

## Verification

### Check Application Status on the VM

```bash
# SSH into the VM
ssh azureuser@<VM_IP>

# Check service status
sudo systemctl status webapp

# View application logs
journalctl -u webapp -f

# Test locally on the VM
curl http://localhost:5000
```

### Check from Your Local Machine

```bash
curl -I http://<VM_IP>:5000
```

Expected response: `HTTP/1.1 200 OK`

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Cannot SSH into VM | Check NSG rules allow port 22. Verify SSH key is correct. |
| Application not responding | Run `sudo systemctl status webapp` and check for errors. |
| Port 5000 not accessible | Verify NSG allows port 5000. Check `ufw status` on VM. |
| .NET runtime not found | Re-run `setup-dotnet.sh`. Check with `dotnet --list-runtimes`. |
| Service fails to start | Check logs: `journalctl -u webapp -n 50`. Verify file permissions. |
| Build fails | Ensure .NET SDK is installed locally. Run `dotnet restore` first. |

---

## Security Considerations

See [SECURITY.md](SECURITY.md) for detailed security documentation.

Key security measures in this project:
- **SSH key authentication** (password login disabled)
- **Network Security Group** restricting traffic to ports 22, 80, and 5000 only
- **Non-root service execution** (app runs as `azureuser`)
- **Systemd security hardening** (NoNewPrivileges, PrivateTmp, ProtectSystem)

---

## Screenshots

> Add your screenshots in the `docs/screenshots/` directory.

| Step | Screenshot |
|------|------------|
| Local testing | `docs/screenshots/local-testing.png` |
| Azure portal - VM overview | `docs/screenshots/azure-vm-overview.png` |
| Azure portal - NSG rules | `docs/screenshots/azure-nsg-rules.png` |
| Deployed application | `docs/screenshots/deployed-app.png` |
| SSH terminal session | `docs/screenshots/ssh-session.png` |

---

## License

This project is created for educational purposes as part of a university course.
