local count = {}
local transfer = {}
local receiptFormat = "Date: %s\nType: %s\nGold Amount: %d\nReceipt Owner: %s\nRecipient: %s\n\n%s"

function Npc:parseBankMessages(message, npc, creature, npcHandler)
	local messagesTable = {
		["money"] = "We can {change} money for you. You can also access your {bank account}",
		["change"] = "There are three different coin types in Tibia: \z
                        100 gold coins equal 1 platinum coin, 100 platinum coins equal 1 crystal coin. \z
                        So if you'd like to change 100 gold into 1 platinum, \z
                        simply say '{change gold}' and then '1 platinum'",
		["bank"] = "We can {change} money for you. You can also access your {bank account}",
		["advanced"] = "Your bank account will be used automatically when you want to {rent} a house or place an offer \z
                            on an item on the {market}. Let me know if you want to know about how either one works",
		["help"] = "You can check the {balance} of your bank account, {deposit} money or {withdraw} it. \z
                        You can also {transfer} money to other characters, provided that they have a vocation",
		["functions"] = "You can check the {balance} of your bank account, {deposit} money or {withdraw} it. \z
                            You can also {transfer} money to other characters, provided that they have a vocation",
		["basic"] = "You can check the {balance} of your bank account, {deposit} money or {withdraw} it. \z
                        You can also {transfer} money to other characters, provided that they have a vocation",
		["job"] = "I work in this bank. I can {change money} for you and help you with your bank account",
		["bank account"] = {
			"Every Tibian has one. The big advantage is that you can access your money in every branch of the Tibian Bank! ...",
			"Would you like to know more about the {basic} functions of your bank account, the {advanced} functions, \z
                or are you already bored, perhaps?"
		}
	}

	npcHandler:sendMessages(message, messagesTable, npc, creature, true, 3000)
end

