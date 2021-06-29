# My NixOS configurations

Here's my ephemeral NixOS setup files.

I'm just starting out with Nix, so it's not too much (for now).

## Some details:

Inspired by [tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/), [erase your darlings](https://grahamc.com/blog/erase-your-darlings) and [encrypted btrfs root with opt-in state](https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html).

Works with a tmpfs root (and home, using [home-manager](https://github.com/nix-community/home-manager/)) file system, plus an encrypted btrfs partition with subvolumes for everything else: `nix` (Nix store), `data` (Persistent and writable documents, games, mounted with [impermanence](https://github.com/nix-community/impermanence/)) and `dotfiles` (This repo).

### Todos
- Learn flakes (seems cool)
- Improve secret management (for now it all depends on my pgp key stored on `data`, waiting on my yubikey)

## How to setup

Note: Remember to tweak (specially hostname and username) as necessary

### Create partitions
First, create your boot partition (usually vfat) and btrfs partition (i usually encrypt it).

We'll create a few subvolumes:
- `nix` For (disposable) nix store data, no need to set snapshots.
- `dotfiles` For configuration files, will be managed by home-manager as write-only, we'll also bind the `nixos` directory to `/etc/nixos` shortly. Intended to be tracked by git
- `data` For persistent data, will be mounted writable. I suggest setting up snpashots.

First mount your btrfs. Assuming you opened the encrypted btrfs partition at `nixenc`:
```
mount -t btrfs /dev/mapper/nixenv /mnt
```
Then, create subvolumes, and umount the partition when done:
```
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/dotfiles
btrfs subvolume create /mnt/data
umount /mnt
```

Of course, you can set this up in any other way you prefer, just remember to adapt the mount commands as necessary.

### Mountpoints

Time to mount (my ESP is at `/dev/nvme0n1p1`, and i'm assuming you find 2gb of tmpfs storage accetable):
```
mount -t tmpfs -o size=2G,mode=755 none /mnt

mkdir /mnt/{boot,nix,nixos,data,dotfiles}

mount /dev/nvme0n1p1 /mnt/boot

mount -o subvol=nix,compress=zstd,noatime /dev/mapper/nixenc /mnt/nix
mount -o subvol=dotfiles,compress=zstd,noatime /dev/mapper/nixenc /mnt/dotfiles
mount -o subvol=data,compress=zstd,noatime /dev/mapper/nixenc /mnt/data
```

### Base config

Clone the repo:
```
cd /mnt/dotfiles
git clone git@github.com:Misterio77/nix-config.git
```

Create your (hashed) password:
```
mkpasswd -m sha-512 > nixos/password.nix
```

Bind the dotfiles config to our new system `/etc/nixos`:
```
mkdir -p /mnt/etc/nixos
mount -o bind /mnt/dotfiles/nixos /mnt/etc/nixos
```

Finally, generate your hardware config: `nixos-generate-config --root /mnt`

### Install

You're ready to go! Just install it:
```
nixos-install --no-root-passwd
```

And reboot!
