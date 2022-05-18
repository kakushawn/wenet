#!/usr/bin/env bash

# this corpus is from sinica
corpus=/mnt/hdd18.2t/dataset/SINICA/Mandarin/MATBN_10
data=data/matbn/

if [ -d $data ]; then
  rm -r $data
fi

for s in train eval; do
  dir=$data/$s
  mkdir -p $dir
  cat $corpus/$s/data/text > $dir/text.raw
  paste -d " " <(cut -d " " -f 1 $dir/text.raw) \
    <(cut -d " " -f 2- $dir/text.raw |\
    sed 's/\([A-Z]\) \([A-Z]\)/\1▁\2/g' |\
    sed 's/ \+//g'|\
    sed 's/\(<UNK>\)\+/<unk>/g'|\
    sed 's/<unk>[A-Z]/<unk>▁[A-Z]/g'|\
    sed 's/[A-Z]<unk>/[A-Z]▁<unk>/g') > $dir/text
  cat $dir/text |\
    python -c '
import sys
import json
wav_dir = sys.argv[1]
for line in sys.stdin:
    line = line.strip("\n")
    tokens = line.split(" ")
    output = {
        "key": tokens[0],
        "txt": " ".join(tokens[1:]),
        "wav": f"{wav_dir}/{tokens[0]}.wav"
    }
    print(json.dumps(output, ensure_ascii=False))
' $corpus/$s/wav > $dir/data.list
  cat $dir/text.raw |\
    awk -F" " -v wvp=$corpus/$s/wav '{
      print $1" "wvp"/"$1".wav"
    }' > $dir/wav.scp
done

dir=$data/dev
if [ -d $dir ]; then
  rm -r $dir
fi
mkdir -p $dir
for f in text data.list wav.scp; do
  cat $data/eval/$f |\
    grep "PTSNE20030124|PTSNE20030127|PTSNE20030207|PTSNE20030305|PTSNE20030306" \
      > $dir/$f
done

dir=$data/test
if [ -d $dir ]; then
  rm -r $dir
fi
mkdir -p $dir
for f in text data.list wav.scp; do
  cat $data/eval/$f |\
    grep "PTSNE20030128|PTSNE20030129|PTSNE20030211|PTSNE20030307|PTSNE20030403" \
      > $dir/$f
done

exit 0