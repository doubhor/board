#!/bin/bash

#addGroup
# $0 [forceSeek=KTV_Hotel_Group_Wuye] [forceRun=yes]
shellname=`basename $0 | cut -d "." -f 1`
procname="${shellname}_$$"
cmdoptfile="tmp_cmdopt_${procname}.swap"
echo -n "" > ${cmdoptfile}
for iter_cmdopt in "$@"
do
    echo ${iter_cmdopt} >> ${cmdoptfile}
done
timemetricfile="tmp_timemetric_${procname}.swap"
echo -n "" > ${timemetricfile}

# const or global param
#addGroup
id_k="BkPTdVZaOYaoML6UwMGJyg==";id_h="ZT5pUv4JKL1tomT0u9SEdA==";id_g="NEEF0YcfsFZQSDlWHBblaw==";id_w="Jne4ofFTe7WSnbqQczwPPQ==";
configSep=":"
cmdOptSep="="
keepAliveTimeout=3600
#addGroup
seekTimeout_H=16052;seekTimeout_K=14400;seekTimeout_G=18052;seekTimeout_W=25252;
lineTimeout=59
seekMaxCkTimeMs=1630
useFastCkNum=3
leastSearckMode="Y"
debug_dump="Y"
debug_dump_file="debug.${shellname}.swap"
configfile=runConfig_${shellname}.cfg
searchCodeFile="tmpSearchCode_${shellname}.swap"
configKeyOkCode="cfg_ok_code"
configKeyOkId="cfg_ok_id"
configKeyOldHour="cfg_old_hour"
configKeyKeepAlive="cfg_keep_alive"
configKeyLastSeek="cfg_last_seek"
configKeyShellPid="cfg_shell_pid"

