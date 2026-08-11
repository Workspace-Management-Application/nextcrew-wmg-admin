# Repository Guidelines

## Project Structure & Module Organization

This is a Ruby on Rails 8 admin/API application. Core code lives in `app/`: `models`, `controllers`, `views`, `mailers`, `jobs`, and `services`. Admin UI controllers and views are under `app/controllers/admin` and `app/views/admin`; JSON API endpoints are under `app/controllers/api`. Frontend entry points and Stimulus controllers live in `app/javascript`, while CSS and static assets are in `app/assets` and `public`. Migrations, schema files, and seeds are in `db`. Tests use Rails’ default layout under `test`, with fixtures in `test/fixtures`.

## Build, Test, and Development Commands

- `bin/setup`: install gems, prepare the database, clear logs/temp files, and start the server unless `--skip-server` is passed.
- `bin/dev`: run the Rails development server.
- `bin/rails db:prepare`: create, migrate, or load the database schema as needed.
- `bin/rails test`: run the Minitest suite.
- `bin/rubocop`: check Ruby style using RuboCop Rails Omakase.
- `bin/brakeman`: run static security analysis.

Use `bundle install` only when dependencies are missing or `Gemfile` changes.

## Coding Style & Naming Conventions

Follow standard Rails conventions and existing directory boundaries. Use two-space indentation for Ruby, ERB, CSS, and JavaScript. Name Ruby files in `snake_case`, classes/modules in `CamelCase`, and Rails test files as `*_test.rb`. Keep controllers thin; place reusable business logic in models or `app/services`. Prefer Rails helpers, scopes, validations, and Active Record associations when they fit.

## Testing Guidelines

Tests are written with Minitest, but this project currently does not maintain meaningful test coverage. Do not add new test cases or modify fixtures/test setup unless the user explicitly asks for tests. When verifying changes, prefer syntax checks, route checks, manual workflow checks, or existing commands that do not require creating new tests. If the user specifically requests tests, place them in the standard Rails locations under `test`.

## Commit & Pull Request Guidelines

Recent history uses short, imperative summaries such as `Fixed searching issue in company sidebar` and `Add 'Created At'... fields`. Keep commit subjects concise and behavior-focused. For pull requests, include a clear description, linked issue or task when applicable, test results, and screenshots for visible admin UI changes. Call out migrations, environment variable changes, background job impacts, or deployment steps explicitly.

## Security & Configuration Tips

Do not commit secrets. Runtime configuration belongs in Rails credentials, environment variables, or deployment configuration, not source files. Be careful with authentication changes involving Devise, JWT denylist behavior, CORS, file uploads, or S3 configuration, and cover them with tests where practical.
