# REST API Plan - Flashcards Application

## 1. Resources

### Primary Resources
- **Users** - Maps to `users` table (managed by Devise)
- **Flashcards** - Maps to `flashcards` table
- **Generations** - Maps to `generations` table

### Resource Relationships
- User has many Flashcards (1:N)
- User has many Generations (1:N)
- Generation has many Flashcards (1:N, optional)
- Flashcard belongs to User (required)
- Flashcard belongs to Generation (optional, NULL for manual cards)

## 2. Endpoints

### 2.1 Authentication Endpoints (Devise)

### 2.2 Flashcards Endpoints

#### List All Flashcards
- **Method:** `GET`
- **Path:** `/flashcards`
- **Description:** Retrieve all flashcards for current user
- **Success Response (200 OK):**
```json
{
  "flashcards": [
    {
      "id": 1,
      "front": "What is Ruby on Rails?",
      "back": "A web application framework written in Ruby",
      "source": "manual",
      "generation_id": null,
      "created_at": "2026-01-14T10:00:00Z",
      "updated_at": "2026-01-14T10:00:00Z"
    },
    {
      "id": 2,
      "front": "What is PostgreSQL?",
      "back": "An open-source relational database",
      "source": "ai-full",
      "generation_id": 1,
      "created_at": "2026-01-14T11:00:00Z",
      "updated_at": "2026-01-14T11:00:00Z"
    }
  ]
}
```
- **Authentication:** Required

#### Get Single Flashcard
- **Method:** `GET`
- **Path:** `/flashcards/:id`
- **Description:** Retrieve a specific flashcard
- **Success Response (200 OK):**
```json
{
  "id": 1,
  "front": "What is Ruby on Rails?",
  "back": "A web application framework written in Ruby",
  "source": "manual",
  "generation_id": null,
  "created_at": "2026-01-14T10:00:00Z",
  "updated_at": "2026-01-14T10:00:00Z"
}
```
- **Error Responses:**
  - `404 Not Found` - Flashcard doesn't exist or doesn't belong to user
- **Authentication:** Required

#### Create Manual Flashcard
- **Method:** `POST`
- **Path:** `/flashcards`
- **Description:** Create one or more flashcards (manual or from AI proposal)
- **Request Body:**
```json
{
  "flashcards": [
    {
        "front": "What is Ruby on Rails?",
        "back": "A web application framework written in Ruby",
        "source": "manual",
        "generation_id": null
    },
    {
        "front": "What is Ruby on Rails?",
        "back": "A web application framework written in Ruby",
        "source": "manual",
        "generation_id": null
    },
  ]
}
```
- **Success Response (201 Created):**
- **Error Responses:**
  - `422 Unprocessable Entity` - Validation errors
- **Authentication:** Required
- **Validation:**
  - `front` - required, max 200 characters
  - `back` - required, max 500 characters

#### Update Flashcard
- **Method:** `PATCH/PUT`
- **Path:** `/flashcards/:id`
- **Description:** Update an existing flashcard (manual or AI-generated)
- **Request Body:**
```json
{
  "flashcard": {
    "front": "Updated question?",
    "back": "Updated answer"
  }
}
```
- **Success Response (200 OK):**
```json
{
  "id": 1,
  "front": "Updated question?",
  "back": "Updated answer",
  "source": "ai-edited",
  "generation_id": 1,
  "created_at": "2026-01-14T10:00:00Z",
  "updated_at": "2026-01-14T12:00:00Z"
}
```
- **Error Responses:**
  - `404 Not Found` - Flashcard doesn't exist or doesn't belong to user
  - `422 Unprocessable Entity` - Validation errors
- **Authentication:** Required
- **Business Logic:** If source was `ai-full`, change to `ai-edited` upon update

#### Delete Flashcard
- **Method:** `DELETE`
- **Path:** `/flashcards/:id`
- **Description:** Delete a flashcard (hard delete, removes from review cycle)
- **Success Response (204 No Content)**
- **Error Responses:**
  - `404 Not Found` - Flashcard doesn't exist or doesn't belong to user
