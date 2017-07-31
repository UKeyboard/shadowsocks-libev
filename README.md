# 基本描述

本项目在Shadowsocks的基础上同时封装了polipo服务和 cow 服务， 并使用kcptun加速。  

Polipo将Shadowsocks提供的socks5协议代理转成http代理，满足不支持socks5协议的场合，如 shell环境中    

Cow提供一种无缓存的多代理解决方案，支持条件转发，cow将所有代理请求按条件转发到其他代理服务。Cow对外提供的也是http代理。
<table>
  <tbody>
    <thead>
      <th>代理类型</th>
      <th>服务名称</th>
      <th>默认端口</th>
    </thead>
    <tr>
      <td>socks5</td>
      <td>shadowsocks-libev</td>
      <td>无默认，需在SS_CONFIG中指定</td>
    </tr>
    <tr>
      <td>http</td>
      <td>polipo</td>
      <td>8123</td>
    </tr>
    <tr>
      <td>http</td>
      <td>cow</td>
      <td>7777</td>
    </tr>
  </tbody>
<table>
  
<strong>使用本项目的一般流程：</strong>
1. 根据Dockerfile构建Docker镜像
2. 用有效参数创建 Docker Container （这里要对外暴露 代理端口，如 7777， 8123，$SS_LOCAL_PORT）
3. 在系统或Chrome等浏览器中指定使用代理
代理地址示例：
<table>
  <thead>
    <th> 服务名称 </th>
    <th> 代理类型 </th>
    <th> 代理地址 </th>
  </thead>
  <tbody>
    <tr>
      <td> cow 代理 </td>
       <td> http </td>
      <td> 全局代理：”http://127.0.0.1:7777 “<br/>自动代理：”http://127.0.0.1:7777/pac“</td>
    </tr>
    <tr>
      <td> polipo 代理 </td>
      <td> http </td>
      <td> 全局代理：”http://127.0.0.1:8123 “<br/>polipo自身不支持自动代理</td>
    </tr>
    <tr>
      <td> ss 代理 </td>
      <td> socks5 </td>
      <td> 全局代理：”http://127.0.0.1:$SS_LOCAL_PORT “<br/>shadowsocks自身不支持自动代理<br/>$SS_LOCAL_PORT为shadowsocks参数中指定的 <strong>"-l" 参数</strong></td>
    </tr>
  </tbody>
</table>
<small><i style="color:red">注意： socks5协议的 ss 代理只有当 shadowsocks 参数中指定了 ”-b 0.0.0.0“ 才可用！</i></small>

*****
# 搭建代理服务
使用本项目搭建代理服务非常简单，故简单带过，本节主要讨论启动代理服务的注意事项。
## <strong>构建Docker镜像:</strong>
由于本项目目前尚未上传到Docker服务仓储中备份，用户需要自行编译Docker镜像，步骤如下：
1. 下载项目中的Dockerfile配置文件和enterpoint.sh脚本文件
<pre><code>
wget -sSLO https://raw.githubusercontent.com/UKeyboard/shadowsocks-libev/master/Dockerfile
wget -sSLO https://raw.githubusercontent.com/UKeyboard/shadowsocks-libev/master/entrypoint.sh
</code></pre>
或直接 clone 本项目：
<pre><code>
git clone https://github.com/UKeyboard/shadowsocks-libev.git
cd shadowsocks-libev
</code></pre>
2. 编译Docker镜像
<pre><code>
docker build -t $NAME:$TAG .
</code></pre>

## <strong>启动代理服务:</strong>
编译的Docker镜像中包含了Shadowsocks，polipo，cow服务和kcptun加速服务。 镜像使用 entrypoint.sh 脚本作为启动脚本，该脚本负责按参数启动各项服务，我们只要使用正确、合法的参数构建镜像的Container并启动它就可以轻松启动代理服务。  

代理服务正确打开姿势
<pre><code>
docker run --name=shadowsocks $NAME:$TAG -m $SS_MODULE -s $SS_COFIG -k $KCP_CONFIG -x -v
</code></pre>
其中 -skmxv 为启动参数：
<table>
      <thead>
            <th>参数名称</th>
            <th>参数描述</th>
            <th>可接受参数值</th>
      </thead>
      <tbody>
            <tr>
                  <td>-m $SS_MODULE</td>
                  <td>指定要启动的ss程序，目前仅支持ss-local和ss-server，默认值=ss-server</td>
                  <td>ss-local|ss-server<br/>指定ss-local启动ss客户端<br/>指定ss-server启动ss服务端</td>
            </tr>
            <tr>
                  <td>-s $SS_COFIG</td>
                  <td>shadowsocks-libev 参数字符串，所有参数将被拼接到 -m 指定的ss程序后构成完整ss程序启动代码</td>
                  <td>所有shadowsocks-libev 支持的选项参数</td>
            </tr>
            <tr>
                  <td>-k $KCP_CONFIG</td>
                  <td>kcptun 参数字符串，所有参数将被拼接到 kcptun 程序后构成完整 kcptun启动代码，只有设置了 -x 参数这些参数被使用</td>
                  <td>所有 kcptun 支持的选项参数</td>
            </tr>
            <tr>
                  <td>-x</td>
                  <td>是否启用 kcptun 标志符<br/>设置 -x 参数启用 kcptun 服务<br/>反之，禁用kcptun程序， -k指定的kcptun参数将无效</td>
                  <td>无</td>
            </tr>
            <tr>
                  <td>-v</td>
                  <td>设置启动Debug模式</td>
                  <td>无</td>
            </tr>
      </tbody>
