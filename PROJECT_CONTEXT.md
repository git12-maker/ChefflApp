# Cheffl - Project Context

## App Beschrijving
Cheffl is een premium AI-powered recipe generation en flavor finder app.

## Core Features (MVP)
1. User Authentication (email, Google, Apple)
2. AI Recipe Generation (ingrediënten → recept)
3. Food Scanning (foto → ingrediënten herkennen)
4. Recepten opslaan (favorieten)
5. Premium subscription (free tier + paid)

## Tech Stack
- **Frontend:** Flutter 3.x (Dart)
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **AI:** OpenAI GPT-4 (recipes), GPT-4 Vision (food scan), DALL-E 3 (images)
- **Payments:** RevenueCat + Stripe
- **Notifications:** OneSignal
- **CI/CD:** Codemagic
- **Analytics:** Mixpanel + PostHog

## Design System
- Primary: #1B4D3E (forest green)
- Accent: #D4A574 (warm gold)
- Style: Minimalist, premium, Spotify/Apple inspired
- Typography: Clean, hierarchical
- Dark + Light mode

## Folder Structure
/lib
  /core          - App-wide utilities, constants, themes
  /features      - Feature-based modules
    /auth        - Authentication
    /home        - Home screen
    /generate    - Recipe generation
    /scan        - Food scanning
    /saved       - Saved recipes
    /profile     - User profile
  /shared        - Shared widgets, models
  /services      - API services (Supabase, OpenAI)

## Current Phase
Phase 1: Foundation & Auth