- **Authentication:** Required

### 2.3 Generations Endpoints

#### Create New Generation
- **Method:** `POST`
- **Path:** `/generations`
- **Description:** Initiate the AI generation process for flashcards proposals based on user-provided text.
- **Request Body:**
```json
{
  "generation": {
    "source_text": "Ruby on Rails is a web application framework written in Ruby under the MIT License. Rails is a model–view–controller framework..."
  }
}
```
- **Success Response (201 Created):**
```json
{
  "id": 1,
  "source_text": "Ruby on Rails is a web application framework...",
  "model": "gpt-4",
  "generation_duration": 3450,
  "generated_count": 15,
  "accepted_unedited_count": null,
  "accepted_edited_count": null,
  "created_at": "2026-01-14T10:00:00Z",
  "flashcards_proposals": [
    {
      "id": null,
      "front": "What is Ruby on Rails?",
      "back": "A web application framework written in Ruby",
      "source": "ai-full"
    },
    {
      "id": null,
      "front": "Under what license is Rails released?",
      "back": "MIT License",
      "source": "ai-full"
    }
  ]
}
```
- **Error Responses:**
  - `422 Unprocessable Entity` - Validation errors
  ```json
  {
    "errors": {
      "source_text": ["is too short (minimum is 1000 characters)", "is too long (maximum is 10000 characters)"]
    }
  }
  ```
  - `503 Service Unavailable` - AI service error
  ```json
  {
    "error": "AI service temporarily unavailable",
    "details": "Please try again later"
  }
  ```
- **Authentication:** Required
- **Validation:**
  - `source_text` - required, min 1000 characters, max 10000 characters
- **Business Logic:**
  - Maximum 20 flashcards generated per request
  - Generated flashcards are not saved automatically
  - Records generation duration and model used

#### Get Generation Details
- **Method:** `GET`
- **Path:** `/generations/:id`
- **Description:** Retrieve generation details with preview of generated flashcards
- **Success Response (200 OK):**
```json
{
  "id": 1,
  "source_text": "Ruby on Rails is a web application framework...",
  "model": "gpt-4",
  "generation_duration": 3450,
  "generated_count": 15,
  "accepted_unedited_count": 10,
  "accepted_edited_count": 3,
  "created_at": "2026-01-14T10:00:00Z",
  "flashcards": [
    {
      "id": 5,
      "front": "What is Ruby on Rails?",
      "back": "A web application framework written in Ruby",
      "source": "ai-full",
      "saved": true
    },
    {
      "id": 6,
      "front": "Under what license is Rails released?",
      "back": "MIT License",
      "source": "ai-edited",
      "saved": true
    }
  ]
}
```
- **Error Responses:**
  - `404 Not Found` - Generation doesn't exist or doesn't belong to user
- **Authentication:** Required

#### List User Generations
- **Method:** `GET`
- **Path:** `/generations`
- **Description:** Retrieve generation history for current user
- **Query Parameters:**
  - `page` (integer, optional) - Page number
  - `per_page` (integer, optional, default: 20) - Items per page
- **Success Response (200 OK):**
```json
{
  "generations": [
    {
      "id": 1,
      "model": "gpt-4",
      "generation_duration": 3450,
      "generated_count": 15,
      "accepted_unedited_count": 10,
      "accepted_edited_count": 3,
      "created_at": "2026-01-14T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 25,
    "per_page": 20
  }
}
```
- **Authentication:** Required

### 2.4 Dashboard Endpoint

#### Get Dashboard Data
- **Method:** `GET`
- **Path:** `/dashboard`
- **Description:** Get overview data for user dashboard
- **Success Response (200 OK):**
- **Authentication:** Required

## 3. Authentication and Authorization

