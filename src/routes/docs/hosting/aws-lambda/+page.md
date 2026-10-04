---
title: Host on AWS Lambda
description: Deploy a Wisp app to AWS Lambda as a static Linux binary in bootstrap.zip with a Function URL, using the provided.al2023 runtime.
group: Hosting
order: 80
---

AWS Lambda runs the app's own static Linux binary on the `provided.al2023` runtime. Any Wisp binary answers Lambda's runtime API when `AWS_LAMBDA_RUNTIME_API` is set.

## Build

```sh
rustup target add x86_64-unknown-linux-musl     # once
wisp build --target lambda                      # dist/lambda/bootstrap.zip
```

The binary is built with Rust's lld, with no C toolchain.

## Deploy

Create the function once (runtime `provided.al2023`, `x86_64`, handler `bootstrap`) and add a Function URL (or API Gateway or an ALB):

```sh
aws lambda create-function --function-name my-app --runtime provided.al2023 \
  --architectures x86_64 --handler bootstrap --role <role-arn> \
  --zip-file fileb://dist/lambda/bootstrap.zip
```

Then for each release:

```sh
aws lambda update-function-code --function-name my-app --zip-file fileb://dist/lambda/bootstrap.zip
```

`wisp deploy init lambda` writes a GitHub Actions workflow that runs that update on push to `main`. It reads the secret `AWS_ROLE_ARN` (a role GitHub may assume) and the variables `AWS_REGION` and `LAMBDA_FUNCTION`.

## Environment

- `WISP_SECRET` as an environment variable of the function, for an app that signs cookies.
- Other variables: [Environment variables](/docs/env/).

## Limits

- Everything works except WebSockets and streaming (a stream is sent whole).
- The `tower` feature with `lambda_http` also works: [Testing and mixing with Rust code](/docs/embed/).
- There is no cron trigger to write: the build says so and stops when the app uses `wisp::cron`.

## Files and Data

- `static/` is inside the binary.
- Saved tables go in `/tmp`, per instance: use `wisp::store` for lasting data. See [Where rows are kept](/docs/api-tables/).

## More

[Edge and serverless targets](/docs/deploy-targets/), [Deploying](/docs/deploy/).
