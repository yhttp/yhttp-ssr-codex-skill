# XTA SSR patterns

Use XTA as a concrete example of a multilingual YHTTP SSR application. Confirm the current repository before copying a pattern because implementation details can evolve.

## Source map

| Concern | XTA source |
| --- | --- |
| Composition and readiness | `xta/rollup.py` |
| Root registration | `xta/routes.py` and feature `routes.py` modules |
| Public and admin handlers | `xta/pages.py` and feature `pages.py` modules |
| Public document shell | `xta/templates/master.mako` |
| Admin document shell | `xta/templates/admin/master.mako` |
| Public landing page | `xta/templates/index.mako` |
| Asset resolution | `xta/assets.py` and `vite.config.mjs` |
| Shared browser code | `www/master.js` and `www/master.css` |
| Focused browser behavior | `www/views/*.js` |
| API services | `www/services/*.js` |
| Arabic messages | `xta/i18n/ar_OM/LC_MESSAGES/messages.po` |
| SSR tests | `tests/test_pages.py` and feature page tests |

## Composition

`xta/rollup.py` creates the `Application`, installs media, i18n, database-manager, SQLAlchemy, Mako, and auth extensions, merges built-in YAML settings, registers a readiness callback, imports models, and finally imports route modules. Preserve this order. Settings and extension behavior belong in the composition root, not templates or individual handlers.

Development asset URLs point to Vite; production resolves manifest-backed files under `/assets`. Runtime media and root public files are registered during readiness according to settings.

## Public page pattern

Use the established decorator sequence and return template context:

```python
@app.route(r'/example/(?P<id>\d+)')
@app.bodyguard(strict=True)
@app.queryguard(strict=True)
@app.template('example.mako')
def get(req, id):
    with app.db.session() as session:
        item = session.query(Item).get(id)
        if item is None:
            raise statuses.notfound()
        return {'item': item.todict(req.language)}
```

Match the actual YHTTP capture syntax and status factory used by the target feature; this snippet illustrates the layering rather than an API guarantee.

Public templates inherit `master.mako`. Administration templates inherit `admin/master.mako` and must not render through the public shell.

## Localization

XTA maps `en` to `en_US` and `ar` to `ar_OM`. Public paths are locale-prefixed by the i18n rewriter, while API, asset, media, and selected root files are ignored. Templates receive `_`, locale data, `req`, `settings`, and `asseturl`.

Wrap visible strings in `_()`, build internal links with the active language, and use `l.direction` plus logical Tailwind utilities. Verify Arabic and English routes. Use `dir="ltr"` for phone numbers or similar tokens whose intrinsic direction must remain stable.

## Progressive enhancement

Keep the page server-rendered. Use Alpine modules under `www/views` for focused state and services under `www/services` for API calls. The callback form is the complete example: `index.mako` provides markup, `www/views/index.js` manages state, `www/services/callbacks.js` sends the request, and callback routes validate and persist it.

## Tests and commands

Use bddrest page tests to follow redirects, request English and Arabic pages, and assert rendered content and integration contracts. Keep route, template, localization, and asset assertions close to the affected feature.

The repository requires these checks after changes:

```text
make www-format
make lint
make cover
```

Run `make i18n-compile` for localization changes. Run the disposable database rebuild only after model or mock-data changes and only when the target database is confirmed safe. Inspect `git diff` and `git status`, and remove unrelated formatter changes before reporting.

## Boundaries

- Use `setup.py` and python-makelib; do not introduce TOML automation.
- Use installed YHTTP extensions; do not introduce Flask, Django, FastAPI, or parallel infrastructure.
- Keep public and admin shells separate.
- Register new model and route modules explicitly.
- Keep secrets out of source, tests, documentation, logs, and responses.
- Ask before changing authentication policy, dependencies, destructive migrations, production settings, deployment, or publication.
