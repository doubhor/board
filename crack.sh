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
    ./ok.sh ${ick} | grep -q "请输入车牌" && ck_flag="Y" || ck_flag="n"
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
id_k="BkPTdVZaOYaoML6UwMGJyg=="
id_h="ZT5pUv4JKL1tomT0u9SEdA=="
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
    s=`./try.sh ${ck} ${i}`
    if echo "${s}" | grep -q "ok" 
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
    logTxt="N=${okN}:${failN} checkPass=${checkPassFlag} syncGit=${needSaveGitCode} checkRes=${checkRes}"
fi
logTxt="ckN=${ck_OK_n} T=${besk_ckt} ck=${ck} codeN=${okN}:${failN} checkPass=${checkPassFlag} syncGit=${needSaveGitCode} checkRes=${checkRes}"
echo ${logTxt}

# send by github
gittime=`date +"%Y-%m-%d %H:%M:%S"`
./sendgit.sh crontab.log 50 ${gittime} ${logTxt}


if [ "${checkPassFlag}x" == "yesx" ]
then
    # sync code to git if need
    if [ "${needSaveGitCode}x" == "yesx" ]
    then
        echo "${res_code}" > ${resfile}
        gittime=`date +"%Y-%m-%d %H:%M:%S"`
        ./sendgit.sh vcode.txt 7 ${gittime} ${res_code}
    fi
    exit 0
fi

do_try()
{
    p_ck=$1;shift;
    p_code=$1;shift;
    s=`./try.sh ${p_ck} ${p_code}`
    ns=`echo "${s}" | cut -d "=" -f 2`
    if echo "${s}" | grep -q "ok"
    then
        echo -n -e " [\\033[32m\\033[1m${j}\\033[0m]"
        res_code="${res_code}${p_code} "
    else
        [ "${ns}z" == "xz" ] && echo -n -e " \\033[31m\\033[1m$(printf "%3d" ${j})\\033[0m|${ns}" || echo -n " $(printf "%3d" ${j})|${ns}"
   fi
}


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
        ./ok.sh ${ck} | grep -q "请输入车牌" && echo -n " Y${idxRst}" && rstSucFlag="success" && break
    done
    [ "${rstSucFlag}x" != "successx" ] && { echo " Fail"; exit 1; }
    
    #s=`./try.sh ${ck} ${j}`; echo "${j} ${s}" | grep "[0-9][0-9].*alert"; n=$((n+1)); j=$((j+1));
    #s=`./try.sh ${ck} ${j}`; ns=`echo "${s}" | grep -o "[0-9]次" | grep -o "[0-9]"`; echo "${s}" | grep -q "请输入车牌" && echo -n -e " [\\033[32m\\033[1m${j}\\033[0m]" || echo -n " $(printf "%3d" ${j})|${ns}"; n=$((n+1)); lc=$((lc+1)); j=$((j+1));
    #s=`./try.sh ${ck} ${j}`; ns=`echo "${s}" | cut -d "=" -f 2`; echo "${s}" | grep -q "ok" && echo -n -e " [\\033[32m\\033[1m${j}\\033[0m]" || echo -n " $(printf "%3d" ${j})|${ns}"; n=$((n+1)); lc=$((lc+1)); j=$((j+1));
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
gittime=`date +"%Y-%m-%d %H:%M:%S"`
./sendgit.sh vcode.txt 7 ${gittime} ${res_code}

