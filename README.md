## 基本描述
本项目在Shadowsocks的基础上同时封装了polipo服务和 cow 服务。  

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

## 搭建代理服务
使用本项目搭建代理服务非常简单，故简单带过，本节主要讨论启动代理服务的注意事项。
#### 构建Docker镜像
由于本项目目前尚未上传到Docker服务仓储中备份，用户需要自行编译Docker镜像，步骤如下：
1. 下载项目中的Dockerfile配置文件和enterpoint.sh脚本文件
<pre><code>
wget -sSLO https://raw.githubusercontent.com/UKeyboard/shadowsocks-libev/master/Dockerfile
wget -sSLO https://raw.githubusercontent.com/UKeyboard/shadowsocks-libev/master/entrypoint.sh
</code></pre>
或直接 clone 本项目：
<pre><code>
git clone 
cd shadowsocks-libev
</code></pre>
