# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-05-05

This is a substantial hardening release. The public helper API
(`basic_auth "user", "pass"`, `basic_auth({...})`) is unchanged, but the
internals were reorganized around a `Verifier` strategy interface and the
`Credentials` timing-equalization algorithm changed. See
[Upgrading from 1.x](README.md#upgrading-from-1x) for guidance.

### Added
- `Kemal::BasicAuth::Verifier` abstract class as a pluggable authentication
  strategy. Built-in implementations:
  - `Credentials` (plaintext, in-memory; existing class, now `< Verifier`).
  - `BcryptVerifier` for bcrypt-hashed passwords (uses `Crypto::Bcrypt`).
  - `ProcVerifier` for dynamic credential lookup (DB, environment, etc.).
- `basic_auth` block form for ad-hoc dynamic verification:

  ```crystal
  basic_auth do |user, pass|
    User.authenticate(user, pass)
  end
  ```

- Configurable `realm` and `message` on `Handler` and all `basic_auth`
  helpers; `WWW-Authenticate` header is generated from `realm` and
  sanitized against header injection (CR/LF and `"`).
- `Kemal::BasicAuth::RateLimiter`: optional in-memory sliding-window rate
  limiter for failed authentication attempts. Keys off the request remote
  address; emits `429 Too Many Requests` with `Retry-After` once the
  threshold is exceeded; resets on successful authentication.
- Automatic `only`/`exclude` filtering: subclasses that use the `only` or
  `exclude` macros no longer need to override `call`. The legacy manual
  override pattern keeps working.

### Changed
- `Credentials` now performs timing-equalized comparison via SHA-256
  digests so that response time does not vary with whether the username
  exists or how the supplied password compares to the stored one. SHA-256
  is used purely for length equalization here; for hashed storage use
  `BcryptVerifier`.
- `Handler` constructor accepts a `Verifier` instead of a `Credentials`
  instance. `Credentials < Verifier`, so existing callers passing a
  `Credentials` instance continue to work without changes.
- `Handler` now accepts `realm`, `message`, and `rate_limiter` as
  optional keyword arguments on every constructor variant.
- `Authorization` header parsing is stricter: requires the literal
  prefix `"Basic "` (with the trailing space), tolerates surrounding
  whitespace via `.strip`, and gracefully rejects malformed Base64,
  payloads without a `:` separator, or any other parse failures.
- `shard.yml`: `kemal` moved from `development_dependencies` to
  `dependencies` (it is a runtime requirement) and pinned to
  `>= 1.0.0, < 2.0.0`. Minimum Crystal version is now `1.12.0`.

### Fixed
- Passwords containing `:` are now supported (parsing uses
  `String#partition` instead of `String#split`).
- Malformed `Authorization` headers (invalid Base64, missing colon,
  unexpected scheme) now produce a clean `401` response instead of
  raising `Base64::Error` / `IndexError`.
- Removed dead `headers = HTTP::Headers.new` allocation in
  `Handler#call`.
- Doc comment typos (`password2` -> `password1`, `authorized_username`
  -> `kemal_authorized_username?`).
- `crendentials` parameter name typo (`crendentials` -> `credentials`).

### Removed
- `src/kemal-basic-auth/version.cr` (`Kemal::BasicAuth::VERSION` constant).
  The version lives in `shard.yml` only.

### Infrastructure
- CI moved from Travis to GitHub Actions, matrix tests against Crystal
  `latest` and `nightly`, with format check, ameba lint, and full spec
  run.
- `.ameba.yml` added with minimal configuration.
- Test suite expanded from 3 to 42 specs covering malformed headers,
  passwords with `:`, realm/message customization, header injection
  sanitization, all verifiers, the rate limiter (with an injectable
  fake clock), and `only`/`exclude` behavior in both auto and legacy
  modes.

## [1.0.0] - 2024-09-12

Last tagged release prior to 2.0.0. See
[git history](https://github.com/kemalcr/kemal-basic-auth/commits/v1.0.0)
for details. Highlights:

- Refactor to inherit from `Kemal::Handler` (gaining `only` / `exclude`).
- Pluggable `Kemal.config.auth_handler`.
- `Credentials` extracted with constant-time username comparison.

[2.0.0]: https://github.com/kemalcr/kemal-basic-auth/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/kemalcr/kemal-basic-auth/releases/tag/v1.0.0
