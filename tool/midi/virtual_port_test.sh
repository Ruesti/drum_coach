#!/usr/bin/env bash
# Linux-Integrationstest über den virtuellen ALSA-Port (Brief A, Technische
# Festlegungen). Voraussetzungen: modprobe snd-virmidi, Benutzer in audio.
set -euo pipefail
cd "$(dirname "$0")/../.."
exec sg audio -c "DRUM_COACH_ALSA_TEST=1 flutter test --tags alsa test/integration_linux/"
