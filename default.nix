# entry point of the packages
{ nixpkgs ? <nixpkgs>,
  system ? builtins.currentSystem }:

let

  # official nixpkgs for the selected system
  pkgs = import nixpkgs { inherit system; };

  # lib extended with the custom lib
  lib = pkgs.lib // { custom = import ./lib; };
  
  # loading the custom packages
  customPkgs = (import ./pkgs { pkgs = newPkgs; }) // { inherit lib; };

  # trick to have customPkgs at pkgs root and in pkgs.customPkgs
  # pkgs.customPkgs is useful to refer the full set of custom packages
  newPkgs = pkgs // customPkgs // { inherit customPkgs; };

in
  newPkgs