### Authentication Mechanism
- **Strategy:** Session-based authentication via Devise
- **Implementation:**
  - Devise handles user registration, login, logout
  - Session cookie stores authentication state
  - CSRF protection enabled via Rails
  - `authenticate_user!` before_action in controllers

### Authorization Rules
- **Scope-based Authorization:**
  - All flashcard operations scoped to `current_user.flashcards`
  - All generation operations scoped to `current_user.generations`
  - All review operations scoped to `current_user.flashcards`
  
- **Access Control:**
  - Users can only access their own flashcards
  - Users can only access their own generations
  - Users can only review their own flashcards
  - No admin or public access in MVP

### Security Measures
- **CSRF Protection:** Rails default CSRF tokens for all state-changing requests
- **Rate Limiting:**
  - Generation endpoint: 10 requests per hour per user
  - Review submission: 100 requests per hour per user
  - Other endpoints: 100 requests per minute per user
- **Input Sanitization:** Rails default parameter sanitization and strong parameters
- **Password Security:** Devise default bcrypt encryption with cost factor 12

## 4. Validation and Business Logic

### 4.1 Flashcard Validation

**Model-Level Validations:**
- `front` - presence: true, length: { maximum: 200 }
- `back` - presence: true, length: { maximum: 500 }
- `source` - presence: true, inclusion: { in: ['manual', 'ai-full', 'ai-edited'] }
- `user_id` - presence: true
- `generation_id` - presence: true (if source is 'ai-full' or 'ai-edited')

**Business Rules:**
- Manual flashcards must have `source: 'manual'` and `generation_id: nil`
- AI flashcards generated but not edited have `source: 'ai-full'`
- AI flashcards that were edited before or after saving have `source: 'ai-edited'`
- When updating a flashcard with `source: 'ai-full'`, automatically change to `'ai-edited'`
- Deleted flashcards are permanently removed (hard delete)
- Deleting flashcard also removes it from Anki review cycle

### 4.2 Generation Validation

**Model-Level Validations:**
- `source_text` - presence: true, length: { minimum: 1000, maximum: 10000 }
- `user_id` - presence: true
- `generated_count` - presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 20 }

**Business Rules:**
- Generate maximum 20 flashcards per request
- Generated flashcards are returned but not saved automatically
- User must explicitly save selected flashcards via `/generations/:id/flashcards`
- Record generation duration and model used for analytics
- Update `accepted_unedited_count` when user saves AI flashcards without editing
- Update `accepted_edited_count` when user saves AI flashcards with edits
- Calculate acceptance rate: `(accepted_unedited_count + accepted_edited_count) / generated_count`

**AI Integration Logic:**
- Call Openrouter.ai API with source text
- Timeout: 30 seconds
- Retry: 2 attempts with exponential backoff
- Error handling: Return user-friendly error if AI service fails
- Prompt engineering: Request structured JSON response with front/back pairs
- Post-processing: Validate length constraints before returning to user


### 4.3 User Validation

**Model-Level Validations (Devise):**
- `email` - presence: true, uniqueness: true, format: email regex
- `password` - presence: true (on creation), length: { minimum: 6 }

**Business Rules:**
- Email confirmation not required in MVP
- Password reset via email token
- Session expires after 2 weeks of inactivity

## 5. Success Metrics Tracking

### 5.1 AI Acceptance Rate
**Calculation:** 
```
(accepted_unedited_count + accepted_edited_count) / generated_count * 100
```
**Target:** 75% of AI-generated flashcards are saved

**Implementation:**
- Track at generation level
- Update counters when flashcards are saved
- Aggregate across all users for system-wide metric

### 5.2 AI Flashcards Percentage
**Calculation:**
```
COUNT(flashcards WHERE source IN ('ai-full', 'ai-edited')) / COUNT(flashcards) * 100
```
**Target:** 75% of all flashcards come from AI generation

**Implementation:**
- Query database for counts by source
- Calculate percentage at user and system level
