# Third-Party Notices

This repository may include or reference third-party open-source software.

## Policy

- This project is licensed under MIT for original code (see `LICENSE`).
- Any included third-party code retains its original license and required attribution.
- Third-party licenses (when code is vendored) should be placed under `third_party/<name>/LICENSE`.

## Currently referenced

### Vendored/Referenced Code

- **`omaskery/shenzhen.io-assembler`** (MIT) — Reference implementation for assembler/preprocessor
  - Location: `third_party/omaskery-shenzhen.io-assembler/`
  - License: MIT (see `third_party/omaskery-shenzhen.io-assembler/LICENSE`)
  - Attribution: Original work by omaskery

### External Test Data (Not Distributed)

- **`sunzenshen/shenzhen-io-solutions`** — Community solutions for validation testing
  - Repository: https://github.com/sunzenshen/shenzhen-io-solutions
  - Location: `third_party/solutions/` (gitignored, clone separately)
  - License: Public domain / No copyright (per repo README)
  - Attribution: Alan Shen (@sunzenshen)
  - Coverage: 47 assembly chips tested, 100% compatibility

- **`shiawasenahikari/SHENZHEN-IO-Solutions`** — Comprehensive solution set for validation
  - Repository: https://github.com/shiawasenahikari/SHENZHEN-IO-Solutions
  - Location: `third_party/solutions-shiawasenahikari/` (gitignored, clone separately)
  - License: Not specified
  - Coverage: 407 assembly chips tested, 100% compatibility

- **`StinkingBanana/shenzhen-io-solutions`** — Additional validation solutions
  - Repository: https://github.com/StinkingBanana/shenzhen-io-solutions
  - Location: `third_party/solutions-stinkingbanana/` (gitignored, clone separately)
  - License: Not specified
  - Coverage: 29 assembly chips tested, 100% compatibility

**Total**: 483 real-world assembly chips validated with 100% compatibility  
**Note**: Not included in repository - clone manually and extract via `scripts/extract-solutions.sh`

### Dependencies (NuGet Packages)

- **Newtonsoft.Json** — JSON serialization
- **YamlDotNet** — YAML deserialization
- **NJsonSchema** — JSON schema validation

All NuGet dependencies retain their respective licenses as specified in their packages.

