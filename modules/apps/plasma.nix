{ inputs, ... }:
let
  waylandSessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };
in
{
  flake-file.inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs = {
      home-manager.follows = "home-manager";
      nixpkgs.follows = "nixpkgs";
    };
  };

  nixos =
    { config, pkgs, ... }:
    {
      environment.sessionVariables = waylandSessionVariables;

      services = {
        desktopManager.plasma6 = {
          enable = true;
          enableQt5Integration = true;
        };
        displayManager = {
          defaultSession = "plasma";
          plasma-login-manager = {
            enable = true;
            settings.Greeter.WallpaperPluginId = "org.kde.image";
          };
        };
        logind.settings.Login.IdleAction = "ignore";
      };

      environment.etc."plasmalogin.conf.d/zz-stylix-wallpaper.conf".text = ''
        [Greeter][Wallpaper][org.kde.image][General]
        Image=${config.stylix.image}
      '';

      programs.kde-pim.enable = false;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
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

      home.sessionVariables = waylandSessionVariables;
      systemd.user.sessionVariables = waylandSessionVariables;

      stylix = {
        cursor = lib.mkForce {
          name = "breeze_cursors";
          package = pkgs.kdePackages.breeze;
          size = 24;
        };

        targets.qt.enable = lib.mkForce false;
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

        startup.startupScript."1password" = {
          text = "1password --silent &";
          runAlways = true;
        };

        workspace.iconTheme = "breeze-dark";

        kwin = {
          edgeBarrier = 100;
          cornerBarrier = true;
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
            height = 42;
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
              {
                iconTasks.launchers = [
                  "applications:kitty.desktop"
                  "applications:org.kde.dolphin.desktop"
                  "applications:google-chrome.desktop"
                  "applications:wechat.desktop"
                  "applications:qq.desktop"
                  "applications:org.telegram.desktop.desktop"
                  "applications:com.discordapp.Discord.desktop"
                  "applications:slack.desktop"
                  "applications:bytedance-feishu.desktop"
                ];
              }
              {
                systemTray = {
                  icons.scaleToFit = false;
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
              {
                digitalClock = {
                  time.format = "24h";
                  date = {
                    enable = true;
                    format = "isoDate";
                  };
                };
              }
            ];
          }
        ];

        configFile = {
          breezerc.Common.RoundedCorners = false;
          kded_device_automounterrc.General = {
            AutomountEnabled = true;
            AutomountOnLogin = true;
            AutomountOnPlugin = true;
            AutomountUnknownDevices = true;
          };
          kdeglobals.General.TerminalService = "kitty.desktop";
          kdeglobals.KDE.AnimationDurationFactor = 0.5;
        };
      };
    };
}
