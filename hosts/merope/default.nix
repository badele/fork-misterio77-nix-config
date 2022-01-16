# System configuration for my Raspberry Pi 4
{ config, pkgs, system, inputs, ... }:

let nur = import inputs.nur { nurpkgs = import inputs.nixpkgs { inherit system; }; };
in
{
  imports = [
    nur.repos.misterio.modules.argonone
    inputs.hardware.nixosModules.raspberry-pi-4
    inputs.sistemer-bot.nixosModule
    inputs.paste-misterio-me.nixosModule

    ./hardware-configuration.nix
    ../common
    ../common/postgres.nix

    ./sistemer-bot.nix
    ./nginx.nix
    ./ddclient.nix
    ./paste-misterio-me.nix
    ./wireguard.nix
    ./minecraft.nix
  ];

  # Static IP address
  networking.networkmanager.extraConfig = ''
    [ipv4]
    address1=192.168.77.10/24
  '';

  # Open ports for nginx
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Passwordless sudo (for remote build)
  security.sudo.extraConfig = "%wheel ALL = (ALL) NOPASSWD: ALL";

  # Enable argonone fan daemon
  hardware.argonone.enable = true;
}