usleep()
{
    p_ms=$1;shift;
    p_random=$1;shift;

    p_sleep_len=${p_ms}
    [ "${p_random}x" != "x" ] && p_sleep_len=$((${RANDOM} % ${p_ms}))
    p_sleep_s=$((${p_sleep_len}/1000))
    p_sleep_ms=$((${p_sleep_len} % 1000))
    p_sleep_v="${p_sleep_s}.$(printf "%03d" ${p_sleep_ms})"
    #echo "p_ms=${p_ms} p_sleep_len=${p_sleep_len} p_sleep_time=${p_sleep_s}.${p_sleep_ms} p_sleep_v=${p_sleep_v}"
    sleep ${p_sleep_v}
}

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
get_time_metric()
{
    touch ${timemetricfile}
    p_timestr=`cat ${timemetricfile} | grep "real" | head -n 1`
    time_m=`echo ${p_timestr} | grep "[0-9]\+" -o | head -n 1 | tail -n 1 | sed "s/^0*//g"`
    time_s=`echo ${p_timestr} | grep "[0-9]\+" -o | head -n 2 | tail -n 1 | sed "s/^0*//g"`
    time_ms=`echo ${p_timestr} | grep "[0-9]\+" -o | head -n 3 | tail -n 1 | sed "s/^0*//g"`
    p_res_t=0
    [ "${time_ms}x" != "x" ] && p_res_t=$((p_res_t+time_ms))
    [ "${time_s}x" != "x" ] && p_res_t=$((p_res_t+time_s*1000))
    [ "${time_m}x" != "x" ] && p_res_t=$((p_res_t+time_m*1000*60))

    echo "${p_res_t}"
}
exit_clsopt()
{
    p_exitcode=$1;shift;
    [ "${p_exitcode}x" == "x" ] && p_exitcode=0
    
    # reset ck
    iterN=0
    for ick in ${ck_set}
    do
        check_park ${ick} ${ok_code} ${ok_id} | grep -q "res:success" && echo "[RST] Y ok_code=${ok_code} ck=${ick}" || echo "[RST] n ok_code=${ok_code} ck=${ick}"
        iterN=$((iterN+1)); [ ${iterN} -ge ${ck_Total_n} ] && break
    done
    
    # clear file
    rm -rf ${cmdoptfile}
    rm -rf ${timemetricfile}
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
#addGroup
resCode_H="";resCode_K="";resCode_G="";resCode_W=""
resfile=runResultCode_${shellname}.cfg
gitlogfile=crontab.txt
gitcodefile=vcode.txt
#ok inf
ok_code=580
ok_id="${id_k}"
cfgValue=`read_config ${configfile} ${configKeyOkCode}`
[ "${cfgValue}x" != "x" ] && ok_code=${cfgValue}
cfgValue=`read_config ${configfile} ${configKeyOkId}`
[ "${cfgValue}x" != "x" ] && ok_id=${cfgValue}

#    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
#    -H 'User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 13_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/7.0.14(0x17000e29) NetType/WIFI Language/zh_CN'
#    -H 'User-Agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Mobile Safari/537.36'
#    -H 'User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A403 Safari/8536.25'
#    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' 
#    -H 'User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1'
query_park()
{
    p_c=$1;shift;
    p_code=$1;shift;
    p_id=$1;shift;

    curl --connect-timeout 12 -m 16 -L "http://wx.parkingwang.com/coupon/coupon_show?coupon=${p_id}&verification=${p_code}" \
    -H "Cookie: parking_ses=${p_c}" \
    -H 'Connection: keep-alive' \
    -H 'Upgrade-Insecure-Requests: 1' \
    -H 'User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 13_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/7.0.14(0x17000e29) NetType/WIFI Language/zh_CN' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
    -H 'Referer: http://wx.parkingwang.com/coupon/input_code?coupon_id=BkPTdVZaOYaoML6UwMGJyg==' \
    -H 'Accept-Encoding: gzip, deflate' \
    -H 'Accept-Language: zh-CN,zh;q=0.9' \
    -H 'misctooltoken: c6d1ad2b9afs4fbab56aaa3e0267deb9' --compressed 2>&1 | egrep "(alert)|(span)|(div)" | paste -s -d ":" -
}

parse_res()
{
    p_res=$1;shift;
    #if echo "${p_res}" | grep -q "次数优惠券"
    if echo "${p_res}" | grep -q "切换新能源车牌"
    then
        enddate=`echo "${p_res}" | grep "有效期限[^<>]\+" -o | grep "至[^<>]\+" -o | sed "s/[^0-9]//g" | cut -c 1-8`
        curdate=`date +%Y%m%d`
        [ "${debug_dump}x" == "Yx" ] && { echo "${curdate} ${enddate} ${#enddate}" >> ${debug_dump_file}; }
        [ ${#enddate} -eq 38 -a ${curdate} -gt ${enddate} ] && echo "res:fail:code:x" || echo "res:success"
    elif echo "${p_res}" | grep -q "输入您的手机号码"
    then
        echo "res:fail:ck:login"
    elif echo "${p_res}" | grep -q "innerHTML"
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
    elif [ "${p_res}x" == "x" ]
    then
        echo "res:fail:ck:timeout"
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

    for iRetry in `seq 1 9`
    do
        curls1=`date +%s`
        p_html=`query_park ${p_c} ${p_code} ${p_id}`
        curls2=`date +%s`
        curl_t=$((curls2-curls1));
        [ "${p_html}x" != "x" -o ${curl_t} -gt 7 ] && break
        [ "${debug_dump}x" == "Yx" ] && { echo "------ ${iRetry} ------ p_c:${p_c} p_code:${p_code} p_id:${p_id}" >> ${debug_dump_file}; }
        sleep 1
    done
    [ "${debug_dump}x" == "Yx" ] && { echo "p_c:${p_c} p_code:${p_code} p_id:${p_id}" >> ${debug_dump_file}; echo "${p_html}" >> ${debug_dump_file}; }
    parse_res "${p_html}"
}

do_try()
{
    p_ck=$1;shift;
    p_code=$1;shift;
    p_tryId=$1;shift;
    [ "${debug_dump}x" == "Yx" ] && { echo "place=do_try p_ck:${p_ck} p_code:${p_code} p_tryId:${p_tryId}" >> ${debug_dump_file}; }
    
    keep_alive
    [ "${p_tryId}x" == "x" ] && p_tryId="${id_h}"
    p_s=`check_park ${p_ck} ${p_code} ${p_tryId}`
    if echo "${p_s}" | grep -q "res:success"
    then
        echo -n -e " [\\033[32m\\033[1m$(printf "%3d" ${p_code})\\033[0m]"
        #addGroup
        #[ "${p_tryId}x" == "${id_h}x" ] && resCode_H="${resCode_H} ${p_code} "
        [ "${p_tryId}x" == "${id_h}x" ] && resCode_H=`echo "${resCode_H} ${p_code} " | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
        #[ "${p_tryId}x" == "${id_k}x" ] && resCode_K="${resCode_K} ${p_code} "
        [ "${p_tryId}x" == "${id_k}x" ] && resCode_K=`echo "${resCode_K} ${p_code} " | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
        [ "${p_tryId}x" == "${id_g}x" ] && resCode_G="${resCode_G} ${p_code} "
        [ "${p_tryId}x" == "${id_w}x" ] && resCode_W="${resCode_W} ${p_code} "
        echo "";save_result;
    else
        ns=`echo "${p_s}" | grep "res:fail:code" | cut -d ":" -f 4`
        [ "${ns}z" == "z" ] && ns="Q"
        [ "${ns}z" == "xz" ] && echo -n -e " \\033[31m\\033[1m$(printf "%3d" ${p_code})\\033[0m|${ns}" || echo -n " $(printf "%3d" ${p_code})|${ns}"
        if [ "${ns}z" == "Qz" ]
        then
            ck=$(find_diff_ck ${ck})
        fi
   fi
}

sendgit()
{
    p_file=$1;shift;
    p_linen=$1;shift;
    p_desc=$1;shift;
    p_msg=$*

    p_dir=~/work/code/github/board
    p_tmpfile="tmpgit_${p_file}"
    p_gittime=`date +"%m-%d %H:%M:%S"`

    echo "${p_gittime} ${p_msg}" | cat - ${p_dir}/${p_file} | head -n ${p_linen} > ${p_tmpfile}
    cat ${p_tmpfile} > ${p_dir}/${p_file}
    cd ${p_dir} && git commit -a -m "add line by shell" && echo "git commit [${p_desc}] $(colorecho "g" "success")" || echo "${p_gittime} git commit [${p_desc}] $(colorecho "r" "fail")"; cd -
    
    # git push
    cd ${p_dir}
    for idxRst in `seq 1 7`
    do
        p_gittime=`date +"%m-%d %H:%M:%S"`
        git push && { echo "${p_gittime} git push [${p_desc}:${idxRst}] $(colorecho "g" "success")"; break; } || { echo "${p_gittime} git push [${p_desc}:${idxRst}] $(colorecho "r" "fail")"; }
        sleep 1
    done
    cd -
}
loggit()
{
    p_desc=$1;shift;
    p_msg=$*
    sendgit ${gitlogfile} 144 ${p_desc} ${p_msg}
}
trim_str()
{
    p_str=$*

    echo "${p_str}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -
}
savefile()
{
    p_resfile=$1;shift;
    #addGroup
    p_code_H=$1;shift;
    p_code_K=$1;shift;
    p_code_G=$1;shift;
    p_code_W=$1;shift;
        
    echo -n "" > ${p_resfile}
    #addGroup
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
    for i in `echo "${p_code_W}" | grep "[0-9]\+" -o`
    do
        echo "${i}:${id_w}" >> ${resfile}
    done
}
savegit()
{
    p_msg=$*

    p_dir=~/work/code/github/board
    p_old_msg=`head -n 1 ${p_dir}/${gitcodefile} | cut -d " " -f 3-`
    # filename is same with tmp filename in func sendgit
    p_old_msg_tmp=`head -n 1 tmpgit_${gitcodefile} | cut -d " " -f 3-`
    echo "act=debug_chkDupSaveGit p_new_msg=#${p_msg}#"
    echo "act=debug_chkDupSaveGit p_old_msg=#${p_old_msg}#"
    echo "act=debug_chkDupSaveGit p_tmp_msg=#${p_old_msg_tmp}#"
    [ "${p_old_msg}x" == "${p_msg}x" ] && { echo "$(colorecho "r" "REPEAT") msg: ${p_msg}"; return 0; }

    sendgit ${gitcodefile} 60 "SaveCode" "${p_msg}"
}

# ckinfo 92c579c430a6a1cd7fea755ed0443425a00cfdee 17107705263 20210204
# ckinfo 434d2a21e1b2068573a596895140d7c7a6c5333f 17199741192 20210112
# ckinfo f4f9165d6da1fa57778b513ca7771eeadb0d910f 17199741415 20210112
# ckinfo 01d6d9599c4a3399ec9ee1f08b40b3f69b866d93 16224458348 20210104
# ckinfo 0ee2c3b35db51098ee53c2e39c189f609851e84a 16726604302 20210104
# ckinfo 09b25b7b3065a4f9141f0d347a7dabe154fe760f 16224457440 20210102
# ckinfo 8783b9ac15773f29dc0e44bdac35ded5236d9af9 18411631210 20210102
# ckinfo d7825b9e2e80e6cdfc44b82b86288aec49935227 18411631211 20210102
# ckinfo 66c5186cf894b5591313e1b07888dbeea29fc1c8 16232525706 20210102
# ckinfo 88575005bddd4270ef2b4e2c2968eb6a5db3ba11 18411631208 20210102

#
#如果速度很慢，重新登录换一个Cookie
# test cookie
ck_set="
8783b9ac15773f29dc0e44bdac35ded5236d9af9
09b25b7b3065a4f9141f0d347a7dabe154fe760f
0ee2c3b35db51098ee53c2e39c189f609851e84a
434d2a21e1b2068573a596895140d7c7a6c5333f
d7825b9e2e80e6cdfc44b82b86288aec49935227
88575005bddd4270ef2b4e2c2968eb6a5db3ba11
66c5186cf894b5591313e1b07888dbeea29fc1c8
92c579c430a6a1cd7fea755ed0443425a00cfdee
f4f9165d6da1fa57778b513ca7771eeadb0d910f
01d6d9599c4a3399ec9ee1f08b40b3f69b866d93
"
# old
# ckinfo 7c396715c190b5e865b238f0f116ca2b3bc61da0 16232525705 20210101
# ckinfo 6ff8e240a4ae13cce879f86d9c97335408c80647 16232525729 20210101
# ckinfo 409bfb7a64e228e45702085547870ecc491e691f 16232525707 20210101
# ckinfo 73533f49d9c006e4b52de1999e35551d20f4ab3f 16726604303 20210101
# ckinfo ff72755b5f9aac149d7ecb9ce1c41907b5bed0b2 16232525703 20210101
# ckinfo b40ff4401bf085b36ded0663da6c9c50ff31bc5f 17107703029 20201001
# ckinfo f1da9beadbd39d4a203deb6eb1a87ed183f87ca5 16224457804 20201228
# ckinfo d4b1327a06c0d75604a44f2368533cfb4770fb6d 16224457442 20201228
# ckinfo 336e9028de1d8ea68d3edae1e221750e8126f115 18411631212 20201228
# ckinfo 7636f09120a7047bf46d92841ee6b591df1e7235 17199741418 20201211
# ckinfo 3635610611a217ec54e9790e8481d20444c44eda 17107706354 20201211
# ckinfo 43d7639169f66860f8582783407648b3dd7bc07f 16532701568 20201211
# ckinfo 29ae1d8ec46cf1c73315d836856cc89ffa69f50f 16532701569 20201211
# ckinfo 2341126b78f4b71f8eb81de9b8e21d4235e0b2de 16232525738 20201211
# ckinfo 313369b49697fa33af1800a8aca5835e58e1c0c7 16224457443 20201224
# ckinfo 66793eb7ea82efd8d7fa4a98e5bc5e7efa131bda 16224457841 20201224
# ckinfo 946682551df4bbe30bd1167fa598103ff2910280 16224457441 20201222
# ckinfo 3fc7dfae80a32169286ef2dac12642ed6c428e9b 16532701570 20201217
# ckinfo 8559bed34b3842209298cc1a8f95f9af18fd695c 16532701485 20201217
# ckinfo 474e8b5ac9d73c6b295d10f649f82dce57048d0a 17107705263 20201217
# ckinfo 31097fc2db2efa931777698ffda7939080f8d58b 17107706062 20201217
# ckinfo ea62cf33b19ef4845735eea5f32f841bef63e2dd 17107706264 20201217
# ckinfo 518c240013133a4a204fd4121cbaf9d7c1c322e0 16532701648 20201211
# ckinfo e15445c3491cdc16d542fce90b3f48c0af88ed08 16532701546 20201217
# ckinfo 8cdb221ed40017bcfc101c0456944b89f52b244c 16532701603 20201211
# ckinfo d8aa92d652e448c6af63111d4640fde090ef459d 16232525721 20201211
# ckinfo 8b4e87b271b55a13434aa17d17468bc8c52f7f37 16232525736 20201211
# ckinfo f834ed9899e29e3dbb838970f88b19578679f92c 17199741371 20201211
# ckinfo f6d715d1d4a99a5d653fd14d2920b540a8a7e2e9 17199741196 20201211
# ckinfo a375d2586dd6640c35f8afa68dd6e599402f97df 17199741178 20201211
# ckinfo 4a1f5a8429f8a86a4c6c39f6c964905b8d5efacc 16534084358 20201211
# ckinfo 4b8a2462ed5cf57c99620c6d56b8a6736a9b6eb9 17199741419 20201211
# ckinfo fea3cb6042a4c6d4f93b174fb4dce8bf70b450ae 16716582402 20201211
# ckinfo ac3fff82173c998bc152f854bc37d4a6c7b50bf9 16534088033 20201211
# ckinfo d41b6944d50b56100e7d660a4b4ff94cf16bfee2 16530800928 20200729
# ckinfo 0ac0bb6cf197b2943b0b6ea23c6653f3b2c02a49 18866674203 20201116
# ckinfo 1275f91f5e3f87d50b29e1ffcd08aaeac6c90719 16232525730 20201211
# ckinfo 389736debfe7b7e17b851b5a92d1d6693c57dd73 16534087769 20201116
# ckinfo 72a89cecd98db608898925fe88b3ea741fe85c9f 15263819405 20200729
# ckinfo 4b4945cc519c0c172df14fa88beaf7fe0666e031 16530800914 20200729
# ckinfo f70f7f291851f25761efab27d9b72f2ff6bd5258 15263819409 20200728
# ckinfo 31441d410646c3ae336a269cc96c0c60d84162d5 17043763114 20200728
# ckinfo ffbad64a8addf0cc9fec5a125e2370b05d298fbe 16530800938 20200728
# ckinfo 7f4eeecdfdfb91ec1f1299406cd2670981c70e31 16530801181 20200727
# ckinfo 142c1240c42ea05e23432cb9b28df473c7472fa9 18866478849 20200727
# ckinfo 29253fe91a9cf6ef6f551ca00d0e0aa44c3cf6a9 16530801182 20200727
# ckinfo 0a6acd400ecc27b44527a1c48cc6c15d79a80874 13521838587 20200729
# ckinfo 262ab56bf486fb3053f35f83039652543bd90bd6 18866674206 20200529
# ckinfo 8d47bd5c6ee92462bcab406462fc8ee1acc6056b 16530800935 20200529
# ckinfo 587a91bce1506ccb476b0f7c194ceffd53f2d58c 16530801176 20200529
# ckinfo 139aa473f0ced440770df5d0fbf3eb024c422c6d 16530800941 20200529
# ckinfo a43eeee4fbc9766d54570776906222ec83672bd7 16532795427 20200428
# ckinfo d3fc64be39cfc9546d19d7beddc6d4a5fe8a6fa2 16532795637 20200428
# ckinfo 92cc374580425cdf3c1af880dfe2ddd1da588185 17134502834 20200424
# ckinfo 4ad235d837cdd2cb1f2056e1f1dd4d1d2c9927cf 18866478504 20200424
# ckinfo e78cf2f7e67050a719a666762290763c41383ab4 17134025326 20200424
# ckinfo f3ebd5784c9cfcf66f792286f213aa3253ac2811 17134025325 20200424
# ckinfo d9b166e1713d3675c3baee816feeb8ec52a2ff4a 18866478704 20200424
# ckinfo 94bb5555b344483de26f0063233f6325f638f239 18866478654 20200424
# ckinfo 512da72fa4ba04e2cee7daaa482797691c6e217e 17134025303 20200417
# ckinfo 84e9c3305eef16e3221b377343b300cce8dffe8d 17134502724 20200417
# ckinfo e34423dabcef119ffe94b7bfedc26992b20599bd 17134502974 20200415
# ckinfo 637dd83f6ac856d941e359d6e12146e18f16443c 18866478914 20200415
# ckinfo 3632857efc0b4ee9310a5b0676bba675d4ffe7a8 18866478714 20200415
# ckinfo 0f444ff386439eab5f18dfb1fd19f75ecb8e5edd 18866478945 20200415
# ckinfo 43fc4c724f4612cdc8371d4e3b059e7e49ff6349 18515987963 20200302
# ckinfo b7e4e45e9d3a07849125ffdee70c8dd586df1ff9 13521838587 20200302
# ckinfo c7d9458bf32930ff3218a253d152317696754108 17134025278 20200119
# ckinfo c2b5553f30652bbe4c05643f4a500b9c6d5cc667 17134025323 20200119
# ckinfo 21bd00ad45b67125f2a1db46c4037d294f15f4c6 17109324209 20200119
# ckinfo 45d4861587a41c910d4ea2d864db2f7298d8ef2b 18866478945 20200119
# ckinfo 02e2adc8dd7820d7226a86aa6bb72cded52cbae0 17134025286 20200119
# slow
# ckinfo de29be3c79f78c62894538bafa0fb2fbf226cd80 18866674203 20191203
# ckinfo 70c52bd5c787037a65ff014e176a760bd5ee8a15 17128240041 20191203
# ckinfo 08be3d0010c20c98e122566a34a7acfc47ef439b 17109324200 20191203
# ckinfo c4a09aa61dd3ea8f47b540ae604083c529303dfd 17109324198 20191203
# ckinfo 392d31931a49be6c8f24f360be0100ae026d4412 17128240149 20191203
# bad
# ckinfo ba7ca61772e361df63e4b856d7cc27899f7bd21c 17109324121 20200110
# ckinfo aa3b5fef753978f06a8d834021c52643626d0f65 17134025301 20200110
# ckinfo 0c4178b2810223336cbaa51c191eea008b7b2c8d 17109324122 20200110
# ckinfo e295d8c6a1344365a0440f92389f95e7d4549e9d 17134025282 20200110
# ckinfo 863f28d16fbeca5334f05100c5b4a4a9b5bd44a9 17109324203 20200110
# ckinfo 9ab403b586c9b61e975a454b6f4ad1c2bc630734 17128240194 20191203
# ckinfo 3f0762133b08f7a77a691d43e985a3f2404f695c 15263819407 20191107
# ckinfo 3b3363844ec543db71f9b2176fb87ace2bbf38a5 16739465448 20191107
# ckinfo 6e38c052913affe190944494e59919a460ec5bfc 18866674208 20191107
# ckinfo ea19e08ba88c439e903affd4bfa631e2dca6f644 18866674195 20191031
# ckinfo c36ed18d64b225e25fcc52f4fe90ddc69fa6c12c 15263819419 20191031
# ckinfo 48c8de6edae8c60ff2ca5847a2f5f35489966a90 18866674223 20191031
# ckinfo 4a961a7390091a410675839e8d4622bf8b37fef7 17109324204 20191020 1023x 1028
# ckinfo 364beeb9d67580f6ab8f1906e36f576a7ff3925d 18866674180 20191023 1023x 1028
# ckinfo 8db19b98f9f8e97820da19772e77875d90407413 18866674211 20191023 1023x 1028
# ckinfo a75ef402921948a497acdb38b0bef33c5b245e90 18866478794 20191023
# ckinfo 24a6af824b90763b738663e64464c682ed5d09ad 17128240164 20191023
# ckinfo 392a777819e640839d2d838a2855239f239a53f4 15263819410 20191023
# ckinfo 892972fd5a016156bfad33c119ce1283a801e3f6 13521838587 20191020 1023x 1028
#
# ckinfo ab9421ef0847d0e26357b97a097b73d2491dce23 13001077534 20191014 1023s
# ckinfo ef74b1cf95139da7ce9d19ce02113a2f5914f71c 17128240042 20191023 1107s
# ckinfo 6a0b36cde3bf78babfce15b8da8af79dc694b231 18515987963 20190901 1023x 1028s
# ckinfo bba42eafa9984768840163f14c81ff654cf13d6b 18866674230 20191031 1107s

best_ck=""
good_ck_set=""
best_ckt=998000
ck_OK_n=0;ck_Fail_n=0;ck_Fast_n=0;
ck_Total_n=0;ck_Total_t_ms=0;
ck_dt_0=0;ck_dt_1=0;ck_dt_2=0;ck_dt_3=0;ck_dt_4=0;ck_dt_5=0;ck_dt_6=0;ck_dt_7=0;ck_dt_8=0;ck_dt_9=0;
for ick in ${ck_set}
do
    cks1=`date +%s`
    { time check_park ${ick}; } 2>${timemetricfile} | grep -q "res:fail:ck" && ck_flag="n" || ck_flag="Y"
    cks2=`date +%s`
    ck_t=$((cks2-cks1));ck_t_ms=$(get_time_metric);
    eval ck_dt_${ck_t}=$(( ck_dt_${ck_t}+1))
    ck_Total_n=$((ck_Total_n+1));ck_Total_t_ms=$((ck_Total_t_ms+ck_t_ms));
    echo -n "cktest ok_code="${ok_code} ok_id="${ok_id}" "[$(printf "%3d" ${ck_t})] [$(printf "%5d" ${ck_t_ms})] ${ck_flag} ${ick}"
    [ "${ck_flag}x" == "Yx" ] && ck_OK_n=$((ck_OK_n+1)) || ck_Fail_n=$((ck_Fail_n+1))
    [ "${ck_flag}x" == "Yx" ] && good_ck_set="${good_ck_set}:${ick}"
    [ "${ck_flag}x" == "Yx" -a \( ${ck_t_ms} -lt ${best_ckt} -o "${best_ck}x" == "x" \) ] && { best_ckt=${ck_t_ms}; best_ck="${ick}"; echo -n " U"; } || { echo -n " -"; }
    [ "${ck_flag}x" == "Yx" -a ${ck_t_ms} -le 1680 ] && { ck_Fast_n=$((ck_Fast_n+1)); echo " F"; } || { echo " -"; }
    [ ${ck_Fast_n} -ge ${useFastCkNum} ] && break
done
echo "ckN:${ck_OK_n}:${ck_Fast_n}-${ck_Fail_n}/${ck_Total_n}[${ck_dt_0}][${ck_dt_1}][${ck_dt_2}] bestCkT:${best_ckt} bestCk:${best_ck} AvgCkT=$((ck_Total_t_ms/ck_Total_n))"

[ "${ck}x" == "x" ] && ck="${best_ck}"
[ "${n1}x" == "x" ] && n1=10
[ "${n2}x" == "x" ] && n2=999
echo " begin=${n1} end=${n2} ck=${ck} ${ok_id:0:2}_Code=${ok_code}"
if [ "${ck}x" == "x" ]
then
    #errExitMsg="ckN=${ck_OK_n}:${ck_Fast_n}:${ck_Fail_n} T=${best_ckt} err=noValidCk"
    errExitMsg="ckN=${ck_OK_n}:$(printf "%02d" ${ck_Fast_n})-${ck_Fail_n}/${ck_Total_n} T=${best_ckt} err=noValidCk"
    echo "${errExitMsg}"
    loggit "LostCk" "${errExitMsg}"
    exit_clsopt 1
fi
find_best_ck()
{
    p_def_ck=$1;shift;
    
    p_best_ck="${p_def_ck}"
    p_best_ckt=997000
    iterN=0
    #for ick in ${ck_set}
    for ick in `echo "${good_ck_set}" | grep "[0-9a-fA-F]\+" -o`
    do
        cks1=`date +%s`
        { time check_park ${ick}; } 2>${timemetricfile} | grep -q "res:fail:ck" && ck_flag="n" || ck_flag="Y"
        cks2=`date +%s`
        ck_t=$((cks2-cks1));ck_t_ms=$(get_time_metric);
        [ "${ck_flag}x" == "Yx" -a \( ${ck_t_ms} -lt ${p_best_ckt} -o "${p_best_ck}x" == "x" \) ] && { p_best_ckt=${ck_t_ms}; p_best_ck="${ick}"; }
        iterN=$((iterN+1)); [ ${iterN} -ge ${ck_Total_n} ] && break
    done
    echo "${p_best_ck}"
}

find_diff_ck()
{
    p_def_ck=$1;shift;
    tmpfile_find_diff_ck="tmpfile_find_diff_ck_${procname}.swap"

    find_ck="${p_def_ck}"
    
    for i in `seq 1 9`
    do
        echo "" > ${tmpfile_find_diff_ck}
        for ick in `echo "${good_ck_set}" | grep "[^:]\+" -o`
        do
            echo "${ick}:${RANDOM}" >> ${tmpfile_find_diff_ck}
        done
        find_ck=`cat ${tmpfile_find_diff_ck} | grep  ":" | sort -t ":" -k2,2n | head -n 1 | cut -d ":" -f 1`
        rm -rf ${tmpfile_find_diff_ck}
        #find_ck=`echo "${good_ck_set}" | for i in `cat - | grep "[^:]\+" -o`; do echo "$i:${RANDOM}"; done| sort -t ":" -k2,2n | head -n 1 | cut -d ":" -f 1`
        if [ "${find_ck}x" != "${p_def_ck}x" ]
        then
            break
        fi
    done
    echo ${find_ck}
}


cfm_N=0
cfm_okN=0
cfm_failN=0
#addGroup
cfm_HokN=0;cfm_KokN=0;cfm_GokN=0;cfm_WokN=0;
cfm_HfailN=0;cfm_KfailN=0;cfm_GfailN=0;cfm_WfailN=0;

cfm_checkRes=""
ok_code_bak=""
ok_id_bak=""
touch ${resfile}
rm -rf ${resfile}.tmprm
cp "${resfile}" "${resfile}.tmprm"
# check ok_code and ok_id
check_park ${ck} ${ok_code} ${ok_id} | grep -q "res:success" || ok_code=""

for iterLine in `cat ${resfile}`
do
    cfm_N=$((cfm_N+1))
    iterCode=`echo ${iterLine} | cut -s -d ":" -f 1`
    iterId=`echo ${iterLine} | cut -s -d ":" -f 2`
    [ "${iterId}x" == "x" ] && iterId="${id_h}"
    iterIdType="X"
    #addGroup
    [ "${iterId}x" == "${id_h}x" ] && iterIdType="H"
    [ "${iterId}x" == "${id_k}x" ] && iterIdType="K"
    [ "${iterId}x" == "${id_g}x" ] && iterIdType="G"
    [ "${iterId}x" == "${id_w}x" ] && iterIdType="W"
    s=`check_park ${ck} ${iterCode} ${iterId}`
    echo "check_code iterLine=${iterLine} code=${iterCode} res_s=${s}"
    # process code by result of checking
    if echo "${s}" | grep -q "res:fail:code"
    then
        cfm_failN=$((cfm_failN+1))
        #addGroup
        [ "${iterId}x" == "${id_h}x" ] && cfm_HfailN=$((cfm_HfailN+1))
        [ "${iterId}x" == "${id_k}x" ] && cfm_KfailN=$((cfm_KfailN+1))
        [ "${iterId}x" == "${id_g}x" ] && cfm_GfailN=$((cfm_GfailN+1))
        [ "${iterId}x" == "${id_w}x" ] && cfm_WfailN=$((cfm_WfailN+1))
        cfm_checkRes="${cfm_checkRes}${iterCode}_$(echo ${iterIdType} | tr [:upper:] [:lower:])_"
        # remove iterLine from file to avoid dead loop
        cat ${resfile}.tmprm | grep -v "${iterLine}" > ${resfile}.tmprm.tmp
        mv ${resfile}.tmprm.tmp ${resfile}.tmprm
        # RST ck to avoid making ck broken
        if [ "${ok_code_bak}x" != "x" -a "${ok_id_bak}x" != "x" ]
        then
            echo "RST ck=${ck} badIterCode=${iterCode} code=${ok_code_bak} id=${ok_id_bak}"
            check_park ${ck} ${ok_code_bak} ${ok_id_bak}
        elif [ "${ok_code}x" != "x" -a "${ok_id}x" != "x" ]
        then
            echo "RST ck=${ck} badIterCode=${iterCode} code=${ok_code} id=${ok_id}"
            check_park ${ck} ${ok_code} ${ok_id}
        else
            echo "rsT ck=${ck} badIterCode=${iterCode} code=${ok_code} id=${ok_id}"
        fi
    else
        # set code_bak only when res is success
        l_codeQflag=""
        if echo "${s}" | grep -q "res:success" 
        then
            l_codeQflag=""
            ok_code_bak=${iterCode}
            ok_id_bak="${iterId}"
        else
            l_codeQflag="q"
            t_oldCk=${ck}
            ck=$(find_diff_ck ${ck})
            echo "change_ck oldCk=${t_oldCk} ck=${ck}"
        fi
        cfm_okN=$((cfm_okN+1))
        #addGroup
        [ "${iterId}x" == "${id_h}x" ] && { cfm_HokN=$((cfm_HokN+1)); resCode_H="${resCode_H} ${iterCode} "; }
        [ "${iterId}x" == "${id_k}x" ] && { cfm_KokN=$((cfm_KokN+1)); resCode_K="${resCode_K} ${iterCode} "; }
        [ "${iterId}x" == "${id_g}x" ] && { cfm_GokN=$((cfm_GokN+1)); resCode_G="${resCode_G} ${iterCode} "; }
        [ "${iterId}x" == "${id_w}x" ] && { cfm_WokN=$((cfm_WokN+1)); resCode_W="${resCode_W} ${iterCode} "; }
        cfm_checkRes="${cfm_checkRes}${iterCode}_$(echo ${iterIdType} | tr [:lower:] [:upper:])${l_codeQflag}_"
    fi
done
mv ${resfile}.tmprm ${resfile}

#addGroup
cfm_HpassFlag="No";cfm_KpassFlag="No";cfm_GpassFlag="No";cfm_WpassFlag="No";
needSaveGitCode="NA"

hasCodeTypeN=0
[ ${cfm_HokN} -ge 1 ] && { hasCodeTypeN=$((hasCodeTypeN+1)); }
[ ${cfm_KokN} -ge 1 ] && { hasCodeTypeN=$((hasCodeTypeN+1)); }
[ ${cfm_GokN} -ge 1 ] && { hasCodeTypeN=$((hasCodeTypeN+1)); }
[ ${cfm_WokN} -ge 1 ] && { hasCodeTypeN=$((hasCodeTypeN+1)); }

forceSeek=$(getcmdopt "forceSeek")
#Hotel
LastSeekValue_H=`read_config ${configfile} "${configKeyLastSeek}H" 0`
if echo "${forceSeek}" | grep -q "Hotel"
then
    cfm_HpassFlag="Nf"
elif [ "1"$(date +%-H%M) -gt 12300 -a "1"$(date +%-H%M) -lt 12330 -a ${best_ckt} -lt ${seekMaxCkTimeMs} ]
then
    cfm_HpassFlag="Nf"
elif [ "1"$(date +%-H%M) -gt 1000 -a "1"$(date +%-H%M) -lt 1030 -a ${best_ckt} -lt ${seekMaxCkTimeMs} ]
then
    cfm_HpassFlag="Nf"
elif [ ${cfm_HokN} -ge 2 ]
then
    cfm_HpassFlag="OK"
elif [ ${cfm_HokN} -ge 1 ]
then
    if [ ${cfm_HfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_H})) -lt ${seekTimeout_H} ]
    then
        cfm_HpassFlag="Ok"
    elif [ ${best_ckt} -gt ${seekMaxCkTimeMs} ]
    then
        # skip seek if ck is too slow and okN >= 1
        cfm_HpassFlag="Ot"
    fi
fi
#KTV
LastSeekValue_K=`read_config ${configfile} "${configKeyLastSeek}K" 0`
if echo "${forceSeek}" | grep -q "KTV"
then
    cfm_KpassFlag="Nf"
elif [ ${cfm_KokN} -ge 1 ]
then
    cfm_KpassFlag="OK"
elif [ ${cfm_KokN} -ge 1 ]
then
    if [ ${cfm_KfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_K})) -lt ${seekTimeout_K} ]
    then
        cfm_KpassFlag="Ok"
    elif [ ${best_ckt} -gt ${seekMaxCkTimeMs} ]
    then
        # skip seek if ck is too slow and okN >= 1
        cfm_KpassFlag="Ot"
    elif [ $(date +%-H%M) -gt 2320 ]
    then
        # prepare for checking and seeking at 00:00
        cfm_KpassFlag="Op"
    fi
