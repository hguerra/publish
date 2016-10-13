-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2016 INPE and TerraLAB/UFOP -- www.terrame.org

-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.

-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.

-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this software and its documentation.
--
-------------------------------------------------------------------------------------------

local printNormal = _Gtme.print
local printWarning = _Gtme.printWarning
local printInfo = function (value)
	if sessionInfo().color then
		_Gtme.print("\027[00;34m"..tostring(value).."\027[00m")
	else
		_Gtme.print(value)
	end
end

-- Lustache is an implementation of the mustache template system in Lua (http://mustache.github.io/).
-- Copyright Luastache (https://github.com/Olivine-Labs/lustache).
local function loadLuastache()
	local curr = Directory(currentDir())
	Directory(packageInfo("publish").path.."/lua/layout/lustache"):setCurrentDir()

	local lib = require "lustache"
	curr:setCurrentDir()

	return lib
end

local lustache = loadLuastache()

local terralib = getPackage("terralib")

local SourceTypeMapper = {
	shp = "OGR",
	geojson = "OGR",
	tif = "GDAL",
	nc = "GDAL",
	asc = "GDAL",
	postgis = "POSTGIS",
	access = "ADO"
}

local Templates = {}
local templateDir = Directory(packageInfo("publish").path.."/lua/layout")
local function registerApplicationTemplate(data)
	mandatoryTableArgument(data, "input", "string")
	mandatoryTableArgument(data, "output", "string")
	verifyNamedTable(data.model)

	table.insert(Templates, data)
end

local function createDirectoryStructure(data)
	printInfo("Creating directory structure.")
	if data.clean == true and data.output:exists() then
		data.output:delete()
	end

	if not data.output:exists() then
		data.output:create()
	end

	data.datasource = Directory(data.output.."data")
	if not data.datasource:exists() then
		data.datasource:create()
	end

	data.assets = Directory(data.output.."assets")
	if not data.assets:exists() then
		data.assets:create()
	end

	local depends = {"publish.css", "publish.js", "colorbrewer.min.js"}
	forEachElement(depends, function(_, file)
		printNormal("Copying dependency '"..file.."'.")
		os.execute("cp \""..templateDir..file.."\" \""..data.assets.."\"")
	end)
end

local function exportLayers(data, sof)
	terralib.forEachLayer(data.project, function(layer, idx)
		if sof and not sof(layer, idx) then
			return
		end

		if SourceTypeMapper[layer.source] == "OGR" or SourceTypeMapper[layer.source] == "POSTGIS" then
			printNormal("Exporting layer '"..layer.name.."'.")
			layer:export(data.datasource..layer.name..".geojson", true)
		else
			printWarning("Publish cannot export raster layer '"..layer.name.."'.")
		end
	end)
end

local function loadLayers(data)
	if data.project and not data.layers then
		printInfo("Loading layers from '"..data.project.file.."'.")
		data.layers = {}
		exportLayers(data, function(layer)
			table.insert(data.layers, layer.name)
			return true
		end)
	elseif data.project and data.layers then
		printInfo("Loading layers from '"..data.project.file.."'.")
		exportLayers(data, function(layer)
			local found = false
			forEachElement(data.layers, function(_, mvalue)
				if mvalue == layer.name or mvalue == layer.file then
					found = true
					return false
				end
			end)
			return found
		end)
	else
		printInfo("Loading layers from path.")
		local mproj = {
			file = data.layout.title..".tview",
			clean = true
		}

		forEachElement(data.layers, function(_, file)
			file = File(file)
			if file:exists() then
				mproj[file:name()] = tostring(file)
			end
		end)

		data.project = terralib.Project(mproj)
		exportLayers(data)

		File(data.project.file):deleteIfExists()
	end
end

local function exportTemplates(data)
	forEachElement(Templates, function(_, mfile)
		local fopen = File(mfile.input):open()
		local template = fopen:read("*all")
		fopen:close()

		printNormal("Creating file '"..mfile.output.."'.")
		local fwrite = File(data.output..mfile.output)
		fwrite:write(lustache:render(template, mfile.model))
		fwrite:close()
	end)
end

local function loadTemplates(data, path)
	printInfo("Loading template.")
	local page, config
	if not path then
		path = "null"
		page = "index.html"
		config = "config.js"
	else
		page = path ..".html"
		config = path ..".js"
	end

	registerApplicationTemplate{
		input = templateDir.."config.mustache",
		output = config,
		model = {
			path = path,
			center = data.layout.center,
			zoom = data.layout.zoom,
			minZoom = data.layout.minZoom,
			maxZoom = data.layout.maxZoom,
			base = data.layout.base:upper()
		}
	}

	registerApplicationTemplate{
		input = templateDir.."template.mustache",
		output = page,
		model = {
			config = config,
			title = data.layout.title,
			description = data.layout.description,
			layers = data.layers,
			legend = data.legend
		}
	}

	exportTemplates(data)
end

Application_ = {
	type_ = "Application"
}

metaTableApplication_ = {
	__index = Application_,
	__tostring = _Gtme.tostring
}

--- Creates a web page to visualize the published data.
-- @arg data.clean A boolean value indicating if the output directory could be automatically removed. The default value is false.
-- @arg data.layers A table of strings with the layers to be exported. As default, it will export all the available layers.
-- @arg data.layout A mandatory Layout.
-- @arg data.legend A string value with the layers legend. The default value is project title.
-- @arg data.output A mandatory Directory or directory name where the output will be stored.
-- @arg data.package A string with the package name. Uses automatically the .tview files of the package to create the application.
-- @arg data.progress A boolean value indicating if the progress should be shown. The default value is true.
-- @arg data.project A Project or string with the path to a .tview file.
-- @usage import("publish")
-- local emas = filePath("emas.tview", "terralib")
-- local emasDir = Directory("EmasWebMap")
--
-- local layout = Layout{
--     title = "Emas",
--     description = "Creates a database that can be used by the example fire-spread of base package.",
--     base = "satellite",
--     zoom = 14,
--     center = {lat = -18.106389, long = -52.927778}
-- }
--
-- local app = Application{
--     project = emas,
--     layout = layout,
--     clean = true,
--     progress = false,
--     output = emasDir
-- }
--
-- print(app)
-- if emasDir:exists() then emasDir:delete() end
function Application(data)
	verifyNamedTable(data)
	verify(data.project or data.layers or data.package, "Argument 'project', 'layers' or 'package' is mandatory to publish your data.")
	mandatoryTableArgument(data, "layout", "Layout") -- TODO #8
	optionalTableArgument(data, "layers", "table")
	defaultTableValue(data, "clean", false)
	defaultTableValue(data, "progress", true)
	defaultTableValue(data, "legend", "Legend")
	verifyUnnecessaryArguments(data, {"project", "layers", "output", "clean", "layout", "legend", "progress", "package"})

	local initialTime = os.clock()
	if not data.progress then
		printNormal = function() end
		printWarning = function() end
		printInfo = function() end
	end

	if type(data.output) == "string" then
		data.output = Directory(data.output)
	end

	mandatoryTableArgument(data, "output", "Directory")

	if data.package then
		mandatoryTableArgument(data, "package", "string")
		verify(not data.layers, unnecessaryArgumentMsg("layers"))
		data.package = packageInfo(data.package)

		printInfo("Creating application for package '"..data.package.package.."'.")
		local nProj = 0
		local projects = {}
		local dataPath = Directory(data.package.data)
		forEachFile(dataPath:list(), function(fname)
			if fname ~= "amazonia.tview" and fname:endswith(".tview") then
				projects[fname:sub(1, -7)] = terralib.Project{file = dataPath..fname}
				nProj = nProj + 1
			end
		end)

		if nProj == 0 then
			if data.output:exists() then data.output:delete() end
			customError("Package '"..data.package.package.."' does not have any project.")
		else
			createDirectoryStructure(data)

			if nProj == 1 then
				loadLayers{
					project = projects[1],
					layers = data.layers,
					output = data.output,
					clean = data.clean,
					layout = data.layout,
					legend = data.legend,
					datasource = data.datasource
				}
			else
				forEachElement(projects, function(fname, proj)
					local datasource = Directory(data.datasource..fname)
					if not datasource:exists() then
						datasource:create()
					end

					loadLayers{
						project = proj,
						layers = data.layers,
						output = data.output,
						clean = data.clean,
						layout = data.layout,
						legend = data.legend,
						datasource = datasource
					}

					loadTemplates(data, fname)
				end)
			end
		end
	else
		if data.project then
			if type(data.project) == "string" then
				if File(data.project):exists() then
					data.project = terralib.Project{file = data.project}
				else
					customError("Project '"..data.project.."' was not found.")
				end
			end

			mandatoryTableArgument(data, "project", "Project")
		end

		createDirectoryStructure(data)
		loadLayers(data)
		loadTemplates(data)
	end

	setmetatable(data, metaTableApplication_)

	local finalTime = os.clock()
	printInfo("Summing up, application '"..data.layout.title.."' were successfully created in "..round(finalTime - initialTime, 4).." seconds.")

	return data
end