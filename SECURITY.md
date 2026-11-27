# Security Policy

## Supported Versions

Security fixes are provided in the latest released version of strong_csv.

The gem runs on Ruby 2.5 and later, but the Ruby project only maintains
Ruby 3.3 and later. Use a Ruby version that still receives security fixes,
especially when parsing untrusted input.

| Version        | Supported |
| -------------- | --------- |
| Latest release | Yes       |
| Older releases | No        |

## Reporting a Vulnerability

Please report vulnerabilities privately through GitHub's private
vulnerability reporting:

[GitHub private vulnerability reporting](https://github.com/yykamei/strong_csv/security/advisories/new)

Do not open a public issue for a security problem.

Include:

- the strong_csv version,
- the Ruby and csv versions,
- a minimal CSV input and type declaration that reproduces the issue,
- the impact you expect, such as a denial of service or a validation bypass.

We aim to acknowledge a report within 7 days and to publish a fix or
mitigation as soon as practical. We will credit reporters unless they
prefer to remain anonymous.
