import string, json

from common import *



PREFIX = "io_pzl1_"
IN_FILENAME = "bang1.txt"
OUT_FILENAME = "bang1.vmf"




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


class IOBase(object):
	SHORT = "?"
	CLASSNAME = "unknown"

	def __init__( self, data ):
		self.pos = data["pos"]
		self.ang = data["angles"]
		self.state = int( data["state"] )
		self.targetname = None

	def gen_targetname(self, all_entities):
		count = 1
		for ent in all_entities:
			if ent == self: break
			if type(ent) == type(self): count += 1
		self.targetname = PREFIX + self.SHORT + str(count)

	def get_block( self, id, all_entities ):
		return Block( "entity",
		                (
							"id", str(id),
							"classname", self.CLASSNAME,
							"state", str(self.state),
							"targetname", self.targetname,
							"angles", strip_braces(self.ang),
			                "origin", strip_brackets(self.pos)
						),
		                make_endblock())


class IOThrough(IOBase):
	SHORT = "thr"
	CLASSNAME = "sent_tv_io_through"


class IOButton(IOBase):
	SHORT = "btn"
	CLASSNAME = "sent_tv_io_button"


class IOSwitch(IOBase):
	SHORT = "swt"
	CLASSNAME = "sent_tv_io_switch"

	def __init__( self, data ):
		self.pos = data["pos"]
		self.ang = data["angles"]
		self.state = int( data["state"] )
		self.is_on = data["is_on"]
		self.targetname = None

	def get_block( self, id, all_entities ):
		return Block( "entity",
		                (
							"id", str(id),
							"classname", self.CLASSNAME,
							"is_on", str( int( self.is_on ) ),
							"state", str(self.state),
							"targetname", self.targetname,
							"angles", strip_braces(self.ang),
			                "origin", strip_brackets(self.pos)
						),
		                make_endblock())



class IOCapacitor(IOBase):
	SHORT = "cap"
	CLASSNAME = "sent_tv_io_capacitor"

	def __init__( self, data ):
		self.pos = data["pos"]
		self.ang = data["angles"]
		self.state = int( data["state"] )
		self.charge = int( data["charge"] )
		self.threshold = int( data["threshold"] )
		self.maximum = int( data["maximum"] )
		self.targetname = None

	def get_block( self, id, all_entities ):
		return Block( "entity",
		                (
							"id", str(id),
							"classname", self.CLASSNAME,
							"state", str(self.state),
							"charge", str( self.charge ),
							"maximum", str( self.maximum ),
							"targetname", self.targetname,
							"threshold", str( self.threshold ),
							"angles", strip_braces(self.ang),
			                "origin", strip_brackets(self.pos)
						),
		                make_endblock())


class IOIndicator(IOBase):
	SHORT = "ind"
	CLASSNAME = "sent_tv_io_indicator"


class IOPower(IOBase):
	SHORT = "pwr"
	CLASSNAME = "sent_tv_io_power"


class IORelay(IOSwitch):
	SHORT = "rly"
	CLASSNAME = "sent_tv_io_relay"


class IOSystem(IOSwitch):
	SHORT = "sys"
	CLASSNAME = "sent_tv_io_system"


class IOCable(IOBase):
	SHORT = "cbl"
	CLASSNAME = "sent_tv_io_cable"

	def __init__( self, data ):
		self.pos = data["pos"]
		self.ang = data["angles"]
		self.high = bool( data["high"] )
		self.i_ent_id = int( data["i_ent"] )
		self.o_ent_id = int( data["o_ent"] )
		self.i_id = int( data["i_id"] )
		self.o_id = int( data["o_id"] )
		self.targetname = None

	def get_block( self, id, all_entities ):
		i_ent = all_entities[self.i_ent_id - 1]
		o_ent = all_entities[self.o_ent_id - 1]

		return Block( "entity",
		                (
							"id", str(id),
							"classname", self.CLASSNAME,
							"high", str( int( self.high ) ),
							"InputEntity", i_ent.targetname,
							"InputID", str( self.i_id ),
							"OutputEntity", o_ent.targetname,
							"OutputID", str(self.o_id),
							"targetname", self.targetname,
							"angles", strip_braces(self.ang),
			                "origin", strip_brackets(self.pos)
						),
		                make_endblock())


