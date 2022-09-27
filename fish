<drac2> 

# Setup the embed
base = f'''embed -title "{name} goes fishing!" -color {color} -thumb {image} -desc "Fishing is a complicated process. You need to find a good spot, choose the right bait, hook a fish and bring it in, then gut and clean the fish to harvest the meat. There's a reason they don't call it catching, y'know."'''

# Load data and seed variables
c = character()
cs = character().skills
rr_num = c.csettings.get("reroll", None)
min_harvest = 1
harv_mod = False
harv_mult = 1
nl = "\n"
backfeat = get("backgroundFeature", "")
args = &ARGS&
if "harvest the water" in backfeat.lower():
	args.append('cadv')
parse = argparse(args)
percentile_species = vroll('1d100')
percentile_dc = vroll('1d100')
loot_added = False
misc_bonus = ""
find_bonus = ""
catch_bonus = ""
harv_bonus = ""

# Load svars
dataSelect = load_json(get_svar("FishArgs", "{}"))
fishdata = load_json(get_svar("FishSpecies", '[{"species": "Catfish", "weight": 20, "percent": 0, "DC": 10}, {"species": "Bass", "weight": 5, "percent": 35, "DC": 5}, {"species": "Carp", "weight": 10, "percent": 60, "DC": 5}, {"species": "Salmon", "weight": 25, "percent": 75, "DC": 15}, {"species": "Sturgeon", "weight": 100, "percent": 90, "DC": 15}]').replace("species","s").replace("weight","w").replace("percent","p").replace("DC","d").replace("info","i").replace("meat","m"))
if len(dataSelect) > 0:
	if args and args[0] in dataSelect.keys():
		fishdata = load_json(get_svar(dataSelect.get(args[0]), "[]").replace("species","s").replace("weight","w").replace("percent","p").replace("DC","d").replace("info","i").replace("meat","m"))
settings = load_json(get_svar("SurvSettings", '{"fishFind": [10,50,80,95], "fishHarvDC": 20, "huntFind": [10,45,75,90], "huntHarvDC": 22, "foraFind": [15,40,85,90], "foraHarvDC": 17, "harvest": true, "cooldown": false, "coolTime": 0, "fishCool": false, "fishCoolTime": 0, "huntCool": false, "huntCoolTime": 0, "forageCool": false, "forageCoolTime": 0}'))

if not settings.get('coolType'):
	settings.update({"coolType": "blank"})

dc_percent_list = settings.get("fishFind")
max_DC = settings.get("fishHarvDC")

# Error on empty fishdata
if len(fishdata) == 0 or len(fishdata[0]) == 0:
	err(f'''Seems like your server's bot gurus have disabled fishing or you have used an invalid argument. Please contact them to correct this. They can check `{ctx.prefix}svar FishSpecies` and/or `{ctx.prefix}svar FishArgs` to fix it.''')

# Setup bonuses from args
bonus = parse.get('b')
fbonus = parse.get('fb')
cbonus = parse.get('cb')
hbonus = parse.get('hb')
if "-b" in args:
	misc_bonus += f'+{bonus[0]}'
if "-fb" in args:
	find_bonus += f'+{fbonus[0]}'
if "-cb" in args:
	catch_bonus += f'+{cbonus[0]}'
if "-hb" in args:
	harv_bonus += f'+{hbonus[0]}'

# Setup advantage boolwise logic
advbase = parse.adv(boolwise=True)
far = parse.adv(custom={'adv': 'fadv', 'dis': 'fdis'}, boolwise=True)
car = parse.adv(custom={'adv': 'cadv', 'dis': 'cdis'}, boolwise=True)
har = parse.adv(custom={'adv': 'hadv', 'dis': 'hdis'}, boolwise=True)
if far == None and advbase != None:
	far = advbase
if car == None and advbase != None:
	car = advbase
if har == None and advbase != None:
	har = advbase
if far == True and advbase != None:
	if advbase == False:
		far = None
	else:
		far = far
if far == False and advbase != None:
	if advbase == True:
		far = None
	else:
		far = far
if car == True and advbase != None:
	if advbase == False:
		car = None
	else:
		car = car
if car == False and advbase != None:
	if advbase == True:
		car = None
	else:
		car = car
if har == True and advbase != None:
	if advbase == False:
		har = None
	else:
		har = har
if har == False and advbase != None:
	if advbase == True:
		har = None
	else:
		har = har

# Setup settings for bag integration and automatic harvesting
bag_setting = load_json(get("SurvivalNoBag", "false").lower())
if bag_setting is True:
	bag_integration = False
else:
	bag_integration = True
harv_setting = load_json(get("fishSurvHarvesting", "true").lower())
if harv_setting is False or settings.get('harvest') is False:
	harvesting = False
else:
	harvesting = True

# Help setup
help = f'''help {ctx.alias} -here'''
if len(args) == 1 and args[0].lower() in '?help':
	return help

# Establish DC to find a good fishing spot
find_dc = 5
for i in dc_percent_list:
	if percentile_dc.total > i:
		find_dc += 5
	else:
		break

