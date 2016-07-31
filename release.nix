# all the arguments of this function are overridable by Hydra jobset inputs
{ 
# system default nixpkgs
  nixpkgs ? <nixpkgs> 
# some default systems to build
, systems ? ["i686-linux" "x86_64-linux" ] }:

let
  
  # import the system default nixpkgs for lib and stdenv 
  pkgs = import ./. { inherit nixpkgs; };

  # function to create a channel
  # this should get in pkgs.releaseTools someday
  # see https://github.com/NixOS/nixpkgs/issues/17356
  # snippet taken from https://github.com/snabblab/snabblab-nixos/blob/customchannel/jobsets/snabblab.nix
  mkChannel = with pkgs; { name, src, constituents ? [], meta ? {}, isNixOS ? true, ... }@args:
    stdenv.mkDerivation ({
      preferLocalBuild = true;
      _hydraAggregate = true;

      phases = [ "unpackPhase" "patchPhase" "installPhase" ];

      # I still have to figure what this is needed for
      # probably that nixos-rebuild will automatically update the channel
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
  # this will generate a set with each custom packages for each system
  customPkgs = pkgs.lib.genAttrs systems (system:
      # importing our package set for the selected system
      let pkgs = import ./. { inherit system; };
      # and selecting the customPkgs set
      in pkgs.customPkgs);

in
# the following set is what Hydra will evaluate
{
  # Fancy way to get our custom package set in here
  # a easier to understand but ugly way to write it is
  #   customPkgs = customPkgs;
  inherit customPkgs;

  # declaring the channel
  channel = mkChannel {

    # some name, as a channel is also a normal derivation
    name = "test-channel";

    # the src is what will be in the channel tarball
    # the idea to have the full repository in it so the channels user can install our packages

    src = ./.;

    # we get all the derivations in the customPkgs set for each systems
    # test are also very good candidates for constituents
    constituents = with pkgs.lib; collect isDerivation customPkgs; 
  };
}


/* in the future this complicated thing should become small and elegant like the following


{ nixpkgs ? <nixpkgs> 
, systems ? ["i686-linux" "x86_64-linux" ] }:

let
  
  pkgs = import ./. { inherit nixpkgs; };

  customPkgs = pkgs.lib.genAttrs systems (system:
      let pkgs = import ./. { inherit system; };
      in pkgs.customPkgs);

in
{
  inherit customPkgs;

  channel = pkgs.releaseTools.channel {
    name = "test-channel";
    src = ./.;
    constituents = with pkgs.lib; collect isDerivation customPkgs; 
  };
}

*/

