# Remorrow on-device intelligence — integration

The app targets iOS 17 and runs `SmartExtractionPipeline`. Its baseline is `ConversationContextEngine`, which calls deterministic local date parsing, identifies explicit first-person undated tasks, and flags ambiguous commitments. No messages are automatically collected.

On devices with an iOS SDK supporting `FoundationModels` and with Apple Intelligence available and enabled, `AppleOnDeviceExtractionEngine` can classify the *user-selected* conversation into grounded action excerpts using `SystemLanguageModel.default` and a local `LanguageModelSession`. No server or external API is used. All model excerpts must match the source verbatim; proposed dates come from validated local parsing, not from generated date strings. Any unavailable model, model error, or invalid output falls back to local rules. Both engines require user approval before EventKit writes.

**Verification limits:** The GitHub workflow's installed Xcode may not include the FoundationModels framework, so the guarded iOS 26 code path can be excluded by the compiler. Actual Apple Intelligence functionality must be built and run with the iOS 26+ SDK on an eligible, configured device. This integration is a capability-gated first slice, not a guarantee of perfect conversational understanding.

Do not claim that Apple's model understands unrelated photos or has permission to scan SMS. App Intent and Share Extension receive only user-provided content.
