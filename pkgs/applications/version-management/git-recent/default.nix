{
  lib,
  stdenv,
  git,
  less,
  fetchFromGitHub,
  makeWrapper,
  # util-linuxMinimal is included because we need the column command
  util-linux,
}:

stdenv.mkDerivation rec {
  pname = "git-recent";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "paulirish";
    repo = "git-recent";
    rev = "v${version}";
    sha256 = "sha256-BwnSDIBGjhfQ9mA/29NfWYaVZGXzZudX9LsCdRlnT0I=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = null;

  installPhase = ''
    mkdir -p $out/bin
    cp git-recent $out/bin
    wrapProgram $out/bin/git-recent \
      --prefix PATH : "${
        lib.makeBinPath [
          git
          less
          util-linux
        ]
      }"
  '';

  meta = with lib; {
    homepage = "https://github.com/paulirish/git-recent";
    description = "See your latest local git branches, formatted real fancy";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ maintainers.jlesquembre ];
    mainProgram = "git-recent";
  };
}
