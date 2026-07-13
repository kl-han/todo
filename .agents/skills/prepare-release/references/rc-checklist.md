# Release-candidate validation checklist

Sustained real use (days, not minutes) on every deployment shape.

## iPhone 13 Pro (physical), local mode
- [ ] Cold start to interactive matrix; create/edit/complete/reopen/delete/undo
- [ ] Background + reopen: state intact
- [ ] Force-quit mid-use: every acknowledged write present after relaunch
- [ ] Hours suspended (jetsam likely): backend restarts transparently on resume
- [ ] Airplane mode: fully functional
- [ ] VoiceOver labels, Dynamic Type at large sizes, rotation

## Arch Linux + Sway, local mode
- [ ] Full keyboard-only session (Alt+1/2/3, h/j/k/l, Enter, Tab)
- [ ] hjkl typed into text fields stays text
- [ ] Tiled/floating resizes, workspace switches
- [ ] Close + reopen: data intact

## Remote mode (both platforms)
- [ ] Settings sheet: test-connection diagnostics name each failure kind
- [ ] Switch confirmation appears; cancel keeps the old dataset
- [ ] Server outage mid-session: explicit offline banner, retry recovers,
      no local fallback
- [ ] Wrong token: authentication message, not a generic error

## Server
- [ ] Foreground run + SIGTERM clean exit
- [ ] systemd unit: enable, restart, journal logs
- [ ] Daemon mode: pid file lifecycle
- [ ] vault-create + isolation between vaults over HTTP
- [ ] backup (self-verifying) + restore drill from the snapshot
