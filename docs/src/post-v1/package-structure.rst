Package Structure
=================

.. code-block:: text

   packages/
   ├── quadrant_temporal/
   │   ├── recurrence/
   │   ├── occurrence_generation/
   │   └── timezone/
   ├── quadrant_input/          # v2.1: inline #/! entry parsing
   │   └── inline_entry/
   ├── quadrant_query/          # v2.1: boolean filter-rule language
   │   └── filter_rule/
   ├── quadrant_reminders/
   │   ├── scheduler/
   │   └── platform_contract/
   ├── quadrant_focus/
   │   ├── sessions/
   │   └── timer/
   ├── quadrant_usage/
   │   ├── events/
   │   ├── intervals/
   │   ├── aggregation/
   │   └── privacy/
   ├── quadrant_planning/
   │   ├── daily_plan/
   │   └── weekly_review/
   └── quadrant_agent/
       ├── gateway/
       ├── lifecycle/
       └── local_api/

   platform/
   ├── android/
   │   └── usage_stats_adapter/
   ├── ios/
   │   └── device_activity_adapter/
   ├── linux/
   │   ├── sway_ipc_adapter/
   │   └── idle_adapter/
   └── windows/
       ├── foreground_adapter/
       └── idle_adapter/

The pure-Dart packages follow the existing layering rules: business
rules live in the domain and application layers, never in widgets or
REST handlers, and platform adapters implement narrow contracts defined
by the pure packages.
