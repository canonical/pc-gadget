# The recovery partition

On Ubuntu Core 20 systems there is a new system-recovery partition. It
is big enough to contain a certain number of recovery "systems" that
can then be used to recover or reinstall a broken system.

A full "seed" to reinstall on a generic amd64 system is roughly 280MB
so the recovery partition is sized to 600MB to be able to store two
recovery systems by default.

The system-recovery partition is next to the system-boot
partition. Both are vfat as required by UEFI.

On full disk encrypted systems the system-boot partition contains the
unpacked kernel(s) to boot init initramfs that then unencrypts the
"writable" partition. The partitions are separate because we want to
write to the recovery partition as rarely as possible to avoid
filesystem issues.

# Recovery system file layout

The revery partition contains the following file layout:

/system/<name>/snaps/{base.snap,kernel.snap,other...}
/system/<name>/assertions/<short-name>

Where <name> is an encoded date/time like 20190521-1213. The parition
is FAT so we need to put the assertions in the "stream" format on disk
with a short name. The assertion files must include exactly one model
assertion.

The names of the kernel and the base are fixed. This allows
us a static grub.cfg menu. The selection of the recovery system will
happen at a later time from initramfs. To do this the recovery system
will boot into a sepecial "select" mode and then the selection is set
via a grubenv "snap_recovery_system="

All snaps in snaps/ must be verifiable using the assertions.txt
stream and they will be checked during a "recovery" or "install"
boot.

# Boot sequence

This section describes the operations without taking the TPM into
account for now. This will change in a later revision of this doc.

* always boot into system-recovery partition
** check if system is setup for normal booting
*** if so, chainboot into the system-boot partition
*** if not, boot into recovery bootmode, set snap_mode="recovery"
**** later the initamfs will allow selecting different recovery systems

We always boot into the system-recovery partition. It contain the
/efi/BOOT/BOOTX64.EFI (shim.efi.signed) and grubx86.efi. We will
present a boot menu with the modes "Normal", "Recovery", "Install".

The "normal" boot mode will just chainboot into the system-boot
partition and load "grub" from there.


## Normal bootmode

No changes to today, TPM operations will have to be added.

## Install mode

Similar to "firstboot" mode we have today. The differences:
* explicitly enabled via `snap_recovery_mode == "install"`
* requires mounting:
** create "writable" with a new FDE key
** mount "writable" to the right place
** the "right" directory /var/lib/snapd/seed from the recovery partition


## Recovery mode

* explicitly enabled via `snap_recovery_mode == "recovery"`
* requires mounting:
** unlock /writable to a different mount point
** create tmpfs on ${rootmnt}/writable
** mount the right recovery seed into /var/lib/snapd/seed
** do an "install" into tmpfs to have all snapd available (e.g. nm)


# Testing

Hacky way to test this:
```
$ wget https://people.canonical.com/~mvo/tmp/mvo-amd64.signed
$ snap download pc-kernel=18 core18 snapd
$ cd pc-amd64-gadget
$ snapcraft
$ cd ..
$ ubuntu-image mvo-amd64.signed --extra-snaps ./pc_20-0.1_amd64.snap --extra-snaps ./pc-kernel_*.snap --extra-snaps ./core18_*.snap --extra-snaps ./snapd_*.snap
# use the OVMF.fd from bionc - disco will fail to start
$ kvm -m 1400 -snapshot  -bios /usr/share/qemu/OVMF.fd  pc.img 
```
