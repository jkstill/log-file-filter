#!/usr/bin/env bash

# demonstrate colors that can be use for grep

declare colorCount=$1

: ${colorCount:=8}

if [[ $colorCount -eq 8 ]]; then
	# 8 color
	declare -a fgColors=({30..37})
	declare -a bgColors=({40..47})
else
	# 256 color
	declare -a fgColors=({0..255})
	declare -a bgColors=({0..255})
fi


for bgi in ${!bgColors[@]}
do
	declare bgColor=${bgColors[$bgi]}
	#echo -n bg: $bgColor

	for fgi in ${!fgColors[@]}
	do
		declare fgColor=${fgColors[$fgi]}
		#echo "bg: $bgColor  fg: $fgColor"

		if [[ $colorCount -eq 8 ]]; then
			# 8 color 
			GREP_COLORS="mt=$fgColor;$bgColor"
			printf "\e[%sm" $bgColor
			printf "\e[%sm %s \e[0m" $fgColor $GREP_COLORS
		else 
			# 256 color
			# echo does not seem to work with 256 color
			GREP_COLORS="mt=38;5;$fgColor;48;5;$bgColor"
			printf "\e[48;5;%sm" $bgColor
			printf "\e[38;5;%sm %s \e[0m" $fgColor $GREP_COLORS
		fi

	   if [ $(( ($fgi + 1) % 4)) == 0 ] ; then
			echo
		fi

	done
done

echo