fi
#addGroup
LastSeekValue_G=`read_config ${configfile} "${configKeyLastSeek}G" 0`
if echo "${forceSeek}" | grep -q "Group"
then
    cfm_GpassFlag="Nf"
elif [ ${cfm_GokN} -ge 1 ]
then
    cfm_GpassFlag="OK"
elif [ ${cfm_GokN} -ge 1 ]
then
    if [ ${cfm_GfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_G})) -lt ${seekTimeout_G} ]
    then
        cfm_GpassFlag="Ok"
    elif [ ${best_ckt} -gt ${seekMaxCkTimeMs} ]
    then
        cfm_GpassFlag="Ot"
    elif [ $(date +%-H%-M) -gt 2320 ]
    then
        # prepare for checking and seeking at 00:00
        cfm_GpassFlag="Op"
    fi
elif [ ${hasCodeTypeN} -ge 2 ]
then
    if [ ${cfm_GfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_G})) -lt ${seekTimeout_G} ]
    then
        cfm_GpassFlag="Oc"
    elif [ ${best_ckt} -gt ${seekMaxCkTimeMs} ]
    then
        cfm_GpassFlag="Ot"
    elif [ $(date +%-H%-M) -gt 2320 ]
    then
        # prepare for checking and seeking at 00:00
        cfm_GpassFlag="Op"
    fi