class IOTelephone(IOSwitch):
	SHORT = "tel"
	CLASSNAME = "sent_tv_io_telephone"


class IOSteppingSwitch(IOBase):
	SHORT = "stp"
	CLASSNAME = "sent_tv_io_steppingswitch"

	def __init__( self, data ):
		self.pos = data["pos"]
		self.ang = data["angles"]
		self.state = int( data["state"] )
		self.step_pos = int( data["step_pos"] )
		self.charged = int( data["charged"] )
		self.locked = int( data["locked"] )
		self.targetname = None

	def get_block( self, id, all_entities ):
		return Block( "entity",
		                (
							"id", str(id),
							"classname", self.CLASSNAME,
							"state", str( self.state ),
							"step_pos", str( self.step_pos ),
							"charged", str( int( self.charged ) ),
							"locked", str( int( self.locked ) ),
							"targetname", self.targetname,
							"angles", strip_braces(self.ang),
			                "origin", strip_brackets(self.pos)
						),
		                make_endblock())


class EntLabel(IOBase):
	SHORT = "lbl"
	CLASSNAME = "sent_tv_label"

	def __init__( self, data ):
		self.pos = data["pos"]
		self.ang = data["angles"]
		self.message = data["message"]
		self.editable = data["editable"]
		self.pickupable = data["pickupable"]
		self.targetname = None

	def get_block( self, id, all_entities ):
		return Block( "entity",
		                (
							"id", str(id),
							"classname", self.CLASSNAME,
							"message", self.message,
							"editable", str( int( self.editable ) ),
							"pickupable", str( int( self.pickupable ) ),
							"targetname", self.targetname,
							"angles", strip_braces(self.ang),
			                "origin", strip_brackets(self.pos)
						),
		                make_endblock())


class EntStickynote(EntLabel):
	SHORT = "note"
	CLASSNAME = "sent_tv_stickynote"



class IOSaveToVMF(object):
	def __init__(self, iosave_str):
		self.iosave_str = iosave_str

		self.entity_data = []
		self.entities = []

		lines = string.split(self.iosave_str, "\n")

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

			ent = None
			cls = data["class"]
			if cls == "sent_tv_io_capacitor":
				ent = IOCapacitor( data )
			elif cls == "sent_tv_io_indicator":
				ent = IOIndicator( data )
			elif cls == "sent_tv_io_power":
				ent = IOPower( data )
			elif cls == "sent_tv_io_switch":
				ent = IOSwitch( data )
			elif cls == "sent_tv_io_relay":
				ent = IORelay( data )
			elif cls == "sent_tv_io_through":
				ent = IOThrough( data )
			elif cls == "sent_tv_io_button":
				ent = IOButton( data )
			elif cls == "sent_tv_io_system":
				ent = IOSystem( data )
			elif cls == "sent_tv_io_cable":
				ent = IOCable( data )
			elif cls == "sent_tv_io_telephone":
				ent = IOTelephone( data )
			elif cls == "sent_tv_io_steppingswitch":
				ent = IOSteppingSwitch( data )
			elif cls == "sent_tv_label":
				ent = EntLabel( data )
			elif cls == "sent_tv_stickynote":
				ent = EntStickynote( data )
			else:
				print "got unknown class:", cls

			if ent:
				self.entities.append( ent )

		for ent in self.entities:
			ent.gen_targetname( self.entities )

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
			output.append( ent.get_block( self.next_ent_id(), self.entities ) )

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

converter = IOSaveToVMF( data )
converter.gen()
vmf_format = converter.to_vmf_format()

f = open(OUT_FILENAME, "w")
f.writelines(vmf_format)
f.close()