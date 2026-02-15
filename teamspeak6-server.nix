{stdenv
, fetchurl
, lib
, autoPatchelfHook
, glibc
, makeWrapper
, ...}:

stdenv.mkDerivation rec {
  pname = "teamspeak6-server";
  version = "6.0.0";
  betaVersion = "beta8";

  src = fetchurl {
    url = "https://github.com/teamspeak/teamspeak6-server/releases/download/v${version}/${betaVersion}/teamspeak-server_linux_amd64-v${version}-${betaVersion}.tar.bz2";
    hash = "sha256-U9jazezXFGcW95iu20Ktc64E1ihXSE4CiQx3jkgDERc=";
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/teamspeak6-server
    mkdir -p $out/bin

    cp -r * $out/share/teamspeak6-server/

    makeWrapper $out/share/teamspeak6-server/tsserver $out/bin/teamspeak6-server \
      --prefix PATH ":" "${stdenv.cc.cc}/bin" \
      --set TSSERVER_DATABASE_SQL_PATH $out/share/teamspeak6-server/sql
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "TeamSpeak 6 Server (beta)";
    homepage = "https://teamspeak.com/";
    platforms = platforms.linux;
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}