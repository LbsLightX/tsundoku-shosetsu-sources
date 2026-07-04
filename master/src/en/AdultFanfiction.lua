-- {"id":1308639978,"ver":"1.5.1","libVer":"1.0.0","author":"Jobobby04"}

local baseURL = "https://www.adult-fanfiction.org"
local settings = {}

local function shrinkURL(url)
	local cleanUrl = url:gsub("^https?://", "")
	local subdomain, rest = cleanUrl:match(
		"^([^./]+)%.adult%-fanfiction%.org(/.*)$"
	)
	if not subdomain then
		rest = cleanUrl:match("^adult%-fanfiction%.org(/.*)$")
		subdomain = "www"
	end
	return (subdomain or "www") .. "@" .. (rest or "/")
end

local function expandURL(shrunkUrl)
	return "https://" .. shrunkUrl:gsub("@", ".adult-fanfiction.org")
end

--- @param url string
--- @return Document
local function GETDocumentAdult(url)
	local response = Request(GET(url))
	return Document(response:body():string())
end

--- @param element Element
--- @return Element
local function cleanupDocument(element)
	element = tostring(element):gsub('<div', '<p'):gsub('</div', '</p'):gsub('<br>', '</p><p>')
	element = Document(element):selectFirst('body')
	return element
end

local Tags =  {
	["3Plus"] = "Threesomes/Moresomes",
	["ABDL"] = "Adult Baby Diaper Lover",
	["Abortion"] = "Abortion",
	["Abuse"] = "Abuse",
	["AFFO"] = "AFFO Exclusive",
	["Ageplay"] = "Ageplay - Age based play",
	["AI-AS"] = "AI story development",
	["AI-BS"] = "AI story brainstorming",
	["AI-SGT"] = "AI spelling",
	["Anal"] = "Anal",
	["Angst"] = "Angst",
	["Anthro"] = "Anthro",
	["BDSM"] = "BDSM",
	["Beast"] = "Bestiality",
	["Bi"] = "Bisexuality",
	["Bigotry"] = "Bigotry",
	["BMod"] = "Body modification",
	["Bond"] = "Bondage",
	["BP"] = "Blood Play",
	["CBT"] = "Cock/Ball Torture",
	["ChallengeFic"] = "ChallengeFic",
	["COMPLETE"] = "COMPLETE",
	["Contro"] = "Controversial",
	["CR"] = "Corruption",
	["Cuck"] = "Cuckold",
	["Cuckquean"] = "Cuckquean",
	["Dom"] = "Male or Female Domination",
	["DP"] = "Double Penetration",
	["Ds"] = "Dominance/submission",
	["Exhib"] = "Exhibitionism",
	["FD"] = "Futanari/Dickgirls",
	["Fet"] = "Fetish",
	["FF"] = "F/F",
	["Fingering"] = "Fingering",
	["Fist"] = "Fisting",
	["GB"] = "Gender Bender",
	["HC"] = "Hurt/Comfort",
	["Herm"] = "Hermaphrodite",
	["HJ"] = "Handjob",
	["Hum"] = "Humanoid",
	["Humil"] = "Humiliation",
	["Inc"] = "Incest",
	["loli"] = "Loli",
	["MBP"] = "Menstrual blood play",
	["MC"] = "Mind Control",
	["MCD"] = "Main Character Death",
	["MF"] = "M/F",
	["MiCD"] = "Minor Character Death",
	["Minor1"] = "Minor under 14",
	["Minor2"] = "Minor over 14",
	["MM"] = "M/M",
	["MPreg"] = "Male Pregnancy",
	["Ms"] = "Master/slave",
	["Nec"] = "Necrophilia",
	["Non-Fic"] = "Non Fiction",
	["NoSex"] = "No Sexual Content",
	["OC"] = "Original Character",
	["Oneshot"] = "Oneshot",
	["Oral"] = "Oral sex",
	["Other"] = "Other",
	["Parody"] = "Parody",
	["Peg"] = "Pegging",
	["Preg"] = "Pregnancy",
	["PWP"] = "Porn without Plot",
	["Racist"] = "Racism",
	["Rape"] = "Rape",
	["Rim"] = "Rimming",
	["SandM"] = "Sadism/Masochism",
	["Scat"] = "Scat",
	["SH"] = "Sexual Harassment",
	["Shouta"] = "Shota",
	["SI"] = "Self-Insertion",
	["Slave"] = "Slavery",
	["Solo"] = "Masturbation",
	["Spank"] = "Spanking",
	["TBDL"] = "Teen Baby Diaper Lover",
	["Tent"] = "Tentacles",
	["TF"] = "Transformation",
	["Tort"] = "Torture",
	["Toys"] = "Sex toys",
	["Trans"] = "Transgender",
	["UST"] = "Unresolved Sexual Tension",
	["Violence"] = "Violence",
	["Voy"] = "Voyeurism",
	["WAFF"] = "Warm and Fuzzy Feeling",
	["WD"] = "Wet Dream",
	["WIP"] = "Work In Progress",
	["WS"] = "Water-sports",
	["Xeno"] = "Xenophilia"
}