# Figure out which fish is being fished for
index = 0
specific_species = []
for i,j in enumerate(fishdata):
	cur_species = fishdata[i].get('s')
	for arg in args:
		if (arg.lower() in cur_species.lower()) and (cur_species not in specific_species):
			specific_species.append(cur_species)
	if percentile_species.total > fishdata[i].get('p'):
		index += 1
index -= 1

# Load the data for that particular fish
catch_dc = fishdata[index].get('d')
species = fishdata[index].get('s')
max_weight = fishdata[index].get('w')
information = fishdata[index].get('i')
meat_replace = fishdata[index].get('m')

# Handling of specific species
targeted = None
if len(specific_species) > 0 and species in specific_species:
	targeted = True
elif len(specific_species) > 0 and species not in specific_species:
	targeted = False

# Roll the check to find a good spot
if 'fani' in args:
	fab = cs.animalHandling
	fskill = "Animal Handling"
elif 'finsi' in args:
	fab = cs.insight
	fskill = "Insight"
elif 'finv' in args:
	fab = cs.investigation
	fskill = "Investigation"
elif 'fnat' in args:
	fab = cs.nature
	fskill = "Nature"
elif 'fperc' in args:
	fab = cs.perception
	fskill = "Perception"
elif 'fsurv' in args:
	fab = cs.survival
	fskill = "Survival"
else:
	find_skill_list = [cs.animalHandling, cs.insight, cs.investigation, cs.nature, cs.perception, cs.survival]
	fab = max(find_skill_list)
	f_skills_list = ["Animal Handling", "Insight", "Investigation", "Nature", "Perception", "Survival"]
	findex = find_skill_list.index(fab)
	fskill = f_skills_list[findex]
fmc = (10 if c.csettings.get("talent", False) and fab.prof else None)
find_string = fab.d20(far, rr_num, fmc) + ("+1d4[guidance]" if parse.get("guidance") else "") + misc_bonus + find_bonus
find_check = vroll(find_string)

# Establish the catch check
if 'cani' in args:
	cab = cs.animalHandling
	cskill = "Animal Handling"
elif 'cath' in args:
	cab = cs.athletics
	cskill = "Athletics"
elif 'csurv' in args:
	cab = cs.survival
	cskill = "Survival"
else:
	catch_skill_list =[cs.animalHandling, cs.athletics, cs.survival]
	cab = max(catch_skill_list)
	c_skills_list = ["Animal Handling", "Athletics", "Survival"]
	cindex = catch_skill_list.index(cab)
	cskill = c_skills_list[cindex]
cmc = (10 if c.csettings.get("talent", False) and cab.prof else None)
if c.levels.get('Barbarian') >= 18 and cab == cs.athletics:
  cmc = max(strength - cs.athletics.value,0)
catch_string = cab.d20(car, rr_num, cmc) + ("+1d4[guidance]" if parse.get("guidance") else "") + misc_bonus + catch_bonus
catch_check = vroll(catch_string)

# Establish the harvest check
if 'hani' in args:
	hab = cs.animalHandling
	hskill = "Animal Handling"
elif 'hmed' in args:
	hab = cs.medicine
	hskill = "Medicine"
elif 'hnat' in args:
	hab = cs.nature
	hskill = "Nature"
elif 'hsurv' in args:
	hab = cs.survival
	hskill = "Survival"
else:
	harv_skill_list = [cs.animalHandling, cs.medicine, cs.nature, cs.survival]
	hab = max(harv_skill_list)
	h_skills_list = ["Animal Handling", "Medicine", "Nature", "Survival"]
	hindex = harv_skill_list.index(hab)
	hskill = h_skills_list[hindex]
hmc = (10 if c.csettings.get("talent", False) and hab.prof else None)
harvest_string = hab.d20(har, rr_num, hmc) + ("+1d4[guidance]" if parse.get("guidance") else "") + misc_bonus + harv_bonus
harvest_check = vroll(harvest_string)

# Process the harvest check, even if things weren't caught
if "harvest the water" in backfeat.lower():
	min_harvest = min(max_weight,11)
	harv_mod = True
elif "wanderer" == backfeat.lower():
	min_harvest = min(max_weight, 6)
	harv_mod = True
harv_percent = min(floor(harvest_check.total/max_DC*100),100)
harvest = max(floor(harv_percent/100*max_weight),min_harvest)

# Cooldown handling
current=float(time())
lastHunt = float(get('last_hunt',0))
lastForage = float(get('last_forage',0))
lastFish = float(get('last_fish',0))
if settings.get("coolType").lower() == "hybrid":
	period = settings.get('coolTime')
	periodFish = settings.get('fishCoolTime')
	x = int(lastFish+periodFish)
	y = int(lastHunt+period)
	z = int(lastForage+period)
	if ((current - lastFish) < periodFish) or ((current - lastHunt) < period) or ((current - lastForage) < period):
		if (period < 91) and (periodFish < 91):
			errtext = f''' "This command has a hybrid cooldown and can only be run every {period} seconds since the last run of any survival alias and {periodFish} since the last fish attempt"'''
		elif any((current - last) <= 86400 for last in [lastFish,lastHunt,lastForage]):
			errtext = f'''"Hybrid Cooldown: If your most recent survival alias run was `!fish`, you can fish again {'<t:' + x + ':R>'}. Otherwise, try again {'<t:' + max(int(lastFish+period),y,z) + ':R>'}"'''
		else:
			errtext = f'''"Hybrid Cooldown: If your most recent survival alias run was `!fish`, you can fish again on {'<t:' + x + ':D>'} at {'<t:' + x + ':T>'}. Otherwise, try again on {'<t:' + max(int(lastFish+period),y,z) + ':D>'} at {'<t:' + max(int(lastFish+period),y,z) + ':T>'}"'''
		err(errtext)
	else:
		c.set_cvar('last_fish', current)
