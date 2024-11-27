{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.virtualisation.azureImage;
in
{
  imports = [
    ./azure-common.nix
    ./disk-size-option.nix
    (lib.mkRenamedOptionModuleWith {
      sinceRelease = 2411;
      from = [
        "virtualisation"
        "azureImage"
        "diskSize"
      ];
      to = [
        "virtualisation"
        "diskSize"
      ];
    })
  ];

  options.virtualisation.azureImage = {
    bootSize = mkOption {
      type = types.int;
      default = 256;
      description = ''
        ESP partition size. Unit is MB.
        Only effective when vmGeneration is `v2`.
      '';
    };

    contents = mkOption {
      type = with types; listOf attrs;
      default = [ ];
      description = ''
        Extra contents to add to the image.
      '';
    };

    label = mkOption {
      type = types.str;
      default = "nixos";
      description = ''
        NixOS partition label.
      '';
    };

    vmGeneration = mkOption {
      type =
        with types;
        enum [
          "v1"
          "v2"
        ];
      default = "v1";
      description = ''
        VM Generation to use.
        For v2, secure boot needs to be turned off during creation.
      '';
    };
  };

  config = {
    system.build.azureImage = import ../../lib/make-disk-image.nix {
      name = "azure-image";
      postVM = ''
        ${pkgs.vmTools.qemu}/bin/qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $diskImage $out/disk.vhd
        rm $diskImage
      '';
      configFile = ./azure-config-user.nix;
      format = "raw";

      bootSize = lib.mkIf (cfg.vmGeneration == "v2") "${toString cfg.bootSize}M";
      partitionTableType = if (cfg.vmGeneration == "v2") then "efi" else "legacy";

      inherit (cfg) contents label;
      inherit (config.virtualisation) diskSize;
      inherit config lib pkgs;
    };

    boot.growPartition = true;
    boot.loader.grub = rec {
      efiSupport = (cfg.vmGeneration == "v2");
      device = if efiSupport then "nodev" else "/dev/sda";
      efiInstallAsRemovable = efiSupport;
      font = null;
      splashImage = null;
      extraConfig = lib.mkIf (!efiSupport) ''
        serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
        terminal_input --append serial
        terminal_output --append serial
      '';
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/${cfg.label}";
        fsType = "ext4";
        autoResize = true;
      };

      "/boot" = lib.mkIf (cfg.vmGeneration == "v2") {
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
      };
    };
  };
}