elif [ ${cfm_okN} -ge 3 ]
then
    if [ ${cfm_GfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_G})) -lt ${seekTimeout_G} ]
    then
        cfm_GpassFlag="Og"
    elif [ ${best_ckt} -gt ${seekMaxCkTimeMs} ]
    then
        cfm_GpassFlag="Ot"
    elif [ $(date +%-H%-M) -gt 2320 ]
    then
        # prepare for checking and seeking at 00:00
        cfm_GpassFlag="Op"
    fi
fi
LastSeekValue_W=`read_config ${configfile} "${configKeyLastSeek}W" 0`
if echo "${forceSeek}" | grep -q "Wuye"
then
    cfm_WpassFlag="Nf"
elif [ ${cfm_WokN} -ge 2 -o "${leastSearckMode}x" == "Yx" ]
then
    cfm_WpassFlag="OK"
elif [ ${cfm_WokN} -ge 1 ]
then
    if [ ${cfm_WfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_W})) -lt ${seekTimeout_W} ]
    then
        cfm_WpassFlag="Ok"
    elif [ ${best_ckt} -gt ${seekMaxCkTimeMs} ]
    then
        cfm_WpassFlag="Ot"
    elif [ $(date +%-H%-M) -gt 2320 ]
    then
        # prepare for checking and seeking at 00:00
        cfm_WpassFlag="Op"
    fi
