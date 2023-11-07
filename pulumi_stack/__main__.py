import pulumi_proxmoxve as proxmox
from pulumi import ResourceOptions
from os import environ

provider = proxmox.Provider(
        resource_name="proxmox_provider",
        endpoint=f"https://{environ.get('PROXMOX_URL')}",
        insecure="true",
        username=environ.get("PROXMOX_API_USER"),
        password=environ.get("PROXMOX_API_PASSWORD")
)

virtual_machine = proxmox.vm.VirtualMachine(
    opts=ResourceOptions(provider=provider),
    name="k3smaster01",
    resource_name="vm",
    node_name="pve",
    vm_id="1001",
    agent=proxmox.vm.VirtualMachineAgentArgs(
        enabled=True,
        trim=True,
        type="virtio"
    ),
    bios="seabios",
    cpu=proxmox.vm.VirtualMachineCpuArgs(
        cores=2,
        sockets=1
    ),
    clone=proxmox.vm.VirtualMachineCloneArgs(
        node_name="pve",
        vm_id=103,
        full=True
    ),
    disks=[
        proxmox.vm.VirtualMachineDiskArgs(
            interface="scsi0",
            datastore_id="disks",
            size=20,
            file_format="raw"
        )
    ],
    memory=proxmox.vm.VirtualMachineMemoryArgs(
        dedicated=2048
    ),
    network_devices=[
        proxmox.vm.VirtualMachineNetworkDeviceArgs(
            bridge="vmbr0",
            model="virtio",
            mac_address="EA:53:B3:9F:A2:01"
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