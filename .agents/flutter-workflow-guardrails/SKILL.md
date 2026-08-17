---
name: flutter-workflow-guardrails
description: Apply this project's Flutter validation and runtime restrictions when modifying, reviewing, or verifying Flutter code. Use for all implementation work in this repository.
---

# Flutter Workflow Guardrails

Follow these project rules during implementation and verification.

## Validation

- Do not run builds or test suites, including `flutter build`, `flutter test`, Gradle builds, or equivalent commands.
- Do not perform broad validation such as full-project analysis unless the user explicitly requests it.
- Use only targeted syntax or rule checks that directly cover changed files or the requested behavior.
- Report any verification that could not be performed under these restrictions.

## Runtime

- Do not start, restart, or probe application, development, emulator, or service processes.
- Do not run service availability, port, device, screenshot, or interactive runtime checks.

## Updates

- Add further project-specific constraints to this skill as they are provided.