function Npc:parseBank(message, npc, creature, npcHandler)
	local player = Player(creature)
	local playerId = creature:getId()
	-- Balance
	local goldCoin = player:getItemIdByCid(ITEM_GOLD_COIN)
	local platinumCoin = player:getItemIdByCid(ITEM_PLATINUM_COIN)
	local crystalCoin = player:getItemIdByCid(ITEM_CRYSTAL_COIN)
	if MsgContains(message, "balance") then
		if player:getBankBalance() >= 100000000 then
			npcHandler:say(string.format("I think you must be one of the richest inhabitants in the world! \z
                           Your account balance is %d gold.", player:getBankBalance()), npc, creature)
			return true
		elseif player:getBankBalance() >= 10000000 then
			npcHandler:say(string.format("You have made ten millions and it still grows! \z
                           Your account balance is %d gold.", player:getBankBalance()), npc, creature)
			return true
		elseif player:getBankBalance() >= 1000000 then
			npcHandler:say(string.format("Wow, you have reached the magic number of a million gp!!! \z
                           Your account balance is %d gold!", player:getBankBalance()), npc, creature)
			return true
		elseif player:getBankBalance() >= 100000 then
			npcHandler:say(string.format("You certainly have made a pretty penny. \z
                           Your account balance is %d gold.", player:getBankBalance()), npc, creature)
			return true
		else
			npcHandler:say(string.format("Your account balance is %d gold.", player:getBankBalance()), npc, creature)
			return true
		end
	-- Deposit
	elseif MsgContains(message, "deposit") then
		count[playerId] = player:getMoney()
		if count[playerId] < 1 then
			npcHandler:say("You do not have enough gold.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return false
		end
		if not isValidMoney(count[playerId]) then
			npcHandler:say("Sorry, but you can't deposit that much.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return false
		end
		npcHandler:say("Please tell me how much gold it is you would like to deposit.", npc, creature)
		npcHandler:setTopic(playerId, 1)
	elseif MsgContains(message, "deposit all") then
		count[playerId] = player:getMoney()
		npcHandler:say(string.format("Would you really like to deposit %d gold?", count[playerId]), npc, creature)
		npcHandler:setTopic(playerId, 2)
	elseif MsgContains(message, "all") then
		if npcHandler:getTopic(playerId) == 1 then
			count[playerId] = player:getMoney()
			npcHandler:say(string.format("Would you really like to deposit %d gold?", count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 2)
		end
	elseif npcHandler:getTopic(playerId) == 1 then
		count[playerId] = getMoneyCount(message)
		if isValidMoney(count[playerId]) then
			npcHandler:say(string.format("Would you really like to deposit %d gold?", count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 2)
			return true
		else
			npcHandler:say("You do not have enough gold.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end
	elseif npcHandler:getTopic(playerId) == 2 then
		if MsgContains(message, "yes") then
			if Player.depositMoney(player, count[playerId]) then
				npcHandler:say(string.format("Alright, we have added the amount of %d gold to your {balance}. \z
                               You can {withdraw} your money anytime you want to.", count[playerId]), npc, creature)
			else
				npcHandler:say("You do not have enough gold.", npc, creature)
			end
		elseif MsgContains(message, "no") then
			npcHandler:say("As you wish. Is there something else I can do for you?", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
		return true
	-- Withdraw
	elseif MsgContains(message, "withdraw") then
		if string.match(message,"%d+") then
			count[playerId] = getMoneyCount(message)
			if isValidMoney(count[playerId]) then
				npcHandler:say(string.format("Are you sure you wish to withdraw %d gold from your bank account?",
                               count[playerId]), npc, creature)
				npcHandler:setTopic(playerId, 7)
			else
				npcHandler:say("There is not enough gold on your account.", npc, creature)
				npcHandler:setTopic(playerId, 0)
			end
			return true
		else
			npcHandler:say("Please tell me how much gold you would like to withdraw.", npc, creature)
			npcHandler:setTopic(playerId, 6)
			return true
		end
	elseif npcHandler:getTopic(playerId) == 6 then
		count[playerId] = getMoneyCount(message)
		if isValidMoney(count[playerId]) then
			npcHandler:say(string.format("Are you sure you wish to withdraw %d gold from your bank account?",
                           count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 7)
		else
			npcHandler:say("There is not enough gold on your account.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
		return true
	elseif npcHandler:getTopic(playerId) == 7 then
		if MsgContains(message, "yes") then
			if player:getFreeCapacity() >= getMoneyWeight(count[playerId]) then
				if not player:withdrawMoney(count[playerId]) then
					npcHandler:say("There is not enough gold on your account.", npc, creature)
				else
					npcHandler:say(string.format("Here you are, %d gold. Please let me know if there is something else I can do for you.",
                                   count[playerId]),  npc, creature)
				end
			else
				npcHandler:say("Whoah, hold on, you have no room in your inventory to carry all those coins. \z
                               I don't want you to drop it on the floor, maybe come back with a cart!", npc, creature)
			end
			npcHandler:setTopic(playerId, 0)
		elseif MsgContains(message, "no") then
			npcHandler:say("The customer is king! Come back anytime you want to if you wish to {withdraw} your money.",
                           npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
		return true
	-- Transfer
	elseif MsgContains(message, "transfer") then
		npcHandler:say("Please tell me the amount of gold you would like to transfer.", npc, creature)
		npcHandler:setTopic(playerId, 11)
	elseif npcHandler:getTopic(playerId) == 11 then
		count[playerId] = getMoneyCount(message)
		if player:getBankBalance() < count[playerId] then
			npcHandler:say("There is not enough gold on your account.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end
		if isValidMoney(count[playerId]) then
			npcHandler:say("Who would you like transfer %d gold to?", npc, creature)
			npcHandler:setTopic(playerId, 12)
		else
			npcHandler:say("There is not enough gold on your account.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif npcHandler:getTopic(playerId) == 12 then
		transfer[playerId] = message
		if player:getName() == transfer[playerId] then
			npcHandler:say("Fill in this field with person who receives your gold!", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end
		if playerExists(transfer[playerId]) then
			local arrayDenied = {
				"accountmanager",
				"rooksample",
				"druidsample",
				"sorcerersample",
				"knightsample",
				"paladinsample"
			}
			if table.contains(arrayDenied, string.gsub(transfer[playerId], " ", "")) then
				npcHandler:say("This player does not exist.", npc, creature)
				npcHandler:setTopic(playerId, 0)
				return true
			end
			npcHandler:say(string.format("So you would like to transfer %d gold to %s?",
                           count[playerId], string.titleCase(transfer[playerId])), npc, creature)
			npcHandler:setTopic(playerId, 13)
		else
			npcHandler:say("This player does not exist.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif npcHandler:getTopic(playerId) == 13 then
		if MsgContains(message, "yes") then
			if not player:transferMoneyTo(transfer[playerId], count[playerId]) then
				npcHandler:say("You cannot transfer money to this account.", npc, creature)
			else
				npcHandler:say(string.format("Very well. You have transferred %d gold to %s.",
                               count[playerId], string.titleCase(transfer[playerId])), npc, creature)
				transfer[playerId] = nil
			end
		elseif MsgContains(message, "no") then
			npcHandler:say("Alright, is there something else I can do for you?", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	-- Change money
	elseif MsgContains(message, "change gold") then
		npcHandler:say("How many platinum coins would you like to get?", npc, creature)
		npcHandler:setTopic(playerId, 14)
	elseif npcHandler:getTopic(playerId) == 14 then
		if getMoneyCount(message) < 1 then
			npcHandler:say("Sorry, you do not have enough gold coins.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		else
			count[playerId] = getMoneyCount(message)
			npcHandler:say(string.format("So you would like me to change %d of your gold coins into %d platinum coins?",
                           count[playerId] * 100, count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 15)
		end
	elseif npcHandler:getTopic(playerId) == 15 then
		if MsgContains(message, "yes") then
			if player:removeItem(goldCoin, count[playerId] * 100) then
				player:addItem(platinumCoin, count[playerId])
				npcHandler:say("Here you are.", npc, creature)
			else
				npcHandler:say("Sorry, you do not have enough gold coins.", npc, creature)
			end
		else
			npcHandler:say("Well, can I help you with something else?", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "change platinum") then
		npcHandler:say("Would you like to change your platinum coins into {gold} or {crystal}?", npc, creature)
		npcHandler:setTopic(playerId, 16)
	elseif npcHandler:getTopic(playerId) == 16 then
		if MsgContains(message, "gold") then
			npcHandler:say("How many platinum coins would you like to change into {gold}?", npc, creature)
			npcHandler:setTopic(playerId, 17)
		elseif MsgContains(message, "crystal") then
			npcHandler:say("How many crystal coins would you like to get?", npc, creature)
			npcHandler:setTopic(playerId, 19)
		else
			npcHandler:say("Well, can I help you with something else?", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif npcHandler:getTopic(playerId) == 17 then
		if getMoneyCount(message) < 1 then
			npcHandler:say("Sorry, you do not have enough platinum coins.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		else
			count[playerId] = getMoneyCount(message)
			npcHandler:say(string.format("So you would like me to change %d of your platinum coins into %d gold coins for you?",
                           count[playerId] * 100, count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 18)
		end
	elseif npcHandler:getTopic(playerId) == 18 then
		if MsgContains(message, "yes") then
			if player:removeItem(platinumCoin, count[playerId]) then
				player:addItem(goldCoin, count[playerId] * 100)
				npcHandler:say("Here you are.", npc, creature)
			else
				npcHandler:say("Sorry, you do not have enough platinum coins.", npc, creature)
			end
		else
			npcHandler:say("Well, can I help you with something else?", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	elseif npcHandler:getTopic(playerId) == 19 then
		if getMoneyCount(message) < 1 then
			npcHandler:say("Sorry, you do not have enough platinum coins.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		else
			count[playerId] = getMoneyCount(message)
			npcHandler:say(string.format("So you would like me to change %d of your platinum coins into %d crystal coins for you?",
                           count[playerId] * 100, count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 20)
		end
	elseif npcHandler:getTopic(playerId) == 20 then
		if MsgContains(message, "yes") then
			if player:removeItem(platinumCoin, count[playerId] * 100) then
				player:addItem(crystalCoin, count[playerId])
				npcHandler:say("Here you are.", npc, creature)
			else
				npcHandler:say("Sorry, you do not have enough platinum coins.", npc, creature)
			end
		else
			npcHandler:say("Well, can I help you with something else?", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "change crystal") then
		npcHandler:say("How many crystal coins would you like to change into platinum?", npc, creature)
		npcHandler:setTopic(playerId, 21)
	elseif npcHandler:getTopic(playerId) == 21 then
		if getMoneyCount(message) < 1 then
			npcHandler:say("Sorry, you do not have enough crystal coins.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		else
			count[playerId] = getMoneyCount(message)
			npcHandler:say(string.format("So you would like me to change %d of your crystal coins into %d platinum coins for you?",
                           count[playerId] * 100, count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 22)
		end
	elseif npcHandler:getTopic(playerId) == 22 then
		if MsgContains(message, "yes") then
			if player:removeItem(crystalCoin, count[playerId])  then
				player:addItem(platinumCoin, count[playerId] * 100)
				npcHandler:say("Here you are.", npc, creature)
			else
				npcHandler:say("Sorry, you do not have enough crystal coins.", npc, creature)
			end
		else
			npcHandler:say("Well, can I help you with something else?", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	end
end

function Npc:parseGuildBank(message, npc, creature, playerId, npcHandler)
	local player = Player(creature)
	-- Guild balance
	if MsgContains(message, "guild balance") then
		npcHandler:setTopic(playerId, 0)
		if not player:getGuild() then
			npcHandler:say("You are not a member of a guild.", npc, creature)
			return false
		end
		npcHandler:say(string.format("Your guild account balance is %d gold.", player:getGuild():getBankBalance()), npc, creature)
		return true
	-- Guild deposit
	elseif MsgContains(message, "guild deposit") then
		if not player:getGuild() then
			npcHandler:say("You are not a member of a guild.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return false
		end
		if string.match(message, "%d+") then
			count[playerId] = getMoneyCount(message)
			if count[playerId] < 1 then
				npcHandler:say("You do not have enough gold.", npc, creature)
				npcHandler:setTopic(playerId, 0)
				return false
			end
			npcHandler:say(string.format("Would you really like to deposit %d gold to your {guild account}?",
                           count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 23)
			return true
		else
			npcHandler:say("Please tell me how much gold it is you would like to deposit.", npc, creature)
			npcHandler:setTopic(playerId, 22)
			return true
		end
	elseif npcHandler:getTopic(playerId) == 22 then
		count[playerId] = getMoneyCount(message)
		if isValidMoney(count[playerId]) then
			npcHandler:say(string.format("Would you really like to deposit %d gold to your {guild account}?",
                           count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 23)
			return true
		else
			npcHandler:say("You do not have enough gold.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end
	elseif npcHandler:getTopic(playerId) == 23 then
		if MsgContains(message, "yes") then
			npcHandler:say(string.format("Alright, we have placed an order to deposit the amount of %d gold to \z
                           your guild account. Please check your inbox for confirmation.",
                           count[playerId]), npc, creature)
			local guild = player:getGuild()
			local info = {
				type = "Guild Deposit",
				amount = count[playerId],
				owner = player:getName() .. " of " .. guild:getName(),
				recipient = guild:getName()
			}
			local playerBalance = player:getBankBalance()
			if playerBalance < tonumber(count[playerId]) then
				info.message = "We are sorry to inform you that we could not fulfill your request, \z
                                due to a lack of the required sum on your bank account."
				info.success = false
			else
				info.message = "We are happy to inform you that your transfer request was successfully carried out."
				info.success = true
				guild:setBankBalance(guild:getBankBalance() + tonumber(count[playerId]))
				player:setBankBalance(playerBalance - tonumber(count[playerId]))
			end

			local inbox = player:getInbox()
			local receipt = GetReceipt(info)
			inbox:addItemEx(receipt, INDEX_WHEREEVER, FLAG_NOLIMIT)
		elseif MsgContains(message, "no") then
			npcHandler:say("As you wish. Is there something else I can do for you?", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
		return true
	-- Guild withdraw
	elseif MsgContains(message, "guild withdraw") then
		if not player:getGuild() then
			npcHandler:say("I am sorry but it seems you are currently not in any guild.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return false
		elseif player:getGuildLevel() < 2 then
			npcHandler:say("Only guild leaders or vice leaders can withdraw money from the guild account.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return false
		end

		if string.match(message,"%d+") then
			count[playerId] = getMoneyCount(message)
			if isValidMoney(count[playerId]) then
				npcHandler:say("Are you sure you wish to withdraw %d gold from your guild account?", npc, creature)
				npcHandler:setTopic(playerId, 25)
			else
				npcHandler:say("There is not enough gold on your guild account.", npc, creature)
				npcHandler:setTopic(playerId, 0)
			end
			return true
		else
			npcHandler:say("Please tell me how much gold you would like to withdraw from your guild account.", npc, creature)
			npcHandler:setTopic(playerId, 24)
			return true
		end
	elseif npcHandler:getTopic(playerId) == 24 then
		count[playerId] = getMoneyCount(message)
		if isValidMoney(count[playerId]) then
			npcHandler:say(string.format("Are you sure you wish to withdraw %d gold from your guild account?",
                           count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 25)
		else
			npcHandler:say("There is not enough gold on your guild account.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
		return true
	elseif npcHandler:getTopic(playerId) == 25 then
		if MsgContains(message, "yes") then
			local guild = player:getGuild()
			local balance = guild:getBankBalance()
			npcHandler:say(string.format("We placed an order to withdraw %d gold from your guild account. \z
                            Please check your inbox for confirmation.",
                            count[playerId]), npc, creature)
			local info = {
				type = "Guild Withdraw",
				amount = count[playerId],
				owner = player:getName() .. " of " .. guild:getName(),
				recipient = player:getName()
			}
			if balance < tonumber(count[playerId]) then
				info.message = "We are sorry to inform you that we could not fulfill your request, \z
                                due to a lack of the required sum on your guild account."
				info.success = false
			else
				info.message = "We are happy to inform you that your transfer request was successfully carried out."
				info.success = true
				guild:setBankBalance(balance - tonumber(count[playerId]))
				local playerBalance = player:getBankBalance()
				player:setBankBalance(playerBalance + tonumber(count[playerId]))
			end

			local inbox = player:getInbox()
			local receipt = GetReceipt(info)
			inbox:addItemEx(receipt, INDEX_WHEREEVER, FLAG_NOLIMIT)
			npcHandler:setTopic(playerId, 0)
		elseif MsgContains(message, "no") then
			npcHandler:say("As you wish. Is there something else I can do for you?", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
		return true
	-- Guild transfer
	elseif MsgContains(message, "guild transfer") then
		if not player:getGuild() then
			npcHandler:say("I am sorry but it seems you are currently not in any guild.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return false
		elseif player:getGuildLevel() < 2 then
			npcHandler:say("Only guild leaders or vice leaders can transfer money from the guild account.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return false
		end

		if string.match(message, "%d+") then
			count[playerId] = getMoneyCount(message)
			if isValidMoney(count[playerId]) then
				transfer[playerId] = string.match(message, "to%s*(.+)$")
				if transfer[playerId] then
					npcHandler:say(string.format("So you would like to transfer %d gold from your guild account to guild %d?",
                                                 count[playerId], string.titleCase(transfer[playerId])), npc, creature)
					npcHandler:setTopic(playerId, 28)
				else
					npcHandler:say(string.format("Which guild would you like to transfer %d gold to?",
                                   count[playerId]), npc, creature)
					npcHandler:setTopic(playerId, 27)
				end
			else
				npcHandler:say("There is not enough gold on your guild account.", npc, creature)
				npcHandler:setTopic(playerId, 0)
			end
		else
			npcHandler:say("Please tell me the amount of gold you would like to transfer.", npc, creature)
			npcHandler:setTopic(playerId, 26)
		end
		return true
	elseif npcHandler:getTopic(playerId) == 26 then
		count[playerId] = getMoneyCount(message)
		if player:getGuild():getBankBalance() < count[playerId] then
			npcHandler:say("There is not enough gold on your guild account.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end
		if isValidMoney(count[playerId]) then
			npcHandler:say(string.format("Which guild would you like to transfer %d gold to?",
                           count[playerId]), npc, creature)
			npcHandler:setTopic(playerId, 27)
		else
			npcHandler:say("There is not enough gold on your account.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
		return true
	elseif npcHandler:getTopic(playerId) == 27 then
		transfer[playerId] = message
		if player:getGuild():getName() == transfer[playerId] then
			npcHandler:say("Fill in this field with person who receives your gold!", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end
		npcHandler:say(string.format("So you would like to transfer %d gold from your guild account to guild %d?",
                                     count[playerId], string.titleCase(transfer[playerId])), npc, creature)
		npcHandler:setTopic(playerId, 28)
		return true
	elseif npcHandler:getTopic(playerId) == 28 then
		if MsgContains(message, "yes") then
			npcHandler:say(string.format("We have placed an order to transfer %d gold from your guild account to guild %. \z
                            Please check your inbox for confirmation.",
                            count[playerId], string.titleCase(transfer[playerId])), npc, creature)
			local guild = player:getGuild()
			local balance = guild:getBankBalance()
			local info = {
				type = "Guild to Guild Transfer",
				amount = count[playerId],
				owner = player:getName() .. " of " .. guild:getName(),
				recipient = transfer[playerId]
			}
			if balance < tonumber(count[playerId]) then
				info.message = "We are sorry to inform you that we could not fulfill your request, \z
                                due to a lack of the required sum on your guild account."
				info.success = false
				local inbox = player:getInbox()
				local receipt = GetReceipt(info)
				inbox:addItemEx(receipt, INDEX_WHEREEVER, FLAG_NOLIMIT)
			else
				GetGuildIdByName(transfer[playerId], TransferFactory(player:getName(),
                                 tonumber(count[playerId]), guild:getId(), info))
			end
			npcHandler:setTopic(playerId, 0)
		elseif MsgContains(message, "no") then
			npcHandler:say("Alright, is there something else I can do for you?", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	end
end

-- Greet callback
function NpcBankGreetCallback(npc, creature)
	local playerId = creature:getId()
	count[playerId], transfer[playerId] = nil, nil
	return true
end

function GetReceipt(info)
	local receipt = Game.createItem(info.success and 19598 or 19599)
	receipt:setAttribute(ITEM_ATTRIBUTE_TEXT, receiptFormat:format(os.date("%d. %b %Y - %H:%M:%S"),
                         info.type, info.amount, info.owner, info.recipient, info.message))

	return receipt
end

function GetGuildIdByName(name, func)
	db.asyncStoreQuery("SELECT `id` FROM `guilds` WHERE `name` = " .. db.escapeString(name),
		function(resultId)
			if resultId then
				func(result.getNumber(resultId, "id"))
				result.free(resultId)
			else
				func(nil)
			end
		end
	)
end

function GetGuildBalance(id)
	local guild = Guild(id)
	if guild then
		return guild:getBankBalance()
	else
		local balance
		local resultId = db.storeQuery("SELECT `balance` FROM `guilds` WHERE `id` = " .. id)
		if resultId then
			balance = result.getNumber(resultId, "balance")
			result.free(resultId)
		end

		return balance
	end
end

function SetGuildBalance(id, balance)
	local guild = Guild(id)
	if guild then
		guild:setBankBalance(balance)
	else
		db.query("UPDATE `guilds` SET `balance` = " .. balance .. " WHERE `id` = " .. id)
	end
end

function TransferFactory(playerName, amount, fromGuildId, info)
	return function(toGuildId)
		if not toGuildId then
			local player = Player(playerName)
			if player then
				info.success = false
				info.message = "We are sorry to inform you that we could not fulfil your request, because we could not find the recipient guild."
				local inbox = player:getInbox()
				local receipt = GetReceipt(info)
				inbox:addItemEx(receipt, INDEX_WHEREEVER, FLAG_NOLIMIT)
			end
		else
			local fromBalance = GetGuildBalance(fromGuildId)
			if fromBalance < amount then
				info.success = false
				info.message = "We are sorry to inform you that we could not fulfill your request, due to a lack of the required sum on your guild account."
			else
				info.success = true
				info.message = "We are happy to inform you that your transfer request was successfully carried out."
				SetGuildBalance(fromGuildId, fromBalance - amount)
				SetGuildBalance(toGuildId, GetGuildBalance(toGuildId) + amount)
			end

			local player = Player(playerName)
			if player then
				local inbox = player:getInbox()
				local receipt = GetReceipt(info)
				inbox:addItemEx(receipt, INDEX_WHEREEVER, FLAG_NOLIMIT)
			end
		end
	end
end
