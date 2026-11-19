# SpookyAI Privacy Policy

**Effective date:** November 15, 2026

SpookyAI ("we", "our", "us") is an AI photo and art app. This policy explains what data the SpookyAI mobile app (the "App") handles, why, who processes it and what choices you have.

**In short:** SpookyAI has no user accounts. Your creations are stored on your own device. The photos and prompts you submit are sent to our AI provider only to create your image or video. We do not sell your data, show ads or track you across other apps.

## 1. Data we handle

| Data | When | Why |
|---|---|---|
| **Photos you upload** (they may show faces) | Image-to-image and photo-to-video | To create the result you asked for |
| **Prompts** (text you type or a ready-made style you pick) | Every generation | To create the result you asked for |
| **Generated images and videos** | Every generation | Saved **only on your device** (My Photos) |
| **Ratings** (1–5 stars, the prompt, style name, app version, platform) | When you rate a result | To improve styles and quality |
| **Content reports** (prompt, reason, optional details, the reported image if small enough) | When you report a result | To review and act on harmful content |
| **Device identifier** (Android ID or an app-specific iOS Keychain ID) | First free-token trial, ratings, reports | To prevent trial and reward abuse and to limit report spam |
| **Purchase information** (product, transaction and subscription status) | When you buy tokens or Premium | To deliver and restore purchases |
| **Token balance and app settings** | While you use the App | Stored on your device |

We do **not** collect your name, email address, contacts, location, advertising ID or browsing history. We do not use your photos or face data to identify you, for facial recognition, or to train AI models.

## 2. How photos and face data are processed

When you generate an image or video, your photo and prompt are sent over an encrypted connection to our server proxy (hosted on Cloudflare). The proxy forwards them to **fal.ai**, our AI generation provider, and returns the result to your device. The proxy does not keep your photos or prompts.

fal.ai processes this content only to produce your result. Generated files may be stored temporarily by fal.ai so the App can download them. After that, the result exists only on your device unless you share it. Photos that show faces are used only to create the result you requested and are never used to identify you or kept by us.

## 3. Service providers

| Provider | Purpose | Data |
|---|---|---|
| **fal.ai** | AI image and video generation | Uploaded photos, prompts, generated results |
| **Cloudflare** (Workers) | Secure proxy and one-trial-per-device check | Requests in transit; a salted SHA-256 hash of the device ID for the trial check |
| **Google Firebase** (Cloud Firestore) | Ratings and content reports | The rating and report data listed above, device ID |
| **RevenueCat**, **Apple App Store**, **Google Play** | Purchases and subscriptions | Purchase and subscription data, an anonymous app user ID |

Each provider processes data under its own privacy policy and only as needed to provide its service to us.

## 4. Retention

- **Your creations, settings and token balance** stay on your device until you delete them or uninstall the App.
- **Ratings** are kept for up to 2 years.
- **Content reports** are kept for up to 2 years for review, enforcement and appeals.
- **Trial hashes** are kept as long as needed to prevent repeated free trials.

## 5. Your choices and rights

- Delete any creation in **My Photos**, or uninstall the App to remove all local data.
- Photo and camera access can be turned off at any time in your device settings.
- Manage or cancel subscriptions in your App Store or Google Play account settings.
- To ask about, get a copy of, or delete the ratings and reports linked to your device, email us with the request (you can find your device's app version in Settings). Depending on where you live (for example under the GDPR or the CCPA), you may also have the right to access, correct, delete or object to the processing of your data. We will respond within 30 days.

## 6. Content safety

Prompts are checked by automated moderation before generation. You can report any generated result from inside the App. Reports are reviewed, and we may block prompts or styles that break our rules. See our [Terms of Use](TERMS_OF_USE.md) and content guidelines.

## 7. Children

SpookyAI is not directed to children under 13 (or the minimum age required in your country), and we do not knowingly collect their data. If you believe a child has used the App, contact us and we will delete any related data.

## 8. Security

All data is sent over encrypted connections (HTTPS). AI provider keys live only on our server proxy, never in the App. Ratings and reports cannot be read or changed by any user of the App.

## 9. International transfers

Our providers may process data in the United States and other countries. Where required, transfers rely on appropriate safeguards such as Standard Contractual Clauses.

## 10. Changes

We may update this policy as the App changes. We will update the effective date above and, for significant changes, tell you in the App.

## 11. Contact

**Email:** spookyaihelp@gmail.com
