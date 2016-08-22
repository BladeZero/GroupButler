local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function get_mods_id(chat_id)
    local res = api.getChatAdministrators(chat_id)
    if not res then return false end
    local ids = {}
    for i,admin in pairs(res.result) do
		local uname = admin.user.username
		--print(admin.user.first_name, uname)
		if uname ~= nil then
			--print(admin.user.first_name, uname)
			--print("110101010")
			if not uname:find('bot', -3) then 
				--print("y49")
				table.insert(ids, admin.user.id)
			end
		else 
			print(admin.user.first_name, uname)
			table.insert(ids, admin.user.id)
		end
    end
    return ids
end

local function is_report_blocked(msg)
	--print('0')
    local hash = 'chat:'..msg.chat.id..':reportblocked'
	--print("01111")
    return db:sismember(hash, msg.from.id)
end

local function send_to_admin(mods, chat, msg_id, reporter, is_by_reply, chat_title, msg)
	counter = 0
	result = {}
	adminID = {}
    for i=1,#mods do
		--print('1001'..i)
        api.forwardMessage(mods[i], chat, msg_id)
		--print('101'..i)
		local temp
		temp, code = api.sendMessage(mods[i], reporter..'\n\n'..chat_title)
		--print("CODE: ", code)
		--print("DATADUMP:", dump(temp))
		if temp ~= false and code == nil then 
			result[i] = temp.result.message_id
			counter = counter + 1
			adminID[i] = temp.result.chat.id
			--print("Admin ID", adminID[i])
			--print("Entry count ", result[i])
		end
    end
	--print(result[1], result[2], result[3], result[4])
		hash10 = 'flagged:'..msg.chat.id..':'..msg.message_id
		--print("check 2")
		--api.sendReply(msg,'MessageID: '..msg.message_id..' '..os.date('!%c (UCT)'))
	local timer = os.date('!%c (UCT)')
	alreadyReported = db:hget(hash10, 'Solved')
	--print("Reprorteorijt", alreadyReported)
	if alreadyReported == nil then 
		--print("sigh ", counter)
		for o=1, counter, 1 do
			local sentMsgID = result[o]
			local id = adminID[o]
			--print("Count ", o)
			--print('Database Setting Reached')
			--print(sentMsgID)
			--print(id)
			if id ~= nil then 
				--print(id)
				if sentMsgID ~= nil then
					--print(sentMsgID)
					db:hset(hash10, 'Message'..o, sentMsgID)
					db:hset(hash10, 'adminID'..o, id)
				end 
			end 
		end
		db:hset(hash10, 'Solved', 0)
		db:hset(hash10, 'Created', timer)
		db:hset(hash10, '#Admin', counter)
	end
end

