# App Icon

## Generation Prompt
JawScore iOS app icon, a stylized side-profile jawline silhouette formed by glowing neon teal lines combined with a bold score badge shape, futuristic face-scan aesthetic, large dominant subject filling the entire square frame, edge-to-edge composition, no padding, no margin, no empty space, no transparent edges, solid very dark navy-black background, flat design, simple bold shapes, professional, clean, no text, no words, no letters, square format, 1024x1024

## Generated Image
- File: `JawScore/JawScore/Assets.xcassets/AppIcon.appiconset/icon_1024.png`
- Style: Neon teal (#00E5C7) jawline side-profile on dark navy-black (#0A0C10) background — matches brand palette (electric teal primary + dark-first)
- API: Agnes Image 2.1 Flash (primary, 1 attempt — success)
- Post-processing: cropped 12% inward to remove rounded-corner overflow, subject scaled to fill frame, converted to RGB (no alpha)

## Alpha Verification
- `sips -g hasAlpha` → `hasAlpha: no` ✅

## Asset Catalog
- AppIcon.appiconset configured: ✅ (single 1024x1024 universal icon, used for any/dark/tinted appearances)
- All sizes generated: ✅ (single-size catalog — Xcode generates all derived sizes at build time)
