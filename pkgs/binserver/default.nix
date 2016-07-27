{ stdenv, buildPythonPackage, pythonPackages, fetchFromGitHub }:

buildPythonPackage rec {

  name = "binserver-${version}";
  version = "2.0";

  propagatedBuildInputs = with pythonPackages; [ flask ];

  src = fetchFromGitHub {
    owner  = "ericsagnes";
    repo   = "binserver";
    rev    = "v2.0";
    sha256 = "0mi20ksmfqfff929m7vyfr7miyc36y9bvy5xndwjcp9m8inh6220";
  };

  meta = with stdenv; {
    description = "server converting decimal to binary";
    maintainers = with lib.maintainers; [ ericsagnes ];
  };

}