local action = function(msg, blocks, ln)
    
    if msg.chat.type == 'private' then return end
    
    local hash = 'chat:'..msg.chat.id..':reportblocked'
    if blocks[1] == 'admin' then
        --return 
		--if 'report' is locked, if is a mod or if the user is blocked from using @admin
        if is_locked(msg, 'Report') or is_mod(msg) or is_report_blocked(msg) then
            return 
        end
        if not blocks[2] and not msg.reply then
            api.sendReply(msg, lang[ln].flag.no_input)
        else
            if is_report_blocked(msg) then
                return
            end
            if msg.reply and ((tonumber(msg.reply.from.id) == tonumber(bot.id)) --[[or is_mod(msg.reply)]]) then
                return
            end
            local mods = get_mods_id(msg.chat.id)
            if not mods then
                api.sendReply(msg, lang[ln].bonus.adminlist_admin_required, true)
            end
            local msg_id = msg.message_id
            local is_by_reply = false
            if msg.reply then
                is_by_reply = true
                msg_id = msg.reply.message_id
            end
            local reporter = msg.from.first_name
            if msg.from.username then reporter = reporter..' (@'..msg.from.username..')' end
            send_to_admin(mods, msg.chat.id, msg_id, reporter, is_by_reply, msg.chat.title, msg)
            api.sendReply(msg, lang[ln].flag.reported)
        end
    end
    if blocks[1] == 'report' then
        if is_mod(msg) then
            if not msg.reply then
                api.sendReply(msg, lang[ln].flag.no_reply)
            else
                if blocks[2] == 'off' then
                    local result = db:sadd(hash, msg.reply.from.id)
                    if result == 1 then
                        api.sendReply(msg, lang[ln].flag.blocked)
                    elseif result == 0 then
                        api.sendReply(msg, lang[ln].flag.already_blocked)
                    end
                elseif blocks[2] == 'on' then
                    local result = db:srem(hash, msg.reply.from.id)
                    if result == 1 then
                        api.sendReply(msg, lang[ln].flag.unblocked)
                    elseif result == 0 then
                        api.sendReply(msg, lang[ln].flag.already_unblocked)
                    end
                end
            end
        end
	end
		
	if blocks[1] == 'solved' then 
		if is_mod(msg) or config.admin.superAdmins[msg.from.id] then
			if msg.reply then
				local msg_id = msg.reply.message_id
				print("Mesesage ID:", msg_id)
				hash12 = 'flagged:'..msg.chat.id..':'..msg_id
				isSolved1 = db:hget(hash12, 'Solved')
				--print("12213213")
				hash13 = 'flagged:'..msg.chat.id..':'..msg_id+1
				isSolved2 = db:hget(hash13, 'Solved')
				if isSolved1 then
					hash14 = 'flagged:'..msg.chat.id..':'..msg_id
				elseif isSolved2 then 
					hash14 = 'flagged:'..msg.chat.id..':'..msg_id+1
				else 
					api.sendReply(msg, 'Report not found')
					print("1, ", isSolved1)
					print("2, ", isSolved2)
					return 
				end 
			
				alreadyReported = db:hget(hash14, 'Solved')
				--print("Reprorteorijt", alreadyReported)
				if alreadyReported == '0' then 
					local solvedBy = msg.from.first_name
					if msg.from.username then solvedBy = solvedBy..' (@'..msg.from.username..')' end
					local solvedAt = os.date('!%c (UCT)')
					
					db:hset(hash14, 'SolvedAt', solvedAt)
					db:hset(hash14, 'solvedBy', solvedBy)
					db:hset(hash14, 'Solved', 1)
					counter = db:hget(hash14, '#Admin')
					--print("counter", counter)
					local text = 'This has been solved by: '..solvedBy..'\n'..solvedAt..'\n('..msg.chat.title..')'
					for i=1, counter, 1 do
						local id = db:hget(hash14, 'adminID'..i)
						--print("id", id)
						local msgID = db:hget(hash14, 'Message'..i)
						--print("msgid", msgID)
						if id ~= nil then 
							--print("id", id)
							if msgID ~= nil then
								--print("msgid", msgID)
								api.editMessageText(id, msgID, text, false, false)
							end 
						end 
						
					end 
					api.sendReply(msg, 'Marked as solved')
				elseif alreadyReported == '1' then
					local solvedTime = db:hget(hash14, 'SolvedAt')
					local solvedBy = db:hget(hash14, 'solvedBy')
					api.sendReply(msg, 'This message was solved at '..solvedTime..' by '..solvedBy)
				else
					api.sendReply(msg, 'Please reply to a flagged message (contains @admin).')
				end
			else
				api.sendReply(msg, 'Please reply to a flagged message (contains @admin).')
			end
		else
			api.sendReply(msg, lang[ln].not_mod)
		end
	end	
	
	if blocks[1] == 'msgid' then 
		if is_mod(msg) or config.admin.superAdmins[msg.from.id] then
			if msg.reply then
				api.sendReply(msg,'MessageID: '..msg.reply.message_id..' '..os.date('!%c (UCT)'))
			end
		end	
	end 	
end

return {
	action = action,
	triggers = {
	    '^@(admin)$',
	    '^@(admin) (.*)$',
	    '^/(report) (on)$',
	    '^/(report) (off)$',
		'^/(solved)',
		'^/(msgid)',
    }
}