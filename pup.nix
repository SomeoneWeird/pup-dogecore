{ pkgs }:

let
  coreVersion = "1.14.8";

  overlay = self: super: {
    miniupnpc = super.miniupnpc.overrideAttrs (old: {
      version = "2.1";
      src = super.fetchurl {
        url = "https://github.com/miniupnp/miniupnp/archive/miniupnpc_2_1.tar.gz";
        sha256 = "sha256-GcW2z48/wx1eZBx5ezbsylhZCcfzaFpcGmQyU0BTfJQ=";
      };

      sourceRoot = "miniupnp-miniupnpc_2_1/miniupnpc";

      installPhase = ''
        mkdir -p $out/bin $out/lib $out/include/miniupnpc
        install -D -m755 upnpc-shared $out/bin/upnpc
        if [ -f libminiupnpc.so ]; then
          install -D -m755 libminiupnpc.so $out/lib/libminiupnpc.so
        elif [ -f libminiupnpc.dylib ]; then
          install -D -m755 libminiupnpc.dylib $out/lib/libminiupnpc.dylib
        fi
        find . -name 'miniupnpc*.h' -exec install -D -m644 {} $out/include/miniupnpc/ \;
      '';

      cmakeFlags = [
        "-DUPNPC_BUILD_SHARED=TRUE"
        "-DUPNPC_BUILD_STATIC=FALSE"
      ];

      preConfigure = ''
        sed -i '/target_include_directories(libminiupnpc-static/d' CMakeLists.txt
      '';
    });
  };

  # Apply the overlay to the current package set
  pkgsWithOverlay = import <nixpkgs> {
    overlays = [ overlay ];
  };

  dogecoin-core = pkgsWithOverlay.stdenv.mkDerivation {
    pname = "dogecoin-core";
    inherit coreVersion;

    src = pkgsWithOverlay.fetchurl {
      url = "https://github.com/dogecoin/dogecoin/archive/refs/tags/v${coreVersion}.tar.gz";
      hash = "sha256-+I3EiFNfArmAEsg6gkAC0Ief0nlkQ8Yhjf1keq7Hz2E=";
    };

    configureFlags = [
      "--with-incompatible-bdb"
      "--with-boost-libdir=${pkgsWithOverlay.boost}/lib"
    ];

    nativeBuildInputs = [
      pkgsWithOverlay.pkg-config
    ];

    buildInputs = [
      pkgsWithOverlay.autoreconfHook
      pkgsWithOverlay.openssl
      pkgsWithOverlay.db5
      pkgsWithOverlay.util-linux
      pkgsWithOverlay.boost
      pkgsWithOverlay.zlib
      pkgsWithOverlay.libevent
      pkgsWithOverlay.miniupnpc
      pkgsWithOverlay.protobuf
      pkgsWithOverlay.qrencode
    ];
  };

in
{
  inherit dogecoin-core;
}