local TagsIndexed = {}
for k, v in pairs(Tags) do
	table.insert(TagsIndexed, {key = k, value = v})
end
table.sort(TagsIndexed, function(a, b) return a.value < b.value end)

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
	local document = GETDocumentAdult(expandURL(chapterURL))
	local title = document:selectFirst(".chapter-content-card .chapter-title"):text()
	local chap = document:selectFirst(".chapter-content-card .chapter-body")
	chap = cleanupDocument(chap)

	if chap ~= nil then
		local children = chap:children()
		if children ~= nil and children:size() > 0 then
			chap:child(0):before("<h1>" .. (title or "Chapter") .. "</h1>")
		else
			chap = Document("<h1>" .. (title or "Chapter") .. "</h1>"):selectFirst("body")
		end
	else
		chap = Document("<h1>" .. (title or "Chapter") .. "</h1>"):selectFirst("body")
	end

	return pageOfElem(chap, true)
end

local function startsWithPattern(mainString, startPattern)
	return mainString:find("^" .. startPattern) == 1
end

--- @param novelURL string
--- @param loadChapters boolean
--- @return NovelInfo
local function parseNovel(novelURL, loadChapters)
	if novelURL:match("^how") then
		return NovelInfo {
			title = "How to use this source v2",
			description = "You can use this source by:\n1. searching on the adult-fanfiction.org website and inputting the url of the work in the search bar.\n2. Setting your queries on the adult-fanfiction.org website and copying the search to the search bar."
		}
	end

	local fullUrl = expandURL(novelURL)
	local document = GETDocumentAdult(fullUrl)
	local storyId = fullUrl:match("no=(%d+)")
	local title = document:selectFirst(".story-header-left > h1"):text()
	local authorElement = document:selectFirst(".story-header-author > a")
	local author = authorElement:text()
	local host = fullUrl:match("^https?://([^/]+)")
	local subdomain = host:match("^([^.]+)%.adult%-fanfiction%.org") or "www"
	local authorId = authorElement:attr("href"):match("id=(%d+)")
	local authorStories = GETDocumentAdult(
		"https://members.adult-fanfiction.org/load-user-stories.php?subdomain=" .. subdomain .. "&uid=" .. authorId
	)

	local storyLink = authorStories:selectFirst("a[href*='story.php?no=" .. storyId .. "']")
	local storyCard = storyLink
	if storyCard ~= nil then
		while storyCard ~= nil do
			local classAttr = storyCard:attr("class") or ""
			local padded = " " .. classAttr .. " "
			if string.find(padded, "%sstory%-card%s") or string.find(padded, "%sstory%-entry%s") then
				break
			end
			storyCard = storyCard:parent()
		end
	end

	local summary = ""
	if storyCard ~= nil then
		local descElement = storyCard:selectFirst(".story-card-description")
		if descElement ~= nil then
			summary = descElement:wholeText():gsub('^%s*(.-)%s*$', '%1')
		end
	end

	local stats = map(
			document:select(".story-header-right div.story-header-stats div"),
			function(v)
				return v
			end
	)


	local genres = {}

	table.insert(
			genres,
			"Category: " .. document
					:select(".story-header-right .story-header-category span")
					:get(1)
					:text()
	)
	for _, v in pairs(stats) do
		local name = v:selectFirst("strong"):text()
		if startsWithPattern(name, "Rating") then
			table.insert(genres, "Rating: " .. v:selectFirst("span"):text())
		end
	end

	if storyCard ~= nil then
		map(storyCard:select(".story-card-tags .story-tag"), function(v)
			local tag = v:text()
			table.insert(genres, Tags[tag] or tag)
		end)
	end

	local status = NovelStatus.PUBLISHING
	for _, value in ipairs(genres) do
		if value == "COMPLETE" or value == "Oneshot" then
			status = NovelStatus.COMPLETED
			break
		end
	end

	local info = NovelInfo {
		title = title,
		description = summary,
		genres = genres,
		authors = { author },
		status = status,
	}

	if loadChapters then
		local chaptersDocument = document:selectFirst(".chapter-select"):select("option")
		local chapters
		if chaptersDocument ~= nil then
			chapters = map(chaptersDocument, function(v, i)
				return NovelChapter {
					order = i,
					title = v:text(),
					link = novelURL .. "&chapter=" .. v:attr("value")
				}
			end)
		else
			chapters = {}
		end

		info:setChapters(AsList(chapters))
	end

	return info
