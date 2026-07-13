Usage Import
============

.. versionadded:: 1.5

Android maintains application usage history itself; the app imports it
via ``UsageStatsManager`` after the user grants Usage Access — never an
Accessibility Service, never a permanent foreground service
(:doc:`/decisions/adr-0008-os-mediated-mobile-collection`,
:doc:`/post-v1/android-usage`).

The conversion from raw ``UsageEvents`` to intervals is pure Dart
(``quadrant_usage``'s ``AndroidUsageImporter``), shared by every build,
so the Kotlin adapter stays a thin pass-through of
``(package, event type, timestamp)`` triples:

* Resume/pause pairs become intervals; screen-off and shutdown close
  the current span; screen-on alone opens nothing (recording restarts
  on the next resume).
* Vendor streams lose events: a missed pause is repaired by the next
  resume; unmatched pauses and unknown event kinds are ignored;
  out-of-order delivery is sorted before processing. Intervals are
  marked ``confidence: derived``.
* Imports are **idempotent by watermark**: a batch that overlaps the
  previous one (a delayed ``WorkManager`` run, the re-import on app
  open) skips already-imported events, and a span still open at batch
  end is deferred — re-imported completely later, never lost or
  duplicated.
* The privacy policy applies at import time; excluded packages never
  enter intervals. Revoked Usage Access simply yields empty batches;
  the app must show a clear status.

Remaining device-side work (tracked for hardware validation): the
Usage Access onboarding flow, the Kotlin ``usage_stats_adapter``
platform channel, ``WorkManager`` scheduling of periodic imports, and
per-vendor precision checks. The iOS ``DeviceActivity`` entitlement
spike stays a separate capability-flagged experiment
(:doc:`/post-v1/ios-limitations`).
