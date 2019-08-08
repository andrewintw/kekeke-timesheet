#! /bin/bash

# Usage:
#       $ ./gen_worksign.sh         # generate records for the current month
#       $ ./gen_worksign.sh [1-12]  # generate for a specified month

# No need to modify
MONTH=`echo $1 |  sed -e 's/[^[:digit:]]//g'`
TBheader="工號,申請人,工作日期,原上班時段,簽到時間,簽退時間,簽到IP,簽退IP,備註,"
filename="WorkSign_Import"
csvfile="${filename}.csv"
xlsxfile=""
exe_bin="csv2xlsx.bin"
YEAR=`date +%Y`
signLoc="10.6.1.244"


# Change for your info
userID='108xxx'
fullName="發大財 (Korea Fish)"
loginName='korea.fish'
loginPass='password'


parseInt() {
	printf "%d\n" \'$1
}

# Encoded URL: 574@545@551@548@555@565@626@637@631@609@630@612@573@639@634@637@565@546@547@555@547@547@555@565@546@565@546@550@549@551@554@549@554@555@545@544@555@545@551
# Decoded URL: -2478&andrew.lin&108008&1&1564969823824

encode() {
	local url="$1"
	local i=0
	local data=''
	for c in `echo $url | sed -e 's/\(.\)/\1\n/g'`; do 
		i=$(($i+1))
		encstr=$(printf '%#d@' "$((`parseInt $c`^531))")
		data="${data}${encstr}"
	done
	echo "${data::-1}"
}

login() {
	local scriptTime="`date +%s`999"
	local diffTime='-2680'
	local cookieC=0
	local urlData="${diffTime}&${loginName}&${loginPass}&${cookieC}&${scriptTime}"
	urlData=`encode ${urlData}`
	local popUpURL="http://eip.browan.net/check.jsp?urlData=${urlData}"

	echo "$popUpURL"
}


init_env () {
	if [ "$MONTH" = "" ]; then
		# use this month
		MONTH=`echo "$(date +%m)" "0" | awk '{print $1 - $2}'`
	fi
	xlsxfile="${filename}-${MONTH}"

	return 0
}

do_chk() {
	rm -rf $csvfile ${filename}*.*
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
}

random_sign_min () {
	# for sign in  09:30~09:59
	# for sign out 07:00~07:30
	printf "%02d" $(shuf -i 30-59 -n 1)
}

random_sign_sec () {
	printf "%02d" $(shuf -i 00-59 -n 1)
}

gen_timesheet_data () {
	local i=0
	wd_list=`list_working_days | tr -d ' '`
	local lastwd=`echo $(list_working_days) | awk '{print $NF}'`
	local tb_month=`printf "%02d" $MONTH`

	for h in `seq 1 31`; do
		for d in $wd_list; do
			if [ $h -eq $d ]; then
				#echo -n "$d"
				local tb_day=`printf "%02d" $d`;
				echo "${userID},${fullName},${YEAR}-${tb_month}-${tb_day},10:00~19:00,09:`random_sign_min`:`random_sign_sec`,19:`random_sign_min`:`random_sign_sec`,${signLoc},${signLoc},,"
			fi
		done
		if [ "$h" = "$lastwd"  ]; then
			break;
		fi
	done

	echo ""
}

do_csv2xlsx () {
	local sheetname="Sheet1"

	if [ -f $csvfile ]; then
		$PWD/$exe_bin -silent -infile "$csvfile" -outfile "${xlsxfile}.xlsx" -colsep "," -sheet "$sheetname"
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

	cat $csvfile
	return 0
}

do_done () {
	cat << EOF

 The upload steps
------------------
 0. before running the script, you need to change variable in code: "# Change for your info"

 1. open ${xlsxfile}."xlsx" and save as ${xlsxfile}."xls" (.xlsx is NOT working)

 2. open the following URL in web browser
    `login`

 3. made sure you login already and the user name is: $fullName

 4. change URL to http://eip.browan.net/WorkSign/WorkSign_Import.jsp

 5. import the file -- ${xlsxfile}.xls

 6. (optional) back to http://eip.browan.net/MainFrm.jsp and records

 enjoy :-)
------------------
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

