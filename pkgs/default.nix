{ pkgs }:

rec {

  binserver = pkgs.callPackage ./binserver {};

  trivial = pkgs.callPackage ./trivial {};

}
