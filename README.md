# shadowsocks-libev for Docker
Cross the wall with shadowsocks, built from source and with polipo,cow and kcptun support 
#### Build docker image
Clone this repository 
<pre><code>
git clone 
cd shadowsocks-libev
</code></pre>
or download the Dockerfile and entrypoint.sh file in the repository directlly, and run
<pre><code>
docker build -t $YOUR_DOCKER_IMAGE_NAME:$YOUR_DOCKER_IMAGE_TAG .
</code></pre>
#### Usage
This the right way to create a docker container and start the container.
<pre><code>
docker run --name=shadowsocks-libev $YOUR_DOCKER_IMAGE_NAME:$YOUR_DOCKER_IMAGE_TAG -m $SS_MODULE -s $SS_CONFIG -k $KCPTUN_CONFIG -x -v
</code></pre>
where:  
<table><tbody>
  <tr>
    <td><strong>-m $SS_MODULE</strong></td>
    <td>specify the shadowsocks module to use, <<strong>ss-local</strong>, <strong>ss-server</strong>> are available modules for now
    <br/><strong>ss-local</strong>:  start a shadowsocks client with teh parameters specified in <strong>$SS_CONFIG</strong>
    <br/><strong>ss-server</strong>:  start a shadowsocks server with teh parameters specified in <strong>$SS_CONFIG</strong>
  </td>
  </tr>
  <tr>
    <td><strong>-s $SS_CONFIG</strong></td>
    <td>specify the parameters for running shadowsocks
  </td>
  <tr>
    <td><strong>-k $KCPTUN_CONFIG</strong></td>
    <td>specify the parameters for running kcptun<br/>kcptun will be available only when <strong>-x</strong> is set
  </td>
  </tr>
  <tr>
    <td><strong>-x</strong></td>
    <td>kcptun flag, use kcptun only when it is set</td>
  </tr>
  <tr>
    <td><strong>-v</strong></td>
    <td>verbose, set to run in verbose mode</td>
  </tr>
</tbody></table>  
