# Authentication Setup Guide

## Overview
SmartWebV3 uses NextAuth.js with Supabase adapter for authentication. The system supports multiple authentication methods:
- Email/Password
- Magic Link (Email)
- Google OAuth
- Microsoft Azure AD OAuth

## Prerequisites
1. Supabase project with authentication enabled
2. Google OAuth credentials
3. Microsoft Azure AD app registration
4. SMTP server for email authentication

## Configuration Steps

### 1. Environment Variables
Copy `.env.example` to `.env.local` and fill in your values:

```bash
cp .env.example .env.local
```

### 2. Supabase Setup
1. Create a new Supabase project
2. Copy the project URL and anon key to `.env.local`
3. Copy the service role key (for NextAuth adapter)

### 3. Google OAuth Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URI: `http://localhost:3000/api/auth/callback/google`
6. Copy client ID and secret to `.env.local`

### 4. Microsoft Azure AD Setup
1. Go to [Azure Portal](https://portal.azure.com/)
2. Register a new application
3. Add redirect URI: `http://localhost:3000/api/auth/callback/azure-ad`
4. Create a client secret
5. Copy application ID, secret, and tenant ID to `.env.local`

### 5. Email Provider Setup
Configure your SMTP settings in `.env.local` for email authentication.

## Testing the Authentication

1. Start the development server:
```bash
npm run dev
```

2. Navigate to http://localhost:3000
3. Click "Get Started" to access the sign-in page
4. Test each authentication method

## User Roles
The system supports the following roles:
- `super_admin`: Full system access
- `org_admin`: Organization-level administration
- `sales_manager`: Sales team management
- `sales_rep`: Sales representative access
- `user`: Basic user access

## Security Considerations
- Always use HTTPS in production
- Keep your `.env.local` file secure and never commit it
- Regularly rotate your API keys and secrets
- Enable 2FA for admin accounts (AUTH-005 ticket)