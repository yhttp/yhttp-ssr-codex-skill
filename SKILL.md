---
name: yhttp-ssr
description: Build, extend, diagnose, and review server-side-rendered YHTTP applications that use Mako templates and YHTTP extensions. Use for localized page routes, shared layouts, forms, metadata, asset integration, Alpine.js progressive enhancement, authentication and OAuth2 provider flows, persistence-backed SSR, route or model registration, RTL/LTR behavior, and bddrest page tests in an existing YHTTP project.
---

# YHTTP SSR

Implement SSR work through the target project's existing YHTTP composition, Mako, localization, assets, and test conventions. Preserve the installed framework and extension stack.

This skill is self-contained and project-neutral. The target repository is the
source of truth: do not assume a package manager, directory name, locale set,
authentication provider, database, frontend tool, or deployment platform until
the repository confirms it.

## Establish the project contract

1. Read repository instructions and the canonical setup, architecture, dependency, and command files, including `Makefile` when present.
2. Inspect the installed YHTTP version and extension pins. Read the matching current official YHTTP documentation and repositories for extensions involved in the task; prefer verified APIs over memory.
3. Trace the composition root, settings merge, readiness callback, model imports, route-registration imports, relevant handler, inherited template, browser entry point, and tests.
4. Find the nearest complete feature and follow it end to end.
5. Inspect the worktree before editing. Record pre-existing changes exactly; never call the worktree clean unless status output is empty. Preserve unrelated changes and existing behavior.
6. Present a short plan covering rendering, routing, localization, browser behavior, data/auth boundaries, and tests.

### Makefile contract

- Treat the repository `Makefile`, when present, as the canonical developer command contract; read its variables, included rules, virtual-environment prefix, and feature-specific targets before running commands or adding new ones.
- Reuse existing targets instead of duplicating their commands in documentation or one-off shell scripts. Add a target only when the workflow is a repeatable project concern and keep its naming consistent with neighboring targets.
- Use the repository's existing targets for formatting, linting, tests, running the development server, and localization compilation when those workflows exist. Do not require Make, makelib, or a particular package manager in a project that does not use them.
- When reporting verification, name the Makefile targets run. If a target cannot run because an environment prerequisite is absent, run the narrow underlying check when safe and report the missing prerequisite explicitly.

## Classify the change

- Keep static presentation changes in Mako and existing CSS utilities.
- Add an Alpine view module only for focused browser state or interaction.
- Put endpoint calls in the project's service layer; do not place raw fetch workflows in templates.
- Add handlers, guards, persistence, and transactions only when server state changes.
- Keep business rules and multi-step operations out of templates.
- Do not add another web framework, client-side application shell, or build system.

## Implement through YHTTP

### Composition and registration

- Install extensions and merge built-in settings before readiness.
- Import models so metadata is registered, then import route modules so decorators execute.
- Treat an unimported handler or model module as inactive.
- Preserve extension ownership of templates, localization, authentication, media, database sessions, and static files.
- Keep application construction, extension installation, settings merging, and
  readiness hooks in the composition root. Configure development asset serving,
  production manifest serving, runtime media, public files, and error handling
  there according to the target project's settings.
- Keep public and administration document shells separate when the application
  has both. Public handlers should inherit the public shell; administrative
  handlers should inherit the administrative shell rather than mixing layout
  responsibilities.

### Routes and handlers

- Register regex paths with `@app.route(...)`; accept capture groups in the handler signature.
- Name handlers for the YHTTP verb used by the project, such as `get`, `create`, `update`, `delete`, or `refresh`.
- Apply body and query guards before handler logic. Choose strictness explicitly and update tests with accepted inputs.
- Render pages with `@app.template(...)` and return context dictionaries.
- Use the project's status and JSON decorators for non-page responses; never expose internal exceptions.
- Reuse installed authentication decorators and session APIs. Do not invent role, cookie, CSRF, or token policy.
- For a page with a captured identifier, keep the route, guards, template,
  database lookup, not-found response, and returned context together. A typical
  shape is `@app.route(...)`, strict body/query guards, `@app.template(...)`, a
  session-scoped lookup, and a context dictionary. Confirm the target YHTTP
  capture syntax and status factories instead of copying a framework version's
  example blindly.

### OAuth 2.0 and authentication flows

