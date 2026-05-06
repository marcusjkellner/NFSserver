# Automated NFS-Fileserver Lab
    Project Name: Automated NFS-Fileserver Lab
    Authors: Marcus Kellner & Ivo Urbanovics
    Class: ITS25
    Course: Virtualization & Automation 
    Date: 2026-05-06 
    Branch: 08-polish2 
This is a lab built by Marcus and Ivo during the spring of 2026 as part of a vocational university course called Virtualization and Automation ("Virtualiseringsteknik och Automation" in Swedish). 

The project will instruct a Proxmox server to create several virtual machines using Terraform and configures the VMs with Ansible to install one NFS fileserver and two NFS client VMs. Two groups of users are created, shares are created on the fileserver and mounted automatically on the clients. Permissions and qoutas are assigned per group.

Our purpose was to learn how to create and document infrastructure as code while being able to manage it effectively by keeping idempotency preserved. The project also served as an introduction to working with GIT using the terminal and we have chosen to preserve our development branches to document our progress.

Total time spent is about four working weeks, including time spent learning Git-basics.

## Table of Contents
- [Project Architecture](#project-architecture)
- [Environment variables & Secrets](#environment-variables-&-secrets)
- [Folder Structure](#folder-structure)
- [System Requirements](#system-requirements)
- [Getting Started](#getting-started)
- [Project Components](#project-components)
- [Verification](#verification)
- [Security](#security)
- [Design Choices](#design-choices)

## Project Architecture
![Description](./topology-07.jpg)

## Environment variables & Secrets
See the file "template.tfvars", copy this file and rename it as "terraform.tfvars". Do NOT upload this info into Github ever, terraform.tfvars has been added to .gitignore to prevent this. <br>
    os_type = "windows" 
    //OS-type, can be set to "windows" or "mac"

    api_token       = "" 
    //You need to create an API token in proxmox for terraform use and enter it here
    
    ssh_public_key  = "" 
    //Enter a public ssh key for your workstation host

    endpoint        = "https://192.168.1.200:8006"
    //IP for proxmox endpoint

    nodename        = "pve" 
    //local proxmox nodename

    VMTemplateID    = 1100 
    //The VM-template ID of the cloud-init you want to use for the base of all VM's.
    //We recommend using Ubuntu 24.4.04 "Jammy"

    vm_gateway      = "192.168.1.1" 
    //Enter the IP of your default gateway (likely your ISP router IP) 

    controller_ip   = "192.168.1.41/24" //Ansible control node
    fileserver_ip   = "192.168.1.42/24" //NFS fileserver
    clientLegal_ip  = "192.168.1.43/24" //Legal client VM
    clientSales_ip  = "192.168.1.44/24" //Sales client VM
    //These are the IPs that will be used for VMs.
    //Notice that they all needto be on the same subnet.

## Folder Structure
![Description](./folder_structure.jpg)

## System Requirements
### Proxmox VE hypervisor
    Proxmox version: 9.1.1
    Project Hardware requirements:  11GB RAM, 60GB Disk
    Cloud-Init template: Ubuntu 22.04.5 LTS / "jammy" 

### Workstation Computer
    OS: Windows 10/11 or macOS Tahoe 26.4
    Software:
        Terraform version: 1.14.8
        Git version: 2.53.0

## Getting Started 
### 1. Clone repository from Github
    git clone https://github.com/marcusjkellner/NFSserver.git
    cd NFSserver 
Download the repository to your workstation, see requirements above.

### 2. Create the shared secrets/env-variables file from template
    cp /terraform/template.tfvars /terraform/terraform.tfvars
    nano /terraform/terraform.tfvars    
Copy the template secrets-file and edit terraform.tfvars with your own environment variables and API-keys. Keep this file secret and local.

### 3. Start VM creation using Terraform
    cd terraform 
    terraform init 
    terraform validate
    terraform plan
    terraform apply  
These instructions will initialize Terraform in the terraform-folder, check for syntax problems and the apply command will start the building process once you type "yes" to confirm. Note: The creation process takes about 6 minutes.

### 4. SSH into VM: ansible-controller
    ssh controller@192.168.1.41
Once complete, it's time to SSH into the ansible controller node.

IMPORTANT NOTE: The IP 192.168.1.41 is the default-template for controller_ip and must match your environment variables in terraform.tfvars!

### 5. Git Pull and Run site.yml to start all playbooks
    cd ~/NFSserver/ansible 
    ansible-playbook site.yml
The Controller should already have the latest version of this repository downloaded. Move into /ansible and run site.yml. It contains all playbooks necessary for the remaining configuration. 

### 6. Verify lab functionality (See verify-section for more info)
    ansible-playbook verify.yml
Once the playbook is finished you can run a separate playbook called verify.yml which will run a few tests verifying the UFW-configuration, user permissions and disk qouta. For more details see "Verification" below.

## Project Components
### Workstation: Windows or Mac
We use Terraform from our respective workstations to create our infrastructure.

### Hypervisor: Proxmox node
To create and host our infrastructure we use Proxmox in our repective homelab environments.
This means that we need to expose IP-addresses to variables in order to adapt our code for both setups. 

For our VMs we have created a template from cloud-init. It's a Ubuntu server 22.04.5 LTS / jammy

In order to use terraform we both needed to create separate terraform API-keys. These are never uploaded to github.

Tailscale: In order to access our proxmox host for the on-site presentation, we will connect to one of our homelabs using Tailscale.

### VM: Ansible Controller
    Name:   ansible-controller
    ID:     2041    
    RAM:    4096 MB 
    Cores:  2 
    Disk:   10 

This is the first VM we create in terraform. The other VM's are dependant on this VM in order to be created.

The ansible-controller generates an SSH keypair and injects the public key into Terraform so the following VM's will allow the controller to SSH into them with Ansible.

On creatation, the system is updated and ansible is installed.
After this, ansible galaxy is forced to update to 2.5.9 and the old version 1.3.6 is removed.

Terrform will also git clone our public repository in order to access the ansible code.
The last Terraform action is to create a dynamic inventory.ini-file based on the local IP-addresses we have enetered into a secret variable file called terraform.tfvars.

From here, all configuration is done using ansible on the ansible controller.

Manual steps at the point of writing:

    ssh controller@192.168.1.41
    cd /NFSserver/ansible 
SSH into ansible_controller and move into the /ansible directory before running the ansible playbooks.<br>
Note: If you changed the IP for ansible_controller in terraform.vars, make sure you use the IP you entered there.

1. Run site.yml to start Ansible configuration playbooks:

        ansible-playbook site.yml

2. Run verify.yml to verify that permissions, firewall rules and connectivity are working.

        ansible-playbook verify.yml

### VM: NFS Fileserver
    Name:   fileserver
    ID:     2042
    RAM:    2560 MB 
    Cores:  2 
    Disk:   20 GB (10 GB OS + 10 GB Filestorage) 

After creation, we format a separate partition for filestorage as /shares with support for quotas using Ansible. Ansible is used to install NFS, create users and groups, create the directories the users will share and start the NFS service.

Directories on fileserver:

    /shares
        /shares/Common - all users can read and write 
        /shares/Legal - only Legal-group can read and write 
        /shares/Sales - only Sales-group can read and write 

The last playbook sets quota limits for groups and users, but currently only the group quotas are applied succesfully.

### VM: Legal Department Client PC
    Name:   client-legal
    ID:     2043
    RAM:    2560 MB
    Cores:  2 
    Disk:   10 GB  

This VM is a standard ubuntu server install. Here we create users and groups with identical UID and GID to match the ones created on the fileserver. 

Currently users Anna_Legal and Peter_Sales are created on both clients and the fileserver simultaneusly.

### VM: Sales Department Client PC
    Name:   client-sales
    ID:     2044
    RAM:    2560 MB
    Cores:  2 
    Disk:   10 GB

This VM is a standard ubuntu server install. Here we create users and groups with identical UID and GID to match the ones created on the fileserver. 

Note: Currently users Anna_Legal and Peter_Sales are created on both clients and the fileserver simultaneusly.
### Terraform files
**main.tf**<br>

**clients.tf**<br>

**template.tfvars**<br>

**terraform.tfvars**<br>

**variables.tf**<br>

**versions.tf**<br>

**providers.tf**<br>

### Ansible files
**ansible.cfg**<br>
Configuration file for Ansible.

    [defaults]
    inventory = inventory.ini
    host_key_checking = False
    pipelining = true

- inventory.ini is set as the default inventory.
- host key checking is disabled for ansible in order to let ansible to SSH without fingerprinting.
- pipelining is set to true in order for our verify-script to change users when performing the tests.

**inventory.ini**<br>
This file is used to define roles with IPs, users and SSH key locations. In this project we generate the ansible inventory file upon running main.tf in order to inject user defined IP-addresses from the environment variables set in terraform.tfvars.

### Ansible playbooks
**01_nfs_install.yml**<br>
Updates the system with apt update, downloads nfs filserver and quote tools.

**02_nfs_users.yml**
Creates two user groups: Legal and Sales.

Creates two different users, one for Legal, (Anna_Legal) and one for Sales (Peter_Sales).

Each group and user are assigned their explicit GID and UID.

Note: These groups and users are created identically on the fileserver and all clients.

**03_nfs_setup_disk.yml**

    Creates a new partition and formats it for use with the quote-system.

    Creates the /shares directory on the new partition and mounts /shares for file storage.
    There are checks that measures if the disk is present and have been formatted at least once in order to preserve ideompotency.
    
        /shares 
            mode: 0755
                Root can read, write, enter
                Legal and Sales can read, enter, not write
                Others can read, enter, not write
    /etc/fstab is configured for automount on reboot.

**04_nfs_shares.yml**

    Creates three directory types: 

        /shares/Common 
            mode: 0775
                Root can read, write, enter
                Legal and Sales can read, write, enter
                Others can read, write, enter
        /shares/Legal
            mode: 0770
                Root can read, write, enter
                Legal can read, write, enter
                Others blocked
        /shares/Sales
            mode: 0770
                Root can read, write, enter
                Sales can read, write, enter
                Others blocked

**05_nfs_exports.yml**

    Configures an 'exports' directory that tells the NFS server what directories to share and who can acess them, it also reloads the changed configuration and starts the the NFS server service.

**06_nfs_ufw.yml**

    Installs the NFS-client package on all clients.

**07_client_install.yml**

    Installs the NFS-client package on all clients.

**08_client_mount.yml**

    Creates mounting points on all clients:
    /mnt/Common
    /mnt/Legal
    /mnt/Sales

**09_client_shares.yml**

    Mounts mnt/shares on all clients to reference the directories on the fileserver:
        /mnt/Common > fileserver /shares/Common
        /mnt/Legal > fileserver /shares/Legal
        /mnt/Sales > fileserver /shares/Sales

**10_nfs_quotas.yml**

    Remounts /shares on the fileserver and sets quotas for both groups and users:
        Create quota files
        Turn the quotas on
        Set quote for group-Legal max 5GB
        Set quote for group-Sales max 5GB
        Set quote for Anna_Legal max 1.2 GB 
        Set quote for Peter_Sales max 1.2 GB 

**site.yml**

    This playbook runs a test to verify lab's functionality, for details please reference the Verification section below.
 
**verify.yml**

    This playbook runs a test to verify lab's functionality, for details please reference the Verification section below.
    

## Verification
The verification playbook contains 4 separate plays designed to act as users Anna_Legal and Peter_Sales to demonstrate our lab's functionality.
### Verification Steps
Step 1:

    Netcat is used to check ports on the VMs according to the UFW-rules. They check that the controller VM can use port 22 to reach all other VMs and that the fileserver is allowing port 2049 for NSF traffic from the client VMs.

Step 2:

    Anna (a user from the Legal group) creates files in /Common and /Legal

Step 3:

    Peter (a user from the Sales group) views her files in /Common, creates his own file, tries to open /Legal but is denied, proceeds to /Sales and creates a file there.

Step 4:

    Fileserver creates a quota-report of the storage used to display the limits and how much storage is spent.

### Expected Terminal output
Firewall Test:

        "=======================================",
        "===    UFW FIREWALL TEST SUMMARY    ===",
        "=======================================",
        "FILESERVER:",
        "  NFS (2049) from controller  → BLOCKED : PASS ✅",
        "  NFS (2049) from clientLegal → ALLOWED : PASS ✅",
        "  NFS (2049) from clientSales → ALLOWED : PASS ✅",
        "  SSH (22)   from controller  → ALLOWED : PASS ✅",
        "  SSH (22)   from clientLegal → BLOCKED : PASS ✅",
        "  SSH (22)   from clientSales → BLOCKED : PASS ✅",
        "======================================="

Qouta Report:

        "=======================================",
        "===    VERIFICATION SUMMARY         ===",
        "=======================================",
        "  /mnt/Common → CAN write    : PASS ✅",
        "  /mnt/Legal  → CAN write    : PASS ✅",
        "  /mnt/Sales  → ACCESS DENIED: PASS ✅",
        "---------------------------------------",
        "PETER_SALES (from clientSales):",
        "  /mnt/Common → CAN write    : PASS ✅",
        "  /mnt/Sales  → CAN write    : PASS ✅",
        "  /mnt/Legal  → ACCESS DENIED: PASS ✅",
        "=======================================",
        "======================================="

User Permissions Report:

        "=======================================",
        "===    VERIFICATION SUMMARY         ===",
        "=======================================",
        "  /mnt/Common → CAN write    : PASS ✅",
        "  /mnt/Legal  → CAN write    : PASS ✅",
        "  /mnt/Sales  → ACCESS DENIED: PASS ✅",
        "---------------------------------------",
        "PETER_SALES (from clientSales):",
        "  /mnt/Common → CAN write    : PASS ✅",
        "  /mnt/Sales  → CAN write    : PASS ✅",
        "  /mnt/Legal  → ACCESS DENIED: PASS ✅",
        "=======================================",
        "======================================="

## Security
## Security Measures Taken
In our lab there is a following security measures applied:

1. API token is created on the Proxmox and placed on the tfvars file that provides a secure connection from the Desktop to the Proxmox hypervisor without any root credentials. 


2. Root login is only allowed with SSH key and password login is disabled. Expected output: permitrootlogin without-password

        sudo sshd -T | grep permitrootlogin


3. Password login is not allowed, only with SSH-key. The SHH keys for all VMs are generated on the creation of Controller VM that secures the Controller's connection with Fileserer, Legal and Sales VMs without password. Expected output: passwordauthentication: no <br>

        sudo sshd -T | grep passwordauthentication


4. UFW firewall is active on Filesever VM. Expected output: Status: active. SSH (port 22) connection allowed-in from Controller VM only. NFS (port  2049) allowed-in connection from Clients' (Legal and Sales) VMs port. Default: deny (incomming). No outgoing traffic is blocked. <br>

        sudo ufw status verbose


5. Client firewall is active on both Clients' VMs. Expected output, example on Client_Legal. Satus: Active. SSH (port 22) connection allowed-in from Controller VM only. Default: deny (incomming). No outgoing traffic is blocked. <br>

        sudo ufw status verbose 


6. Role Based Access Control (RBAC) setup.  Legal and Sales groups have least priviledge permissions to the NFS shares folder based on their roles. Expected output. Users /shares/Common: drwxrwxr-x.  group_Legal /shares/Legal: drwxrws---  .  group_Sales /shares/Sales: drwxrws---  . For more description please view Verify file output. 


7. Disk quotas and partition on the Fileserver is set to the hard disk that prevents denial of service by disk exhaustion. Since NFS shares is stored on a separate partition any disc exhaustion attack is limited and the OS partition is unaffected. <br>

        lsblk | grep -E "sda|sdb"


8. Secrets management. All the secret-relevant information is placed under nfsserver/terraform.tfvars and nfsserver/terraform.tfstate and stored only locally. Additionally both files is added to .gitignore and never stored in the git repository. Must be deployed from Desktop or Controller VM <br>

        cd NFSserver 
        cat .gitignore 
        
### Security Vulnerbility Analysis
#### 1. No Certificates, only SSH-keys
It would be more ideal to use a certificate based approach rather than ssh-keys for creating trust between our vms. An internally signed TLS certificate is more secure since SSH keys can get stolen or leaked my mistake.

**Solution:**

We could set up a CA to issue our internal TLS certificate or use party service if it was a production environment.

**Why this is acceptible:**

The lab network is not directly exposed to the internet and no SSH keys are available online.

#### 2. No Network Segmentation
Currently we have no segmentation between our VMs. We could consider setting up VLANs and separate this project from the rest of our homelabs.<br>
Solution: In production the fileserver should be separated on an isolated network/vlan without internet access. The client-groups (Legal/Sales) could also be set to their own vlan to restrict lateral movement. <br>
Why this is acceptible: We prioritized functionality over hardening. Instead we used UFW to enforce default deny incoming traffic. <br>
#### 3. No Encryption in transit btween clients and fileserver
Since NFS is sent in plaintext it is possible to intercept, tamper with or clone the information in transit. 
Solution: In production the information could be encrypted before transmission, a VPN tunnel could be set up or we could switch to SAMBA <br>
Why this is acceptible: In this lab we have not prioritized encryption and the only files on the server are for testing purposes <br>
#### No Encryption at rest
At the moment we do not encrypt data on the fileserver at rest. This means that anyone with access to the disk can read the files on the server in plaintext.
Solution: We could use encryption like LUKS to encypt data at rest but would need a different solution for data in transit.<br>
Why this is acceptible: In this lab we have not prioritized encryption and the only files on the server are for testing purposes <br>
#### No outgoing UFW rules
In this lab we wanted to include UFW rules and opted to implement default deny incoming traffic on fileserver and clients. There are no rules enforcing outgoing traffic atm and this means its possible for an attacker or malware exfiltrate information from the fileserver.
Solution: Configure firewall rules that default deny incoming and outgoing traffic and only allow traffic that is needed. <br>
Why this is acceptible: We did not want prioritize configuring firewall rules for this lab and will revisit the firewall in the upcoming hardening course. <br>
#### No NFS user Authentication
There is no strong authentication for users Anna_Legal and Peter_Sales, this means they cannot log in to their computers. It also means that you could spoof user identity by copying their UID/GID and stealing their SSH key.
Solution: Generate default passwords for each user and require them to set strong passwords upon logging in for the first time. MFA and/or AD could also be used for stronger authentication.<br>
Why this is acceptible: We do not want to add default credentials to the lab and we can use ansible to simulate them creating files for verification. <br>
#### No backup of NFS fileserver contents
The contents of the fileserver is not backed up on a separate VM, a separate physical device or a separate physical site. This means that any data on the fileserver is lost upon VM destruction.
Solution: Create one backup that is read-only locally, one that is encrypted on a cloud server and one that is mirrored to an off-site location NAS. <br>
Why this is acceptible: The files on the fileserver are only used for testing in this lab andd we did not want to dedicate resources for hardening these files. <br>

Other misc vulnerbilities:
- Host key checking is disabled for ansible, this means fingerprinting is not required for SSH
    - This can be solved by pre-populating a known-hosts file during initial provisioning.
- No strong SSH-key password
- Root Access through SSH
- Root-privileges allow for total control of all files
- No audit logging or monitoring
- Missing fail2Ban to protect against password bruteforce
- All members in "users" group can write to /Common
- Missing Ansible Tower features

## Design Choices

### Design and topology
Focus on the basic concepts working, not volume or hardening. 
### Packages Used
Workstations:

    Git version: 2.53.0
    //To commit project code to public git-repo

    Terraform version: 1.14.8
    //To run Terraform files with Proxmox

ansible-controller:

    Git version: 2.53.0 
    //To clone public repo from Github

    Ansible version: 2.10.8
    //To run Ansible Playbooks in git-repo

    Ansible Galaxy version: 2.5.9
    //[Parted] module: partition management
    //[Filesystem] module: disk formatting
    //[UFW] module: UFW firewall rules.


fileserver:

    NFS-kernel-serve version: 1:2.6.1-1ubuntu1.2
    //To start the NFS-service 

    Quota Utilities version: 4.06
    //To create quotas on the filestorage-partition

client-legal & client-sales 

    NFS-common version: 1:2.6.1-1ubuntu1.2
    //To interface with the NFS service from clients


### Proxmox Terraform vs Virtualbox and Vagrant
We wanted to learn how to use Proxmox and use a type 1 hypervisor in order to get the most out of the spare computers we keep at home. Using Proxmox with Terraform also seemed closer to reality and working with a cloud production.

We got to learn about using Cloud-Init and setting up our own ubuntu template. We do not rely on pre-installed packages but wanted to get everything needed. 

### Multiplatform and customized network project 
We choosed to build the home-lab on our own hardware, using customized own networks and OS for Desktop access. Thats why there are used creation of the ansible inventory file locally.

### VPN / Tailscale
In order to work remotely we choosed a Tailscale VPN solution, for that we created a separate Tailscele VM.

### NFS vs Samba
NFS is Linux based only and was easyer to set up for this project. Samba would have been a better option for use with Active Directory and Windows clients.

#### NFS Protocol
In our lab we are using the NFS-protocol. It works well, when high performance is needed and the enviroment is Linux-exclusive. However, the protocol not very secure on its own:
- There is no encryption for data at rest or data in transit.
- It is possible for anyone with physical access to sniff the trafic in plaintext or even tamper with it.
- There is no strong authentication, NFS relies on GID and UID which can be spoofed
- If the system is exposed to the internet and/or untrusted users locally NFS needs to be combined with other means of encryption, segmentation and authentication to be considered secure. 

#### Samba Protocol
SMB/Samba is better if the environment is shared between Linux and Windows users. It comes with authentication through Active Directory, but that also means Active Directory needs to be configured and managed. It supports encryption through SMB3 and is better suited for connected office environments.

#### When to use NFS over Samba
If all devices run Linux and are isolated from other networks and the internet it provides fast file transefer and feels simillar to using your own local storage. 

#### How to improve NFS security
- Encrypt data in transit using a VPN or simillar service like Kerberos
- Segment the devices using NFS onto their own network
- Encrypt the data at rest with separate encryption method, like LUKS
Note: Every measure that fascilitates ecryption will come with a hit to perfromance and convenience, either through distribution of encryption keys or passwords.

### Playbook design
We choose to split our playbooks in to 10 separate steps. This fraqtionality allowed us to build the project in steps and keep things separate that allowed us to test the performance and error handling under the way.

### Groups and users
We choose to create two user groups and with one user to each group. This enables role-based permissions and keep our project simple. 

### Verification 
We choose to simulate users attemting to create files in their own and others' directories. Also we simulated their permission rights to their own and the other's direcotries  access directory. The verification is performed with ansible code to proove the indepontence. A quota report is printed a the end of the simulation to prove each user-group quota is working before deleting the simulation files. 

During the verification we also ensure to use netcat to check ports on the VMs from clients and controller in order to verify the different UFW rules we have set in place. The rules are currently pretty rudimentary and is focused on setting default deny on incoming traffic to the fileserver and clients while maintaining functionality over SSH and NFS ports.



