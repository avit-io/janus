{
  description = "Janus — bridge bifronte type-safe sopra l'FFI Agda↔Haskell";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2511.912939";
    piforge = {
      url  = "github:avit-io/piforge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, piforge }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};

      # La libreria, come derivazione Nix. Solo Janus/ — Main.agda e
      # MainFS.agda sono demo eseguibili, non parte della libreria pubblica.
      janusLib = pkgs.stdenv.mkDerivation {
        name      = "janus-agda-lib";
        src       = builtins.path { path = ./.; name = "janus-src"; };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r Janus $out/
          printf 'name: janus\ninclude: .\ndepend: standard-library\n' \
            > $out/janus.agda-lib
        '';
      };

      stdlib28 = piforge.packages.${system}."stdlib-28";

      # Agda 2.8 scrive _build/ risalendo dal sorgente fino al .agda-lib più
      # vicino. Se quel file è nello store → EROFS. Soluzione: copiare le
      # librerie in una dir scrivibile locale. Identica strategia di
      # agdovana / cardea / gallicinium — è il pattern del monorepo.
      copyStdlib = ''
        _cache="''${XDG_CACHE_HOME:-$HOME/.cache}/piforge"
        _stdlib="$_cache/stdlib-2.3"
        if [ ! -d "$_stdlib" ]; then
          echo "janus: copying stdlib 2.3 to $_stdlib (one-time setup)..." >&2
          mkdir -p "$_stdlib"
          cp -r ${stdlib28}/. "$_stdlib/"
          chmod -R u+w "$_stdlib"
        fi
      '';

      # Copia scrivibile della libreria janus per i consumer (FS lib,
      # AWS/Azure bridges, ...). include: . per evitare che agda risalga
      # allo store cercando un .agda-lib durante il build.
      copyJanus = ''
        _jns="$_cache/janus-src"
        if [ ! -d "$_jns" ]; then
          echo "janus: copying Janus library to $_jns (one-time setup)..." >&2
          mkdir -p "$_jns"
          cp -r ${janusLib}/. "$_jns/"
          chmod -R u+w "$_jns"
          printf 'name: janus\ninclude: .\ndepend: standard-library\n' \
            > "$_jns/janus.agda-lib"
        fi
      '';

    in
    {
      packages.${system} = {
        lib     = janusLib;
        default = janusLib;
      };

      # Sviluppo di Janus stesso: stdlib + GHC (FFI), il janus.agda-lib
      # locale lo trova per traversal della dir.
      devShells.${system}.default = piforge.lib.agda.mkShell {
        inherit pkgs;
        version             = "v28";
        useRuntimeLibraries = true;
        extraPackages = with pkgs; [
          haskell.packages.ghc910.ghc
          watchexec
        ];
        shellHook = copyStdlib + ''
          mkdir -p "$_cache/janus-dev"
          printf '%s\n' "$_stdlib/standard-library.agda-lib" \
            > "$_cache/janus-dev/libraries"
          export AGDA_DIR="$_cache/janus-dev"
          echo "agda 2.8 | ghc $(ghc --numeric-version)"
        '';
      };

      # API per i consumer: devShell con Agda + stdlib + janus + GHC.
      # Pensata per la libreria FS e per i bridge cloud (AWS/Azure) che
      # vivranno in repo paralleli.
      lib.mkShell = { pkgs, extraPackages ? [], shellHook ? "" }:
        piforge.lib.agda.mkShell {
          inherit pkgs;
          version             = "v28";
          useRuntimeLibraries = true;
          extraPackages = with pkgs; [
            haskell.packages.ghc910.ghc
            watchexec
          ] ++ extraPackages;
          shellHook = copyStdlib + copyJanus + ''
            mkdir -p "$_cache/janus-lib"
            printf '%s\n%s\n' \
              "$_stdlib/standard-library.agda-lib" \
              "$_jns/janus.agda-lib" \
              > "$_cache/janus-lib/libraries"
            export AGDA_DIR="$_cache/janus-lib"
          '' + shellHook;
        };
    };
}
