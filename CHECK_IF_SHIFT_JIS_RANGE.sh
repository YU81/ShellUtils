#!/bin/bash
# 引数指定の文字列またはファイルに対して、シフトJISの範囲内にあるかどうかをチェックする。
# nkf Network Kanji Filter に依存する。

function usage {
    echo "Usage : CHECK_SHIFT_JIS_RANGE.sh \${check_str}"
    echo "        CHECK_SHIFT_JIS_RANGE.sh \${check_file}"
}

#
# ファイル比較モードか文字列比較モードかを決定
# @param  string input ファイルパスまたはチェックする文字列
# @return int          0:モード決定成功 1:モード決定失敗
# @output string       ^(file|string|error)$
#
function determine_mode {
    local input=$1

    if [ -s "${input}" ]; then
        # 存在するファイルパスであった場合、ファイル内容を開いて比較するモードとする
        echo "file"
        return 0
    elif [ "${input}" != "" ]; then
        # 存在しないファイルだった場合で、かつ、文字列として共に空文字でなければ、文字列として比較するモードとする
        echo "string"
        return 0
    else
        echo "error"
        return 1
    fi
}

#
# 引数の文字列(UTF-8前提)を、一旦シフトJISにしてからUTF-8に戻すという往復変換処理を行う
# @param  string input 往復変換処理をする文字列
# @output string
#
function convert_round {
    local input=$1

    echo "${input}" | nkf -sxLw | nkf -wxLu
}

#
# 引数の文字列(UTF-8前提)が、シフトJISの範囲内文字列のみからなるかどうかをチェックする
# @param  string input 往復変換処理をする文字列
# @return int          0:シフトJIS範囲内 1:シフトJIS範囲外
# @output string       ^(OK|NG) ${input}$
#
function compare_string {
    local compared_string=$1
    local converted_round_line=$(convert_round ${compared_string})

    if [ "${compared_string}" = "{convert_round_line}" ]; then
        echo "OK" "${compared_string}"
        return 0
    else
        echo "NG" "${compared_string}"
        return 1
    fi
}

function compare_file {
    local compared_file=$1

    cat ${compared_file} |
    while read line
    do
        local converted_round_line=$(convert_round ${line})
        if [ "${line}" != "${converted_round_line}" ]; then
            echo "OK" "${line}"
        else
            echo "NG" "${line} ${converted_round_line}"
        fi
    done
}

mode=$(determine_mode "$1")

if [ "${mode}" = "error" ]; then
    echo "error"
    usage
    exit 1
fi

if [ "${mode}" = "file" ];then
    compare_file "$1"
elif [ "${mode}" = "string" ]; then
    compare_string "$1"
fi
