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

```
git clone https://github.com/your-org/Flashcards.git
cd Flashcards
```

Install dependencies:

```
bundle install
```

Set up the database:

```
bin/rails db:create db:migrate
```

Start the development server:

```
bin/rails server
```

The application will be available at http://localhost:3000.

## Available Scripts

Common Rails commands used in this project:

```
bin/rails server        # Start the development server
bin/rails console      # Open Rails console
bin/rails db:migrate   # Run database migrations
bin/rails test         # Run test suite
```

Linting and security tools (development/test):

```
bundle exec rubocop
bundle exec brakeman
bundle exec bundler-audit
```

## Project Scope

Included in MVP:
- User registration and authentication
- Manual flashcard creation (front/back)
- AI-generated flashcards from pasted text
- Preview, edit, save, and delete flashcards
- Spaced repetition reviews based on Anki

Out of scope for MVP:
- Custom spaced repetition algorithm
- File imports (PDF, DOCX, etc.)
- Sharing flashcards between users
- Mobile applications
- Advanced analytics and onboarding

## Project Status

The project is currently in the MVP stage and under active development.

## License

This project is licensed under the MIT License.
