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
      # magic variable that force the build locally (no binary cache used)
      preferLocalBuild = true;
      # magic variable that indicate the build ois an aggregate job
      _hydraAggregate = true;

      phases = [ "unpackPhase" "patchPhase" "installPhase" ];

      # This allow to automatically rebuild the channel if the command is
      # nixos-rebuild --update
      patchPhase = stdenv.lib.optionalString isNixOS ''
        touch .update-on-nixos-rebuild
      '';

      # where all the magic happens
      # this create files that Hydra know with the required informations for the channel
      installPhase = ''
        mkdir -p $out/{tarballs,nix-support}

        # create the tarball
        tar cJf "$out/tarballs/nixexprs.tar.xz" \
          --owner=0 --group=0 --mtime="1970-01-01 00:00:00 UTC" \
          --transform='s!^\.!${name}!' .

        # create the tarball information
        echo "channel - $out/tarballs/nixexprs.tar.xz" > "$out/nix-support/hydra-build-products"

        # save the channel constituents list in a place Hydra is aware of
        echo $constituents > "$out/nix-support/hydra-aggregate-constituents"

        # propagating the failure of constituents to the channel
        # if one constituents fails, the channel build should also fail
        for i in $constituents; do
          if [ -e "$i/nix-support/failed" ]; then
            touch "$out/nix-support/failed"
          fi
        done
      '';

      meta = meta // {
        # magic variable that indicate the derivation is a channel
        isHydraChannel = true;
      };
  } // removeAttrs args [ "meta" ]);

  # customPkgs for each supported system
  # this will generate a set with each custom packages for each system
  customPkgs = pkgs.lib.genAttrs systems (system:
      # importing our package set for the selected system
      let pkgs = import ./. { inherit system; };
          # remove non package attributes that cause evaluation errors
          customPkgs = builtins.removeAttrs pkgs.customPkgs [ "lib" "callPackage" ];
      in customPkgs );

  # list of custom packages for each system
  customPkgsList = with pkgs.lib; collect isDerivation customPkgs;

  # channel constituents definition
  # test are also very good candidates for constituents
  #   constituents = customPkgsList ++ tests;
  constituents = customPkgsList;

in
# the following set is what Hydra will evaluate
{
  # Fancy way to get our custom package set in here
  # an easier to understand but ugly way to write it is
  #   customPkgs = customPkgs;
  inherit customPkgs;

  # declaring the channel
  channel = mkChannel {
    # shortcut for
    #   constituents = constituents;
    inherit constituents;

    # some name, as a channel is also a normal derivation
    name = "test-channel";

    # the src is what will be in the channel tarball
    # the idea to have the full repository in it so the channels user can source build the custom packages
    src = ./.;
  };
}


/* 

In the future this complicated thing should become small and elegant like the following


{ nixpkgs ? <nixpkgs> 
, systems ? ["i686-linux" "x86_64-linux" ] }:

let
  
  pkgs = import ./. { inherit nixpkgs; };

  customPkgs = pkgs.lib.genAttrs systems (system:
      let pkgs = import ./. { inherit system; };
          customPkgs = builtins.removeAttrs pkgs.customPkgs [ "lib" "callPackage" ];
      in customPkgs );

  customPkgsList = with pkgs.lib; collect isDerivation customPkgs;

  constituents = customPkgsList;

in
{
  inherit customPkgs;

  channel = pkgs.releaseTools.channel {
    inherit constituents;
    name = "test-channel";
    src = ./.;
  };
}

*/
