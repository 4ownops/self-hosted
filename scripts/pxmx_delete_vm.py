import sys
from proxmoxer import ProxmoxAPI
from os import environ
import argparse

def argparser():
    parser = argparse.ArgumentParser(description="Script removes existing VM. \
                                     All parameters are required or use environment variables instead if supports")
    parser.add_argument("-proxmox_url", nargs="?", help="Proxmox url with port. Example: 192.168.0.10:8006. Env variable: PROXMOX_URL", default="")
    parser.add_argument("-proxmox_user", nargs="?", help="Proxmox api user with @pam. Example: root@pam. Env variable: PROXMOX_USER", default="")
    parser.add_argument("-proxmox_password", nargs="?", help="Proxmox api user password. Env variable: PROXMOX_PASSWORD", default="")
    parser.add_argument("-vm_id", type=int, help="VM id which removes. Type int")
    args = parser.parse_args()
    return args

def arg_checker(var, env_var: str):
    if not var:
        var = environ[env_var]
        try:
            var = environ[env_var]
        except KeyError as e:
            raise SystemExit('You should set parameters or environment variables.\nRun this script with -h parameter for detailed information.')
    return var

def main():
    node_name = "pve"
    args = argparser()
    proxmox_host = arg_checker(args.proxmox_url, "PROXMOX_URL")
    proxmox_api_user = arg_checker(args.proxmox_user, "PROXMOX_USER")
    proxmox_api_password = arg_checker(args.proxmox_password, "PROXMOX_PASSWORD")
    proxmox = ProxmoxAPI(proxmox_host, user=proxmox_api_user, password=proxmox_api_password, verify_ssl=False)
    vms = proxmox.nodes(node_name).qemu.get()
    for vm in vms:
        if vm["vmid"] == args.vm_id:
            print(f"Deleting node with id {args.vm_id}...")
            proxmox.nodes(node_name).qemu.delete(args.vm_id)
            print("Done")
            sys.exit(1)
    print(f"VM with id {args.vm_id} does not found.\nNothing to do.")

if __name__ == "__main__":
    main()
