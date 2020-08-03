## Terraform ADFS environment

### OverView

I've been looking at Terraform for a while now, working up different environments and actually using it in the work place a couple of times. This code produces an environment for ADFS.

I found the following article on the microsoft docs site and decided to use this as blueprint for  quick practice build.

[The original article](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/deployment/how-to-connect-fed-azure-adfs)

the basic environment has 4 servers, 2 ADFS/DC and 2 WAP servers, I decided that I wouldn't in real life put ADFS onto a DC so i added two servers as DC's so the full compliment of servers is 6, servers split as table below


| Role       | Number         | Virtual Network  |
| ------------- |:-------------:| :-----|
| Domain Controllers     | 2 | Internal |
| ADFS      | 2     |   Internal |
| WAP | 2      |    DMZ |

### Pre Reqs

The terraform.tfvars file needs to be created, there is an example file that lists the values required.


### Resources Built

#### Virtual Network
The network contains 3 Subnets, the main network range is 10.0.0.0/22, broken down i the below table

| Subnet Name     | Range        | Use  |
| ------------- |:-------------| :-----|
|DMZ     | 10.0.1.0/24|Used for WAP Servers|
|   Internal   | 10.0.2.0/24     |Used for all other Servers |
| AzureBastionSubnet | 10.0.3.0/24     |Used for Bastion Server |

#### Availability sets

An availability set is created for all 3 pairs of servers to make sure that the service is maintained

#### Network Security Groups

Two network security Groups are created one is assigned to the internal and one to the DMZ to control traffic to both subnets, Default rules are created to allow traffic to the servers

| NSG     | Rule        | Target  |
| ------------- |:-------------| :-----|
|DMZ     | HTTP port 80 |For external facing load balancer to send traffic to the WAP servers|
|Internal   | HTTP Port 443 and 80    |Used fro traffic between the WAPS and the ADFS servers |

#### Storage Accounts

A storage accounts is created so that boot diagnostics can be captured for all servers

### Servers

The servers are all divided into modules , first and foremost, it shows how modules are used and secondly it keeps the main.tf a little more readable and neat.

#### WAPS - Web Application Proxy

In the WAP server module the following is built

1. External Facing load balancer.
2. External Load balancer Public IP
3. Backend pool to contain the two servers for load balancing
4. Probe rule
5. Load balancing for the traffic to port 80 on the servers
6. Two Servers are built
7. Finally a custom script job is created and the Web Application Proxy is installed to both servers, with IIS for testing

#### ADFS Servers

1. Internal Facing load balancer.
2. Backend pool to contain the two servers for load balancing
3. Probe rule
4. Load balancing for the traffic to port 80 and 443 on the servers
5. Two Servers are built
6. Finally a custom script job is created and the ADFS is installed to both servers, with IIS for testing

#### Domain Controllers

There's no need for load balancing here and up to now nothing is installed onto the two servers

1. Two Servers are built


### Bastion Server

This is a reasonably new to me Bastion servers on Azure. I added this as a practice, much better than having a jump server and fairly easy to set up, with the security managed for you except for teh ability to connect and that can be managed through roles.

This service is set up in its own Resource group and REQUIRES a subnet named AzureBastionServer which we create when we build the whole environment, so the ADFS terraform will be ran first, then run the bastion terraform

the code builds

1. The resource group to contain the bastion server service
2. The Public IP for the bastion server service
3. The Bastion Server service itself

