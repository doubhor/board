#!/bin/bash
c=$1;shift
code=$1;shift

html=`curl "http://wx.parkingwang.com/coupon/coupon_show?coupon=ZT5pUv4JKL1tomT0u9SEdA==&verification=${code}" -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: http://wx.parkingwang.com/coupon/input_code?coupon_id=BkPTdVZaOYaoML6UwMGJyg==' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: zh-CN,zh;q=0.9' -H "Cookie: parking_ses=${c}" -H 'misctooltoken: c6d1ad2b9afs4fbab56aaa3e0267deb9' --compressed 2>/dev/null`


lastn=`echo "${html}" | egrep  "(优惠券不存在)" | grep -o "[0-9]次" | grep -o "[0-9]"`
echo "${html}" | egrep -q "(没有优惠券了)" && xn="x" 
echo "${html}" | egrep -q "(请输入车牌)" && res="ok" || res="fail=${xn}${lastn}"

echo "${res}"

