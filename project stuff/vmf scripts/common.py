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



def capless_s(tpl):
	output = ""
	for x in tpl:
		output += str(x) + " "
	if output[-1] == ' ': output = output[:-1]
	return output

def tup_s(tpl):
	output = "("
	for x in tpl:
		output += str(x) + " "
	if output[-1] == ' ': output = output[:-1]
	output += ")"
	return output

def lst_s(lst):
	output = "["
	for x in lst:
		output += str(x) + " "
	if output[-1] == ' ': output = output[:-1]
	output += "]"
	return output

def strip_braces( s ):
	return s[1:-1]

def strip_brackets( s ):
	return s[1:-1]