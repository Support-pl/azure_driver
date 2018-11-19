# OpenNebula Azure Driver for ARM(Azure Resource Manager)

## Installing

 * Download and unpack or clone the repository
 * Put the directories content in the next way:
   ```bash
    mv hooks/* ~oneadmin/remotes/hooks
    mv im/* ~oneadmin/remotes/im
    mv lib/* /usr/lib/one/ruby
    mv vmm/* ~oneadmin/remotes/vmm
    mv etc/* /etc/one
   ```
   Don't forget to set `chmod +x ` for all executables(vmm/*, im/*, hooks/*)
 * Add the following lines to `oned.conf`
    ```bash
    # IM section
    IM_MAD = [
      NAME          = "azure",
      SUNSTONE_NAME = "Microsoft Azure(ARM)",
      EXECUTABLE    = "one_im_sh",
      ARGUMENTS     = "-t 15 -r 1 azure" ]

    # VMM section
    VM_MAD = [
    NAME           = "azure",
    SUNSTONE_NAME  = "Microsoft Azure(ARM)",
    EXECUTABLE     = "one_vmm_sh",
    ARGUMENTS      = "-t 15 -r 0 azure",
    TYPE           = "xml",
    KEEP_SNAPSHOTS = "no",
    IMPORTED_VMS_ACTIONS = "terminate, terminate-hard, hold, release, resume, delete, reboot, resched, unresched, poweroff"
    ]

    # HOOKs section
    VM_HOOK = [
    name      = "adjust_size",
    on        = "CREATE",
    command   = "azure/adjust_size.rb",
    arguments = "$ID"
    ]

    VM_HOOK = [
        name      = "complete_terminate",
        on        = "CUSTOM",
        state     = "ACTIVE",
        lcm_state = "EPILOG_FAILURE",
        command   = "azure/complete_terminate.rb",
        arguments = "$ID"
    ]

    VM_HOOK = [
        name      = "set_image_name",
        on        = "CREATE",
        command   = "azure/set_image_name.rb",
        arguments = "$ID"
    ]
    ```
 * Restart OpenNebula from CLI `systemctl restart opennebula`
 * Fill `azure_driver.conf` with your Azure subscription(s) data

## Template

