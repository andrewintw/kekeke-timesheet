#! /bin/bash

# No need to modify
MONTH=`echo $1 |  sed -e 's/[^[:digit:]]//g'`
TBheader="Project Name,Task Name,Task Item,BU,"
filename="timesheet"
csvfile="${filename}.csv"
xlsxfile=""
exe_bin="csv2xlsx.bin"
YEAR=`date +%Y`

# Change for your timesheet
project_name="WLRRTMS-104"
task_name=""
task_item="development"
bu="BG1_SD1"

init_env () {
	if [ "$MONTH" = "" ]; then
		# use this month
		MONTH=`echo "$(date +%m)" "0" | awk '{print $1 - $2}'`
	fi
	xlsxfile="${filename}-${MONTH}.xlsx"

	return 0
}

do_chk() {
	rm -rf $csvfile ${filename}*.xlsx
	if [ "$MONTH" -gt "12" ] || [ "$MONTH" -lt "1" ]; then
cat << EOF >&2

Are you an idiot?
use $0 <1~12>

EOF
		exit 1
	fi

	if [ ! -f $PWD/$exe_bin ]; then
cat << EOF >&2

There is NO $PWD/$exe_bin

EOF
		exit 1
	fi

	return 0
}

list_working_days () {
	local mm=$MONTH
	ncal -M -h $mm $YEAR | sed -n '2,6p' | sed "s/[[:alpha:]]//g" | fmt -w 1 | sort -n
}

fmt_month () {
	local inputNo=$1
	printf -v inputNo "%02d" $inputNo
	echo $inputNo
}

gen_timesheet_hdr () {
	echo -n "$TBheader"

	for h in `seq 1 31`; do
		echo -n $h

		if [ "$h" -lt "31" ]; then
			echo -n ","
		fi
	done

	echo ""
}

gen_timesheet_data () {
	local i=0
	wd_list=`list_working_days`
	local lastwd=`echo $(list_working_days) | awk '{print $NF}'`

	echo -ne "${project_name},${task_name},${task_item},${bu},"

	for h in `seq 1 31`; do
		for d in $wd_list; do
			if [ $h -eq $d ]; then
				#echo -n "$d"
				echo -n "8"
			else
				echo -n ""
			fi
		done
		if [ "$h" = "$lastwd"  ]; then
			break;
		else
			echo -n ","
		fi
	done

	echo ""
}

do_csv2xlsx () {
	local sheetname="${YEAR}$(fmt_month $MONTH)"

	if [ -f $csvfile ]; then
		$PWD/$exe_bin -silent -colsep "," -sheet "$sheetname" -infile "$csvfile" -outfile "$xlsxfile"
		rm -rf $csvfile
	else
		echo "There is NO $csvfile"
		exit 1
	fi

	return 0
}

gen_csv () {
	cat << EOF > $csvfile
`gen_timesheet_hdr`
`gen_timesheet_data`
EOF

	return 0
}

do_done () {
	cat << EOF

done, ;-)
`ls -l $xlsxfile`

 1. login to Time System
 2. select the month $MONTH
 3. click "Import-2" to import the file -- $xlsxfile

EOF

}

do_main () {
	init_env && \
	do_chk && \
	gen_csv && \
	do_csv2xlsx && \
	do_done
}

do_main