elif [ ${hasCodeTypeN} -ge 2 ]
then
    if [ ${cfm_WfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_W})) -lt ${seekTimeout_W} ]
    then
        cfm_WpassFlag="Oc"
    elif [ ${best_ckt} -gt ${seekMaxCkTimeMs} ]
    then
        cfm_WpassFlag="Ot"
    elif [ $(date +%-H%-M) -gt 2320 ]
    then
        # prepare for checking and seeking at 00:00
        cfm_WpassFlag="Op"
    fi
elif [ ${cfm_okN} -ge 3 ]
then
    if [ ${cfm_WfailN} -le 0 -a $(($(date +%s)-${LastSeekValue_W})) -lt ${seekTimeout_W} ]
    then
        cfm_WpassFlag="Og"
    elif [ ${best_ckt} -gt ${seekMaxCkTimeMs} ]
    then
        cfm_WpassFlag="Ot"
    elif [ $(date +%-H%-M) -gt 2320 ]
    then
        # prepare for checking and seeking at 00:00
        cfm_WpassFlag="Op"
    fi
fi

seekIdCount=0
[ "${cfm_HpassFlag:0:1}x" == "Nx" ] && seekIdCount=$((seekIdCount+1))
[ "${cfm_KpassFlag:0:1}x" == "Nx" ] && seekIdCount=$((seekIdCount+1))
[ "${cfm_GpassFlag:0:1}x" == "Nx" ] && seekIdCount=$((seekIdCount+1))
[ "${cfm_WpassFlag:0:1}x" == "Nx" ] && seekIdCount=$((seekIdCount+1))
[ $seekIdCount -gt 2 -a "${cfm_WpassFlag:0:1}x" == "Nx" ] && { cfm_WpassFlag="On";seekIdCount=$((seekIdCount-1)); }
[ $seekIdCount -gt 2 -a "${cfm_GpassFlag:0:1}x" == "Nx" ] && { cfm_GpassFlag="On";seekIdCount=$((seekIdCount-1)); }