</table>


使用启动参数的命令示例：  

<strong>Server服务端</strong>  

假设服务端的网址或域名是 ss.example.org
<pre><code>
docker run -dt --name=shadowsocks -p 6443:6443 -p 6500:6500/udp $NAME:$TAG -s "-s :: -s 0.0.0.0 -p 6443 -m aes-256-cfb -k test123 --fast-open" -k "-t 127.0.0.1:6443 -l :6500 -mode fast2" -x
</code></pre>
相当于执行了下面命令：
<pre><code>
ss-server -s :: -s 0.0.0.0 -p 6443 -m aes-256-cfb -k test123 --fast-open
kcp-server -t 127.0.0.1:6443 -l :6500 -mode fast2
</code></pre>
ss运行在6443端口； kcp-server为ss构建了加速通道，运行在6500端口。此时服务端准备好了。如果不想开启kcp加速，删除 -k和-x参数即可。

<strong>Client客户端</strong>
<pre><code>
docker run -dt --name=shadowsocks -p 1080：1080 -p 8123:8123 -p 7777:7777 $NAME:$TAG -m "ss-local" -s "-s 127.0.0.1 -p 6443 -l 1080 -b 0.0.0.0 -m aes-256-cfb -k test123 --fast-open" -k "-r ss.example.org:6500 -l :6443 -mode fast2" -x
</code></pre>
相当于执行了下面命令：
<pre><code>
ss-local -s 127.0.0.1 -p 6443 -l 1080 -b 0.0.0.0 -m aes-256-cfb -k test123 --fast-open
kcp-client -r ss.example.org:6500 -l :6443 -mode fast2
</code></pre>
这样就和ss服务端通过kcp建立了快速通道，同时内部还启动了polipo和cow，分别监听8123端口和7777端口实现代理转发，kcp的基本原理如下图：
![kcptun原理示意图](https://github.com/xtaci/kcptun/raw/master/kcptun.png)
如果ss服务端没有开启kcptun服务或不想使用kcptun加速服务，可使用
<pre><code>
docker run -dt --name=shadowsocks -p 1080：1080 -p 8123:8123 -p 7777:7777 $NAME:$TAG -m "ss-local" -s "-s ss.example.org -p 6443 -l 1080 -b 0.0.0.0 -m aes-256-cfb -k test123 --fast-open"
</code></pre>
直接同ss服务端的ss-server建立连接。<i>注意这里的监听ip和端口的变化</i>。


## 环境变量支持
与启动参数 -skmxv 对应地本项目支持 SS_CONFIG，KCP_CONFIG，SS_MODULE，KCP_FLAG，DEBUG 五个环境变量。
<table>
      <thead>
            <th>环境变量</th>
            <th>作用</th>
            <th>取值</th>
      </thead>
      <tbody>
            <tr>
                  <td>SS_CONFIG</td>
                  <td>shadowsocks-libev 参数字符串</td>
                  <td>同 -s 参数，支持所有 shadowsocks-libev 支持的选项参数</td>
            </tr>
            <tr>
                  <td>KCP_CONFIG</td>
                  <td>kcptun 参数字符串</td>
                  <td>同 -k 参数，支持所有kcptun 支持的选项参数</td>
            </tr>
            <tr>
                  <td>SS_MODULE</td>
                  <td>shadowsocks 启动命令</td>
                  <td>同 -m 参数，ss-local 或 ss-server</td>
            </tr>
            <tr>
                  <td>KCP_FLAG</td>
                  <td>是否开启 kcptun 支持</td>
                  <td>效果同 -x参数，可选参数为 true 和 false，默认为 fasle 禁用 kcptun</td>
            </tr>
            <tr>
                  <td>DEBUG</td>
                  <td>是否输出debug信息</td>
                  <td>效果同 -v参数，可选参数为 true 和 false，默认为 fasle 禁用 debug信息</td>
            </tr>
      </tbody>
</table>
环境变量与启动参数一一对应，但启动参数相对环境变量具有更高的优先级，也就是说同时指定环境变量和启动参数的情况下将以启动参数为准，环境变量会被屏蔽。

上文使用启动参数示例换成使用环境变量后命令如下：

<strong>Server服务端</strong>
<pre><code>
docker run -dt --name=shadowsocks -p 6443:6443 -p 6500:6500/udp  -e SS_CONFIG="-s :: -s 0.0.0.0 -p 6443 -m aes-256-cfb -k test123 --fast-open" -e KCP_CONFIG="-t 127.0.0.1:6443 -l :6500 -mode fast2" -e KCP_FLAG="true" $NAME:$TAG
</code></pre>

<strong>Client客户端</strong>
<pre><code>
docker run -dt --name=shadowsocks -p 1080：1080 -p 8123:8123 -p 7777:7777 -e SS_CONFIG="ss-local" -s "-s 127.0.0.1 -p 6443 -l 1080 -b 0.0.0.0 -m aes-256-cfb -k test123 --fast-open" -e KCP_CONFIG="-r ss.example.org:6500 -l :6443 -mode fast2" -e KCP_FLAG="true" $NAME:$TAG
</code></pre>


