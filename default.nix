# entry point
{ nixpkgs ? <nixpkgs>,
  system ? builtins.currentSystem }:

let

  pkgs = import nixpkgs { inherit system; };

  # trick to have customPkgs at pkgs root and in pkgs.customPkgs
  # pkgs.customPkgs is useful to refer the full set of custom packages
  newPkgs = (pkgs // customPkgs) // { inherit customPkgs; };
  
  callPackage = pkgs.lib.callPackageWith (pkgs);

  customPkgs = import ./pkgs { pkgs = newPkgs; };

in
  newPkgs
