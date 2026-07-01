-- {"id":1308639978,"ver":"1.0.7","libVer":"1.0.0","author":"Jobobby04"}

local baseURL = "https://www.adult-fanfiction.org"
local settings = {}

local function shrinkURL(url)
	local cleanUrl = url:gsub("^https?://", "")
	local subdomain, rest = cleanUrl:match(
		"^([^./]+)%.?adult%-fanfiction%.org(/.*)$"
	)
	return (subdomain or "www") .. "@" .. (rest or "/")
end

local function expandURL(shrunkUrl)
	return "https://" .. shrunkUrl:gsub("@", ".adult-fanfiction.org")
end

--- @param url string
--- @return Document
local function GETDocumentAdult(url)
	-- Temp safe fallback so compiler doesn't fail on initialization
	return Document("<html></html>")
end

--- @param element Element
--- @return Element
local function cleanupDocument(element)
	element = tostring(element):gsub('<div', '<p'):gsub('</div', '</p'):gsub('<br>', '</p><p>')
	element = Document(element):selectFirst('body')
	return element
end

local Tags =  {
	["3Plus"] = "Threesomes/Moresomes"
}

local TagsIndexed = {}

local function getPassage(chapterURL)
	return ""
end

local function parseNovel(novelURL, loadChapters)
	-- Global Inspector card details viewer
	local keys = {}
	for k, v in pairs(_G) do
		table.insert(keys, tostring(k) .. " (" .. type(v) .. ")")
	end
	table.sort(keys)
	local desc = table.concat(keys, "\n")

	return NovelInfo {
		title = "Tsundoku Global Environment API",
		description = desc,
		genres = {"Debug"},
		authors = {"System"},
		status = NovelStatus.COMPLETED
	}
end

--- @param filters table @of applied filter values [QUERY] is the search query, may be empty
--- @return Novel[]
local function search(filters)
	return {
		Novel {
			title = "Inspect Globals (Click Here)",
			link = "how.v1",
			imageURL = ""
		}
	}
end

local function searchFilters()
	return {}
end

return {
	id = 1308639978,
	name = "AdultFanFiction",
	baseURL = baseURL,
	imageURL = "",
	hasCloudFlare = true,
	hasSearch = true,
	chapterType = ChapterType.HTML,
	listings = {
		Listing("Nothing", false, function(data)
			return {
				Novel {
					title = "Inspect Globals (Click Here)",
					link = "how.v1",
					imageURL = ""
				}
			}
		end),
	},
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
