_: {
  nixos =
    { config, lib, ... }:
    {
      security.pam.services.swaylock = {
        fprintAuth = config.services.fprintd.enable;
      }
      // lib.optionalAttrs config.services.fprintd.enable {
        rules.auth.fprintd.order = config.security.pam.services.swaylock.rules.auth.unix.order + 10;
      };
    };

  home =
    {
      config,
      nixosConfig,
      pkgs,
      ...
    }:
    let
      # Left-aligned clock that stays on screen in every auth state, with a
      # state-coloured underline instead of the rotating ring/arc.
      clockPatch = pkgs.writeText "swaylock-effects-clock.patch" ''
        --- a/render.c
        +++ b/render.c
        @@ -221,13 +221,15 @@
         			cairo_fill(cairo);
         		}
         
        -		// Fill inner circle
        -		cairo_set_line_width(cairo, 0);
        -		cairo_arc(cairo, buffer_width / 2, buffer_diameter / 2,
        -				arc_radius - arc_thickness / 2, 0, 2 * M_PI);
        -		set_color_for_state(cairo, state, &state->args.colors.inside);
        -		cairo_fill_preserve(cairo);
        -		cairo_stroke(cairo);
        +		if (!state->args.clock) {
        +			// Fill inner circle
        +			cairo_set_line_width(cairo, 0);
        +			cairo_arc(cairo, buffer_width / 2, buffer_diameter / 2,
        +					arc_radius - arc_thickness / 2, 0, 2 * M_PI);
        +			set_color_for_state(cairo, state, &state->args.colors.inside);
        +			cairo_fill_preserve(cairo);
        +			cairo_stroke(cairo);
        +		}
         
         		// Draw ring
         		cairo_set_line_width(cairo, arc_thickness);
        @@ -301,6 +303,13 @@
         			break;
         		}
         
        +		// Keep the clock on screen while a fingerprint/password is checked.
        +		if (state->args.clock) {
        +			text = NULL;
        +			timetext(surface, &text_l1, &text_l2);
        +			cairo_set_source_u32(cairo, state->args.colors.text.input);
        +		}
        +
         		if (text_l1 && !text_l2)
         			text = text_l1;
         		if (text_l2 && !text_l1)
        @@ -327,17 +336,14 @@
         			}
         		} else if (text_l1 && text_l2) {
         			cairo_text_extents_t extents_l1, extents_l2;
        -			cairo_font_extents_t fe_l1, fe_l2;
         			double x_l1, y_l1, x_l2, y_l2;
         
        -			/* Top */
        +			/* Clock follows --font-size. */
        +			cairo_set_font_size(cairo, font_size);
         
         			cairo_text_extents(cairo, text_l1, &extents_l1);
        -			cairo_font_extents(cairo, &fe_l1);
        -			x_l1 = (buffer_width / 2) -
        -				(extents_l1.width / 2 + extents_l1.x_bearing);
        -			y_l1 = (buffer_diameter / 2) +
        -				(fe_l1.height / 2 - fe_l1.descent) - arc_radius / 10.0f;
        +			x_l1 = (buffer_width / 2) - arc_radius - extents_l1.x_bearing;
        +			y_l1 = -extents_l1.y_bearing;
         
         			cairo_move_to(cairo, x_l1, y_l1);
         			cairo_show_text(cairo, text_l1);
        @@ -346,31 +352,44 @@
         
         			/* Bottom */
         
        -			cairo_set_font_size(cairo, arc_radius / 6.0f);
        +			cairo_set_font_size(cairo, font_size / 2.0f);
         			cairo_text_extents(cairo, text_l2, &extents_l2);
        -			cairo_font_extents(cairo, &fe_l2);
        -			x_l2 = (buffer_width / 2) -
        -				(extents_l2.width / 2 + extents_l2.x_bearing);
        -			y_l2 = (buffer_diameter / 2) +
        -				(fe_l2.height / 2 - fe_l2.descent) + arc_radius / 3.5f;
        +			x_l2 = (buffer_width / 2) - arc_radius - extents_l2.x_bearing;
        +			y_l2 = extents_l1.height + 18 * surface->scale - extents_l2.y_bearing;
         
         			cairo_move_to(cairo, x_l2, y_l2);
         			cairo_show_text(cairo, text_l2);
         			cairo_close_path(cairo);
         			cairo_new_sub_path(cairo);
         
        -			if (new_width < extents_l1.width)
        -				new_width = extents_l1.width;
        -			if (new_width < extents_l2.width)
        -				new_width = extents_l2.width;
        +			/* Underline: grey when idle, blue while typing, then state. */
        +			if (state->auth_state == AUTH_STATE_IDLE ||
        +					state->auth_state == AUTH_STATE_GRACE) {
        +				cairo_set_source_u32(cairo, state->args.colors.inside.caps_lock);
        +			} else {
        +				set_color_for_state(cairo, state, &state->args.colors.inside);
        +			}
        +			cairo_set_line_width(cairo, arc_thickness);
        +			double ux = buffer_width / 2 - arc_radius;
        +			double uy = y_l2 + extents_l2.y_bearing + extents_l2.height
        +				+ 16 * surface->scale;
        +			cairo_move_to(cairo, ux, uy);
        +			cairo_line_to(cairo, ux + extents_l1.width, uy);
        +			cairo_stroke(cairo);
        +
        +			/* Left-aligned text may extend past the original circle's right edge. */
        +			if (new_width < 2 * extents_l1.width)
        +				new_width = 2 * extents_l1.width;
        +			if (new_width < 2 * extents_l2.width)
        +				new_width = 2 * extents_l2.width;
         
         
         			cairo_set_font_size(cairo, font_size);
         		}
         
         		// Typing indicator: Highlight random part on keypress
        -		if (state->auth_state == AUTH_STATE_INPUT
        -				|| state->auth_state == AUTH_STATE_BACKSPACE) {
        +		if (!state->args.clock && (state->auth_state == AUTH_STATE_INPUT
        +				|| state->auth_state == AUTH_STATE_BACKSPACE)) {
         
         			static double highlight_start = 0;
         			if (state->indicator_dirty) {
      '';
    in
    {
      stylix.targets.swaylock.enable = true;
      stylix.targets.swaylock.colors.enable = false;

      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ clockPatch ];
        });
        settings =
          let
            colors = config.lib.stylix.colors;
            transparent = "00000000";
          in
          {
            daemonize = true;
            fade-in = 0.25;
            font = nixosConfig.stylix.fonts.sansSerif.name;
            font-size = 80;
            ignore-empty-password = !nixosConfig.services.fprintd.enable;

            clock = true;
            timestr = "%H:%M";
            datestr = "%A, %B %d";

            indicator = true;
            indicator-radius = 120;
            indicator-thickness = 6;
            indicator-x-position = 184;
            indicator-y-position = 187;

            color = colors.base00;

            # Underline: grey idle, blue while typing, then state colours.
            # inside-caps-lock-color doubles as the idle colour.
            inside-color = colors.base0D;
            inside-ver-color = colors.base0B;
            inside-clear-color = colors.base0A;
            inside-wrong-color = colors.base08;
            inside-caps-lock-color = colors.base04;

            ring-color = transparent;
            ring-clear-color = transparent;
            ring-caps-lock-color = transparent;
            ring-ver-color = transparent;
            ring-wrong-color = transparent;

            line-color = transparent;
            line-clear-color = transparent;
            line-caps-lock-color = transparent;
            line-ver-color = transparent;
            line-wrong-color = transparent;
            separator-color = transparent;

            text-color = colors.base05;
            text-clear-color = colors.base04;
            text-caps-lock-color = colors.base0A;
            text-ver-color = colors.base0B;
            text-wrong-color = colors.base08;

            layout-bg-color = "${colors.base00}d9";
            layout-border-color = transparent;
            layout-text-color = colors.base05;
          };
      };
    };
}
