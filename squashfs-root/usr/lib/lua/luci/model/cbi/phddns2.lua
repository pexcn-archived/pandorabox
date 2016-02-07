require "luci.fs"
require "luci.sys"
require "luci.util"

local phddns2_enabled=luci.sys.init.enabled("phddns2")

m = SimpleForm("phddns2", "花生壳动态域名（内网版）", "由花生壳提供的内网穿透服务。这项服务可以将局域网内的网站直接映射到外网中，在外网通过域名访问您搭建的站点。")
m.reset=false
m.submit=false
s = m:section(SimpleSection, "状态信息")
e = s:option(Button, "endisable", " ", "启用/禁用花生壳内网版")
e.render = function(self, section, scope)
	if phddns2_enabled then
		self.title = translate("禁用花生壳")
		self.inputstyle = "reset"
	else
		self.title = translate("启用花生壳")
		self.inputstyle = "apply"
	end
	Button.render(self, section, scope)
end
e.write = function(self, section)
	if phddns2_enabled then
		phddns2_enabled=false
		luci.sys.init.stop("phddns2")
		luci.http.write("<script type=\"text/javascript\">location.replace(location)</script>")
		luci.http.close()
		return luci.sys.init.disable("phddns2")
	else
		phddns2_enabled=true
		luci.sys.init.start("phddns2")
		luci.sys.exec("sleep 2")
		luci.http.write("<script type=\"text/javascript\">location.replace(location)</script>")
		luci.http.close()
		return luci.sys.init.enable("phddns2")
	end
end
if (luci.sys.call("pidof oraysl > /dev/null") == 0) then
	if nixio.fs.access("/tmp/oraysl.status") then
		s:option(DummyValue,"detailedstatus" ,"花生壳状态信息：", "花生壳运行中。<br />SN:" .. luci.sys.exec("head -n 2 /tmp/oraysl.status  | tail -n 1 | cut -d= -f2-") .. "<br />运行状态：" .. luci.sys.exec("head -n 3 /tmp/oraysl.status  | tail -n 1 | cut -d= -f2-"))
	s:option(DummyValue,"opennewwindow" ,"<br /><p align=\"justify\"><input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"花生棒管理页面\" onclick=\"window.open('http://b.oray.com/')\" /></p>", "使用SN登录管理页面。<br />默认密码为admin。")
	else
		s:option(DummyValue,"detailedstatus" ,"花生壳状态信息：", "无法获取状态配置文件。")
	end
else
	s:option(DummyValue,"detailedstatus" ,"花生壳状态信息：", "花生壳未运行。")
end
return m
