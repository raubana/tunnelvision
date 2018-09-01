import pygame
from pygame.locals import *

pygame.init()


class Main():
	def __init__(self):
		self.screen_size = (1366, 768)
		self.screen = pygame.display.set_mode(self.screen_size)

		self.fps = 60
		self.clock = pygame.time.Clock()

		self.reset()

	def reset(self):
		pass

	def update(self):
		pass

	def render(self):
		self.screen.fill((32, 32, 32))

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

				if e.type == KEYDOWN and e.key == K_r:
					self.reset()

			self.clock.tick(self.fps)

		pygame.quit()


main = Main()
main.run()