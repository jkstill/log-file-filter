#!/usr/bin/env bash

set +u

declare -r rulesFile=$1
declare -r msgFile=$2

# throw an error if an undefined variable is referenced
set -u

[[ -z $rulesFile ]] && { echo $0 rules-file log-file; exit 1; }
[[ -r $rulesFile ]] || { echo cannot read $rulesFile; exit 2; }

[[ -z $msgFile ]] && { echo $0 rules-file log-file; exit 3; }
[[ -r $msgFile ]] || { echo cannot read $msgFile; exit 4; }

declare configLine
configLine=$(tail -n+2 $rulesFile  | head -1)

declare ruleType contextLinesBefore contextLinesAfter caseSensitive grepColor

ruleType=$(echo $configLine | cut -f1 -d:)
contextLinesBefore=$(echo $configLine | cut -f2 -d:)
contextLinesAfter=$(echo $configLine | cut -f3 -d:)
caseSensitive=$(echo $configLine | cut -f4 -d:)
grepColor=$(echo $configLine | cut -f5 -d:)

declare grepIncExFlag

if [[ $ruleType == 'INCLUDE' ]]; then
	grepIncExFlag=''
elif [[ $ruleType = 'EXCLUDE' ]]; then
	grepIncExFlag='-v'
else
	echo
	echo "ruleType of $ruleType is unknown"
	echo
	exit 1
fi

declare contextBeforeOption='' contextAfterOption=''

[[ $contextLinesBefore -gt 0 ]] && { contextBeforeOption="-B $contextLinesBefore"; }
[[ $contextLinesAfter -gt 0 ]] && { contextAfterOption="-A $contextLinesAfter"; }

declare caseSensitivityFlag=''
[[ $caseSensitive == 'N' ]] && { caseSensitivityFlag='-i'; }

declare grepColorFlag='auto'

case $grepColor in
	Y|y) grepColorFlag='always';;
	A|a) grepColorFlag='auto';;
	N|n) grepColorFlag='never';;
esac

# set GREP_COLORS to highlight the matched part of a line
# white on blue
#export GREP_COLORS='mt=38;5;223;48;5;19'
# yellow on black
#export GREP_COLORS='mt=38;5;16;48;5;227'

# black on white
# 256 color
export GREP_COLORS='mt=38;5;16;48;5;231'
# 8 color
#export GREP_COLORS='mt=30;47'

: << 'GREP-COLOR-COMMENTS'

run grep-colors.sh to see available colors

--color=auto
grep will automatically determine if output is to a tty
when redirected, to a file, or to 'less' the ANSI escape codes are just clutter

--color=always

If you use this, the output can be piped to 'less -R' or 'less -r' and the highlight colors will be preserved
'more' seems to work fine as is

--color=never 
Never output ANSI color codes

GREP-COLOR-COMMENTS

grep --color=$grepColorFlag -E $caseSensitivityFlag $grepIncExFlag $contextBeforeOption $contextAfterOption -f <(tail -n+3 $rulesFile) $msgFile

