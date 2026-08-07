# YHTTP SSR Codex Skill

A Codex skill for building, extending, diagnosing, and reviewing server-side-rendered [YHTTP](https://github.com/yhttp/yhttp) applications.

The skill guides Codex through an existing project's composition, routing, Mako templates, localization, assets, authentication, persistence, and tests. It favors the project's installed YHTTP extensions and established conventions over introducing parallel frameworks or infrastructure.

## What it covers

- YHTTP application composition and route or model registration
- Server-rendered pages, shared Mako layouts, forms, and metadata
- Localized routes, translated content, and LTR/RTL behavior
- Alpine.js progressive enhancement and Vite-managed assets
- Authentication-aware pages, authorization, and persistence boundaries
- bddrest and project-native page tests
- Safe worktree inspection, verification, and change reporting

The bundled XTA reference also provides concrete patterns for production-style multilingual YHTTP applications.

## Install

Ask Codex to install the skill from this repository:

```text
$skill-installer install https://github.com/yhttp/yhttp-ssr-codex-skill
```

Alternatively, clone it into your user skills directory:

```console
mkdir -p ~/.agents/skills
git clone https://github.com/yhttp/yhttp-ssr-codex-skill.git ~/.agents/skills/yhttp-ssr
```

Codex usually detects new skills automatically. Restart Codex if the skill does not appear in `/skills`.

## Use

Mention the skill explicitly in a Codex prompt:

```text
$yhttp-ssr add a localized contact page with English and Arabic routes.
```

```text
$yhttp-ssr diagnose why this Mako page is not reachable and add a regression test.
```

```text
$yhttp-ssr review the authentication, localization, and asset handling in this SSR feature.
```

Codex can also select the skill automatically when a request matches its scope.

## Repository contents

```text
.
├── SKILL.md                    # Core workflow and implementation guidance
├── agents/openai.yaml          # Skill display metadata and default prompt
├── references/xta-patterns.md  # Concrete XTA architecture and SSR patterns
└── LICENSE
```

## Scope

This skill is intended for work in an existing YHTTP codebase. It does not install YHTTP, replace project-specific instructions, or prescribe a new application architecture. Codex first inspects the target repository, verifies the installed framework and extension APIs, and follows the nearest complete feature before making changes.

## License

Released under the [MIT License](LICENSE).
