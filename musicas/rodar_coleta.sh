#!/bin/bash
cd "/home/richard/Documentos/play store/Musicas para Estudar/musicas" || exit 1
LOG="log_coleta.txt"
echo "== iniciado $(date) ==" >> "$LOG"
for cat in barroco piano_estudar piano_dormir classica_leitura brasil foco_profundo; do
  echo "===== CATEGORIA $cat =====" >> "$LOG"
  python3 -u coletar_musicas.py --only "$cat" --target 15 >> "$LOG" 2>&1
  echo "----- fim $cat (exit $?) -----" >> "$LOG"
done
echo "== concluido $(date) ==" >> "$LOG"
