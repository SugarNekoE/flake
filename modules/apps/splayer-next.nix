_: {
  home = { pkgs, ... }: {
    home.packages = with pkgs; [
      (unstable.splayer-next.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          cpalDevice="$(find "$cargoDepsCopy" \
            -path '*/cpal-0.18.2/src/host/pipewire/device.rs' -print)"
          if [ ! -f "$cpalDevice" ]; then
            echo "Expected exactly one CPAL 0.18.2 PipeWire device.rs" >&2
            exit 1
          fi

          substituteInPlace "$cpalDevice" --replace-fail \
          'properties.insert("node.group", format!("cpal-{}", std::process::id()));' \
          'properties.insert("node.group", format!("cpal-{}", std::process::id()));
            if matches!(direction, DeviceDirection::Output) {
              properties.insert(
                *pw::keys::NODE_RATE,
                format!("1/{}", config.sample_rate),
              );
            }'
        '';
      }))
    ];
  };
}
