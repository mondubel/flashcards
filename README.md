# Flashcards

A web application for creating and learning with flashcards using spaced repetition, with a strong focus on AI-assisted flashcard generation.

## Table of Contents
- Project Description
- Tech Stack
- Getting Started Locally
- Available Scripts
- Project Scope
- Project Status
- License

## Project Description

Flashcards is a web-based educational application designed to reduce the friction of creating high-quality flashcards for spaced repetition learning.
The core idea of the product is to use AI to generate flashcards from pasted text, allowing users to focus on learning rather than manual content preparation. Users can also create flashcards manually, manage their collection, and review cards using a spaced repetition algorithm based on Anki.

## Tech Stack

Frontend – Ruby on Rails (Views) + Turbo:
- Ruby on Rails views for server-side rendered HTML
- Turbo (Hotwire) for dynamic interactions without full page reloads
- Tailwind CSS for styling

Backend – Ruby on Rails:
- Ruby on Rails as a monolithic application
- ActiveRecord ORM
- PostgreSQL database

Authentication:
- Devise for user registration and login (email + password)

AI:
- Openrouter.ai for communication with large language models

CI/CD and Hosting:
- GitHub Actions for CI/CD pipelines
- AWS for application hosting

## Getting Started Locally

### Prerequisites

- Ruby 3.4.6
- PostgreSQL
- Bundler

### Setup

Clone the repository:

```bash
git clone https://github.com/your-org/Flashcards.git
cd Flashcards
```

Install dependencies:

```bash
bundle install
```

Configure OpenRouter API (required for AI flashcard generation):

```bash
# Set environment variable for development
export OPENROUTER_API_KEY='sk-or-v1-your-key-here'

# Get your API key from: https://openrouter.ai
```

Set up the database:

```bash
bin/rails db:create db:migrate db:seed
```

Start the development server:

```bash
bin/dev
```

The application will be available at http://localhost:3000.

## Available Scripts

Common Rails commands used in this project:

```bash
bin/dev                # Start development server (recommended)
bin/rails server       # Start Rails server only
bin/rails console      # Open Rails console
bin/rails db:migrate   # Run database migrations
bundle exec rspec      # Run test suite
```

Linting and security tools (development/test):

```
bin/rubocop                          # Lint Ruby code
bundle exec erb_lint --lint-all      # Lint ERB templates
bundle exec brakeman                 # Security vulnerability scanner
bundle exec bundler-audit            # Check for vulnerable dependencies
```

Auto-fix linting issues:

```
bin/rubocop -a                                 # Auto-fix Ruby code issues
bundle exec erb_lint --lint-all --autocorrect  # Auto-fix ERB template issues
```

## Project Scope

Included in MVP:
- User registration and authentication
- Manual flashcard creation (front/back)
- AI-generated flashcards from pasted text
- Preview, edit, save, and delete flashcards

Out of scope for MVP:
- Spaced repetition reviews based on Anki
- Custom spaced repetition algorithm
- File imports (PDF, DOCX, etc.)
- Sharing flashcards between users
- Mobile applications
- Advanced analytics and onboarding

## Project Status

The project is currently in the MVP stage and under active development.

## Services Architecture

### OpenRouterService

Low-level API client for OpenRouter.ai communication:
- Handles HTTP requests and authentication
- Manages structured JSON responses
- Comprehensive error handling
- SSL configuration for development

### FlashcardGenerationService

High-level service for AI flashcard generation:
- Intelligent prompt engineering
- Response validation and formatting
- Quality control (length, content)
- Multiple model support

## License

This project is licensed under the MIT License.
