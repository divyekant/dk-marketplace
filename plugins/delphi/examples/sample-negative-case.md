# GC-002: Login with invalid password

## Metadata
- **Type**: negative
- **Priority**: P0
- **Surface**: ui
- **Flow**: authentication
- **Tags**: login, auth, negative, validation, security
- **Generated**: 2026-02-27
- **Last Executed**: never

## Preconditions
- Application is running at `http://localhost:3000`
- A user account exists with email `test@example.com` and password `TestPass123!`
- User is not currently logged in (no active session)

## Steps

1. Navigate to `http://localhost:3000/login`
   - **Expected**: Login page loads with email and password fields visible

2. Click on the email input field and type `test@example.com`
   - **Target**: Email/username input field
   - **Input**: `test@example.com`
   - **Expected**: Email field shows the entered text

3. Click on the password input field and type `WrongPassword99!`
   - **Target**: Password input field
   - **Input**: `WrongPassword99!`
   - **Expected**: Password field shows masked characters

4. Click the "Sign In" button
   - **Target**: Primary submit/sign-in button
   - **Expected**: Loading indicator appears briefly

5. Observe error response
   - **Expected**: An error message appears (e.g., "Invalid email or password")
   - **Expected**: Error message does NOT reveal whether email or password was wrong (security best practice)
   - **Expected**: User remains on the login page — no redirect occurs
   - **Expected**: URL remains `/login`

6. Verify form state after error
   - **Expected**: Email field retains the entered email (`test@example.com`)
   - **Expected**: Password field is cleared (security best practice) OR retains input (UX choice)
   - **Expected**: "Sign In" button is re-enabled and clickable
   - **Expected**: User can immediately attempt another login

## Success Criteria
- [ ] Error message appears and is user-friendly
- [ ] Error message does not leak information about which credential was wrong
- [ ] User remains on login page (no redirect)
- [ ] Form is usable for retry without page refresh
- [ ] No console errors beyond the expected 401/403 API response
- [ ] No sensitive data exposed in console or network tab

## Failure Criteria
- Login succeeds with wrong password (critical security issue)
- Error message reveals whether email exists (information disclosure)
- Page crashes or becomes unresponsive
- Form is broken after failed attempt (fields disabled, button stuck)
- Sensitive data (password, tokens) visible in console logs

## Notes
- Run this case BEFORE testing rate limiting (GC-003) to avoid lockout
- The error message wording may vary — focus on whether it's generic vs. specific
- Check network tab to ensure password is not sent in URL parameters (should be POST body only)
