# Quadrant Todo

A personal Eisenhower-matrix task manager for **iOS** and **Linux
(Sway/Wayland)**, built on one architectural rule: **every application
operation crosses a REST boundary**, whether the backend is embedded in
the app or a server you host.

```text
Flutter UI ─ typed REST client ─┬─ loopback HTTP ─ embedded isolate ─ SQLite   (local mode)
                                └─ HTTPS ─ quadrant_server ─ SQLite vault      (remote mode)
```

Both backends serve the identical v1 contract (`api/openapi.yaml`) and
must pass the same conformance suite. Switching modes switches the
dataset; nothing is merged or synchronized. Local mode is fully offline;
remote mode is honestly online-only.

**Status: v1.0.0** — stable v1 API (additive-only from here), tested
migrations, verified backups, complete documentation.

## Install

### Linux app (Arch)

```bash
# Prereqs: flutter (stable), clang cmake ninja gtk3
cd apps/quadrant_todo
flutter create --platforms=linux .   # once
flutter build linux --release        # bundle in build/linux/x64/release/bundle/
# Or build the package: devops/linux/PKGBUILD
```

Data lives in `$XDG_DATA_HOME/quadrant-todo/`. Keyboard: `Alt+1/2/3`
tabs, `h/j/k/l` focus, `Enter` toggles completion.

### iOS app

```bash
# Prereqs: macOS + Xcode + flutter (stable)
cd apps/quadrant_todo
flutter create --platforms=ios .     # once; set Team in Xcode
flutter run -d <your-iphone>
```

See `docs/src/devops/ios-build-signing.rst` for signing notes.

### Server (optional, for remote mode)

```bash
dart compile exe server/bin/quadrant_server.dart -o ~/.local/bin/quadrant_server
(umask 077; mkdir -p ~/.config/quadrant-todo; openssl rand -base64 32 > ~/.config/quadrant-todo/token)
quadrant_server serve --token-file ~/.config/quadrant-todo/token
# systemd unit: devops/server/systemd/quadrant-server.service
```

Create vaults with `quadrant_server vault-create <name>`; snapshot with
`quadrant_server backup <vault> <dest>` (self-verifying). Point the app
at the server from the in-app backend settings (gear icon).

## Development

```bash
dart pub get                 # resolves the whole pure-Dart workspace
dart analyze --fatal-infos
(cd packages/quadrant_conformance && dart test)   # the merge gate
make -C docs html            # sphinx-build -W
```

- Rules: `AGENTS.md` (root + subtree files). Workflows: `.agents/skills/`.
- One feature per `feature/`/`claude/` branch; PRs squash-merge
  automatically when marked ready (`CONTRIBUTING.md`).
- Full documentation: `docs/` (Sphinx; architecture, API, platforms,
  testing, operations, ADRs).

## License

Personal project; no license granted yet.