end

local function removePage(url)
	return url:gsub("&page=%d+", ""):gsub("?page=%d+&", "?"):gsub("?page=%d+", "")
end

local function addPage(url, page)
	if url:match("?[^/]+$") then
		return url .. "&page=" .. page
	else
		return url .. "?page=" .. page
	end
end

--- @param filters table @of applied filter values [QUERY] is the search query, may be empty
--- @return Novel[]
local function search(filters)
	local page = filters[PAGE]
	local url = filters[QUERY]:gsub('^%s*(.-)%s*$', '%1')
	local shrunkUrl = shrinkURL(url)
	if page == 1 and shrunkUrl:match("story%.php%?no=") then
		local novelUrl = url:gsub("&chapter=%d+", ""):gsub("?chapter=%d+&", "?"):gsub("?chapter=%d+", "")
		local novel = GETDocumentAdult(novelUrl)
		local storyId = novelUrl:match("no=(%d+)") or "Unknown"
		
		-- Safety check: Avoid nil pointer crashes if story doesn't exist or is blocked
		local titleElement = novel:selectFirst(".story-header-left > h1")
		local title = "Story #" .. storyId
		if titleElement ~= nil then
			title = titleElement:text()
		end

		return {
			Novel {
				title = title,
				link = shrinkURL(novelUrl),
				imageURL = ""
			}
		}
	end

	local subdomain = shrunkUrl:match("^@?(%w+)@/$")
	if shrunkUrl:match("cat=%d+") or (subdomain and subdomain ~= "www") then
		local newUrl = addPage(removePage(url), page)
		for i, tag in ipairs(TagsIndexed) do
			local value = filters[i + 100] or 0
			if value == 1 then
				newUrl = newUrl .. "&tags[]=" .. tag.key .. "&tag_mode[" .. tag.key .. "]=include"
			elseif value == 2 then
				newUrl = newUrl .. "&tags[]=" .. tag.key .. "&tag_mode[" .. tag.key .. "]=exclude"
			end
		end
		local sort = filters[2]
		local sortMode
		if sort == 1 then
			sortMode = "published"
		elseif sort == 2 then
			sortMode = "reviews"
		elseif sort == 3 then
			sortMode = "recommendations"
		elseif sort == 4 then
			sortMode = "reading"
		elseif sort == 5 then
			sortMode = "views"
		end

		if sortMode then
			newUrl = newUrl .. "&sort=" .. sortMode
		end

		local document = GETDocumentAdult(newUrl)
		local works = document:select(".story-entry")

		local urlPrefix = shrunkUrl:match("^([^.]+)%@") .. ".adult-fanfiction.org/"
		return map(works, function(v)
			local title = v:selectFirst(".story-title")
			return Novel {
				title = title:text(),
				link = urlPrefix .. title:attr("href"),
				imageURL = ""
			}
		end)
	end
	return {}
end

local function searchFilters()
	local filters = {}
	for i, tag in ipairs(TagsIndexed) do
		table.insert(
				filters,
				TriStateFilter(
						i + 100,
						tag.value
				)
		)
	end

	return {
		DropdownFilter(
				2,
				"Sort",
				{
					"Recently Updated",
					"Recently Published",
					"Most Reviews",
					"Most Recommend",
					"Most Reading",
					"Most Viewed"
				}
		),
		FilterGroup("Tags", filters)
	}
end

return {
	id = 1308639978,
	name = "AdultFanFiction",
	baseURL = baseURL,

	-- Optional values to change
	imageURL = "https://LbsLightX.github.io/tsundoku-shosetsu-sources/master/icons/aff_icon.jpg",
	hasCloudFlare = true,
	hasSearch = true,

	chapterType = ChapterType.HTML,


	-- Must have at least one value
	listings = {
		Listing("Nothing", false, function(data)
			return {
				Novel {
					title = "How to use this source",
					link = "how.v1",
					imageURL = ""
				}
			}
		end),
	},

	-- Default functions that have to be set
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,

	settings = {},
	updateSetting = function(id, value)
		settings[id] = value
	end,

	searchFilters = searchFilters(),

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