elif settings.get('cooldown') == True or settings.get('fishCool') == True:
	if (settings.get('fishCoolTime') is not None and settings.get('fishCoolTime') > 0) or (settings.get('coolType').lower() == 'alias'):
		period = settings.get('fishCoolTime')
	else:
		period = settings.get('coolTime')
	x = int(lastFish+period)
	if (current-lastFish) < period:
		if period < 91:
			errtext = f''' "This command can only be run every {period} seconds"'''
		elif (current-lastFish) <= 86400:
			errtext = f'''"You can do this again {'<t:' + x + ':R>'}"'''
		else:
			errtext = f'''"You can do this again on {'<t:' + x + ':D>'} at {'<t:' + x + ':T>'}"'''
		err(errtext)
	else:
		c.set_cvar('last_fish',current)

# Find a good spot (or not), catch it (or not), harvest it and add to bag (or not)
if find_check.total >= find_dc:
	base += f''' -f "You found a good fishing spot!|**DC {find_dc}**{nl}**{fskill}:** {find_check}{nl}You {'are fishing for' if specific_species else 'end up hooking'}: **{'** or **'.join(specific_species) if specific_species else species}**{nl+information if information else ''}"'''
	deposit = meat_replace if meat_replace else species
	if catch_check.total >= catch_dc:
		base += f''' -f "You caught a fish!|**DC {catch_dc}**{nl}**{cskill}:** {catch_check}{nl+'**Species:** '+species if specific_species else ''}{nl+'*Fisher Background: automatically applied `cadv`*' if 'harvest the water' in backfeat.lower() else ''}"'''
		if harvesting and (targeted == True or targeted == None):
			dumb = '\*'
			base += f''' -f "Time to clean your catch|**DC {max_DC}** (for 100%){nl}**Max Weight:** {max_weight} lbs.{nl}**{hskill}:** {harvest_check}/{max_DC}{dumb+str(harv_mult) if harv_mult>1 else ''}\*100 = **{harv_percent}%** (max 100){nl}You harvested: **{harvest}** lbs. of **{deposit}**{nl+'*Background or class feature affected harvest math*' if harv_mod or harv_mult>1 else ''}"'''
			if bag_integration is False:
				base += f''' -footer "{ctx.prefix}survival help | @eternalphoenix64#3855 | Harvest was not automatically added to your bag."'''
			else:
				bag_name = 'Fish'
				bag = load_json(get('bags', []))
				for bag_cat in bag:
					if bag_name.lower() in bag_cat[0].lower():
						bag_name = bag_cat[0]
						bag_loot_count = bag_cat[1][deposit] if deposit in list(bag_cat[1].keys()) else 0
						bag_cat[1][deposit] = bag_cat[1][deposit] + harvest if bag_loot_count > 0 else harvest
						loot_added = True
						break
				if not loot_added:
					bag.append([bag_name, {deposit: harvest}])
				c.set_cvar('bags', dump_json(bag))
				base += f''' -f "Your fish harvest was added to your bag!|{harvest} pounds of **{deposit}** was added to your __{bag_name.capitalize()}__ pouch for you!"'''
				base += f''' -footer "{ctx.prefix}survival help | @eternalphoenix64#3855"'''
		elif harvesting and targeted == False:
			base += f''' -f "Catch and Release|You wanted to catch a **{'** or **'.join(specific_species)}** but caught **{species}** instead, so you threw it back."'''
			base += f''' -footer "{ctx.prefix}survival help | @eternalphoenix64#3855"'''
		else:
			base += f''' -f "Catch and Release|You're a good person. Thank you for not overfishing."'''
			base += f''' -footer "{ctx.prefix}survival help | @eternalphoenix64#3855"'''
	else:
		base += f''' -f "Your fish got away!|**DC {catch_dc}**{nl}**{cskill}:** {catch_check}"'''
		base += f''' -footer "{ctx.prefix}survival help | @eternalphoenix64#3855"'''
elif find_dc >= 60 and find_check.total < find_dc:
	base += f''' -f "There was nothing here!|**DC {find_dc}**{nl}**{fskill}:** {find_check}"'''
else:
	base += f''' -f "You couldn't find anything!|**DC {find_dc}**{nl}**{fskill}:** {find_check}"'''
	base += f''' -footer "{ctx.prefix}survival help | @eternalphoenix64#3855"'''

return base
</drac2>
