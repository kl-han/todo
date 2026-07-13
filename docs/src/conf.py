"""Sphinx configuration for Quadrant Todo."""

project = "Quadrant Todo"
author = "Karl Han"
copyright = "2026, Karl Han"
version = "0.3"
release = "0.3.0"

extensions = []

exclude_patterns = ["_build"]

html_theme = "furo"
html_title = "Quadrant Todo"

# Documentation quality gates: the build runs with -W, so any warning
# (broken reference, orphan page, malformed markup) fails CI.
nitpicky = False

linkcheck_ignore = [
    # Example hosts from the API contract.
    r"https://todo\.example\.net.*",
    r"https://quadrant-todo\.invalid.*",
]
