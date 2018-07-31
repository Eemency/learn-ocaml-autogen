#!/usr/bin/env bash

DIR=sed
META=$DIR/meta.json
TEMP=$DIR/template.ml

echo "$TEMP"
echo Removing trailing whitespaces
sed -i.bak -E 's/[ \t]+$//' "$TEMP"
echo Changing fill
sed -i.bak -E 's/Replace this string by your implementation./CHANGED/' -E '/CHANGED/G' "$TEMP"
#echo Adding line breaks
#sed -i.bak -E '/CHANGED/G' "$TEMP"
rm "$TEMP.bak"

echo "$META"
echo Spreading left bracket
sed -i.bak $'s/{"/{\\\n"/' "$META"
echo Spreading right bracket
sed -i.bak $'s/}/\\\n}/' "$META"
echo Breaking lines
sed -i.bak $'s/,"/,\\\n"/g' "$META"
echo Sticking back lists
awk '/\[/{printf "%s",$0;next} 1' "$META" | tee "$META" > /dev/null
echo Indenting
sed -i.bak '/^[^{}]/{s/^/  /;}' "$META"
rm "$META.bak"

echo Results
echo ""
cat "$TEMP"
wc -l "$TEMP"
echo ""
cat "$META"
wc -l "$META"
