module("luci.controller.phddns2", package.seeall)
function index()
	if not nixio.fs.access("/etc/init.d/phddns2") then
		return
	end
	local page
	page = entry({"admin", "services", "phddns2"}, form("phddns2"), _("花生壳内网版"), 40)
	page.dependent = true
end
