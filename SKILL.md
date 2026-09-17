---
name: yhttp-ssr
description: Build, extend, diagnose, and review server-side-rendered YHTTP applications that use Mako templates and YHTTP extensions. Use for localized page routes, shared layouts, forms, metadata, asset integration, Alpine.js progressive enhancement, authentication-aware pages, persistence-backed SSR, route or model registration, RTL/LTR behavior, and bddrest page tests in an existing YHTTP project.
---

# YHTTP SSR

Implement SSR work through the target project's existing YHTTP composition, Mako, localization, assets, and test conventions. Preserve the installed framework and extension stack.

## Establish the project contract

1. Read repository instructions and the canonical setup, architecture, dependency, and command files, including `Makefile` when present.
2. Inspect the installed YHTTP version and extension pins. Read the matching current official YHTTP documentation and repositories for extensions involved in the task; prefer verified APIs over memory.
3. Trace the composition root, settings merge, readiness callback, model imports, route-registration imports, relevant handler, inherited template, browser entry point, and tests.
4. Find the nearest complete feature and follow it end to end.
5. Inspect the worktree before editing. Record pre-existing changes exactly; never call the worktree clean unless status output is empty. Preserve unrelated changes and existing behavior.
6. Present a short plan covering rendering, routing, localization, browser behavior, data/auth boundaries, and tests.

Read [references/xta-patterns.md](references/xta-patterns.md) when working in XTA or when a concrete production-style example is useful.

### Makefile contract

- Treat the repository `Makefile` as the canonical developer command contract; read its variables, included makelib rules, virtual-environment prefix, and feature-specific targets before running commands or adding new ones.
- Reuse existing targets instead of duplicating their commands in documentation or one-off shell scripts. Add a target only when the workflow is a repeatable project concern and keep its naming consistent with neighboring targets.
- A new YHTTP SSR project should provide, or clearly inherit, targets for formatting, linting, tests, running the development server, and localization compilation when localization is installed. Keep target commands aligned with the project's selected virtual environment and package manager.
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

### Routes and handlers

- Register regex paths with `@app.route(...)`; accept capture groups in the handler signature.
- Name handlers for the YHTTP verb used by the project, such as `get`, `create`, `update`, `delete`, or `refresh`.
- Apply body and query guards before handler logic. Choose strictness explicitly and update tests with accepted inputs.
- Render pages with `@app.template(...)` and return context dictionaries.
- Use the project's status and JSON decorators for non-page responses; never expose internal exceptions.
- Reuse installed authentication decorators and session APIs. Do not invent role, cookie, CSRF, or token policy.

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

### Browser enhancement and assets

- Keep the SSR page useful before JavaScript where practical.
- Treat `www/` as the browser source tree: shared bootstrap and styles live in
  `www/master.js` and `www/master.css`, page-specific Alpine controllers live
  in `www/views/`, API clients live in `www/services/`, and source images live
  in `www/images/`.
- Keep Alpine state in the established view directory and network calls in
  resource services. Register shared behavior in `www/master.js`; page
  controllers should be imported as page-specific Vite entries and registered
  with `Alpine.data(...)`.
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
  hard-code development-server or fingerprinted production paths. Check both
  development URLs and production-manifest resolution when changing the asset
  boundary.

### Client toolchain and source files

- Read `package.json` before changing browser code. It is the source of truth
  for the Node engine, pnpm package manager, client dependencies, and scripts
  such as `dev`, `build`, `lint`, and `format`. Add a dependency only when the
  existing browser stack cannot support the feature; update
  `pnpm-lock.yaml` with pnpm rather than editing the lockfile by hand.
- Treat `vite.config.mjs` as the asset-boundary contract. Preserve its dev
  server settings, Tailwind Vite plugin, manifest output, `.var/static` build
  directory, CSS splitting, module-preload policy, and explicit/globbed input
  entries. A new `www/views/*.js`, `www/views/*.css`, or source image must be
  included by the configured inputs before a template references it.
- Keep `www/master.js` as the shared browser bootstrap and `www/master.css` as
  the shared Tailwind/CSS entry. The stylesheet may include Tailwind source
  directives, template scan paths, custom fonts, and global Alpine helpers such
  as `[x-cloak]`; do not move page-specific rules into the shared file without
  a cross-page need.
- Use `.prettierrc` as the formatting contract. Preserve its quote, width,
  indentation, XML, and Tailwind-class-sorting settings. Run the repository's
  `www-format` target after frontend edits and inspect formatter changes for
  unrelated rewrites.
- Use `eslint.config.mjs` as the lint contract. It defines JavaScript module
  rules, browser globals, JSON rules, Prettier integration, and generated
  `.var/**` ignores. Fix lint/configuration issues in the appropriate source
  file instead of suppressing them broadly.
- Keep `www/services/` limited to endpoint clients and shared request/error
  handling; keep `www/views/` limited to Alpine controllers and browser state;
  keep Mako responsible for SSR markup and initial state. Do not put raw fetch
  flows in templates or duplicate service logic in each view.
- Use the Makefile's `www-env`, `www-format`, `www-lint`, and `www-dist`
  targets rather than ad-hoc package-manager commands when those workflows are
  required. `www-dist` must produce the manifest and assets expected by the
  server-side asset resolver, and generated `.var/` output must not be treated
  as source.

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
- Add a regression assertion for every bug fix.

## Verify and report

1. Read and use the repository's Makefile targets for the required formatter, localization compiler when applicable, lint, focused tests, and full coverage suite.
2. Run database rebuild or migration checks only when required and only against a confirmed disposable database.
3. Inspect the final diff and status; remove formatter noise and retain user-owned changes.
4. Report the behavior delivered, checks run, and any remaining browser, deployment, or migration uncertainty.
