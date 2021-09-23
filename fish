<drac2> 

# Setup the embed
base = f'embed -title "{name} goes fishing!" -color {color} -thumb {image} -desc "Fishing is a complicated process. You need to find a good spot, choose the right bait, hook a fish and bring it in, then gut and clean the fish to harvest the meat. There\'s a reason they don\'t call it catching, y\'know."'

# Load data
c = character()
cs = character().skills
args = &ARGS&
parse = argparse(args)
fishdata = load_json(get_svar("FishSpecies", '[{"species": "Catfish", "weight": 20, "percent": 0, "DC": 10}, {"species": "Bass", "weight": 5, "percent": 35, "DC": 5}, {"species": "Carp", "weight": 10, "percent": 60, "DC": 5}, {"species": "Salmon", "weight": 25, "percent": 75, "DC": 15}, {"species": "Sturgeon", "weight": 100, "percent": 90, "DC": 15}]'))
settings = load_json(get_svar("SurvSettings", '{"fishFind": [10,50,80,95], "fishHarvDC": 20, "huntFind": [10,45,75,90], "huntHarvDC": 22, "foraFind": [15,40,85,90], "foraHarvDC": 17, "harvest": true, "cooldown": false, "coolTime": 0, "fishCool": false, "fishCoolTime": 0, "huntCool": false, "huntCoolTime": 0, "forageCool": false, "forageCoolTime": 0}'))
dc_percent_list = settings.get("fishFind")
max_DC = settings.get("fishHarvDC")
percentile_species = vroll('1d100')
percentile_dc = vroll('1d100')
loot_added = False
misc_bonus = ""
find_bonus = ""
catch_bonus = ""
harv_bonus = ""
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

#Setup advantage boolwise logic
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
help = 'help fish -here'
if len(args) == 1 and args[0].lower() in ['help', '?']:
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
	cur_species = fishdata[i].get('species')
	for arg in args:
		if (arg.lower() in cur_species.lower()) and (cur_species not in specific_species):
			specific_species.append(cur_species)
	if percentile_species.total > fishdata[i].get('percent'):
		index += 1
index -= 1

# Load the data for that particular fish
catch_dc = fishdata[index].get('DC')
species = fishdata[index].get('species')
max_weight = fishdata[index].get('weight')

#handling of specific species
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
find_string = fab.d20(base_adv=far) + ("+1d4[guidance]" if parse.get("guidance") else "") + misc_bonus + find_bonus
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
catch_string = cab.d20(base_adv=car) + ("+1d4[guidance]" if parse.get("guidance") else "") + misc_bonus + catch_bonus
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
harvest_string = hab.d20(base_adv=har) + ("+1d4[guidance]" if parse.get("guidance") else "") + misc_bonus + harv_bonus
harvest_check = vroll(harvest_string)

# Process the harvest check, even if things weren't caught
if harvest_check.total < max_DC:
	harv_percent = floor(harvest_check.total/max_DC*100)
else:
	harv_percent = 100
if harv_percent/100*max_weight < 1:
	harvest = 1
else:
	harvest = floor(harv_percent/100*max_weight)

# Find a good spot (or not), catch it (or not), harvest it and add to bag (or not)
if find_check.total >= find_dc:
	base += f' -f "You found a good fishing spot!|**DC {find_dc}**\n**{fskill}:** {find_check}\nYou {"are fishing for" if specific_species else "end up hooking"}: **{"** or **".join(specific_species) if specific_species else species}**"'
	if catch_check.total >= catch_dc:
		base += f' -f "You caught a fish!|**DC {catch_dc}**\n**{cskill}:** {catch_check}\n{"**Species:** "+species if specific_species else ""}"'
		if harvesting and (targeted == True or targeted == None):
			base += f' -f "Time to clean your catch|**DC {max_DC}** (for 100%)\n**Max Weight:** {max_weight} lbs.\n**{hskill}:** {harvest_check}/{max_DC}*100 = **{harv_percent}%** (max 100)\nYou harvested: **{harvest}** lbs. of **{species}**"'
			if bag_integration is False:
				base += f' -footer "!survival help | @eternalphoenix64#3855 | Harvest was not automatically added to your bag."'
			else:
				bag_name = 'Fish'
				bag = load_json(get('bags', []))
				for bag_cat in bag:
					if bag_name.lower() in bag_cat[0].lower():
						bag_name = bag_cat[0]
						bag_loot_count = bag_cat[1][species] if species in list(bag_cat[1].keys()) else 0
						bag_cat[1][species] = bag_cat[1][species] + harvest if bag_loot_count > 0 else harvest
						loot_added = True
						break
				if not loot_added:
					bag.append([bag_name, {species: harvest}])
				c.set_cvar('bags', dump_json(bag))
				base += f' -f "Your fish harvest was added to your bag!|{harvest} pounds of **{species}** was added to your __{bag_name.capitalize()}__ pouch for you!"'
				base += f' -footer "!survival help | @eternalphoenix64#3855"'
		elif harvesting and targeted == False:
			base += f' -f "Catch and Release|You wanted to catch a **{"** or **".join(specific_species)}** but caught **{species}** instead, so you threw it back."'
			base += f' -footer "!survival help | @eternalphoenix64#3855"'
		else:
			base += f' -f "Catch and Release|You\'re a good person. Thank you for not overfishing."'
			base += f' -footer "!survival help | @eternalphoenix64#3855"'
	else:
		base += f' -f "Your fish got away!|**DC {catch_dc}**\n**{cskill}:** {catch_check}"'
		base += f' -footer "!survival help | @eternalphoenix64#3855"'
else:
	base += f' -f "You couldn\'t find anything!|**DC {find_dc}**\n**{fskill}:** {find_check}"'
	base += f' -footer "!survival help |  @eternalphoenix64#3855"'

#cooldown handling
if settings.get('fishCoolTime') is not None and settings.get('fishCoolTime') > 0:
	period = settings.get('fishCoolTime')
else:
	period=settings.get('coolTime')
if settings.get('cooldown') == True or settings.get('fishCool') == True:
	last=float(get('last_fish',0))
	current=float(time()) 
	if (current-last) < period:
		if period < 91:
			errtext = f' "This command can only be run every {period} seconds"'
		else:
			x = int(last+period)
			errtext = f'''"You can do this again at {'<t:' + x + ':f>'}"'''
		err(errtext)
	else:
		c.set_cvar('last_fish',current)

return base
</drac2>
