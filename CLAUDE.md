# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Setup
- `mix setup` - Install dependencies, setup database, and build assets
- `mix phx.server` - Start Phoenix server (accessible at localhost:4000)
- `iex -S mix phx.server` - Start server in interactive Elixir shell

### Database
- `mix ecto.create` - Create database
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop and recreate database with seeds
- `mix ecto.setup` - Create database, run migrations, and seed data

### Testing
- `mix test` - Run all tests (creates test database and runs migrations first)

### Assets
- `mix assets.setup` - Install Tailwind and esbuild if missing
- `mix assets.build` - Build CSS and JS assets
- `mix assets.deploy` - Build and minify assets for production

## Architecture

This is a Phoenix 1.7+ web application using:

### Core Stack
- **Phoenix Framework**: Web framework with LiveView support
- **Ecto**: Database wrapper and query generator with SQLite3
- **Phoenix LiveView**: Real-time web applications without JavaScript
- **Tailwind CSS**: Utility-first CSS framework
- **esbuild**: JavaScript bundler

### Application Structure
- **TealMultiplayer.Application**: OTP application supervisor managing:
  - Database connection pool (TealMultiplayer.Repo)
  - PubSub for real-time features
  - Phoenix endpoint
  - Telemetry and HTTP client (Finch)

### Web Layer
- **Router**: Single browser pipeline with basic page routing
- **Endpoint**: Configured for LiveView WebSocket connections
- **Controllers**: Currently just PageController for home page
- **LiveDashboard**: Available at `/dev/dashboard` in development

### Database
- Uses SQLite3 via Ecto
- Migrations in `priv/repo/migrations/`
- Seeds in `priv/repo/seeds.exs`

### Assets
- Tailwind CSS configuration in `assets/tailwind.config.js`
- JavaScript entry point at `assets/js/app.js`
- Compiled assets output to `priv/static/assets/`

The application appears to be a fresh Phoenix project ready for multiplayer functionality development.