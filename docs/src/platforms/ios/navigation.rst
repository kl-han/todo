iOS Navigation
==============

.. versionadded:: 0.4

* **Bottom tab bar** with the same three destinations as Linux — Matrix,
  Tasks, Tags — using Material ``NavigationBar``, which matches iOS thumb
  reach.
* On iPhone-sized widths (< 600 logical pixels) the matrix stacks into a
  **single scrolling column** of quadrant sections, Q1 first; the 2×2 grid
  is a desktop/tablet layout.
* The tag task view pushes onto the navigation stack with the standard
  back affordance and swipe-back gesture.
* The task editor opens as a **modal bottom sheet** (tap the edit icon or
  long-press a task): title, notes, urgent/important switches, tag chips,
  and delete. The sheet respects the keyboard inset and safe areas.
* Completion toggling stays a single tap on the task row — the highest
  frequency action gets the cheapest gesture.
