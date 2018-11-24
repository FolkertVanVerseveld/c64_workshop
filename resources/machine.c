#include <stdio.h>
#include <stdlib.h>

#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <GL/gl.h>

#define TITLE "Workshop-O-Matic"
#define WIDTH 800
#define HEIGHT 600

#define MACHINE_OFFSET 40

static SDL_Window *win;
static SDL_GLContext gl;

#define TEXTURES 4

#define MACHINES 4

static GLuint tex[TEXTURES];
static unsigned tex_w[TEXTURES], tex_h[TEXTURES];

static unsigned machine_index = 0;

static const char *machine_scripts[MACHINES] = {
	"atari", "apple", "msdos", "zxspectrum"
};

static void display(void)
{
	if (machine_index == 1)
		glClearColor(0, 0, 0, 0);
	else
		glClearColor(1, 1, 1, 0);

	glClear(GL_COLOR_BUFFER_BIT);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0, WIDTH, HEIGHT, 0, -1, 1);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	// Draw machine centered in view
	GLfloat x0, y0, x1, y1;
	double aspect, w, h;

	aspect = tex_w[machine_index] / (double)tex_h[machine_index];
	h = HEIGHT - MACHINE_OFFSET;
	w = aspect * h;

	x0 = WIDTH / 2 - w / 2;
	x1 = WIDTH / 2 + w / 2;
	y0 = MACHINE_OFFSET / 2;
	y1 = HEIGHT - MACHINE_OFFSET;

	glBindTexture(GL_TEXTURE_2D, tex[machine_index]);
	glEnable(GL_TEXTURE_2D);
	glColor3f(1, 1, 1);
	glBegin(GL_QUADS);
		glTexCoord2f(0, 0); glVertex2f(x0, y0);
		glTexCoord2f(1, 0); glVertex2f(x1, y0);
		glTexCoord2f(1, 1); glVertex2f(x1, y1);
		glTexCoord2f(0, 1); glVertex2f(x0, y1);
	glEnd();
	glDisable(GL_TEXTURE_2D);
}

static int mainloop(void)
{
	glViewport(0, 0, WIDTH, HEIGHT);
	glClearColor(0, 0, 0, 0);

	while (1) {
		SDL_Event ev;

		while (SDL_PollEvent(&ev)) {
			switch (ev.type) {
			case SDL_QUIT:
				return 0;
			case SDL_KEYDOWN: {
				unsigned virt = ev.key.keysym.sym;
				switch (virt) {
				case 'q':
					return 0;
				case ' ':
					machine_index = (machine_index + 1) % MACHINES;
					break;
				case '\r':
				case '\n': {
					char buf[80];
					snprintf(buf, sizeof buf, "bash ./%s", machine_scripts[machine_index]);
					system(buf);
					break;
				}
				}
				break;
			}
			}
		}

		display();
		SDL_GL_SwapWindow(win);
	}

	return 1;
}

static void gfx_load(unsigned i, const char *name)
{
	SDL_Surface *surf;
	int mode = GL_RGB;
	GLuint texture = tex[i];

	surf = IMG_Load(name);
	if (!surf) {
		fprintf(stderr, "Could not load \"%s\": %s\n", name, IMG_GetError());
		exit(1);
	}
	if (surf->w <= 0 || surf->h <= 0) {
		fprintf(stderr, "Bogus dimensions: %d, %d\n", surf->w, surf->h);
		exit(1);
	}

	printf("%s: %u\n", name, texture);

	glBindTexture(GL_TEXTURE_2D, texture);

	//printf("%s: bpp = %d\n", name, surf->format->BytesPerPixel);
	// Not completely correct, but good enough
	if (surf->format->BytesPerPixel == 4)
		mode = GL_RGBA;

	glTexImage2D(GL_TEXTURE_2D, 0, mode, surf->w, surf->h, 0, mode, GL_UNSIGNED_BYTE, surf->pixels);

	tex_w[i] = (unsigned)surf->w;
	tex_h[i] = (unsigned)surf->h;

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	SDL_FreeSurface(surf);
}

static void gfx_init(void)
{
	glGenTextures(TEXTURES, tex);

	gfx_load(0, "../images/vcs.jpg");
	gfx_load(1, "../images/appleii.jpg");
	gfx_load(2, "../images/ibm5150.jpg");
	gfx_load(3, "../images/zxspectrum.jpg");
}

static void gfx_free(void)
{
	glDeleteTextures(4, tex);
}

int main(void)
{
	int ret = 1;
	unsigned img_mask = IMG_INIT_JPG | IMG_INIT_PNG;

	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		fprintf(stderr, "Could not init SDL: %s\n", SDL_GetError());
		goto fail;
	}

	if (SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1))
		fputs("No double buffering\n", stderr);

	win = SDL_CreateWindow(
		TITLE,
		SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
		WIDTH, HEIGHT,
		SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN
	);
	if (!win) {
		fprintf(stderr, "Could not create window: %s\n", SDL_GetError());
		goto err_win;
	}

	if (!(gl = SDL_GL_CreateContext(win))) {
		fprintf(stderr, "Could not create OpenGL context: %s\n", SDL_GetError());
		goto err_gl;
	}

	if ((IMG_Init(img_mask) & img_mask) != img_mask) {
		fprintf(stderr, "Could not init image library: %s\n", IMG_GetError());
		goto err_img;
	}
	gfx_init();

	ret = mainloop();

	// Cleanup
	gfx_free();
	IMG_Quit();
err_img:
	SDL_GL_DeleteContext(gl);
err_gl:
	SDL_DestroyWindow(win);
err_win:
	SDL_Quit();
fail:
	return ret;
}
