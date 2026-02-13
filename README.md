# ⚠️ Recommended Deployment Order

Proceed step by step:

1. **First, comment out the creation of the Customer Gateway on the Scaleway side** and the `aws.tf` file. This allows you to retrieve the public IP of the Scaleway VPN Gateway.
2. **Then, uncomment on the AWS side** to get the tunnel IP address.
3. **Finally, provide the correct PSK** to finalize the link (retrieve the Scaleway PSK and set it on the AWS side).

# Step-by-step guide: AWS <-> Scaleway Site-to-Site VPN

This guide explains how to deploy a site-to-site VPN tunnel between AWS and Scaleway using Terraform, following best practices from the official guide.

## Prerequisites
- Access to an AWS and a Scaleway account
- Terraform installed
- Access to AWS and Scaleway credentials

## 1. Prepare variables

- Fill in access variables in `scaleway.auto.tfvars` and AWS variables in your environment files.
- Set the AWS VPC CIDR in `aws_plage` (e.g.: `10.1.0.0/16`).

## 2. Deploy Scaleway infrastructure

```sh
terraform init
terraform apply
```
- This will create the VPC, private network, public gateway, Kapsule cluster, and VPN gateway on the Scaleway side.

## 3. Deploy AWS infrastructure

- Make sure the `scw_vpn_public_ip` variable matches the public IP of the Scaleway gateway.
- Run:
```sh
terraform init
terraform apply
```
- This will create the VPC, subnets, customer gateway (pointing to Scaleway), VPN gateway, and VPN connection on the AWS side.

## 4. Retrieve BGP and tunnel parameters

- After applying AWS, retrieve the outputs:
	- `aws_vpn_tunnel1_address`: AWS tunnel public IP
	- `aws_vpn_tunnel1_vgw_inside_address`: AWS BGP IP
	- `aws_vpn_tunnel1_cgw_inside_address`: Scaleway BGP IP
	- `aws_vpn_tunnel1_preshared_key`: generated PSK (if not overridden)

## 5. Configure the Customer Gateway and connection on Scaleway

- In `main.tf` on the Scaleway side, set:
	- `cgw_ip` = `aws_vpn_tunnel1_address`
	- `private_ip` = `aws_vpn_tunnel1_cgw_inside_address/30`
	- `peer_private_ip` = `aws_vpn_tunnel1_vgw_inside_address/30`

- Apply the configuration:
```sh
terraform apply
```

## 6. Retrieve the Scaleway PSK

- After applying Scaleway, retrieve the PSK:
```sh
terraform output scw_vpn_psk
```

## 7. Synchronize the PSK on AWS

- Pass the Scaleway PSK value to the `scw_vpn_psk` variable on AWS (via a `.tfvars` file or environment variable).
- Re-run:
```sh
terraform apply
```

## 8. Verification

- Check the VPN tunnel status in the AWS and Scaleway consoles.
- Test network connectivity between the two VPCs.

---

**Notes:**
- For each tunnel, repeat the steps with the values of the second tunnel.
- Adjust CIDR, ASN, and parameters according to your architecture.
- To automate output synchronization between the two stacks, use the `terraform_remote_state` provider.
