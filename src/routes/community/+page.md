---
title: Community
description: Where to get help with Wisp, report a bug and contribute to the framework or these docs.
---

Wisp is an open source project, and it lives on GitHub. This page lists the places where work on it happens.

## Get Help

Start with the docs. [Quick Start](/docs/quick-start) and the [Tutorial](/docs/tutorial) cover the everyday path, and the search box finds any page. For a question the docs do not answer, open an issue and say what you tried:

- [Wisp issues](https://github.com/wyziedevs/wisp/issues) for questions and problems with the framework, the `wisp` command or an example.
- [Docs issues](https://github.com/wyziedevs/wisp-docs/issues) for a mistake, a gap or an unclear page on this site.

If you work with a coding agent, [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) is the whole framework reference in one file, and `wisp mcp` serves the docs to the agent over MCP: `claude mcp add wisp -- wisp mcp`.

## Report a Bug

Open an issue on [wyziedevs/wisp](https://github.com/wyziedevs/wisp/issues). A report is easiest to act on when it has:

- The Wisp version and your operating system
- The smallest page or route that shows the problem
- What you expected and what happened, with the error text if there is any

## Contribute to Wisp

Issues and pull requests are welcome at [wyziedevs/wisp](https://github.com/wyziedevs/wisp). Before you change code, read the design rule at the top of [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md): speed first, then cheap in tokens for app authors, then durable, then flexible.

The repository's `CLAUDE.md` lists the commands a change has to pass: `cargo build`, `cargo test -q`, `cargo fmt --check` and `cargo clippy --all-targets -- -D warnings`. A change to the API, the syntax, the CLI or behavior also updates the docs in the same change.

The [examples](https://github.com/wyziedevs/wisp/tree/main/examples) are a good place to see how a feature is used, and a good place to add one.

## Contribute to the Docs

This site is a Wisp app, in [wyziedevs/wisp-docs](https://github.com/wyziedevs/wisp-docs). Every docs page is a Markdown file at `src/routes/docs/<slug>/+page.md`, and each page has an edit link at the bottom. A fix to a typo, a sample that does not run or a missing explanation is a good first pull request.

## License

Wisp is released under the [MIT license](https://github.com/wyziedevs/wisp/blob/main/LICENSE).
