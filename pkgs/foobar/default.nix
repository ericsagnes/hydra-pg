{ stdenv, trivial, lib }:

stdenv.mkDerivation {
  name = "trivial";
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/test

    # using another package binary
    ${trivial}/bin/trivial > $out/test/trivial

    # using custom library from top level
    echo ${lib.custom.fooBar 1} > $out/test/foobar

    # and dedicated attribute
    echo ${lib.custom.trivial.fooBar 1} > $out/test/barfoo
  '';

  meta = {
    description = "sample package using custom lib";
    maintainers = with stdenv.lib.maintainers; [ ericsagnes ];
  };
}
