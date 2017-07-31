#!/bin/bash
trap 'appTerminate; exit 1' HUP INT QUIT TSTP

usage()
{
    echo "Usage:script -s <string> [-m <string>] [-x [-k <string>] [-v] [-h]"
    echo "This is docker-shadowsocks-libev entrypoint script, only ss-server|ss-client supported currently"
    echo ""
    echo "Options:"
    echo "  -s SS_CONFIG            shadowsocks command config string"
    echo "  -m <ss-local|ss-server>        shadowsocks command, use 'ss-server' if not set "
    echo "  -x      kcptun flag, set to use kcptun"
    echo "  -k      kcptun config string, will be omitted if -x is not set"
    echo "  -v      verbose mode"
    echo "  -h      show this help message"
    exit 1
}


#################################################
isNumberic()
{
    if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
        return 0
    else
        return 1
    fi
}

getLocalTime(){
    timeStamp=$((`date -u +%s`))
    time=$(date -d @$timeStamp|sed 's/Jan/01/g;s/Feb/02/g;s/Mar/03/g;s/Apr/04/g;s/May/05/g;s/Jun/06/g;s/Jul/07/g;s/Aug/08/g;s/Sep/09/g;s/Oct/10/g;s/Nov/11/g;s/Dec/12/g')
    echo $time|awk '{print $6"/"$2"/"$3" "$4}'
}

checkConnectionStatus(){
    # $1 specify the extra runtime parameter for command "wget"
    for i in `seq 0 3`;do
        t=$(wget -t 3 -T 3 --spider -S --no-check-certificate $1 2>&1|grep "HTTP/" |awk '{print $2}')
        if [ "$t" != "" ];then
            break
        else
            t=-1
            sleep 3
        fi
    done
    echo $t
}

netappProcessID(){
    echo $((ps -o comm,pid |grep $1|grep -v "COMMAND"|awk '{print $2}') 2>/dev/null)
}
netappListenPort(){
    echo $((netstat -nlp|grep $1|grep -v "Local Address"|awk '{print $4}'|rev|cut -d ':' -f 1|rev) 2>/dev/null)
}
netappRunningStatus(){
    # Get the running status of a network application 
    _port=$(netappListenPort $1)
    _pid=$(netappProcessID $1)
    if [[ $_pid == "" ]];then
        if [[ "$DEBUG" == "true" ]];then
            echo -e "\033[31m`getLocalTime`\tWARNING: cannot find a process which satisfies the fileter \"$1\"\033[0m"
        fi
        return 1
    else
        if [[ "$DEBUG" == "true" ]];then
            echo -e "\033[32m`getLocalTime`\tINFO: filter \"$1\" satisfied process $_pid running on $_port\033[0m"
        fi
        return 0
    fi    
}

appTerminate(){
    case "#$SS_MODULE#" in
        "#ss-server#")
            netappProcessID "kcp-server" | xargs kill -9 2>/dev/null
            netappProcessID "ss-server" | xargs kill -9 2>/dev/null
            ;;
        "#ss-local#")
            netappProcessID "kcp-client" | xargs kill -9 2>/dev/null
            netappProcessID "cow" | xargs kill -9 2>/dev/null
            netappProcessID "polipo" | xargs kill -9 2>/dev/null
            netappProcessID "ss-local" | xargs kill -9 2>/dev/null
            ;;
        *)
            :;;
      esac
}
###########################################################################

DEBUG=${DEBUG:-"false"}
LOCAL_MACHINE="127.0.0.1|0.0.0.0|localhost|::1|::0|::"
SS_CONFIG=${SS_CONFIG:-""}
SS_MODULE=${SS_MODULE:-""}

KCP_CONFIG=${KCP_CONFIG:-""}
KCP_FLAG=${KCP_FLAG:-"false"}



while getopts "s:m:k:xv" OPT; do
    case $OPT in
        s)
            SS_CONFIG=$OPTARG;;
        m)
            SS_MODULE=$OPTARG;;
        k)
            KCP_CONFIG=$OPTARG;;
        x)
            KCP_FLAG="true";;
        v)
            DEBUG="true";;
        *)
            usage;;
    esac
done

if [[ "$DEBUG"=="true" ]]; then
    echo -e "\033[32m`getLocalTime`\tINFO: docker is running under debug mode ......ok \033[0m"
    echo "|ss-local|ss-server|$SS_MODULE|"
    ps | grep entrypoint | grep -v grep
fi

# shadowsocks config cannot be empty
if [[ "$SS_CONFIG" == "" ]]; then
    echo -e "\033[31m`getLocalTime`\tERROR: shadowsocks config string is empty [SS_CONFIG==\"\"]\033[0m"
    usage
fi


