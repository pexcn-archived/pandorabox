--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

m = Map("w8021x", translate("Wired 802.1X Authentication"),
	translate("IEEE 802.1X Authentication for Wired Networks is mainly used in many campus networks."))

s = m:section(TypedSection, "item", translate("Items"))
s.template = "cbi/tblsection"
s.extedit  = luci.dispatcher.build_url("admin/network/w8021x/item/%s")
s.addremove = true
s.anonymous = true

function s.create(...)
	local id = TypedSection.create(...)
	luci.http.redirect(s.extedit % id)
end

function s.remove(self, section)
	if m.uci:get("w8021x", section) == "item" then
		local iface = m.uci:get("w8021x", section, "interface")
	end

	return TypedSection.remove(self, section)
end

o = s:option(Flag, "auto", translate("Auth on boot"))
o.rmempty = false
o.width   = "120px"
function o.cfgvalue(...)
	local v = Flag.cfgvalue(...)
	return v == "1" and "1" or "0"
end
function o.write(self, section, value)
	Flag.write(self, section, value == "1" and "1" or "0")
end

o = s:option(DummyValue, "identity", translate("Identity"))
o.width    = "16%"
function o.cfgvalue(...)
	local v = Value.cfgvalue(...) or ("<%s>" % translate("Unknown"))
	return v
end

o = s:option(DummyValue, "method", translate("EAP-Method"))
o.width    = "15%"
function o.cfgvalue(...)
	local v = Value.cfgvalue(...)
	if v == "md5" then
		v = translate("MD5-Challenge")
	else
		v = translate("Protected EAP (PEAP)")
	end
	return v
end

o = s:option(DummyValue, "interface", translate("Interface"))
o.template = "cbi/network_netinfo"
o.width    = "10%"

o = s:option(DummyValue, "_status", translate("Status"))
o.template = "w8021x/w8021x_eap_status"
o.width    = "10%"

o = s:option(DummyValue, "_action", translate("Action"))
o.template = "w8021x/w8021x_eap_action"
o.width    = "10%"

return m
