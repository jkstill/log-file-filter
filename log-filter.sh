#!/usr/bin/env bash

set +u

declare -r rulesFile=$1
declare -r msgFile=$2

# throw an error if an undefined variable is referenced
set -u

# default GREP_COLORS - black on white
# 256 color
#export GREP_COLORS='mt=38;5;16;48;5;231'
# 8 color
export GREP_COLORS='mt=30;47'

[[ -z $rulesFile ]] && { echo $0 rules-file log-file; exit 1; }
[[ -r $rulesFile ]] || { echo cannot read $rulesFile; exit 2; }

[[ -z $msgFile ]] && { echo $0 rules-file log-file; exit 3; }
[[ -r $msgFile ]] || { echo cannot read $msgFile; exit 4; }

declare configLine
configLine=$(tail -n+2 $rulesFile  | head -1)

declare -A configNameRef configVals

configNameRef[0]='ruleType'
configNameRef[1]='contextLinesBefore'
configNameRef[2]='contextLinesAfter'
configNameRef[3]='caseSensitive'
configNameRef[4]='grepColor'
configNameRef[5]='grepColors'
configNameRef[6]='showMatchedOnly'

declare grepIncExFlag

IFS=':'

declare i=0
for parm in $configLine
do

	#echo parm: $parm
	#echo ${configNameRef[$i]}

	configVals[${configNameRef[$i]}]=$parm
	(( i++ ))

done

unset IFS i

if [[ ${configVals[ruleType]} == 'INCLUDE' ]]; then
	grepIncExFlag=''
elif [[ ${configVals[ruleType]} = 'EXCLUDE' ]]; then
	grepIncExFlag='-v'
else
	echo
	echo "ruleType of ${configVals[ruleType]} is unknown"
	echo
	exit 1
fi

# validate the color codes
echo ${configVals[grepColors]} | grep -E 'mt=3[0-9];4[0-9]|mt=38;5;[0-9]{1,3};48;5;[0-9]{1,3}' > /dev/null
[[ (( $? == 0 )) ]] && { export GREP_COLORS=${configVals[grepColors]}; }

declare contextBeforeOption='' contextAfterOption=''

[[ ${configVals[contextLinesBefore]} -gt 0 ]] && { contextBeforeOption="-B ${configVals[contextLinesBefore]}"; }
[[ ${configVals[contextLinesAfter]} -gt 0 ]] && { contextAfterOption="-A ${configVals[contextLinesAfter]}"; }

declare caseSensitivityFlag=''
[[ ${configVals[caseSensitive]} == 'N' ]] && { caseSensitivityFlag='-i'; }

declare grepColorFlag='auto'

case ${configVals[grepColor]} in
	Y|y) grepColorFlag='always';;
	A|a) grepColorFlag='auto';;
	N|n) grepColorFlag='never';;
esac

declare showMatchedOnlyFlag=''
[[ ${configVals[showMatchedOnly]} == 'Y' ]] && { showMatchedOnlyFlag='-o'; }


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

#grep --color=$grepColorFlag -E $caseSensitivityFlag $grepIncExFlag $contextBeforeOption $contextAfterOption -f <(tail -n+3 $rulesFile) $msgFile

# use the exclude file to filter out things we never want to see

grep --color=$grepColorFlag -v -E -f always-exclude.rules $msgFile | \
	grep --color=$grepColorFlag -E $showMatchedOnlyFlag $caseSensitivityFlag $grepIncExFlag $contextBeforeOption $contextAfterOption -f <(tail -n+3 $rulesFile)


