I've been using this command, but it only works if you're using versions of nargo and bb that line-up with aztec-packages. It's a bit of a pain.

`~/git/noir/target/debug/noir-profiler gates-flamegraph --artifact-path ../../target/use.json --backend-path ~/.bb/bb --output ./flamegraph --backend-gates-command "gates_mega_honk" -- -h && python3 -m http.server --directory "./flamegraph" 3000`