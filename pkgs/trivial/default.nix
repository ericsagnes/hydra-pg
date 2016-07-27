{ stdenv }:

stdenv.mkDerivation {
  name = "trivial";
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    echo "echo trivial" > $out/bin/trivial
    chmod +x $out/bin/trivial
  '';
}
