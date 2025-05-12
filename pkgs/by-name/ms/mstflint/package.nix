{
  lib,
  stdenv,
  fetchurl,
  rdma-core,
  openssl,
  zlib,
  xz,
  expat,
  boost,
  curl,
  pkg-config,
  libxml2,
  pciutils,
  busybox,
  python3,
  automake,
  autoconf,
  libtool,
  git,
  # use this to shrink the package's footprint if necessary (e.g. for hardened appliances)
  onlyFirmwareUpdater ? false,
  # contains binary-only libraries
  enableDPA ? true,
}:

stdenv.mkDerivation rec {
  pname = "mstflint";

  # if you update the version of this package, also update the input hash in mstflint_access!
  version = "4.32.0-1";

  src = fetchurl {
    url = "https://github.com/Mellanox/mstflint/releases/download/v${version}/mstflint-${version}.tar.gz";
    hash = "sha256-dNshekn1770psArIvBnRjjQHQJzqN6xODGPa2VuMoHY=";
  };

  nativeBuildInputs = [
    autoconf
    automake
    libtool
    pkg-config
    libxml2
    git
  ];

  buildInputs =
    [
      rdma-core
      zlib
      libxml2
      openssl
    ]
    ++ lib.optionals (!onlyFirmwareUpdater) [
      boost
      curl
      expat
      xz
      python3
    ];

  preConfigure = ''
    export CPPFLAGS="-I$(pwd)/tools_layouts -isystem ${libxml2.dev}/include/libxml2"
    export INSTALL_BASEDIR=$out
    ./autogen.sh
  '';

  # Cannot use wrapProgram since the python script's logic depends on the
  # filename and will get messed up if the executable is named ".xyz-wrapped".
  # That is why the python executable and runtime dependencies are injected
  # this way.
  #
  # Remove host_cpu replacement again (see https://github.com/Mellanox/mstflint/pull/865),
  # needs to hit master or a release. master_devel may be rebased.
  prePatch = [
    ''
      patchShebangs eval_git_sha.sh
      substituteInPlace configure.ac \
          --replace "build_cpu" "host_cpu"
      substituteInPlace common/compatibility.h \
          --replace "#define ROOT_PATH \"/\"" "#define ROOT_PATH \"$out/\""
    ''
    (lib.optionals (!onlyFirmwareUpdater) ''
      substituteInPlace common/python_wrapper.sh \
        --replace \
        'exec $PYTHON_EXEC $SCRIPT_PATH "$@"' \
        'export PATH=$PATH:${
          lib.makeBinPath [
            (placeholder "out")
            pciutils
            busybox
          ]
        }; exec ${python3}/bin/python3 $SCRIPT_PATH "$@"'
    '')
  ];

  configureFlags =
    [
      "--enable-xml2"
      "--datarootdir=${placeholder "out"}/share"
    ]
    ++ lib.optionals (!onlyFirmwareUpdater) [
      "--enable-adb-generic-tools"
      "--enable-cs"
      "--enable-dc"
      "--enable-fw-mgr"
      "--enable-inband"
      "--enable-rdmem"
    ]
    ++ lib.optionals enableDPA [
      "--enable-dpa"
    ];

  enableParallelBuilding = true;

  hardeningDisable = [ "format" ];

  dontDisableStatic = true; # the build fails without this. should probably be reported upstream

  meta = with lib; {
    description = "Open source version of Mellanox Firmware Tools (MFT)";
    homepage = "https://github.com/Mellanox/mstflint";
    license = with licenses; [
      gpl2Only
      bsd2
    ];
    maintainers = with maintainers; [ thillux ];
    platforms = platforms.linux;
  };
}
