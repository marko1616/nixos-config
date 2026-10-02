{ runCommand, fetchurl, python3, librime }:
let
  strokeRevision = "1e8fff9b9494ddec23b0cbc526bcfd8171a6fd48";
  encodingRevision = "a985b62a9b45c17da3e17a9f0a0b4e30c34c4a8a";
  stroke = fetchurl {
    url = "https://codeload.github.com/rime/rime-stroke/tar.gz/1e8fff9b9494ddec23b0cbc526bcfd8171a6fd48";
    hash = "sha256-E0elerTPJpvpscSc5Q+s/mBhcgfyeAYE/oKRQHDaioA=";
  };
  gbIndex = fetchurl {
    url = "https://raw.githubusercontent.com/whatwg/encoding/a985b62a9b45c17da3e17a9f0a0b4e30c34c4a8a/index-gb18030.txt";
    hash = "sha256-dGs8VfGo7EuQtFHzhEN6F/03zVHNZoRWooBxp1jRB4Q=";
  };
  gbRanges = fetchurl {
    url = "https://raw.githubusercontent.com/whatwg/encoding/a985b62a9b45c17da3e17a9f0a0b4e30c34c4a8a/index-gb18030-ranges.txt";
    hash = "sha256-h0xrb290z31CetIo1bQd3ZNU//2SoiWb9Cn4bmuqeh4=";
  };
in
runCommand "rime-marko-input-1.0.0" {
  nativeBuildInputs = [ (python3.withPackages (ps: [ ps.pyyaml ])) librime ];
  meta = {
    description = "Flypy with Microsoft-style U/V modes for Rime";
  };
} ''
  mkdir stroke
  tar -xzf ${stroke} -C stroke --strip-components=1
  mkdir -p "$out/share/rime-data"
  # rime-ice is referenced as the Git submodule at assets/rime-ice, not vendored here.
  # Store sources are read-only, and plain cp -r propagates that mode to the
  # directories it creates, which would block the copies that follow.
  cp -r --no-preserve=mode ${../assets/rime-ice}/. "$out/share/rime-data/"
  cp --no-preserve=mode stroke/stroke.dict.yaml "$out/share/rime-data/"
  cp -r --no-preserve=mode ${../assets/rime}/. "$out/share/rime-data/"
  chmod -R u+w "$out"
  python ${../scripts/build_rime_uv_data.py} ${../assets/rime-ice} ${gbIndex} ${gbRanges} \
    "$out/share/rime-data/lua/marko_uv"
  # Compilation is a build gate, not an activation-time modification of user data.
  rime_deployer --build "$out/share/rime-data" "$out/share/rime-data" "$out/share/rime-data/build"
  test -s "$out/share/rime-data/build/marko-input.schema.yaml"
  test -s "$out/share/rime-data/build/marko_terms.table.bin"
  test -s "$out/share/rime-data/build/marko-input-radical.prism.bin"
  test -s "$out/share/rime-data/build/marko-input-stroke.prism.bin"
''
