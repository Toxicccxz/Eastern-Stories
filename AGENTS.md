# AGENTS.md

## General Behavior

- Think before coding.
- Make surgical changes only.
- Do not refactor unrelated code.
- Do not add speculative features.
- Every changed line must be related to the user request.
- When the task is ambiguous, state assumptions or ask a focused question.
- Prefer the simplest implementation that solves the current task.

## Flutter and Dart Rules

- Use modern Dart and Flutter best practices.
- Follow Effective Dart.
- Keep code soundly null-safe.
- Avoid using `!` unless the value is guaranteed to be non-null.
- Prefer `const` constructors where possible.
- Do not perform network calls, file IO, or expensive computation inside `build()`.
- Break large widgets into small private Widget classes.
- Prefer composition over inheritance.
- Use meaningful names and avoid abbreviations.
- Keep functions short and focused.

## State Management

- Match the existing project state management style.
- Prefer built-in Flutter solutions first:
  - setState for small local UI state
  - ValueNotifier / ChangeNotifier for simple shared state
  - FutureBuilder / StreamBuilder for async state
- Do not introduce Riverpod, Bloc, Provider, GetX, or other state
  management libraries unless explicitly requested.

## Dependencies

- Do not modify pubspec.yaml unless required.
- Before adding a dependency, explain why it is needed.
- Prefer Flutter SDK and Dart standard library solutions first.

## Project Architecture

- Keep UI, game state, and game rules separate.
- Presentation code belongs in widgets/screens.
- Game logic belongs in domain or controller classes.
- Data models should be simple, immutable where practical, and easy to test.
- Do not create global singletons unless explicitly requested.

## Game Project Rules

- This is a Flutter MUD / text RPG project.
- Prioritize readable UI, clear command input, and maintainable game state.
- Do not add speculative mechanics.
- Do not add combat, inventory, NPC behavior, save files, or map systems
  unless the task asks for them.
- Keep the first implementation simple and expandable.

## Verification

When possible, run:

- flutter analyze
- flutter test

If these cannot be run, explain why.

After changes, summarize:

- files changed
- what changed
- how to manually test it