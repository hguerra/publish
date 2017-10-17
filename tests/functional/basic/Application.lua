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

return {
	Application = function(unitTest)
		local emasDir = Directory("functional-basic-app")
		if emasDir:exists() then emasDir:delete() end

		local app = Application{
			project = filePath("emas.tview", "publish"),
			output = "functional-basic-app",
			clean = true,
			select = "river",
			color = "BuGn",
			value = {0, 1, 2},
			progress = false
		}

		unitTest:assertType(app, "Application")
		unitTest:assertType(app.output, "Directory")
		unitTest:assertEquals(app.title, "Emas database")
		unitTest:assert(app.clean)
		unitTest:assert(not app.progress)
		unitTest:assertNil(app.key)

		if app.output:exists() then app.output:delete() end

		app = Application{
			project = filePath("emas.tview", "publish"),
			output = emasDir,
			key = "AIzaSyCFXMRJlfDoDK7Hk8KkJ9R9bWpNauoLVuA",
			clean = true,
			select = "river",
			color = "BuGn",
			value = {0, 1, 2},
			progress = false
		}

		unitTest:assertType(app, "Application")
		unitTest:assertNotNil(app.key)
		unitTest:assertEquals(app.key, "AIzaSyCFXMRJlfDoDK7Hk8KkJ9R9bWpNauoLVuA")

		if emasDir:exists() then emasDir:delete() end

		local caraguaDir = Directory("CaraguaWebMap")
		if caraguaDir:exists() then caraguaDir:delete() end

		app = Application{
			key = "AIzaSyCFXMRJlfDoDK7Hk8KkJ9R9bWpNauoLVuA",
			project = filePath("caragua.tview", "publish"),
			clean = true,
			output = caraguaDir,
			Limit = List{
				limit = View{
					color = "goldenrod",
				},
				regions = View{
					select = "name",
					color = "Set2"
				}
			},
			SocialClasses = List{
				real = View{
					title = "Social Classes 2010",
					select = "classe",
					color = {"red", "orange", "yellow"},
					label = {"Condition C", "Condition B", "Condition A"}
				},
				baseline = View{
					title = "Social Classes 2025",
					select = "classe",
					color = {"red", "orange", "yellow"},
					label = {"Condition C", "Condition B", "Condition A"}
				}
			},
			OccupationalClasses = List{
				use = View{
					title = "Occupational Classes 2010",
					select = "uso",
					color = "RdPu"
				}
			}
		}

		unitTest:assertType(app, "Application")
		unitTest:assertNotNil(app.key)
		unitTest:assertEquals(app.key, "AIzaSyCFXMRJlfDoDK7Hk8KkJ9R9bWpNauoLVuA")

		local group = app.group
		unitTest:assertNotNil(group)
		unitTest:assertType(group, "table")
		unitTest:assertType(group.Limit, "string")
		unitTest:assertEquals(group.Limit, "limit")

		unitTest:assertType(group.SocialClasses, "string")
		unitTest:assertEquals(group.SocialClasses, "baseline")

		unitTest:assertType(group.OccupationalClasses, "string")
		unitTest:assertEquals(group.OccupationalClasses, "use")

		local view = app.view.limit
		unitTest:assertType(view, "View")
		unitTest:assertEquals(view.group, "Limit")

		view = app.view.real
		unitTest:assertType(view, "View")
		unitTest:assertEquals(view.group, "SocialClasses")

		view = app.view.use
		unitTest:assertType(view, "View")
		unitTest:assertEquals(view.group, "OccupationalClasses")

		if caraguaDir:exists() then caraguaDir:delete() end
	end,
	__tostring = function(unitTest)
		local emas = filePath("emas.tview", "publish")
		local emasDir = Directory("functional-basic-tostring")

		if emasDir:exists() then emasDir:delete() end

		local app = Application{
			project = tostring(emas),
			clean = true,
			select = "river",
			color = "BuGn",
			value = {0, 1, 2},
			progress = false,
			output = emasDir,
			title = "Emas",
			description = "Creates a database that can be used by the example fire-spread of base package.",
			zoom = 14,
			center = {lat = -18.106389, long = -52.927778}
		}

		unitTest:assertType(app, "Application")
		unitTest:assert(app.clean)
		unitTest:assert(not app.progress)
		unitTest:assertEquals(tostring(app), [[assets       Directory
base         string [satellite]
center       named table of size 2
clean        boolean [true]
datasource   Directory
description  string [Creates a database that can be used by the example fire-spread of base package.]
legend       string [Legend]
loading      string [default.gif]
maxZoom      number [20]
minZoom      number [0]
output       Directory
progress     boolean [false]
project      Project
template     named table of size 2
title        string [Emas]
view         named table of size 4
zoom         number [14]
]])

		if emasDir:exists() then emasDir:delete() end
	end
}
