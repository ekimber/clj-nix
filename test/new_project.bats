# vi: ft=sh

setup_file() {

  bats_require_minimum_version 1.5.0

  # For debugging
  # project_dir="/tmp/_clj-nix_project"

  project_dir="$BATS_FILE_TMPDIR/clj-nix_project"
  export project_dir
  cljnix_dir=$(dirname "$BATS_TEST_DIRNAME")
  export cljnix_dir

  nix flake new --template . "$project_dir"
  echo "cljnixUrl: $cljnix_dir" | mustache "$cljnix_dir/test/integration/flake.template" > "$project_dir/flake.nix"

  cd "$project_dir" || exit
  nix flake lock
}

teardown_file() {
    docker rmi jvm-container-test
    docker rmi graal-container-test
}

@test "Generate deps-lock.json" {
    cp deps-lock.json deps-lock.json.bkp
    nix run "$cljnix_dir#deps-lock"
    cmp deps-lock.json deps-lock.json.bkp
}

@test "nix build .#mkCljBin-test" {
    nix build .#mkCljBin-test
    run -0 ./result/bin/cljdemo
    [ "$output" = "Hello from CLOJURE!!!" ]
}

@test "nix build .#customJdk-test" {
    nix build .#customJdk-test
    run -0 ./result/bin/cljdemo
    [ "$output" = "Hello from CLOJURE!!!" ]
}

# bats test_tags=graal
@test "nix build .#mkGraalBin-test" {
    nix build .#mkGraalBin-test
    run -0 ./result/bin/cljdemo
    [ "$output" = "Hello from CLOJURE!!!" ]
}

# bats test_tags=docker
@test "nix build .#jvm-container-test" {
    nix build .#jvm-container-test
    docker load -i result
    run -0 docker run --rm jvm-container-test:latest
    [ "$output" = "Hello from CLOJURE!!!" ]
}

# bats test_tags=docker,graal
@test "nix build .#graal-container-test" {
    nix build .#graal-container-test
    docker load -i result
    run -0 docker run --rm graal-container-test:latest
    [ "$output" = "Hello from CLOJURE!!!" ]
}

# bats test_tags=babashka
@test "nix build .#babashka-test" {
    nix build .#babashka-test
    run -0 ./result/bin/bb -e "(inc 101)"
    [ "$output" = "102" ]
    run ! ./result/bin/bb -e "(require '[next.jdbc])"
}

# bats test_tags=babashka
@test "nix build .#babashka-with-features-test" {
    nix build .#babashka-with-features-test
    ./result/bin/bb -e "(require '[next.jdbc])"
}