- Treat the installed `yhttp-auth` extension as the owner of access tokens,
  refresh tokens, cookies, CSRF tokens, OAuth state tokens, Redis blacklist
  state, and authentication decorators. Use `app.auth.session_new()`,
  `session_refresh()`, `session_delete()`, `token_fromcookie()`,
  `oauth2_session_new()`, and `oauth2_session_verify()` instead of setting
  cookies or signing tokens in application code.
- Trace the actual installed extension version before importing exceptions.
  For example, yhttp-auth 11.1 exposes `TokenMissmatchError` while newer
  versions may expose `TokenMismatchError`; a compatibility import may be
  required during a supported-version transition. Dependency declarations may
  also specify a different yhttp-auth major range; reconcile the declared and
  installed versions before relying on an exception or helper.
- Keep provider-specific code in a small module such as
  `auth/oauth2.py`. It should build the provider authorization URL and
  exchange the authorization code; route handlers should validate requests,
  update the member, create the application session, and redirect.
- Configure OAuth under `app.settings.auth.oauth2`, separating the signed
  state-token settings from provider settings. A Google configuration needs an
  authorization URL, token URL, client ID, and client secret. Keep secrets in
  protected deployment configuration or a secret manager; never copy real
  values into a skill, test fixture, log, exception, URL, or commit.

#### A Google authorization-code flow

- The public SSR page is `GET /signin`. Its optional `then` query value is
  validated with the project's path guard and strict query/body guards. The
  template renders a URL-encoded link to
  `/apiv1/tokens?then=<destination>`; it does not construct the Google URL or
  OAuth state in Mako.
- `GET /apiv1/tokens` first validates `then` and attempts
  `app.auth.session_refresh(req)`. A valid refresh cookie creates a new
  application session and redirects to `then`. Missing, malformed, or expired
  refresh tokens start Google sign-in instead.
- The start helper reads the configured `publicurl`, creates a CSRF cookie and
  signed `OAuth2StateToken` through `app.auth.oauth2_session_new(req, redirect,
  payload)`, and places that token in Google's `state` query parameter. The
  state contains the CSRF-token value and the encoded return path; do not put
  secrets or unnecessary identity data in it. Preserve only validated local
  relative paths to prevent an open redirect.
- The authorization request uses `response_type=code`, scope
  `openid email profile`, the exact callback URI
  `<publicurl>/apiv1/oauth2/callbacks/google`, `access_type=offline`, and
  `prompt=consent`. If a refresh cookie can be decoded with expiration checks
  disabled, its `id` is passed as `login_hint`; verify that this is actually a
  provider email in the application's token model before copying this
  behavior. If application tokens use a numeric local member ID, do not pass
  that ID as a provider email hint; use a verified provider email instead.
- `GET /apiv1/oauth2/callbacks/google` strictly requires `code` and `state`.
  Call `oauth2_session_verify()` before contacting Google. It checks that the
  state JWT is valid and unexpired and that its embedded CSRF value exactly
  matches the `yhttp-csrftoken` cookie. Convert missing, malformed, expired,
  or mismatched state to an application 401; do not continue to token exchange.
- Exchange the code server-side with a POST containing `code`, `client_id`,
  `client_secret`, the same exact callback URI, and
  `grant_type=authorization_code`. Treat non-200 responses, network failures,
  invalid JSON, missing `id_token`, missing required provider tokens, and
  malformed JWTs as an unauthorized provider failure. Use an explicit HTTP
  timeout and avoid logging response bodies or credentials.
- The callback extracts the provider email, optional name, locale, and avatar,
  then updates an existing `Member` inside the project's explicit database
  transaction. An application may deliberately update an existing member
  rather than auto-provisioning one: an OAuth identity that is not already
  registered then receives 401 and no application session. Preserve that
  allowlist policy unless account provisioning is explicitly designed and
  tested.
- After the member update, call `member.token_create()` and
  `app.auth.session_new(req, accesstoken)` so yhttp-auth sets the access and
  refresh cookies. Do not persist a provider access token in the application
  JWT. If the application stores provider access tokens, refresh tokens,
  provider markers, or avatars on its member record, treat those fields as
  sensitive and consider encryption, redaction, rotation, and least-privilege
  access before adopting the pattern.
- Redirect using the validated `redirecturl` recovered from the verified state.
  Never trust a raw callback query parameter for the final destination, and
  never let a failed callback create cookies or update the member.

#### Local development and deployment boundaries

