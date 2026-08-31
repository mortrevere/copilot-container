#!/usr/bin/env bash
set -euo pipefail

copilot plugin marketplace add DietrichGebert/ponytail \
  && copilot plugin install ponytail@ponytail
