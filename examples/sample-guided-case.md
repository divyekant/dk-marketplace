# GC-001: Login with valid credentials

## Metadata
- **Type**: positive
- **Priority**: P0
- **Surface**: ui
- **Flow**: authentication
- **Tags**: login, auth, happy-path
- **Generated**: 2026-02-27
- **Last Executed**: never

## Preconditions
- Application is running at `http://localhost:3000`
- A user account exists with email `test@example.com` and password `TestPass123!`
- User is not currently logged in (no active session)

## Steps

1. Navigate to `http://localhost:3000/login`
   - **Expected**: Login page loads with email and password fields visible
   - **Expected**: "Sign In" button is present and disabled (or enabled, depending on app)
   - **Expected**: No console errors

2. Click on the email input field and type `test@example.com`
   - **Target**: Email/username input field
   - **Input**: `test@example.com`
   - **Expected**: Email field shows the entered text
   - **Expected**: No validation errors appear yet

3. Click on the password input field and type `TestPass123!`
   - **Target**: Password input field
   - **Input**: `TestPass123!`
   - **Expected**: Password field shows masked characters (dots or asterisks)
   - **Expected**: "Sign In" button becomes enabled (if it was disabled)

4. Click the "Sign In" button
   - **Target**: Primary submit/sign-in button
   - **Expected**: Loading indicator appears (spinner, disabled button, or progress bar)
   - **Expected**: No duplicate requests sent (button is disabled during submission)

5. Wait for redirect to complete
   - **Expected**: User is redirected to `/dashboard` or home page
   - **Expected**: URL changes from `/login` to the authenticated landing page
   - **Expected**: Login page is no longer visible

6. Verify authenticated state
   - **Expected**: User's name or email is displayed in the header/navbar
   - **Expected**: Navigation shows authenticated menu items (e.g., "Settings", "Logout")
   - **Expected**: No "Sign In" or "Register" links visible in the navigation

## Success Criteria
- [ ] All expected outcomes match actual behavior
- [ ] No console errors during the entire flow
- [ ] Page remains responsive throughout
- [ ] Redirect happens within 3 seconds of clicking Sign In
- [ ] Authenticated state persists on page refresh

## Failure Criteria
- Any step's expected outcome does not match actual behavior
- Console shows unhandled errors or exceptions
- Page becomes unresponsive or crashes
- Login succeeds but redirect does not happen
- Authenticated state is lost on refresh

## Notes
- If the app uses OAuth/SSO instead of email+password, this case needs adaptation
- Some apps may have a "Remember me" checkbox — this case does not test that feature
- Rate limiting may interfere if this case is run repeatedly; wait between executions if needed
