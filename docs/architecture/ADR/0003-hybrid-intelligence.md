# ADR-0003: Hybrid intelligence, on-device by default
**Status:** Accepted architecture direction; SDK integration pending feasibility
**Date:** 2026-11-06

## Context
Remorrow must understand shared messages, screenshots, return notices and informal dates, yet earn revenue via a one-time $4.99 purchase. Pure paid cloud inference creates recurring costs, privacy complexity and availability dependencies. Apple Foundation Models may not be available on older devices.

## Decision
1. Apple Vision OCR converts user-selected images to text locally.
2. Extraction is expressed through a protocol and typed candidate actions. The interface has **no EventKit or notification privileges**.
3. A rules/date-detection engine is the guaranteed baseline and works offline.
4. On eligible devices, optionally select an Apple Foundation Models engine after checking runtime availability, model capability, locale and SDK support; if invalid or unavailable, fall back.
5. The model must return evidence and uncertainty; a validator rejects impossible dates, unsupported output and hallucinated return policies.
6. An eventual cloud engine requires explicit user opt-in, a secure backend, published privacy changes and feature gating. It is not enabled in MVP.
7. Every result requires review and confirmation before any external write.

## Consequences
Strong privacy/cost posture and device coverage, but more complexity in fallbacks and differing quality. Cannot guarantee semantic understanding from rules alone. Treat extraction as suggestions, not autonomous decisions.

## Revisit conditions
Validated device coverage, measured false positives, supported OS SDK changes, cloud economics and consent requirements.