- Some applications detect loopback hosts such as `localhost`, `127.0.0.1`,
  `::1`, or `0.0.0.0` and bypass the provider with a seeded development
  identity. If the target project has this convenience, keep it limited to
  explicit development environments and registered identities, unreachable in
  production, and covered by tests. It is not a general authentication
  pattern.
- The authorization request and code exchange must use the same callback URI,
  and that URI must exactly match the provider console registration. Set
  production `publicurl` to the externally reachable HTTPS origin; do not
  leave the built-in loopback value in effect. Verify proxy/forwarded-host
  handling rather than deriving OAuth URLs from an untrusted request host.
- Check the deployed `auth.domain`, `secure`, `httponly`, `samesite`, and
  `path` settings. A development default may use a loopback cookie domain and
  non-secure cookies for local HTTP, while a deployment override may not
  replace every cookie setting. A production host with a loopback cookie
  domain or `secure: false` can prevent the session from working or expose it
  over HTTP.
- The transient CSRF cookie must be sent on the top-level cross-site redirect
  from the provider. `SameSite=Strict` can suppress that cookie on a Google
  callback; test the real browser flow and use the narrowest safe policy (often
  `Lax` for this transient cookie) if the installed extension and threat model
  require it. Keep access/refresh cookie policy separate from OAuth callback
  state policy.

#### Security gaps to resolve before treating the flow as production-safe

- A permissive implementation may decode the Google `id_token` with signature
  verification disabled and only check that `email` exists. Do not copy this
  shortcut.
  Verify the signature against Google's rotating JWKS and validate issuer,
  audience/client ID, expiration, issued-at, nonce when used, and the required
  identity claims. Decide explicitly whether `email_verified` is required.
- The current authorization request does not use PKCE or a nonce, and
  `yhttp-auth`'s state verification is integrity/expiry/CSRF checking rather
  than a one-time-consumption store. Add PKCE, nonce, and replay prevention
  when the provider and application threat model require them; at minimum,
  document these as deliberate decisions and test them.
- Provider error callbacks (`error`, `error_description`, and related fields)
  need a user-safe failure path; a guard that requires `code` may otherwise
  turn a user cancellation into a generic 400. Do not expose provider response
  bodies or internal exception details.
- Refresh-token responses may omit a refresh token on later consent. Preserve
  an existing stored refresh token when the provider intentionally omits a
  replacement, or define a tested failure policy; do not blindly overwrite a
  usable token with null.
- OAuth state is signed but visible to the browser and provider. Keep its
  payload minimal, use short expiry/leeway values, and test missing CSRF cookie,
  invalid signature, expiration, mismatch, replay, invalid destination, and
  provider denial.

### Mako and HTML

- Inherit the correct shared document shell; keep public and administration layouts separate when the project does.
- Use template-provided helpers for translations, locale data, settings, request data, and asset URLs.
- Escape user-controlled text. Render stored HTML without escaping only when the application contract explicitly trusts it.
- Keep templates presentational and semantic. Add accessible names to icon-only controls and descriptive titles to embedded content.
- Reuse existing components and utility classes before adding new CSS.

### Localization and direction

- Wrap visible translatable strings in the project's translation helper.
- Update and compile catalogs with the repository's canonical commands when strings change.
- Verify every supported locale, localized links, and canonical path behavior.
- Use logical CSS directions and locale direction from template context. Isolate phone numbers, email addresses, and similar LTR tokens where needed.
- Test both LTR and RTL output rather than inferring one from the other.
- Discover the project's locale mapping and route-rewrite exclusions before
  adding localized routes. API, asset, media, health, and selected root paths
  are often intentionally unlocalized. Pass the configured translation helper,
  locale data, request, settings, and asset resolver to templates through the
  existing Mako integration rather than recreating them.
- Build internal links with the active locale when the project prefixes public
  paths. Use `dir="ltr"` or an equivalent isolation rule only for values whose
  intrinsic direction must remain stable, such as phone numbers, email
  addresses, and technical identifiers.

### Browser enhancement and assets

- Keep the SSR page useful before JavaScript where practical.
- Identify the project's browser source tree and preserve its existing layout.
  If it uses the common `www/` convention, shared bootstrap and styles may
  live in `www/master.js` and `www/master.css`, page-specific controllers in
  `www/views/`, API clients in `www/services/`, and source images in
  `www/images/`; these names are conventions, not requirements.
