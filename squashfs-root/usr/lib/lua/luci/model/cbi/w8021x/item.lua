--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local sid = arg[1]
local utl = require "luci.util"

m = Map("w8021x", translatef("Wired 802.1X Authentication - Item of interface %q", "?"),
	translate("IEEE 802.1X Authentication for Wired Networks is mainly used in many campus networks."))

m.redirect = luci.dispatcher.build_url("admin/network/w8021x")

if m.uci:get("w8021x", sid) ~= "item" then
	luci.http.redirect(m.redirect)
	return
end

m.uci:foreach("w8021x", "item",
	function(s)
		if s['.name'] == sid and s.interface then
			m.title = translatef("Wired 802.1X Authentication - Item of interface %q", s.interface)
			return false
		end
	end)

s = m:section(NamedSection, sid, "settings", translate("Authentication Setup"))
s.addremove = false

o = s:option(Flag, "auto", translate("Authenticate on boot"))
o.rmempty = false

o = s:option(ListValue, "method", translate("EAP-Method"))
o:value("md5", translate("MD5-Challenge"))
o:value("peap", translate("Protected EAP (PEAP)"))
o.default = "md5"

o = s:option(Value, "identity", translate("Identity"))
o = s:option(Value, "anon_ident", translate("Anonymous identity"))
o:depends("method", "peap")

o = s:option(Value, "password", translate("Password"))
o.password = true

o = s:option(ListValue, "net_type", translate("Network Type"))
o:value("net", translate("Internet"))
o:value("local", translate("Local Area Network"))
o:depends("method", "md5")

o = s:option(ListValue, "phase2", translate("PEAP Authentication Type"))
o:value("peap", "EAP-PEAP (MSCHAPv2)")
o:value("ttls", "EAP-TTLS (MSCHAPv2 + MD5)")
o:depends("method", "peap")
o.default = "peap"

o = s:option(ListValue, "eap_ver", translate("PEAP Version"))
o:value("0")
o:value("1")
o:depends("method", "peap")
o.default = "1"

o = s:option(ListValue, "eap_label", translate("PEAP Label"))
o:value("0", "0 - client EAP encryption")
o:value("1", "1 - client PEAP encryption")
o:depends("method", "peap")
o.default = "1"

o = s:option(Value, "interface", translate("Interface"),
	translate("Specifies the logical interface name the authentication will be applied on"))

o.template = "cbi/network_netlist"
o.nocreate = true
o.optional = false

function o.formvalue(...)
	return Value.formvalue(...) or "-"
end

function o.validate(self, value)
	if value == "-" then
		return nil, translate("Interface required")
	end
	return value
end

function o.write(self, section, value)
	m.uci:set("w8021x", section, "interface", value)
end

return m
