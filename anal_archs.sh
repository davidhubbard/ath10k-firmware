#!/bin/bash

ARCH=$(rasm2 -L | grep -v '\(8051\|dcpu16\|dalvik\|i8080\|java\|malbolge\|propeller\|snes\|sparc\|x86\)' | awk '{
		a=substr($0, 18)
		b=substr($0, 6, 12)
		sub(" .*", "", a)
		if (a == "arc" || a == "avr" || a == "bf" || a == "gb" || a == "ws" || a == "arm.gnu" || a == "arm.winedbg") {
			next
		}
		cn = split(b, c, " ")
		for (i = 1; i <= cn; i++) {
			print  "e asm.arch=" a "; e asm.bits=" c[i]
		}
	}')

while read a; do
	if ! grep -q "arm" <<<"$a"; then
		echo "not arm: $a"
		break
	fi
	o=0
	while [ $o -lt 15 ]; do
		s=$(printf 's 0x%x' $(( 0x73000 + $o )))
		cat >/tmp/s.r2 <<EOF
		$a; $s
		pd
EOF
		R=$(radare2 -e scr.color=false -qi /tmp/s.r2 -n "$1")
		if [ $? -ne 0 ]; then
			exit 1
		fi
		C=$(cut -c 41- <<<"$R")
		if head -n1 <<<"$C" | grep -q '^ [^ ]'; then
			C=$(cut -c 42- <<<"$R")
		fi
		if ! grep -q '^\(invalid\|illegal\|\?\?\?\|\.word\|Unknown\)' <<<"$C"; then
			break
		fi

		head -n1 /tmp/s.r2
		o=$(( o + 2 ))
	done
	if [ $o -lt 8 ]; then
		head -n1 /tmp/s.r2
		radare2 -qi /tmp/s.r2 -n "$1" || exit 1
	fi
done <<<"$ARCH"
