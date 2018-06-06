import pygame
from pygame.locals import *
pygame.init()


WALL_THICKNESS = 16
TILE_SIZE = 128
WALL_HEIGHT = 128

MAT_NODRAW = "TOOLS/TOOLSNODRAW"
MAT_WALL_X = "BRICK/BRICKWALL_BRIGHTRED"
MAT_WALL_Y = "WALLPAPER/GREEN01"
MAT_FLOOR = "CONCRETE/BLACKTOP_EXT_01"
MAT_CEILING = "BUILDINGS/AWNING_BLUE"


# REMEMBER:
# X is left
# Y is forward
# Z is up


class Rect3(object):
	def __init__( self, rect, mats, color ):
		self.rect = list(rect)
		self.mats = list(mats)
		self.color = color

	def __str__(self):
		return str(self.rect)

	def corner(self, x, y, z):
		X = self.rect[0]
		Y = self.rect[1]
		Z = self.rect[2]
		if x: X += self.rect[3]
		if y: Y += self.rect[4]
		if z: Z += self.rect[5]

		return ( X, Y, Z )

	def could_merge_with(self, rect):
		if self.color[0] != rect.color[0] or self.color[1] != rect.color[1] or self.color[2] != rect.color[2]:
			return False

		#x axis
		if self.rect[4] == rect.rect[4] and self.rect[5] == rect.rect[5]:
			if self.rect[1] == rect.rect[1] and self.rect[2] == rect.rect[2]:
				if self.rect[0] == rect.rect[0]+rect.rect[3] or self.rect[0]+self.rect[3] == rect.rect[0]:
					return True

		#y axis
		if self.rect[3] == rect.rect[3] and self.rect[5] == rect.rect[5]:
			if self.rect[0] == rect.rect[0] and self.rect[2] == rect.rect[2]:
				if self.rect[1] == rect.rect[1]+rect.rect[4] or self.rect[1]+self.rect[4] == rect.rect[1]:
					return True

		#z axis
		if self.rect[3] == rect.rect[3] and self.rect[4] == rect.rect[4]:
			if self.rect[0] == rect.rect[0] and self.rect[1] == rect.rect[1]:
				if self.rect[2] == rect.rect[2]+rect.rect[5] or self.rect[2]+self.rect[5] == rect.rect[2]:
					return True

		return False

	def get_merged(self, rect):
		X1 = min(self.rect[0], rect.rect[0])
		Y1 = min(self.rect[1], rect.rect[1])
		Z1 = min(self.rect[2], rect.rect[2])
		X2 = max(self.rect[0]+self.rect[3], rect.rect[0]+rect.rect[3])
		Y2 = max(self.rect[1]+self.rect[4], rect.rect[1]+rect.rect[4])
		Z2 = max(self.rect[2]+self.rect[5], rect.rect[2]+rect.rect[5])

		return Rect3(
			(
				X1,
				Y1,
				Z1,
				X2-X1,
				Y2-Y1,
				Z2-Z1
			),

			self.mats,

			rect.color
		)

	def overlaps_with(self, rect):
		x_overlap = max(0, ( self.rect[3]+rect.rect[3] ) - (max(self.rect[0]+self.rect[3], rect.rect[0]+rect.rect[3]) - min(self.rect[0], rect.rect[0])) )
		y_overlap = max(0, ( self.rect[4]+rect.rect[4] ) - (max(self.rect[1]+self.rect[4], rect.rect[1]+rect.rect[4]) - min(self.rect[1], rect.rect[1])) )
		z_overlap = max(0, ( self.rect[5]+rect.rect[5] ) - (max(self.rect[2]+self.rect[5], rect.rect[2]+rect.rect[5]) - min(self.rect[2], rect.rect[2])) )

		return x_overlap * y_overlap * z_overlap > 0



class Block(object):
	def __init__(self, name, options, contents):
		self.name = name
		self.options = options
		self.contents = contents

	def __str__(self):
		output = self.name + "\n{\n"
		for i in xrange(0, len(self.options), 2):
			output += "\t"+'"'+self.options[i]+'"'+' '+'"'+str(self.options[i+1])+'"'+'\n'
		contents = ""
		for content in self.contents:
			contents += str(content)
		if contents:
			lines = contents.split("\n")
			new_contents = ""
			for line in lines:
				new_contents += "\t" + line + "\n"
			output += new_contents
		output += "}\n"

		return output

	def add( self, new_content ):
		self.contents.append(new_content)