#addGroup
if [ "${cfm_HpassFlag:0:1}x" == "Ox" -a "${cfm_KpassFlag:0:1}x" == "Ox" -a "${cfm_GpassFlag:0:1}x" == "Ox" -a "${cfm_WpassFlag:0:1}x" == "Ox" ]
then
    [ ${cfm_failN} -gt 0 ] && needSaveGitCode="yes" || needSaveGitCode="no"
fi
logTxt="ckN=${ck_OK_n}:$(printf "%02d" ${ck_Fast_n})-${ck_Fail_n}/${ck_Total_n} $(printf "%04d" ${best_ckt})ms:$(printf "%4d" $((ck_Total_t_ms/ck_Total_n)))ms[$(printf "%02d" ${ck_dt_0})-$(printf "%02d" ${ck_dt_1})-${ck_dt_2}-${ck_dt_3}]"
#addGroup
logTxt="${logTxt} codeN=${cfm_HokN}:${cfm_KokN}:${cfm_GokN}:${cfm_WokN}-${cfm_HfailN}:${cfm_KfailN}:${cfm_GfailN}:${cfm_WfailN}/${cfm_N}"
logTxt="${logTxt} chkRes=${hasCodeTypeN}:${cfm_HpassFlag}:${cfm_KpassFlag}:${cfm_GpassFlag}:${cfm_WpassFlag}:${needSaveGitCode} checkRes=${cfm_checkRes} ck=${ck:0:4} V=${cfm_okN}-${cfm_failN}"