Add to Templates basic template:
```bash
CPU = "1"
CPU_COST = "1"
DESCRIPTION = "Azure VM Template"
INPUTS_ORDER = "OS_DISK_SIZE,OS_IMAGE,USER_OS_NAME,VM_USER_NAME,PASSWORD,SIZE,PUBLIC_IP,ALLOW_PORTS,LOCATION"
MEMORY = "1"
MEMORY_COST = "1"
MEMORY_UNIT_COST = "MB"
OS = [
  BOOT = "" ]
PUBLIC_CLOUD = [
  IMAGE = "$OS_IMAGE<->$USER_OS_NAME", # If USER_OS_NAME empty, uses OS_IMAGE
  INSTANCE_TYPE = "$SIZE", # SKU name
  LOCATION = "$LOCATION",
  RESOURCE_GROUP = "opennebula-default",
  SUBNET = "default",
  TYPE = "AZURE",
  VM_PASSWORD = "$PASSWORD",
  VM_USER = "$VM_USER_NAME" ]
SUNSTONE = [
  NETWORK_SELECT = "NO" ]
USER_INPUTS = [
  ALLOW_PORTS = "O|text|Comma-separated list of allowed connections names, supported: SSH(22), HTTP(80), HTTPS(443), RDP(3389):",
  CPU = "O|fixed|| |1",
  LOCATION = "M|list|VM Location|Southeast Asia,Australia East,Australia Southeast,Brazil South,Canada Central,North Europe,West Europe,Central India,South India,West India,Japan East,Japan West,UK South,UK West,Central US,South Central US,West US 2,West Central US|West Europe",
  MEMORY = "O|fixed|| |1",
  OS_DISK_SIZE = "M|range|VM Disk Size in GB|30..4000|30",
  OS_IMAGE = "O|list|OS name(choose from list below or type in the next field)|  ,Canonical_UbuntuServer_14.04.5-LTS,Canonical_UbuntuServer_16.04-LTS,Canonical_UbuntuServer_18.04-LTS,RedHat_RHEL_6.10,RedHat_RHEL_6.7,RedHat_RHEL_6.8,RedHat_RHEL_6.9,RedHat_RHEL_7-LVM,RedHat_RHEL_7.2,RedHat_RHEL_7.3,RedHat_RHEL_7.4,OpenLogic_CentOS_6.10,OpenLogic_CentOS_6.5,OpenLogic_CentOS_6.6,OpenLogic_CentOS_6.7,OpenLogic_CentOS_6.8,OpenLogic_CentOS_6.9,OpenLogic_CentOS_7.0,OpenLogic_CentOS_7.1,OpenLogic_CentOS_7.2,OpenLogic_CentOS_7.3,OpenLogic_CentOS_7.4,OpenLogic_CentOS_7.5,credativ_Debian_7,credativ_Debian_8,credativ_Debian_9,MicrosoftWindowsDesktop_Windows-10_RS3-Pro,MicrosoftWindowsDesktop_Windows-10_rs3-pro-test,MicrosoftWindowsDesktop_Windows-10_RS3-ProN,MicrosoftWindowsDesktop_Windows-10_rs4-pro,MicrosoftWindowsDesktop_Windows-10_rs4-pron,MicrosoftWindowsDesktop_Windows-10_rs5-pro,MicrosoftWindowsDesktop_Windows-10_rs5-pron,MicrosoftWindowsServer_WindowsServer_2008-R2-SP1,MicrosoftWindowsServer_WindowsServer_2008-R2-SP1-smalldisk,MicrosoftWindowsServer_WindowsServer_2008-R2-SP1-zhcn,MicrosoftWindowsServer_WindowsServer_2012-Datacenter,MicrosoftWindowsServer_WindowsServer_2012-Datacenter-smalldisk,MicrosoftWindowsServer_WindowsServer_2012-Datacenter-zhcn,MicrosoftWindowsServer_WindowsServer_2012-R2-Datacenter,MicrosoftWindowsServer_WindowsServer_2012-R2-Datacenter-smalldisk,MicrosoftWindowsServer_WindowsServer_2012-R2-Datacenter-zhcn,MicrosoftWindowsServer_WindowsServer_2016-Datacenter,MicrosoftWindowsServer_WindowsServer_2016-Datacenter-Server-Core,MicrosoftWindowsServer_WindowsServer_2016-Datacenter-Server-Core-smalldisk,MicrosoftWindowsServer_WindowsServer_2016-Datacenter-smalldisk,MicrosoftWindowsServer_WindowsServer_2016-Datacenter-with-Containers,MicrosoftWindowsServer_WindowsServer_2016-Datacenter-with-RDSH,MicrosoftWindowsServer_WindowsServer_2016-Datacenter-zhcn|",
  PASSWORD = "M|password|VM Password(between 12 and 72 characters long)",
  PUBLIC_IP = "M|boolean|Attach Public IP?| |YES",
  SIZE = "M|list|VM Instance Size|Standard_A0,Standard_A1,Standard_A2,Standard_A3,Standard_A5,Standard_A4,Standard_A6,Standard_A7,Basic_A0,Basic_A1,Basic_A2,Basic_A3,Basic_A4,Standard_A10,Standard_A8_v2,Standard_A2_v2,Standard_A8m_v2,Standard_A4_v2,Standard_A4m_v2,Standard_A8,Standard_A9,Standard_A1_v2,Standard_A2m_v2,Standard_A11,Standard_B1ms,Standard_B1s,Standard_B2ms,Standard_B4ms,Standard_B8ms,Standard_B2s,Standard_DS13-2_v2,Standard_D2s_v3,Standard_DS11,Standard_DS12,Standard_DS13,Standard_DS14,Standard_D1_v2,Standard_D2_v2,Standard_D3_v2,Standard_D4_v2,Standard_D5_v2,Standard_D11_v2,Standard_D12_v2,Standard_D13_v2,Standard_D14_v2,Standard_D15_v2,Standard_D2_v2_Promo,Standard_D3_v2_Promo,Standard_D4_v2_Promo,Standard_D5_v2_Promo,Standard_D11_v2_Promo,Standard_D12_v2_Promo,Standard_D13_v2_Promo,Standard_D14_v2_Promo,Standard_DS2,Standard_DS1,Standard_D14,Standard_D13,Standard_D64s_v3,Standard_D12,Standard_D11,Standard_D4,Standard_D3,Standard_D2,Standard_D1,Standard_DS1_v2,Standard_DS2_v2,Standard_DS3_v2,Standard_DS4_v2,Standard_DS5_v2,Standard_DS11-1_v2,Standard_DS11_v2,Standard_DS12-1_v2,Standard_DS12-2_v2,Standard_DS12_v2,Standard_DS3,Standard_DS13-4_v2,Standard_DS13_v2,Standard_DS14-4_v2,Standard_DS14-8_v2,Standard_DS14_v2,Standard_DS15_v2,Standard_DS2_v2_Promo,Standard_DS3_v2_Promo,Standard_DS4_v2_Promo,Standard_DS5_v2_Promo,Standard_DS11_v2_Promo,Standard_DS12_v2_Promo,Standard_DS13_v2_Promo,Standard_DS14_v2_Promo,Standard_D64_v3,Standard_D32s_v3,Standard_D16s_v3,Standard_D8s_v3,Standard_D4s_v3,Standard_D2_v3,Standard_D4_v3,Standard_D8_v3,Standard_D16_v3,Standard_D32_v3,Standard_DS4,Standard_E32-16s_v3,Standard_E32s_v3,Standard_E64-16s_v3,Standard_E64-32s_v3,Standard_E64is_v3,Standard_E16-8s_v3,Standard_E4_v3,Standard_E8_v3,Standard_E16_v3,Standard_E20_v3,Standard_E32_v3,Standard_E64i_v3,Standard_E64_v3,Standard_E32-8s_v3,Standard_E20s_v3,Standard_E16s_v3,Standard_E64s_v3,Standard_E2s_v3,Standard_E4-2s_v3,Standard_E4s_v3,Standard_E8-2s_v3,Standard_E8-4s_v3,Standard_E8s_v3,Standard_E16-4s_v3,Standard_E2_v3,Standard_F72s_v2,Standard_F8,Standard_F1,Standard_F16s,Standard_F8s,Standard_F4s,Standard_F2s,Standard_F1s,Standard_F16,Standard_F2s_v2,Standard_F4s_v2,Standard_F8s_v2,Standard_F16s_v2,Standard_F32s_v2,Standard_F64s_v2,Standard_F4,Standard_F2,Standard_G2,Standard_GS5-16,Standard_GS5-8,Standard_G1,Standard_GS5,Standard_G3,Standard_G4,Standard_G5,Standard_GS1,Standard_GS2,Standard_GS3,Standard_GS4,Standard_GS4-4,Standard_GS4-8,Standard_H16,Standard_H16mr,Standard_H8m,Standard_H16m,Standard_H16r,Standard_H8,Standard_L16s,Standard_L8s,Standard_L4s,Standard_L8s_v2,Standard_L32s,Standard_L16s_v2,Standard_M128,Standard_M16ms,Standard_M16-8ms,Standard_M16-4ms,Standard_M8ms,Standard_M32-8ms,Standard_M32-16ms,Standard_M32ls,Standard_M32ms,Standard_M32ts,Standard_M64-16ms,Standard_M64-32ms,Standard_M64ls,Standard_M64ms,Standard_M64s,Standard_M128-32ms,Standard_M128-64ms,Standard_M128ms,Standard_M128s,Standard_M64,Standard_M64m,Standard_M8-4ms,Standard_M128m,Standard_M8-2ms,Standard_NC24r,Standard_ND24rs,Standard_ND24s,Standard_NC6s_v2,Standard_NC12s_v2,Standard_NC24rs_v2,Standard_NC24s_v2,Standard_ND6s,Standard_ND12s,Standard_NC24s_v3,Standard_NC6,Standard_NC12,Standard_NC24,Standard_NC24rs_v3,Standard_NC12s_v3,Standard_NC6s_v3,Standard_NV6,Standard_NV12,Standard_NV24|Standard_B1s",
  USER_OS_NAME = "O|text|Type your OS Image name here in publisher_offer_version format(don't forget to leave previous field blank)",
  VCPU = "O|fixed|| |1",
  VM_USER_NAME = "M|text|VM Admin Username" ]
VCPU = "1"
```

