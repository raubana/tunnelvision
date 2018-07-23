import string, json

from common import *




IN_FILENAME = "props.txt"
OUT_FILENAME = "props.vmf"




def make_endblock():
	end_block_data = [
		"color", capless_s((128,128,128)),
		"visgroupshown", 1,
		"visgroupautoshown", 1,
		"logicalpos", "[0 0]"
	]

	end_block = Block(
		"editor",
		tuple(end_block_data),
		[]
	)

	return [end_block]




class Prop(object):
	def __init__( self, data ):
		self.pos = data["pos"]
		self.ang = data["ang"]
		self.model = data["model"]

	def get_block( self, id ):
		return Block( "entity",
		                (
							"id", str(id),
							"classname", "prop_physics",
							"angles", strip_braces(self.ang),
			                "origin", strip_brackets(self.pos),
			                "model", self.model
						),
		                make_endblock())




class PropSaveToVMF(object):
	def __init__(self, save_str):
		self.save_str = save_str

		self.entities = []
		self.entity_data = []

		lines = string.split(self.save_str, "\n")

		for line in lines:
			data = json.loads(line)

			new_data = {}
			for key in data:
				val = data[key]
				if type(val) == unicode:
					val = str(val)

				new_data[str(key)] = val

			self.entity_data.append( new_data )

		self.ent_id_counter = 1

	def next_ent_id(self):
		output = int(self.ent_id_counter)
		self.ent_id_counter += 1
		return output

	def gen(self):
		for data in self.entity_data:
			print( data )

			self.entities.append( Prop(data) )

	def to_vmf_format(self):
		self.ent_id_counter = 1
		self.side_id_counter = 1

		output = []

		output.append(
			Block(
				"versioninfo",
				(
					"editorversion", 400,
					"editorbuild", 6440,
					"mapversion", 1,
					"formatversion", 100,
					"prefab", 0
				),
				[]
			)
		)

		output.append( Block( "visgroups", (), [] ) )

		output.append(
			Block(
				"viewsettings",
				(
					"bSnapToGrid", 1,
					"bShowGrid", 1,
					"bShowLogicalGrid", 0,
					"nGridSpacing", 64,
					"bShow3DGrid", 0
				),
				[]
			)
		)

		world = Block(
			"world",
			(
				"id", self.next_ent_id(),
				"mapversion", 1,
				"classname", "worldspawn",
				"detailmaterial", "detail/detailsprites",
				"detailvbsp", "detail.vbsp",
				"maxpropscreenwidth", -1,
				"skyname", "sky_day01_01"
			),
			[]
		)

		output.append(world)

		for ent in self.entities:
			output.append( ent.get_block( self.next_ent_id() ) )

		output.append(
			Block(
				"cameras",
				(
					"activecamera", -1
				),
				[]
			)
		)

		output.append(
			Block(
				"cordon",
				(
					"mins", "(-1024 -1024 -1024)",
					"maxs", "(1024 1024 1024)",
					"active", 0
				),
				[]
			)
		)

		output_str = ""
		for block in output:
			output_str += str(block)

		return output_str


f = open( IN_FILENAME, "r" )
data = f.read()
data = string.strip( data )

converter = PropSaveToVMF( data )
converter.gen()
vmf_format = converter.to_vmf_format()

f = open(OUT_FILENAME, "w")
f.writelines(vmf_format)
f.close()