# check ok_code and ok_id
check_park ${ck} ${ok_code} ${ok_id} | grep -q "res:success" && logTxt="${ok_id:0:2}=${ok_code} ${logTxt}" || ok_code=""
[ "${ok_code}x" == "x" -a "${ok_code_bak}x" != "x" ] && { ok_code=${ok_code_bak}; ok_id="${ok_id_bak}"; logTxt="${ok_id:0:2}>${ok_code} ${logTxt}"; }
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
iterN=0
for ick in ${ck_set}
do
    check_park ${ick} ${ok_code} ${ok_id} | grep -q "res:success" && echo "[RST] Y ok_code=${ok_code} ck=${ick}" || echo "[RST] n ok_code=${ok_code} ck=${ick}"
    iterN=$((iterN+1)); [ ${iterN} -ge ${ck_Total_n} ] && break
done

save_result()
{
    #addGroup
    savefile ${resfile} "${resCode_H}" "${resCode_K}" "${resCode_G}" "${resCode_W}"
    savegit "Hotel: $(trim_str ${resCode_H}) KTV: $(trim_str ${resCode_K}) Group: $(trim_str ${resCode_G}) Wuye: $(trim_str ${resCode_W})"
}

#addGroup
if [ "${cfm_HpassFlag:0:1}x" == "Ox" -a "${cfm_KpassFlag:0:1}x" == "Ox"  -a "${cfm_GpassFlag:0:1}x" == "Ox" -a "${cfm_WpassFlag:0:1}x" == "Ox" ]
then
    # sync code to git if need
    if [ "${needSaveGitCode}x" == "yesx" ]
    then
        #addGroup
        #savefile ${resfile} "${resCode_H}" "${resCode_K}" "${resCode_G}" "${resCode_W}"
        #savegit "Hotel: $(trim_str ${resCode_H}) KTV: $(trim_str ${resCode_K}) Group: $(trim_str ${resCode_G}) Wuye: $(trim_str ${resCode_W})"
        save_result
    fi
    exit_clsopt 0
