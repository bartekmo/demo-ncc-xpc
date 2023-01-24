terraform code for deployment of a demo/PoC. Features included:
- multi-nic FGT
- A-A
- external VPN termination
- BGP to multiple internal (shared) VPCs

Template deploys:
- 4 internal networks (and a handful of subnets):
    - 2 as NCC spokes (prod and comm)
    - 2 with standard routing via ILB (dev, test). Mind the mix of 2 different routing approaches between these VPCs!
- public, transit, fgsp networks
- 2 FGTs in active-active mode with FGSP for state sync
- ELB in public VPC with a single frontend
- NCC hub with 2 ra spokes (prod and comm); each spoke has a cloud router with 2 NICs
- 8 emulated branches - each with its own VPC, a single-NIC FGT and a single linux VM for testing connectivity; all branches are connected using static IPSec to FGTs in the hub (via ELB)



All FortiGates are deployed with FlexVM licensing. Replace the tokens before re-deployment or change licensing to different scheme:
- using BYOL licenses: modify configuration template files to remove the MIME multi-part and add metadata license field with contents of .lic files (already working with fortigate-fgsp-aaa module using var.license_files, not working with branches module)
- using PAYG licensing: use *-payg image family instad of *-byol (var.image_family in fortigate-fgsp-aaa)
