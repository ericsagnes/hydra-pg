{ pkgs }:

rec {

  # callPackage aware of the custom packages
  callPackage = pkgs.lib.callPackageWith (pkgs);

  binserver = pkgs.callPackage ./binserver {};

  foobar = pkgs.callPackage ./foobar {};

  trivial = pkgs.callPackage ./trivial {};

}