> After resource group created, every VM, which will be deployed to it, must have the same location

> VM capacity sets on instantiate/create

## Available actions

 * Create
 * Power ON
 * Power OFF
 * Monitor(CPU, IP addresses)
 * Terminate
 * Reboot

## Create VM

Template variables review:

1. IMAGE

    Put here Azure Image ref in publisher_name_sku_version format.
    > version always defaults to `latest`.

2. INSTANCE_TYPE

    Put here Azure.VirtualMachineSize name(e.g. Standard_A0).

3. RESOURCE_GROUP

    Puts here the name of existing resource group, if it's not exists, it will be created.

4. TYPE

    Set to `AZURE`, hooks uses it for identification.

5. VM_USER

    New VM user name.
    > Remember, that Azure not accepts reserved word, such as root, admin and etc. If you'll choose one of them, VM will be not created.

6. VM_PASSWORD

    New VM user password. Password requirements could be found [here](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm).
    > Passwords with cyrillic symbols may cause errors.

7. ALLOW_PORTS

    Comma-separated list of ports, where inbound traffic should be allowed. Port names could be found at `AzureDriver::SECURITY_RULES`.
    > If not empty, will be created Network Security Group for this VM, and Network Security Rule for every port.

8. OS_DISK_SIZE

    VM OS disk size in Gigabytes.

9. PUBLIC_IP

    If `YES`, new _**Static**_ PublicIP address will be created and attached to VMs interface

## TO-DO

### 1. Transfer manager
To rule VMs driver, and make attach/detach and disk-snapshot-create/delete/revert actions available.
> Connected bugs: VMs create fails, when `CONTEXT = [...]` defined, and terminates with error
### 2. Network driver
To rule Azure VirtualNetworks from OpenNebula
### 3. Found another way to require `azure-sdk` quickly
Now driver uses minimal version of azure-sdk-for-ruby defined at `azure_driver/`, but it still do this in 1.5-2 seconds.