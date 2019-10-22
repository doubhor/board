#!/bin/bash
c=$1;shift;
code=$1;shift;
id=$1;shift;

# BkPTdVZaOYaoML6UwMGJyg==
# ZT5pUv4JKL1tomT0u9SEdA==
[ "${id}x" == "x" ] && id="BkPTdVZaOYaoML6UwMGJyg=="
[ "${code}x" == "x" ] && code="242"
echo "c=#${c}# code=#${code}# id=#${id}#"

curl "http://wx.parkingwang.com/coupon/coupon_show?coupon=${id}&verification=${code}" \
-H "Cookie: parking_ses=${c}" \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' \
-H 'Referer: http://wx.parkingwang.com/coupon/input_code?coupon_id=BkPTdVZaOYaoML6UwMGJyg==' \
-H 'Accept-Encoding: gzip, deflate' \
-H 'Accept-Language: zh-CN,zh;q=0.9' \
-H 'misctooltoken: c6d1ad2b9afs4fbab56aaa3e0267deb9' --compressed 2>/dev/null | grep "请输入车牌"

