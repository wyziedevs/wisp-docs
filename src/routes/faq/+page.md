---
title: FAQ
description: Short answers to common questions about Wisp.
---

<div class="faq">
<details name="faq">
<summary>What Is Wisp?</summary>
<p>A web framework for Rust. Files are routes, <code>.wisp</code> templates compile to Rust, forms post to actions, and the app ships as one binary. Start with <a href="/docs/why/">Why Wisp</a> or the <a href="/docs/quick-start/">Quick Start</a>.</p>
</details>
<details name="faq">
<summary>Do I Need to Know Rust?</summary>
<p>Yes. Route logic, actions and models are Rust. The templates read like HTML, and the compiler infers most types, so app code stays short.</p>
</details>
<details name="faq">
<summary>How Is It So Fast?</summary>
<p>Templates and routes compile to Rust, so a request runs plain compiled code. The I/O drivers answer most requests without waking a task, and a route pays only for the features it uses. <a href="/docs/benchmarks/">Benchmarks</a> has the details.</p>
</details>
<details name="faq">
<summary>How Does It Compare With SvelteKit or Next.js?</summary>
<p>It aims at the same job, with file routes, form actions and server rendering, in Rust. The measured gaps are in speed (<a href="/docs/benchmarks/">Benchmarks</a>) and in tokens (<a href="/docs/tokens/">Tokens</a>).</p>
</details>
<details name="faq">
<summary>Does It Work Without JavaScript?</summary>
<p>Yes. A form posts to its action and the server answers with HTML. With JavaScript on, the page updates in place. Components ship no JavaScript unless you add some.</p>
</details>
<details name="faq">
<summary>Where Can I Host It?</summary>
<p>Anywhere a binary runs, in a container, as static HTML, or built for Cloudflare, Deno, Vercel, Netlify, Node, Bun or Lambda. See <a href="/docs/deploy/">Deploying</a>.</p>
</details>
<details name="faq">
<summary>Is There a Database or Auth Built In?</summary>
<p>Wisp gives tools, not services: a table type that keeps rows in log files or any database, sessions, password hashing, signed tokens and OAuth helpers. See <a href="/docs/data/">Data</a> and <a href="/docs/auth/">Auth</a>.</p>
</details>
<details name="faq">
<summary>Does It Use Unsafe Code?</summary>
<p>Not outside the Linux I/O drivers and the edge exports. See <a href="/docs/security/">Security and Hardening</a>.</p>
</details>
<details name="faq">
<summary>Which Editors Work?</summary>
<p><code>wisp lsp</code> powers a VS Code extension, and there is support for Zed, tree-sitter and Prettier. See <a href="/docs/design-editors/">AI Agents and Editors</a>.</p>
</details>
<details name="faq">
<summary>How Do I Use It With an AI Agent?</summary>
<p><a href="https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md">AGENTS.md</a> is the whole reference in one file, and <code>wisp mcp</code> serves the docs over MCP: <code>claude mcp add wisp -- wisp mcp</code>.</p>
</details>
<details name="faq">
<summary>Where Do I Ask a Question or Report a Bug?</summary>
<p>On <a href="/community/">Community</a>: the Discord, GitHub Discussions and the issue trackers.</p>
</details>
</div>
