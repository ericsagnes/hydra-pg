{ nixpkgs ? <nixpkgs> 
, systems ? ["i686-linux" "x86_64-linux" ] }:

let
  
  # import the default nixpkgs for lib and stdenv 
  pkgs = import ./. { inherit nixpkgs; };

  # function to create a channel
  # this should be in nixpkgs
  mkChannel = with pkgs; { name, src, constituents ? [], meta ? {}, isNixOS ? true, ... }@args:
    stdenv.mkDerivation ({
      preferLocalBuild = true;
      _hydraAggregate = true;

      phases = [ "unpackPhase" "patchPhase" "installPhase" ];

      patchPhase = stdenv.lib.optionalString isNixOS ''
        touch .update-on-nixos-rebuild
      '';

      installPhase = ''
        mkdir -p $out/{tarballs,nix-support}
        tar cJf "$out/tarballs/nixexprs.tar.xz" \
          --owner=0 --group=0 --mtime="1970-01-01 00:00:00 UTC" \
          --transform='s!^\.!${name}!' .
        echo "channel - $out/tarballs/nixexprs.tar.xz" > "$out/nix-support/hydra-build-products"
        echo $constituents > "$out/nix-support/hydra-aggregate-constituents"
        for i in $constituents; do
          if [ -e "$i/nix-support/failed" ]; then
            touch "$out/nix-support/failed"
          fi
        done
      '';

      meta = meta // {
        isHydraChannel = true;
      };
  } // removeAttrs args [ "meta" ]);

  # customPkgs for each supported system
  customPkgs = with pkgs.lib; 
    genAttrs systems (system:
      # importing our package set for the selected system
      let pkgs = import ./. { inherit system; };
      # and selecting the customPkgs set
      in pkgs.customPkgs);

in
{
  inherit customPkgs;

  # declaring the channel
  channel = mkChannel {
    name = "test-channel";
    src = ./.;
    # we get all the derivations in the customPkgs set for each systems
    constituents = with pkgs.lib; collect isDerivation customPkgs; 
  };
}
