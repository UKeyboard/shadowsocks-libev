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
