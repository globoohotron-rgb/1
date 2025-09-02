Param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
$HERE = Split-Path -Parent $MyInvocation.MyCommand.Path
python3 "$HERE/bin/ats" @Args
