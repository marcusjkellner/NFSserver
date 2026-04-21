# NFSserver
authors: Marcus & Ivo

# Infrastructure
<toplogy-png>
## Proxmox
To create and host our infrastructure we use Proxmox in our repective homelab environments.
This means that we need to expose IP-addresses to variables in order to adapt our code for both setups. 

For our VMs we have created a template from cloud-init. It's a Ubuntu server 22.04.5 LTS / jammy

In order to use terraform we both needed to create separate terraform API-keys. These are never uploaded to github.

Tailscale: In order to access our proxmox host for the on-site presentation, we will connect to one of our homelabs using Tailscale.

## Terraform
We use Terraform from our respective workstations to create our infrastructure. These are the VMs we create:

### VM:ansible-controller
RAM: 4096 MB
Cores: 2
Disk: 10

This is the first VM we create in terraform. The other VM's are dependant on this VM in order to be created.
The ansible-controller generates an SSH keypair and injects the public key into Terraform so the following VM's will allow the
controller to SSH into them with Ansible.

On creatation, the system is updated and ansibler is installed.
Terrform will also git clone our public repository in order to access the ansible code.
The last Terraform action is to create a dynamic inventory.ini-file based on the local IP-addresses we have enetered into a secret
variable file called terraform.tfvars.

From here, all configuration is done using ansible on the ansible controller.

Manual steps at the point of writing:
ansible controller: switch to development branch: 01-NFSserver
ansible controller: start each playbook manually
    - 01_nfs_install
    - 02_nfs_users
    - 03_nfs_shares
    - 04_nfs_exports

### VM:fileserver
RAM: 2048 MB
Cores: 2
Disk: 20

After creation, ansible is used to install NFS, create users and groups, create the directories the users will share and start the NFS service

Directories:
/Shares
    /Shares/Common - all users can read and write
    /Shares/Legal - only Legal-group can read and write
    /Shares/Sales - nly Sales-group can read and write

### VM:client-legal
This VM will connect a Legal group user to access legal-files at a later point, right now it is only a standard ubuntu server install
RAM: 2048 MB
Cores: 2
Disk: 10

### VM:client-sales
This VM will connect a Sales group user to access sales-files at a later point, right now it is only a standard ubuntu server install
RAM: 2048 MB
Cores: 2
Disk: 10

# Ansible playbooks
01_nfs_install
    Updates the system with apt update and downloads nfs filserver.

02_nfs_users
    Creates two user groups: Legal and Sales.
    Creates two different users, one for Legal, (Anna_Legal) and one for Sales (Peter_Sales)

03_nfs_shares
    Creates three directory types: 
        /shares
            mode: 0755
                Root can read, write, enter
                Legal and Sales can read, enter, not write
                Others can read, enter, not write
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

04_nfs_exports
    Configures a permanent directory 'exports' that tells the NFS server the direcories to share and who can acess them, it also reloads the changed configuration and starts the the NFS server service.


# Security
It would be more ideal to use a certificate based approach rather than ssh-keys for creating trust between our vms.

We have added terraform.vars to .gitignore, it includes information about:
- API Keys
- Local OS
- Local IP-addresses
- Proxmox host

While we never upload this information to github it would be better to use hashicorp vault to store our secrets.

Currently we have no segmentation between our VMs. We could consider setting up VLANs and separate this project from the rest of our homelabs.





