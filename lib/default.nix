let
  # importing the custom lib
  trivial = import ./trivial.nix;
in
  # add the imported lib at top level in a dedicated attribute
  trivial // { inherit trivial; }
