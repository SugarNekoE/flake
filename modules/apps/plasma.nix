{ inputs, ... }:
{
  flake-file.inputs.runcat-kde = {
    url = "github:fioncat/kde-runcat/v0.4.0";
    flake = false;
  };

  flake-file.inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs = {
      home-manager.follows = "home-manager";
      nixpkgs.follows = "nixpkgs";
    };
  };

  nixos =
    { pkgs, ... }:
    {
      services = {
        desktopManager.plasma6 = {
          enable = true;
          enableQt5Integration = true;
        };
        displayManager = {
          defaultSession = "plasma";
          plasma-login-manager.enable = true;
        };
        logind.settings.Login.IdleAction = "ignore";
      };

      programs.kde-pim.enable = false;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        aurorae
        discover
        elisa
        khelpcenter
        konsole
        kwin-x11
        plasma-browser-integration
        plasma-keyboard
        plasma-workspace-wallpapers
        qtvirtualkeyboard
      ];
    };

  home =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

      stylix = {
        cursor = lib.mkForce {
          name = "breeze_cursors";
          package = pkgs.kdePackages.breeze;
          size = 24;
        };

        targets.kde = {
          enable = true;
          useWallpaper = true;
          decorations = "org.kde.breeze";
          decorationTheme = "";
          widgetStyle = "Breeze";
          applicationStyle = "default";
          plasmaWorkspacePackage = pkgs.kdePackages.plasma-workspace;
        };
      };

      programs.plasma = {
        enable = true;

        workspace.iconTheme = "breeze-dark";

        kwin = {
          effects = {
            blur.enable = false;
            translucency.enable = false;
            minimization.animation = "squash";
            desktopSwitching.animation = "fade";
            windowOpenClose.animation = "fade";
            wobblyWindows.enable = false;
            cube.enable = false;
            fallApart.enable = false;
            slideBack.enable = false;
          };
          virtualDesktops = {
            number = 4;
            rows = 1;
          };
          tiling.padding = 0;
          scripts.polonium.enable = false;
        };

        kscreenlocker = {
          autoLock = true;
          timeout = 30;
          passwordRequired = true;
          passwordRequiredDelay = 0;
          lockOnResume = true;
        };

        powerdevil = {
          AC = {
            powerButtonAction = "showLogoutScreen";
            autoSuspend.action = "nothing";
            dimDisplay.enable = false;
            turnOffDisplay = {
              idleTimeout = 1800;
              idleTimeoutWhenLocked = "immediately";
            };
          };
          battery = {
            powerButtonAction = "showLogoutScreen";
            autoSuspend.action = "nothing";
          };
          lowBattery = {
            powerButtonAction = "showLogoutScreen";
            autoSuspend.action = "nothing";
          };
          batteryLevels.criticalAction = "shutDown";
        };

        panels = [
          {
            location = "bottom";
            height = 30;
            floating = false;
            opacity = "opaque";
            hiding = "none";
            lengthMode = "fill";
            widgets = [
              {
                kickoff = {
                  icon = "start-here-kde-symbolic";
                  sortAlphabetically = true;
                  showButtonsFor.custom = [
                    "lock-screen"
                    "suspend"
                    "reboot"
                    "shutdown"
                  ];
                  showActionButtonCaptions = true;
                };
              }
              "org.kde.plasma.pager"
              "org.kde.plasma.icontasks"
              {
                systemTray = {
                  icons.scaleToFit = true;
                  items = {
                    extra = [
                      "org.kde.plasma.battery"
                      "org.kde.plasma.brightness"
                      "org.kde.plasma.bluetooth"
                      "org.kde.plasma.networkmanagement"
                      "org.kde.plasma.volume"
                    ];
                    shown = [
                      "org.kde.plasma.battery"
                      "org.kde.plasma.brightness"
                      "org.kde.plasma.bluetooth"
                      "org.kde.plasma.networkmanagement"
                      "org.kde.plasma.volume"
                    ];
                  };
                };
              }
              "org.kde.plasma.digitalclock"
            ];
          }
        ];

        configFile = {
          breezerc.Common.RoundedCorners = false;
          kdeglobals.KDE.AnimationDurationFactor = 0.5;
        };
      };
    };
}
