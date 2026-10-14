# StudeCo manual QA plan

## 1. Registration and authentication
- Create a new student account.
- Confirm email verification flow.
- Sign in successfully.
- Sign out and verify session is cleared.

## 2. Student onboarding
- Select education level: secondary or university.
- Complete profile details.
- Save profile photo and bio.

## 3. Feed and post workflows
- Create text post.
- Create image or PDF attachment.
- Edit and delete authorized post.
- Validate comment and reaction behaviors.

## 4. Groups and resources
- Join a public group.
- Request membership to a private group.
- Verify resource upload metadata is stored correctly.
- Attempt unauthorized access to a private group or resource and confirm denial.

## 5. Messaging
- Send direct message.
- Receive realtime update.
- Test unread state and message history.
- Confirm blocked users cannot message each other.

## 6. Storage exhaustion scenario
1. Student uploads a valid document while uploads are enabled.
2. Admin changes upload state to `LIMIT_REACHED`.
3. Student attempts upload again.
4. UI shows the admin-configured message and optional alternative destination only if enabled.
5. Student can still access unrelated platform features.
6. Admin restores uploads.
7. Student uploads a second valid document successfully.

## 7. Admin access
- Verify superadmin can change settings.
- Verify non-admin cannot edit upload settings.
- Confirm audit log is recorded for sensitive actions.

## 8. Responsive and accessibility checks
- Validate mobile layout.
- Test keyboard navigation on auth and admin forms.
- Check color contrast and readable form labels.
