{
  description = "Zen Browser (Twilight)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zen-browser = {
      url = "https://github.com/zen-browser/desktop/releases/download/twilight/zen.linux-x86_64.tar.xz";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      zen-browser,
      self,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pname = "zen-browser";
      runtimeLibs =
        with pkgs;
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
        ]
        ++ (with xorg; [
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
      version = "twilight";
    in
    with pkgs;
    {
      overlay = (
        _: _: {
          zen = self.packages.x86_64-linux.default;
        }
      );

      packages.x86_64-linux.default = stdenv.mkDerivation (finalAttrs: {
        inherit pname version;

        src = zen-browser;
        nativeBuildInputs = [
          makeWrapper
          wrapGAppsHook3
        ];

        installPhase = ''
          mkdir -p $out/bin
          cp -r $src/* $out/bin
          install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
          mkdir -p $out/share/applications
          echo "[Desktop Entry]
          Name=Zen Browser (Twilight)
          Exec=zen %u
          Icon=$out/share/icons/hicolor/128x128/apps/zen.png
          Type=Application
          MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;application/x-xpinstall;application/pdf;application/json;
          StartupWMClass=zen-alpha
          Categories=Network;WebBrowser;
          StartupNotify=true
          Terminal=false
          X-MultipleArgs=false
          Keywords=Internet;WWW;Browser;Web;Explorer;
          Actions=new-window;new-private-window;profilemanager;new-tab;

          [Desktop Action new-tab]
          Name=Open a New Tab in existing window
          Exec=zen --new-tab %u

          [Desktop Action new-window]
          Name=Open a New Window
          Exec=zen --new-window %u

          [Desktop Action new-private-window]
          Name=Open a New Private Window
          Exec=zen --private-window %u

          [Desktop Action profilemanager]
          Name=Open the Profile Manager
          Exec=zen --ProfileManager %u" > $out/share/applications/zen.desktop
        '';

        fixupPhase = ''
          for file in "$out"/bin/{zen,zen-bin,glxtest,updater,vaapitest}; do
            chmod u+rwx,go+rx "$file"
            patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file"
            wrapProgram "$file" \
                --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"\
                --set MOZ_LEGACY_PROFILES 1\
                --set MOZ_ALLOW_DOWNGRADE 1\
                --set MOZ_APP_LAUNCHER zen
            chmod -w "$file"
          done
        '';

        meta = {
          description = "Zen is a firefox-based browser with the aim of pushing your productivity to a new level!";
          homepage = "https://zen-browser.app/";
          license = lib.licenses.mpl20;
          mainProgram = "zen";
          platforms = [ "x86_64-linux" ];
        };
      });

    }
    // flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    });
}
