{
  inputs = {
    hyprland.url = "github:hyprwm/hyprland";

    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = {
    self,
    hyprland,
    nix-filter,
    ...
  }: let
    inherit (hyprland.inputs) nixpkgs;
    forHyprlandSystems = fn: nixpkgs.lib.genAttrs (builtins.attrNames hyprland.packages) (system: fn system nixpkgs.legacyPackages.${system});
  in {
    packages = forHyprlandSystems (system: pkgs: let
      hyprlandPackage = hyprland.packages.${system}.hyprland;
    in rec {
      hyprgreen = pkgs.gcc14Stdenv.mkDerivation {
        pname = "hyprgreen";
        version = "1.0.0";
        src = nix-filter.lib {
          root = ./.;
          include = [
            "src"
            ./Makefile
          ];
        };

        nativeBuildInputs = with pkgs; [ pkg-config ];
        buildInputs = [hyprlandPackage.dev] ++ hyprlandPackage.buildInputs;

        installPhase = ''
          mkdir -p $out/lib
          install ./out/hypr-darkwindow.so $out/lib/libhyprgreen.so
        '';

        meta = with pkgs.lib; {
          homepage = "https://github.com/FridayFaerie/hyprgreen";
          description = "Adds Chromakey Effect to Windows";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };

      default = hyprgreen;
    });

    devShells = forHyprlandSystems (system: pkgs: {
      default = pkgs.mkShell {
        name = "hyprgreen";

        nativeBuildInputs = with pkgs; [
          clang-tools_16
        ];

        inputsFrom = [self.packages.${system}.hyprgreen];
      };
    });
  };
}