if [[ "#$SS_MODULE#" == "##" ]]; then SS_MODULE="ss-server"; fi
if ! $( echo "|ss-local|ss-server|" | grep -q "|$SS_MODULE|" > /dev/null ); then
    echo -e "\033[31m`getLocalTime`\tERROR: unknown command, cannot resolve ss command $SS_MODULE\033[0m"
    usage
fi

case "#$SS_MODULE#" in
    "#ss-server#")
        SS_SERVER_OPTIONS="-s|-p|-l|-k|-m|-a|-f|-t|-c|-n|-i|-b|-u|-U|-6|-d|-v|-h|--reuse-port|--fast-open|--acl|--manager-address|--mtu|--mptcp|--key|--plugin|--plugin-opts|--help"
        SS_SERVER_PORT=$(echo ${SS_CONFIG#*-p} | awk '{print $1}')
        if echo "|$SS_SERVER_OPTIONS|" | grep -q "|$SS_SERVER_PORT|" > /dev/null; then
            echo -e "\033[31m`getLocalTime`\tWARNING: option [-p] is missing from SS_CONFIG, use [-p 8388] as default value\033[0m"
            SS_SERVER_PORT="8388"
            SS_CONFIG="$SS_CONFIG -p $SS_SERVER_PORT"
        fi
        if ! isNumberic $SS_SERVER_PORT; then
            echo -e "\033[31m`getLocalTime`\tERROR: cannot resolve ss parameter $SS_SERVER_PORT\033[0m"
            exit 1
        fi
        if [[ "$KCP_FLAG" == "true" ]]; then
            #KCP_SERVER_OPTIONS="help|h|--listen|-l|--target|-t|--key|--crypt|--mode|--mtu|--sndwnd|--rcvwnd|--datashard|--ds|--parityshard|--ps|--dscp|--nocomp|--snmplog|--snmpperiod|--pprof|--log|-c|--help|-h|--version|-v"
            KCP_CONFIG="$KCP_CONFIG -t 127.0.0.1:$SS_SERVER_PORT"
            echo -e "\033[32m`getLocalTime`\tINFO: executing ==> kcp-server $KCP_CONFIG\033[0m"
            nohup kcp-server $KCP_CONFIG 2>&1 &
        fi
        if [[ "$DEBUG" == "true" ]]; then SS_CONFIG="$SS_CONFIG -v"; fi
        echo -e "\033[32m`getLocalTime`\tINFO: executing ==> $SS_MODULE $SS_CONFIG\033[0m"
        nohup $SS_MODULE $SS_CONFIG 2>&1 &
        echo -e "\033[32m`getLocalTime`\tINFO: start watching on shadowsocks running status\033[0m"
        while [[ true ]]; do
            if ! netappRunningStatus "ss-server"; then
                if [[ $DEBUG == "true" ]]; then
                    echo -e "\033[31m`getLocalTime`\tERROR: shadowsocks server terminated, try to restart\033[0m"
                fi
                nohup $SS_MODULE $SS_CONFIG 2>&1 &
            fi
            if [[ "$KCP_FLAG" == "true" ]] && ! netappRunningStatus "kcp-server"; then
                if [[ $DEBUG == "true" ]]; then
                    echo -e "\033[31m`getLocalTime`\tERROR: kcptun server terminated, try to restart\033[0m"
                fi
                nohup kcp-server $KCP_CONFIG 2>&1 &
            fi
            sleep 10            
        done
        ;;
    "#ss-local#")
        SS_CLIENT_OPTIONS="-s|-p|-l|-k|-m|-a|-f|-t|-c|-n|-i|-b|-u|-U|-6|-d|-v|-h|--reuse-port|--fast-open|--acl|--manager-address|--mtu|--mptcp|--key|--plugin|--plugin-opts|--help"
        SS_CLIENT_PORT=$(echo ${SS_CONFIG#*-l} | awk '{print $1}')
        if echo "|$SS_CLIENT_OPTIONS|" | grep -q "|$SS_CLIENT_PORT|" > /dev/null; then
            echo -e "\033[32m`getLocalTime`\tINFO: option [-l] is missing from SS_CONFIG\033[0m"
        else
            mkdir -p $WORKSPACE/config \
            && mkdir -p $WORKSPACE/cache \
            && mkdir -p $WORKSPACE/log

            # start polipo, listen on 8123 by default
            cp /etc/polipo/config.sample $WORKSPACE/config/polipo.ini \
            && sed -i 's/^[^#]/#&/g' $WORKSPACE/config/polipo.ini \
            && echo "proxyAddress = \"0.0.0.0\"" >> $WORKSPACE/config/polipo.ini \
            && echo "proxyPort = $POLIPO_PORT" >> $WORKSPACE/config/polipo.ini \
            && echo "socksParentProxy = \"127.0.0.1:${SS_CLIENT_PORT}\"" >> $WORKSPACE/config/polipo.ini \
            && echo "socksProxyType = socks5" >> $WORKSPACE/config/polipo.ini \
            && echo "diskCacheRoot = $WORKSPACE/cache/polipo" >> $WORKSPACE/config/polipo.ini \
            && echo "logSyslog = true" >> $WORKSPACE/config/polipo.ini \
            && echo "logLevel = 4" >> $WORKSPACE/config/polipo.ini \
            && echo "logFile = $WORKSPACE/log/polipo.log" >> $WORKSPACE/config/polipo.ini \
            && echo "allowedPorts = 1-65535" >> $WORKSPACE/config/polipo.ini \
            && echo "daemonise = true" >> $WORKSPACE/config/polipo.ini \
            && echo "dontCacheCookies = true" >> $WORKSPACE/config/polipo.ini \
            && echo "maxAge = 1d" >> $WORKSPACE/config/polipo.ini \
            && echo "serverTimeout = 30s" >> $WORKSPACE/config/polipo.ini \
            && echo -e "\033[32m`getLocalTime`\tINFO: executing==> polipo -c $WORKSPACE/config/polipo.ini\033[0m" \
            && polipo -c $WORKSPACE/config/polipo.ini

            # start cow, listen on 7777 by default
            cp /etc/cow/rc $WORKSPACE/config/cow.ini \
            && sed -i 's/^[^#]/#&/g' $WORKSPACE/config/cow.ini \
            && echo "listen = http://0.0.0.0:$COW_PORT" >> $WORKSPACE/config/cow.ini \
            && echo "loadBalance = backup" >> $WORKSPACE/config/cow.ini \
            && echo "estimateTarget = www.google.com" >> $WORKSPACE/config/cow.ini \
            && echo "dialTimeout = 5s" >> $WORKSPACE/config/cow.ini \
            && echo "readTimeout = 3s" >> $WORKSPACE/config/cow.ini \
            && echo "detectSSLErr = true" >> $WORKSPACE/config/cow.ini \
            && echo "proxy = http://127.0.0.1:$POLIPO_PORT" >> $WORKSPACE/config/cow.ini \
            && echo "proxy = socks5://127.0.0.1:${SS_CLIENT_PORT}" >> $WORKSPACE/config/cow.ini \
            && COW_CONFIG="-rc=$WORKSPACE/config/cow.ini -logFile=$WORKSPACE/log/cow.log"
            if [[ "$DEBUG" == "true" ]]; then COW_CONFIG="$COW_CONFIG -debug"; fi
            echo -e "\033[32m`getLocalTime`\tINFO: executing==> cow $COW_CONFIG\033[0m"
            nohup cow $COW_CONFIG 2>&1 &

            if [[ "$KCP_FLAG" == "true" ]]; then
                echo -e "\033[32m`getLocalTime`\tINFO: executing==> kcp-client $KCP_CONFIG\033[0m"
                nohup kcp-client $KCP_CONFIG 2>&1 &
            fi
        fi
        echo -e "\033[32m`getLocalTime`\tINFO: executing==> $SS_MODULE $SS_CONFIG\033[0m"
        nohup $SS_MODULE $SS_CONFIG 2>&1 &
        echo -e "\033[32m`getLocalTime`\tINFO: start watching on shadowsocks running status\033[0m"
        while [[ true ]]; do
            if ! netappRunningStatus "ss-local"; then
                if [[ $DEBUG == "true" ]]; then
                    echo -e "\033[31m`getLocalTime`\tERROR: shadowsocks client terminated, try to restart\033[0m"
                fi
                nohup $SS_MODULE $SS_CONFIG 2>&1 &
            fi
            if ! netappRunningStatus "polipo"; then
                if [[ $DEBUG == "true" ]]; then
                    echo -e "\033[31m`getLocalTime`\tERROR: polipo proxy terminated, try to restart\033[0m"
                fi
                polipo -c $WORKSPACE/config/polipo.ini
            fi
            if ! netappRunningStatus "cow"; then
                if [[ $DEBUG == "true" ]]; then
                    echo -e "\033[31m`getLocalTime`\tERROR: cow proxy terminated, try to restart\033[0m"
                fi
                nohup cow $COW_CONFIG 2>&1 &
            fi
            if [[ "$KCP_FLAG" == "true" ]] && ! netappRunningStatus "kcp-client"; then
                if [[ $DEBUG == "true" ]]; then
                    echo -e "\033[31m`getLocalTime`\tERROR: kcptun client terminated, try to restart\033[0m"
                fi
                nohup kcp-client $KCP_CONFIG 2>&1 &
            fi
            sleep 10
        done
        ;;
    *)
        usage
        ;;
esac