class Bitmap2Rect3s(object):
	def __init__(self, srf):
		self.srf = srf

		self.floor_rects = []
		self.ceiling_rects = []

		self.f_wall_rects = []
		self.r_wall_rects = []
		self.b_wall_rects = []
		self.l_wall_rects = []

		self.visgroups = {}

		self.ent_id_counter = 1
		self.side_id_counter = 1

	def make_visgroup(self, color):
		self.visgroups[self.capless_s(color)] = len(self.visgroups) + 1

	def get_visgroup(self, color):
		key = self.capless_s(color)
		if not key in self.visgroups:
			return self.make_visgroup(color)
		return self.visgroups[key]

	def capless_s(self, tpl):
		output = ""
		for x in tpl:
			output += str(x) + " "
		if output[-1] == ' ': output = output[:-1]
		return output

	def tup_s(self, tpl):
		output = "("
		for x in tpl:
			output += str(x) + " "
		if output[-1] == ' ': output = output[:-1]
		output += ")"
		return output

	def lst_s(self, lst):
		output = "["
		for x in lst:
			output += str(x) + " "
		if output[-1] == ' ': output = output[:-1]
		output += "]"
		return output

	def is_solid_at( self, pos ):
		if pos[0] < 0 or pos[0] >= self.srf.get_width() or pos[1] < 0 or pos[1] >= self.srf.get_height(): return False
		pixel = self.srf.get_at(pos)
		return pixel[0] > 0 or pixel[1] > 0 or pixel[2] > 0

	def create_shell_at( self, pos, color ):
		visgroup_id = self.get_visgroup(color)

		left = self.is_solid_at( (pos[0]-1, pos[1]) )
		right = self.is_solid_at( (pos[0]+1, pos[1]) )
		front = self.is_solid_at( (pos[0], pos[1]-1) )
		back = self.is_solid_at( (pos[0], pos[1]+1) )

		#create a floor
		self.floor_rects.append(
			Rect3(
				(
					-pos[1] * TILE_SIZE,
					-pos[0] * TILE_SIZE,
					-WALL_THICKNESS,
					TILE_SIZE,
					TILE_SIZE,
					WALL_THICKNESS
				),

				(
					MAT_FLOOR,
					MAT_NODRAW,
					MAT_NODRAW,
					MAT_NODRAW,
					MAT_NODRAW,
					MAT_NODRAW
				),

				color
			)
		)

		# create a ceiling
		self.ceiling_rects.append(
			Rect3(
				(
					-pos[1] * TILE_SIZE,
					-pos[0] * TILE_SIZE,
					WALL_HEIGHT,
					TILE_SIZE,
					TILE_SIZE,
					WALL_THICKNESS
				),

				(
					MAT_NODRAW,
					MAT_CEILING,
					MAT_NODRAW,
					MAT_NODRAW,
					MAT_NODRAW,
					MAT_NODRAW
				),

				color
			)
		)

		if not front:
			# create front wall
			self.f_wall_rects.append(
				Rect3(
					(
						-pos[1] * TILE_SIZE + TILE_SIZE,
						-pos[0] * TILE_SIZE,
						0,
						WALL_THICKNESS,
						TILE_SIZE,
						WALL_HEIGHT
					),

					(
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_WALL_X,
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_NODRAW
					),

					color
				)
			)

		if not back:
			# create back wall
			self.b_wall_rects.append(
				Rect3(
					(
						-pos[1] * TILE_SIZE - WALL_THICKNESS,
						-pos[0] * TILE_SIZE,
						0,
						WALL_THICKNESS,
						TILE_SIZE,
						WALL_HEIGHT
					),

					(
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_WALL_X,
						MAT_NODRAW,
						MAT_NODRAW
					),

					color
				)
			)

		if not left:
			# create left wall
			self.l_wall_rects.append(
				Rect3(
					(
						-pos[1] * TILE_SIZE,
						-pos[0] * TILE_SIZE + TILE_SIZE,
						0,
						TILE_SIZE,
						WALL_THICKNESS,
						WALL_HEIGHT
					),

					(
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_WALL_Y
					),

					color
				)
			)

		if not right:
			# create right wall
			self.r_wall_rects.append(
				Rect3(
					(
						-pos[1] * TILE_SIZE,
						-pos[0] * TILE_SIZE - WALL_THICKNESS,
						0,
						TILE_SIZE,
						WALL_THICKNESS,
						WALL_HEIGHT
					),

					(
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_NODRAW,
						MAT_WALL_Y,
						MAT_NODRAW
					),

					color
				)
			)

	def make_simple_side(self, plane, mat, uaxis, vaxis):
		return Block(
			"side",
			(
				"id", self.next_side_id(),
				"plane", plane,
				"material", mat,
				"uaxis", self.lst_s(uaxis) + " 0.25",
				"vaxis", self.lst_s(vaxis) + " 0.25",
				"rotation", 0,
				"lightmapscale", 16,
				"smoothing_groups", 0
			),
			[]
		)

	def rect_to_block(self, r):
		visgroup_id = self.get_visgroup(r.color)

		end_block_data = [
						"color", self.capless_s(r.color),
						"visgroupid", visgroup_id,
						"visgroupshown", 1,
						"visgroupautoshown", 1
					]

		end_block = Block(
					"editor",
					tuple(end_block_data),
					[]
				)


		block =  Block(
			"solid",
			(
				"id", self.next_ent_id()
			),
			[
				# TOP
				self.make_simple_side(
					self.tup_s(r.corner(0,0,1)) + " " + self.tup_s(r.corner(0,1,1)) + " " + self.tup_s(r.corner(1,1,1)),
					r.mats[0],
					(1, 0, 0, 0),
					(0, -1, 0, 0)
				),

				#BOTTOM
				self.make_simple_side(
					self.tup_s(r.corner(0, 1, 0)) + " " + self.tup_s(r.corner(0, 0, 0)) + " " + self.tup_s(r.corner(1, 0, 0)),
					r.mats[1],
					(-1, 0, 0, 0),
					(0, -1, 0, 0)
				),

				# FRONT
				self.make_simple_side(
					self.tup_s(r.corner(0, 0, 0)) + " " + self.tup_s(r.corner(0, 1, 0)) + " " + self.tup_s(r.corner(0, 1, 1)),
					r.mats[2],
					(0, -1, 0, 0),
					(0, 0, -1, 0)
				),

				# BACK
				self.make_simple_side(
					self.tup_s(r.corner(1, 1, 0)) + " " + self.tup_s(r.corner(1, 0, 0)) + " " + self.tup_s(r.corner(1, 0, 1)),
					r.mats[3],
					(0, 1, 0, 0),
					(0, 0, -1, 0)
				),

				# LEFT
				self.make_simple_side(
					self.tup_s(r.corner(0, 1, 0)) + " " + self.tup_s(r.corner(1, 1, 0)) + " " + self.tup_s(r.corner(1, 1, 1)),
					r.mats[4],
					(-1, 0, 0, 0),
					(0, 0, -1, 0)
				),

				# RIGHT
				self.make_simple_side(
					self.tup_s(r.corner(1, 0, 0)) + " " + self.tup_s(r.corner(0, 0, 0)) + " " + self.tup_s(r.corner(0, 0, 1)),
					r.mats[5],
					(1, 0, 0, 0),
					(0, 0, -1, 0)
				),

				end_block
			]
		)

		return block

	def next_ent_id(self):
		output = int(self.ent_id_counter)
		self.ent_id_counter += 1
		return output

	def next_side_id(self):
		output = int(self.side_id_counter)
		self.side_id_counter += 1
		return output

	def gen(self):
		# first stage - create pixel shells
		for y in xrange(self.srf.get_height()):
			for x in xrange(self.srf.get_width()):
				if self.is_solid_at((x,y)):
					color = self.srf.get_at((x,y))
					if len(color) > 3: color = color[:3]
					self.create_shell_at((x,y), color)

	def get_rect_groups(self, l):
		groups = []

		for rect in l:
			found_group = False
			for group in groups:
				for rect2 in group:
					if rect.could_merge_with(rect2):
						found_group = True
						break
				if found_group:
					group.append(rect)
					break

			if not found_group:
				groups.append([rect])

		return groups

	def get_optimised_group(self, group):
		new_group = list(group)

		i = 0
		j = 1

		while i < len(new_group)-1:
			if j >= len(new_group):
				i += 1
				j = i+1
			else:
				if new_group[i].could_merge_with(new_group[j]):
					new_rect = new_group[i].get_merged(new_group[j])
					new_group.pop(j)
					new_group[i] = new_rect
				else:
					j += 1

		return new_group

	def get_optimised_groups_as_rects(self, groups):
		l = []
		for group in groups:
			l += self.get_optimised_group(group)
		return l

	def optimise(self):
		running = True

		while running:
			new_floor_rects = self.get_optimised_groups_as_rects(self.get_rect_groups(self.floor_rects))
			new_ceiling_rects = self.get_optimised_groups_as_rects(self.get_rect_groups(self.ceiling_rects))
			new_l_wall_rects = self.get_optimised_groups_as_rects(self.get_rect_groups(self.l_wall_rects))
			new_b_wall_rects = self.get_optimised_groups_as_rects(self.get_rect_groups(self.b_wall_rects))
			new_r_wall_rects = self.get_optimised_groups_as_rects(self.get_rect_groups(self.r_wall_rects))
			new_f_wall_rects = self.get_optimised_groups_as_rects(self.get_rect_groups(self.f_wall_rects))
			if len(self.floor_rects) == len(new_floor_rects) and \
					len(self.ceiling_rects) == len(new_ceiling_rects) and \
					len(self.l_wall_rects) == len(new_l_wall_rects) and \
					len(self.b_wall_rects) == len(new_b_wall_rects) and \
					len(self.r_wall_rects) == len(new_r_wall_rects) and \
					len(self.f_wall_rects) == len(new_f_wall_rects):
				running = False

			self.floor_rects = new_floor_rects
			self.ceiling_rects = new_ceiling_rects
			self.l_wall_rects = new_l_wall_rects
			self.b_wall_rects = new_b_wall_rects
			self.r_wall_rects = new_r_wall_rects
			self.f_wall_rects = new_f_wall_rects

	def repair(self):
		all_y_walls = self.l_wall_rects + self.r_wall_rects

		for y_wall in all_y_walls:
			for f_wall in self.f_wall_rects:
				if f_wall.overlaps_with(y_wall):
					y_wall.rect[3] = y_wall.rect[3] - WALL_THICKNESS
					y_wall.rect[0] = y_wall.rect[0] + WALL_THICKNESS

					f_wall.mats[4] = MAT_WALL_Y
					f_wall.mats[5] = MAT_WALL_Y

			for b_wall in self.b_wall_rects:
				if b_wall.overlaps_with(y_wall):
					y_wall.rect[3] = y_wall.rect[3] - WALL_THICKNESS

					b_wall.mats[4] = MAT_WALL_Y
					b_wall.mats[5] = MAT_WALL_Y

	def to_json(self):
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

		visgroup_blocks = []

		for key in self.visgroups:
			visgroup_blocks.append(
				Block(
					"visgroup",
					(
						"name", key,
						"visgroupid", self.visgroups[key],
						"color", key
					),
					[]
				)
			)

		output.append( Block( "visgroups", (), visgroup_blocks ) )

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

		for floor_rect in self.floor_rects:
			world.add(
				self.rect_to_block(
					floor_rect
				)
			)

		for ceiling_rect in self.ceiling_rects:
			world.add(
				self.rect_to_block(
					ceiling_rect
				)
			)

		for f_wall_rect in self.f_wall_rects:
			world.add(
				self.rect_to_block(
					f_wall_rect
				)
			)

		for b_wall_rect in self.b_wall_rects:
			world.add(
				self.rect_to_block(
					b_wall_rect
				)
			)

		for l_wall_rect in self.l_wall_rects:
			world.add(
				self.rect_to_block(
					l_wall_rect
				)
			)

		for r_wall_rect in self.r_wall_rects:
			world.add(
				self.rect_to_block(
					r_wall_rect
				)
			)

		output.append(world)

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


screen = pygame.display.set_mode((800,600))
srf = pygame.image.load("map.bmp")
screen.blit( srf, (0,0) )
pygame.display.flip()

converter = Bitmap2Rect3s( srf )
converter.gen()
converter.optimise()
converter.repair()
json = converter.to_json()

f = open("output.vmf", "w")
f.writelines(json)
f.close()

#TODO - stuff