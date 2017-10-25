--- 模块功能：HTTP客户端
-- @module http
-- @author 稀饭放姜
-- @lincense MIT
-- @copyright OpenLuat.com
-- @release 2017.10.23
require "socket"
require "utils"
module(..., package.seeall)

--- 创建HTTP客户端
-- @string put,提交方式"GET" or "POST"
-- @string url,HTTP请求超链接
-- @number timeout,超时时间
-- @string data,"POST"提交的数据表
-- @return string ,HttpServer返回的数据
function request(put, url, timeout, data)
    local message = {
        "GET ",
        " ",
        "head",
        " HTTP/1.0\n",
        "Accept: */*\n",
        "Accept-Language: zh-CN,zh,cn\n",
        "User-Agent: Mozilla/4.0\n",
        "Host: ",
        "wthrcdn.etouch.cn",
        "\n",
        "Content-Type: application/x-www-form-urlencoded\n",
        "Content-Length: ",
        "0",
        "\n",
        "Connection: close\n\n",
        "\n",
    }
    -- 数据，端口,主机,
    local port, host, len, sub, head, str, gzip, r, s
    -- 判断SSL支持是否满足
    local ssl, https = string.find(rtos.get_version(), "SSL"), url:find("https://")
    if ssl == nil and https then return "SOCKET_SSL_ERROR" end
    -- 对host:port整形
    if url:find("://") then url = url:sub(8) end
    sub = url:find("/")
    if not sub then url = url .. "/"; sub = -1 end
    str = url:match("([%w%.%-%:]+)/")
    port = str:match(":(%d+)") or 80
    host = str:match("[%w%.%-]+")
    head = url:sub(sub)
    if type(data) == "table" then
        local msg = {}
        for k, v in pairs(data) do
            table.insert(msg, string.urlencode(k) .. "=" .. string.urlencode(v))
            table.insert(msg, "&")
            print("http.data", msg[1])
        end
        table.remove(msg)
        str = table.concat(msg)
        len = str:utf8len()
        if put == "GET" then
            head = head .. "?" .. str
            str = "\n"
        end
    else
        len = 0
        str = "\n"
    end
    message[1] = put
    message[3] = head
    message[9] = host
    message[13] = len
    message[16] = str
    str = table.concat(message) .. "\n"
    local c = socket.tcp()
    if not c:connect(host, port) then c:close() return "SOCKET_CONN_ERROR" end
    if not c:send(str) then c:close() return "SOCKET_SEND_ERROR" end
    r, s = c:recv(timeout)
    if not r then return "SOCKET_RECV_TIMOUT" end
    gzip = string.match(s, "%aontent%-%ancoding: (%w+)")
    log.info("http.request recv is:\t", len, gzip)
    local msg = {}
    while true do
        r, s = c:recv(timeout)
        if not r then break end
        table.insert(msg, s)
    end
    c:close()
    if gzip then return (zlib.inflate(table.concat(msg))):read() end
    return table.concat(msg)
end