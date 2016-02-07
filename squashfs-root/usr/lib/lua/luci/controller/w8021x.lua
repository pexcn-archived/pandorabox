--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

require("luci.sys")

module("luci.controller.w8021x", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/w8021x") then
		return
	end
	
	local page

	page = entry({"admin", "network", "w8021x"}, cbi("w8021x"), _("IEEE 802.1X"), 50)
	entry({"admin", "network", "w8021x", "item"}, cbi("w8021x/item"), nil).leaf = true
	entry({"admin", "network", "w8021x", "status"}, call("w8021x_status"), nil).leaf = true
	entry({"admin", "network", "w8021x", "auth"}, call("w8021x_auth"), nil).leaf = true
	entry({"admin", "network", "w8021x", "logoff"}, call("w8021x_logoff"), nil).leaf = true
end

function w8021x_status(cmdid, args)
	local uci = require "luci.model.uci".cursor()
	
	w8021x_status = ""
	if uci:get("w8021x", cmdid) == "item" then
		status = luci.sys.exec("w8021x_status " .. cmdid)
		if status == "SUCCESS" then
			w8021x_status = "success"
		elseif status == "FAILURE" then
			w8021x_status = "failure"
		elseif status == "CONNECTING" then
			w8021x_status = "connecting"
		elseif status == "IDLE" then
			w8021x_status = "idle"
		else
			w8021x_status = "free"
		end
	else
		w8021x_status = "unknown"
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({
		status  = w8021x_status
	})
end

function w8021x_logoff(cmdid, args)
	local uci = require "luci.model.uci".cursor()
	
	w8021x_status = ""
	if uci:get("w8021x", cmdid) == "item" then
		status = luci.sys.exec("w8021x_logoff " .. cmdid)
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({
		status  = 1
	})
end

function w8021x_auth(cmdid, args)
	local uci = require "luci.model.uci".cursor()
	
	w8021x_status = ""
	if uci:get("w8021x", cmdid) == "item" then
		status = luci.sys.exec("w8021x_auth " .. cmdid)
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({
		status  = 1
	})
end