- When Alpine is installed, keep its state in the established view directory
  and network calls in resource services. Register shared behavior in the
  existing bootstrap; import page controllers through the configured asset
  entries and register them with `Alpine.data(...)`.
- Use Alpine as progressive enhancement, not a client-side application shell.
  Mako must render the usable HTML and initial values first; Alpine then
  hydrates elements marked with `x-data` after the shared bootstrap calls
  `Alpine.start()`.
- Pass initial state from Mako as safely serialized data to `x-data` (or an
  equivalent data attribute), and make the controller tolerate missing or
  empty values. Do not duplicate server truth by fetching initial state again
  on hydration.
- Keep hydration side effects small and explicit: use Alpine lifecycle hooks
  or event bindings for browser-only setup, and preserve the server-rendered
  fallback while assets are loading. Use `x-cloak` for elements that must stay
  hidden until Alpine initializes.
- Resolve Vite-managed assets through the project's asset helper; do not
  hard-code development-server or fingerprinted production paths. If another
  bundler is installed, follow its resolver instead. Check both development
  URLs and production-manifest resolution when changing the asset boundary.

### Client toolchain and source files

- Read the repository's frontend manifest before changing browser code. This
  may be `package.json` or another project-selected manifest; it is the source
  of truth for the runtime, package manager, dependencies, scripts, and lock
  file. Add a dependency only when the existing browser stack cannot support
  the feature, and update its lock file with the selected package manager.
- Treat the configured asset bundler, such as `vite.config.*`, as the
  asset-boundary contract. Preserve its development-server settings, plugins,
  manifest output, build directory, CSS/module-preload policy, and explicit or
  globbed input entries. A new browser module, stylesheet, or source image
  must be included by the configured inputs before a template references it.
- Keep the project's shared browser bootstrap and stylesheet as shared entries.
  They may contain utility-CSS source directives, template scan paths, custom
  fonts, and global Alpine helpers such as `[x-cloak]`; do not move
  page-specific rules into shared files without a cross-page need.
- Use the repository's formatter configuration, such as `.prettierrc`, as the
  formatting contract. Preserve its quote, width, indentation, XML, and
  class-sorting settings. Run the repository's frontend-format target after
  frontend edits and inspect formatter changes for unrelated rewrites.
- Use the repository's lint configuration, such as `eslint.config.*`, as the
  lint contract. Fix lint/configuration issues in the appropriate source file
  instead of suppressing them broadly.
- Keep browser service modules limited to endpoint clients and shared
  request/error handling; keep view modules limited to browser state; keep
  Mako responsible for SSR markup and initial state. Do not put raw fetch flows
  in templates or duplicate service logic in each view.
- Use the project's named frontend targets rather than ad-hoc package-manager
  commands when those workflows are required. A production build must produce
  the manifest and assets expected by the server-side asset resolver, and
  generated output must not be treated as source.

### Persistence and authorization

- Use the installed database session context and the project's explicit transaction pattern.
- Validate before mutation and keep transaction boundaries visible.
- Add and register a model only when persistence is required; include the project's migration workflow.
- Protect page and API handlers with the established decorators and cover unauthenticated and forbidden states where applicable.

## Test behavior

- Extend the nearest bddrest or project-native test instead of relying on template snapshots alone.
- Cover localized redirects, successful rendering, strict query/body rejection, missing resources, and auth states relevant to the change.
- Assert meaningful output: route URLs, localized text, direction-sensitive markup, resolved assets, semantic attributes, and persisted effects.
- Test browser behavior at the strongest available layer. If no browser harness exists, cover the server-rendered contract and keep client logic small.
- For OAuth flows, test the authorization URL parameters, exact callback URI, state expiry/signature, CSRF-cookie presence and mismatch, provider failure and malformed-token handling, registered versus unregistered identities, persisted profile/token updates, session cookies, redirect destination, refresh, logout, and the local-development branch if one exists. Use mocked provider HTTP and deterministic time; never use live credentials.
- Add a regression assertion for every bug fix.

## Verify and report

1. Read and use the repository's canonical targets or commands for the required formatter, localization compiler when applicable, lint, focused tests, and full coverage suite.
2. Run database rebuild or migration checks only when required and only against a confirmed disposable database.
3. Inspect the final diff and status; remove formatter noise and retain user-owned changes.
4. Report the behavior delivered, checks run, and any remaining browser, deployment, or migration uncertainty.