else
    save_result
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

rst_code()
{
    # reset code
    rstSucFlag="false"
    rstBeginTime=`date +%s`
    for idxRst in `seq 1 9`
    do
        #[ $(echo $RANDOM | cut -c1) -le 1 ] && continue
        check_park ${ck} ${ok_code} ${ok_id} | grep -q "res:success" && { echo -n " $(time2letter $(($(date +%s)-${rstBeginTime})))${idxRst}"; rstSucFlag="success"; break; }
        sleep 1
    done
    [ "${rstSucFlag}x" != "successx" ] && { echo " Fail"; exit_clsopt 1; }
}

seek_code()
{
    p_tryId=$1;shift;
    [ "${p_tryId}x" == "x" ] && p_tryId="${id_h}"
    p_seekType="X"
    #addGroup
    [ "${p_tryId}x" == "${id_h}x" ] && p_seekType="H"
    [ "${p_tryId}x" == "${id_k}x" ] && p_seekType="K"
    [ "${p_tryId}x" == "${id_g}x" ] && p_seekType="G"
    [ "${p_tryId}x" == "${id_w}x" ] && p_seekType="W"

    meter_d1=`date +"%Y-%m-%d %H:%M:%S"`
    meter_n=0
    ctrl_ln=30
    ctrl_lc=${ctrl_ln}
    lineT1=$(date +%s)
    echo "seekId: [${p_seekType}] ${p_tryId} ck=${ck}"
    
    # gen searck codes random
    echo "" > ${searchCodeFile}
    for i in `seq ${n1} 3 ${n2}`
    do
        echo ${i}:${RANDOM} >> ${searchCodeFile}
    done
    cat ${searchCodeFile} | grep ":" | sort -t ":" -k2,2n | cut -d ":" -f 1 > ${searchCodeFile}.tmp
    mv ${searchCodeFile}.tmp ${searchCodeFile}
    
    # search
    for i in `cat ${searchCodeFile}`
    do 
        if [ ${ctrl_lc} -ge ${ctrl_ln} ]
        then
            lineT2=$(date +%s);lineT=$((${lineT2}-${lineT1}));lineT1=$(date +%s);
            [ ${lineT} -gt ${lineTimeout} ] && ck=$(find_best_ck ${ck}) || ck=$(find_diff_ck ${ck})
            echo ""
            echo -n "$(date +%H:%M:%S) $(printf "%3d" ${lineT}) ${ck:0:4} $(printf "%3d" ${meter_n})"
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
            sleep 1
        done
        [ "${rstSucFlag}x" != "successx" ] && { echo " Fail"; exit_clsopt 1; }
    
        do_try ${ck} ${j} ${p_tryId}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
        do_try ${ck} ${j} ${p_tryId}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
        do_try ${ck} ${j} ${p_tryId}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
        usleep 1800 1
    done
    meter_d2=`date +%Y-%m-%d#%H:%M:%S`
    echo ""
    #addGroup
    resCode_H=`echo "${resCode_H}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
    resCode_K=`echo "${resCode_K}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
    resCode_G=`echo "${resCode_G}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
    resCode_W=`echo "${resCode_W}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
    #addGroup
    echo "beginT=${meter_d1} endT=${meter_d2} n=${meter_n} seekId=[${p_seekType}]${p_tryId:0:2} resCode_H=${resCode_H} resCode_K=${resCode_K} resCode_G=${resCode_G} resCode_W=${resCode_W}"
    save_config ${configfile} "${configKeyLastSeek}${p_seekType}" "$(date +%s)"
}

#addGroup
[ "${cfm_HpassFlag:0:1}x" == "Ox" ] || { seek_code ${id_h};save_result; }
[ "${cfm_KpassFlag:0:1}x" == "Ox" ] || { seek_code ${id_k};save_result; }
[ "${cfm_GpassFlag:0:1}x" == "Ox" ] || { seek_code ${id_g};save_result; }
[ "${cfm_WpassFlag:0:1}x" == "Ox" ] || { seek_code ${id_w};save_result; }

# send by github
if [ "${tryId}x" != "${id_k}x" ]
then
    #addGroup
    savefile ${resfile} "${resCode_H}" "${resCode_K}" "${resCode_G}" "${resCode_W}"
    savegit "Hotel: $(trim_str ${resCode_H}) KTV: $(trim_str ${resCode_K}) Group: $(trim_str ${resCode_G}) Wuye: $(trim_str ${resCode_W})"
else
    loggit "logKTVcode" "log_KTV_code: ${res_codeK}"
fi

# exit with clear action
exit_clsopt 0


