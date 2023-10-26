import pulumi_proxmoxve as proxmox
from pulumi import ResourceOptions
from os import environ

provider = proxmox.Provider(
        resource_name="proxmox_provider",
        endpoint="https://proxmox:8006",
        insecure="true",
        username=environ.get("proxmox_api_user"),
        password=environ.get("proxmox_api_password")
)

virtual_machine = proxmox.vm.VirtualMachine(
    opts=ResourceOptions(provider=provider),
    name="giteaserver",
    resource_name="vm",
    node_name="pve",
    vm_id="5000",
    agent=proxmox.vm.VirtualMachineAgentArgs(
        enabled=True,
        trim=True,
        type="virtio"
    ),
    bios="seabios",
    cpu=proxmox.vm.VirtualMachineCpuArgs(
        cores=1,
        sockets=1
    ),
    clone=proxmox.vm.VirtualMachineCloneArgs(
        node_name="pve",
        vm_id=102,
        full=True
    ),
    disks=[
        proxmox.vm.VirtualMachineDiskArgs(
            interface="scsi0",
            datastore_id="disks",
            size=30,
            file_format="raw"
        )
    ],
    memory=proxmox.vm.VirtualMachineMemoryArgs(
        dedicated=1024
    ),
    network_devices=[
        proxmox.vm.VirtualMachineNetworkDeviceArgs(
            bridge="vmbr0",
            model="virtio"
        )
    ],
    on_boot=True,
    operating_system=proxmox.vm.VirtualMachineOperatingSystemArgs(type="l26"),
    initialization=proxmox.vm.VirtualMachineInitializationArgs(
        type="nocloud",
        datastore_id="data",
        user_account=proxmox.vm.VirtualMachineInitializationUserAccountArgs(
            username="root",
            password="packer"
        )
    )
)