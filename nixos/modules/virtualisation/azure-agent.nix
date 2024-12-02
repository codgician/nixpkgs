{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.virtualisation.azure.agent;
in
{

  imports = [
    (mkChangedOptionModule
      [
        "virtualisation"
        "azure"
        "agent"
        "enable"
      ]
      [
        "services"
        "waagent"
        "enable"
      ]
    )
    (mkChangedOptionModule
      [
        "virtualisation"
        "azure"
        "agent"
        "verboseLogging"
      ]
      [
        "services"
        "waagent"
        "settings"
        "Logs"
        "Verbose"
      ]
    )
    (mkChangedOptionModule
      [
        "virtualisation"
        "azure"
        "agent"
        "mountResourceDisk"
      ]
      [
        "services"
        "waagent"
        "settings"
        "ResourceDisk"
        "Format"
      ]
    )
  ];

  ###### interface

  options.virtualisation.azure.agent = {
    enable = mkOption {
      default = false;
      description = "Whether to enable the Windows Azure Linux Agent.";
    };
    verboseLogging = mkOption {
      default = false;
      description = "Whether to enable verbose logging.";
    };
    mountResourceDisk = mkOption {
      default = true;
      description = "Whether the agent should format (ext4) and mount the resource disk to /mnt/resource.";
    };
  };

  ###### implementation

  config = lib.mkIf cfg.enable (
    lib.warn
      ''
        `virtualisation.azure.agent` provided by `azure-agent.nix` module has been replaced
        by `services.waagent` options, and will be removed in a future release.
      ''
      {
        services.waagent = {
          inherit (cfg) enable;
          settings = {
            Logs.Verbose = cfg.verboseLogging;
            ResourceDisk = lib.mkIf cfg.mountResourceDisk {
              Format = true;
              FileSystem = "ext4";
              MountPoint = "/mnt/resource";
            };
          };
        };
      }
  );
}
