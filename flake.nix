{
  description = "Zen Browser (Twilight)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        runtimeLibs = with pkgs;
          [
            libGL
            libGLU
            libevent
            libffi
            libjpeg
            libpng
            libstartup_notification
            libvpx
            libwebp
            stdenv.cc.cc
            fontconfig
            libxkbcommon
            zlib
            freetype
            gtk3
            libxml2
            dbus
            xcb-util-cursor
            alsa-lib
            libpulseaudio
            pango
            atk
            cairo
            gdk-pixbuf
            glib
            udev
            libva
            mesa
            libnotify
            cups
            pciutils
            ffmpeg
            libglvnd
            pipewire
          ] ++ (with pkgs.xorg; [
            libxcb
            libX11
            libXcursor
            libXrandr
            libXi
            libXext
            libXcomposite
            libXdamage
            libXfixes
            libXScrnSaver
          ]);
        pname = "zen-browser";
        version = "twilight";
        arch = nixpkgs.lib.strings.removeSuffix "-linux" system;
      in with pkgs; {
        packages.default = stdenv.mkDerivation (finalAttrs: {
          pname = pname;
          version = version;

          src = builtins.fetchTarball {
            url =
              "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-${arch}.tar.xz";
          };

          nativeBuildInputs = [ makeWrapper copyDesktopItems wrapGAppsHook ];

          installPhase = ''
            mkdir -p $out/bin
            cp -r $src/* $out/bin
            install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
          '';

          fixupPhase = ''
            chmod u+rwx,go+rx $out/bin/*
            patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
            wrapProgram $out/bin/zen --set LD_LIBRARY_PATH "${
              pkgs.lib.makeLibraryPath runtimeLibs
            }" \
                            --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
              patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
              wrapProgram $out/bin/zen-bin --set LD_LIBRARY_PATH "${
                pkgs.lib.makeLibraryPath runtimeLibs
              }" \
                            --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
              patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
              wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${
                pkgs.lib.makeLibraryPath runtimeLibs
              }"
              patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
              wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${
                pkgs.lib.makeLibraryPath runtimeLibs
              }"
              patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
              wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${
                pkgs.lib.makeLibraryPath runtimeLibs
              }"
          '';

          meta = {
            description = "Zen browser";
            homepage = "https://zen-browser.app/";
            license = lib.licenses.mpl20;
            mainProgram = "zen";
          };
        });
        formatter = nixfmt-classic;
      });
}
