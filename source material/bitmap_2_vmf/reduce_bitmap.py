import pygame
from pygame.locals import *
pygame.init()

import time



class ReducableRect(object):
	def __init__(self, rect, color):
		self.rect = rect
		self.color = color

	def could_merge_with(self, rect):
		if self.color[0] != rect.color[0] or self.color[1] != rect.color[1] or self.color[2] != rect.color[2]:
			return False

		#x axis
		if self.rect[1] == rect.rect[1]:
			if self.rect[3] == rect.rect[3]:
				if self.rect[0] == rect.rect[0]+rect.rect[2] or self.rect[0]+self.rect[2] == rect.rect[0]:
					return True

		# y axis
		if self.rect[0] == rect.rect[0]:
			if self.rect[2] == rect.rect[2]:
				if self.rect[1] == rect.rect[1] + rect.rect[3] or self.rect[1] + self.rect[3] == rect.rect[1]:
					return True

		return False

	def get_merged(self, rect):
		X1 = min(self.rect[0], rect.rect[0])
		Y1 = min(self.rect[1], rect.rect[1])
		X2 = max(self.rect[0]+self.rect[2], rect.rect[0]+rect.rect[2])
		Y2 = max(self.rect[1]+self.rect[3], rect.rect[1]+rect.rect[3])

		return ReducableRect(
			[
				X1,
				Y1,
				X2-X1,
				Y2-Y1,
			],

			rect.color
		)

	def is_touching_sides(self, rect):
		overlap_x = max(0, min( self.rect[0]+self.rect[2], rect.rect[0]+rect.rect[2]) - max(self.rect[0], rect.rect[0]) )
		overlap_y = max(0, min(self.rect[1] + self.rect[3], rect.rect[1] + rect.rect[3]) - max(self.rect[1], rect.rect[1]))

		if (overlap_x > 0 and overlap_y <= 0) or (overlap_x <= 0 and overlap_y > 0):
			if self.rect[0] == rect.rect[0]+rect.rect[2] or self.rect[0]+self.rect[2] == rect.rect[0] or \
			self.rect[1] == rect.rect[1] + rect.rect[3] or self.rect[1] + self.rect[3] == rect.rect[1]:
				return True

		return False

	def copy(self):
		new_rect = [self.rect[0], self.rect[1], self.rect[2], self.rect[3]]
		new_color = [self.color[0], self.color[1], self.color[2]]
		return ReducableRect( new_rect, new_color )

	def flip(self):
		old_rect = list(self.rect)

		self.rect[0] = old_rect[1]
		self.rect[1] = old_rect[0]
		self.rect[2] = old_rect[3]
		self.rect[3] = old_rect[2]




def key_left_to_right(rect):
	return rect.rect[0]

def key_top_to_bottom(rect):
	return rect.rect[1]




class Main():
	def __init__(self):
		self.screen_size = (1280, 720)
		self.screen = pygame.display.set_mode(self.screen_size)

		self.fps = 60
		self.clock = pygame.time.Clock()

		self.image = pygame.image.load("map.bmp")
		self.scale = 5

		self.restart()

	def sample_image(self):
		for y in xrange(self.image.get_height()):
			for x in xrange(self.image.get_width()):
				pixel = self.image.get_at((x,y))
				if len(pixel) >= 4: pixel = pixel[:3]

				if pixel[0] > 0 or pixel[1] > 0 or pixel[2]:
					rect = ReducableRect( [x,y,1,1], pixel )
					self.rects.append(rect)

	def merge_rects(self):
		repeat = True

		while repeat:
			repeat = False

			i = 0
			j = 1
			while i <= len(self.rects) - 2:
				while j <= len(self.rects) - 1:
					if self.rects[i].could_merge_with( self.rects[j] ):
						self.rects[i] = self.rects[i].get_merged( self.rects[j] )
						self.rects.pop(j)
						repeat = True
					j += 1
				i += 1
				j = i + 1

	def gen_contact_groups(self, L):
		contact_groups = []

		for i in xrange(len(L)):
			contacts = []
			for j in xrange(len(L)):
				if i != j and L[i].is_touching_sides(L[j]):
					contacts.append(j)
			contact_groups.append(contacts)

		return contact_groups

	def clone_rect_list(self, L):
		new_L = []
		for r in L:
			new_L.append(r.copy())
		return new_L

	def reduce_rects(self):
		if len(self.rects) == 0: return

		x = 1
		max_x = 2
		while x < max_x:
			max_x = 1

			repeat = True
			while repeat:
				print "repeat"

				repeat = False

				original_contact_groups = self.gen_contact_groups(self.rects)
				original_L = self.clone_rect_list(self.rects)

				change = False

				for r in self.rects:
					if r.rect[0] < x and r.rect[0]+r.rect[2] > x and r.rect[2] > 1:
						r.rect[2] = r.rect[2] - 1
						change = True

					if r.rect[0] >= x:
						r.rect[0] = r.rect[0] - 1
						change = True

				self.render_no_flip()
				pygame.draw.line(self.screen, (255,255,0), (x*self.scale, 0), (x*self.scale, self.screen_size[1]))
				pygame.display.flip()

				new_contact_groups = self.gen_contact_groups(self.rects)

				if new_contact_groups == original_contact_groups and change:
					repeat = True
				else:
					self.rects = original_L

			for r in self.rects:
				max_x = max(max_x, r.rect[0]+r.rect[2])

			x += 1

			print x, max_x

		print "Done"

	def flip_rects(self):
		for r in self.rects:
			r.flip()

	def save_result(self):
		w = 0
		h = 0
		for r in self.rects:
			w = max(w, r.rect[0]+r.rect[2])
			h = max(h, r.rect[1]+r.rect[3])

		srf = pygame.Surface((w,h))

		for r in self.rects:
			srf.fill(r.color, r.rect)

		pygame.image.save( srf, "output.bmp" )

	def restart(self):
		self.rects = []

		self.sample_image()
		self.merge_rects()
		self.reduce_rects()
		self.flip_rects()
		self.reduce_rects()
		self.flip_rects()
		self.save_result()

	def update(self):
		pass

	def render_no_flip(self):
		self.screen.fill((32,32,32))

		for r in self.rects:
			r2 = (r.rect[0]*self.scale, r.rect[1]*self.scale, r.rect[2]*self.scale, r.rect[3]*self.scale)
			pygame.draw.rect(self.screen, r.color, r2)
			pygame.draw.rect(self.screen, (0,0,0), r2, 1)

	def render(self):
		self.render_no_flip()

		pygame.display.flip()

	def run(self):
		self.running = True

		while self.running:
			self.events = pygame.event.get()

			self.update()
			self.render()

			for e in self.events:
				if e.type == QUIT or e.type == KEYDOWN and e.key == K_ESCAPE:
					self.running = False

				if e.type == KEYDOWN:
					if e.key == K_r:
						self.restart()

			self.clock.tick(self.fps)

		pygame.quit()


main = Main()
main.run()
