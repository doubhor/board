#!/bin/bash
ck=$1;shift;
code=$1;shift;
id=$1;shift;

shellname=`basename $0 | cut -d "." -f 1`
procname="${shellname}_$$"
debug_dump="N"
debug_dump_file="debug.${shellname}.tmp"

id_k="BkPTdVZaOYaoML6UwMGJyg==";id_h="ZT5pUv4JKL1tomT0u9SEdA==";id_g="NEEF0YcfsFZQSDlWHBblaw==";id_w="Jne4ofFTe7WSnbqQczwPPQ==";
[ "${id}x" == "Hotelx" ] && id="${id_h}"
[ "${id}x" == "KTVx" ] && id="${id_k}"
[ "${id}x" == "Groupx" ] && id="${id_g}"
[ "${id}x" == "Wuyex" ] && id="${id_w}"
[ "${id}x" == "x" ] && id="${id_h}"

if [ "${ck}x" == "x" -o "${code}x" == "x" -o "${id}x" == "x" ]
then
    echo "$0 <ck> <code> [id]"
    echo ""
    echo "id=Hotel | KTV | Group | Wuye | {id}"
    echo "Hotel: ${id_h}"
    echo "KTV:   ${id_k}"
    echo "Group: ${id_g}"
    echo "Wuye:  ${id_w}"
    exit 2
fi

echo "ck=${ck} code=${code} id=${id}"

query_park()
{
    p_c=$1;shift;
    p_code=$1;shift;
    p_id=$1;shift;

    # BkPTdVZaOYaoML6UwMGJyg==
    # ZT5pUv4JKL1tomT0u9SEdA==
    [ "${p_id}x" == "x" ] && p_id="BkPTdVZaOYaoML6UwMGJyg=="
    [ "${p_code}x" == "x" ] && p_code="580"
    
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
    echo "ck=#${p_c}# code=#${p_code}# id=#${p_id}#"

    p_html=`query_park ${p_c} ${p_code} ${p_id}`
    echo ${p_html} > debug_query.out.swap
    parse_res "${p_html}"
}

cks1=`date +%s`
check_res=`check_park ${ck} ${code} ${id}`
echo "${check_res}" | grep -q "res:fail:ck" && ck_flag="n" || ck_flag="Y"
cks2=`date +%s`
ck_t=$((cks2-cks1))


echo "[${ck_t}] ${ck_flag} ${check_res}"





