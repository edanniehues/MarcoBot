module Macros
	def macrologic(message) # Outputs an array[trigger,macro,time_since_last_activation]
		macros = []
		triggers = []
		outputarray = []
		for macro in @macros
			macro_split = macro.split(": ")
			if message.downcase.include?(macro_split[0].downcase) and macro_split[0] != " " then
				triggers.push macro_split[0]
			end
		end
		if !triggers.empty? then
			triggers.sort! { |x,y| y.length <=> x.length }
			macro = @yamlmacros[triggers[0]]
			if @macrotime[triggers[0]] != nil then
				timeout = (Time.new - @macrotime[triggers[0]]).to_i
			else
				timeout = 999 # Obnoxiously large number
				@macrotime[triggers[0]] = 999
			end
			return [triggers[0],macro,timeout]
		else
			return nil
		end
	end
	def check_for_macro(message,target,user)
		macroarray = macrologic(message)
		if macroarray.class == Array then
			if macroarray[2] >= 300 then
				puts "Acceptable macro found!"
				output = macroarray[1].chomp
				output.gsub!("$nick",user)
				output.gsub!("$NICK",user.upcase)
				if output.start_with?("/me") then
					output.sub!("/me ","")
					emote(target,output)
				else
					privmsg(target,output)
				end
				@macrotime[macroarray[0]] = Time.new
			end
		end
	end
	def macrocheck(message,target)
		message.sub!("#{@command_identifier}macrocheck ","") # Ugly hack
		macroarray = macrologic(message)
		if macroarray.class == Array then
			if macroarray[2] >= 300 then
				privmsg(target,"The phrase \"#{message}\" triggers the macro \"#{macroarray[1].chomp}\".")
			else
				timeout = (((Time.new + 300).to_i - (Time.new - (Time.new - @macrotime[macroarray[0]])).to_i) - 600)*(-1) # I DON'T EVEN UNDERSTAND THIS ANYMORE
				privmsg(target,"The phrase \"#{message}\" will trigger the macro \"#{macroarray[1].chomp}\" in #{timeout.to_i} seconds.")
			end
		else
			privmsg(target,"The phrase \"#{message}\" doesn't trigger any macro.")
		end
	end
	def add_macro(channel,trigger,macro)
		trigger = trigger.sub("~macro ","")
		if macro != nil then macro.chomp!; end
		puts "DEBUG: channel: #{channel}, trigger: #{trigger}, macro: #{macro}"
		@macrofile = YAML::load(File.open("#{@basepath}macros"))
		if trigger.gsub(" ","").length >4 then
			if macro == nil then
				@macrofile.delete trigger.downcase
				privmsg(channel,"Macro removed.")
			else
				@macrofile[trigger.downcase] = macro
				privmsg(channel,"Macro added.")
			end
		else
			privmsg(channel,"Five chars or more, please.")
		end
		File.open("#{@basepath}macros","w") do |f|
			f << @macrofile.to_yaml
		end
		@macrofile = File.open("#{@basepath}macros","r")
		@yamlmacros = YAML::load(@macrofile)
		@macrofile.rewind
		@macros = @macrofile.readlines
	end
end
