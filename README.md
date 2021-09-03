## What is this?
This is where I store all my work and pending updates for the [Survival](https://avrae.io/dashboard/workshop/612919be807f1f1578ee9ccf) collection for the Avrae Discord D&D Bot.

### What is the current status?
3 core aliases, with another alias + subalias for gaining an understanding of how the aliases work and how to customize them
`!fish`, `!hunt`, and `!forage` for doing those things
`!survival` and `!survival settings` for learning about the aliases in depth and getting help with customizations
Data and DCs are customizable on the server level, most other settings can be changed at the server, user, or character level

### Future plans
Build more customization into the aliases and allow them to write the svars for the users
Possibly add more aliases for more survival tasks if good ideas come up

### Looking for a feature?
Submit a bug report or feature request and I'll try to get around to it. I do this as a hobby and have a regular day job to attend to.


#### How does it all work?
I tried to have everything follow the logic I would use if I was going to have my character go fishing/hunting/scavenging, while also enforcing and enabling ethical practices. Each alias relies on 3 checks, generally called the find/catch/harvest checks. The alias scans a selection of skills that are believed to apply to the activity for the maximum bonus and chooses that skill for the ability check against the DC that is determined by the alias.
"Find" includes all things required to have a chance to catch. As an example: for foraging, this requires possibly knowing about a place where the food is known to grow or having an understanding of nature and where to look for such things, let alone spot them. 
"Catch" includes anything required to be able to harvest from the alias. For ethical hunting, the AC of each creature is (or should be) set higher than the normal stat block to simulate the accuracy of a vitals hit, meaning a hit is a kill.
"Harvest" is the harvesting of food and is compared to a maximum DC to establish a percentage of the maximum weight that is harvested.

#### Questions?
Feel free to message me using any means at your disposal
