#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <GL/gl.h>

#define TITLE "Workshop-O-Matic"
#define WIDTH 800
#define HEIGHT 600

#define MACHINE_OFFSET 40

static SDL_Window *win;
static SDL_GLContext gl;

#define TEXTURES 8

#define TEX_BOMBE 5
#define TEX_VECTREX 6
#define TEX_CRT 7

#define MACHINES 5

#define CRT_LINES 8

static GLuint tex[TEXTURES];
static unsigned tex_w[TEXTURES], tex_h[TEXTURES];

static unsigned machine_index = 0;

static const char *machine_scripts[MACHINES] = {
	"atari", "apple", "msdos", "zxspectrum", "nes"
};

#define MODE_MENU 0
#define MODE_MACHINES 1

static unsigned view_mode = MODE_MENU;

static Uint32 timer;

#define MODE_MENU_MACHINES 0
#define MODE_MENU_VECTREX 1
#define MODE_MENU_CRT 2

#define MENU_MODES 3

static unsigned menu_select = 0;
static float bombe_wobble = M_PI / 2;

static unsigned raster_line = 0;
static float raster_trace = 0;
static float raster_hor_trace = 0;
static float raster_vert_trace = 0;

static void display_machines(void)
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

static void display_menu_bombe(Uint32 ticks)
{
	glClearColor(1, 1, 1, 0);
	glClear(GL_COLOR_BUFFER_BIT);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0, WIDTH, HEIGHT, 0, -1, 1);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	bombe_wobble = fmodf(bombe_wobble + 0.005 * ticks, 2 * M_PI);

	GLfloat x0, y0, x1, y1;
	double aspect, w, h;

	aspect = tex_w[TEX_BOMBE] / (double)tex_h[TEX_BOMBE];
	h = HEIGHT - 100;
	w = aspect * h;

	x0 = WIDTH / 2 - w / 2 + 30 * sin(bombe_wobble);
	x1 = x0 + w;
	y0 = HEIGHT / 2 - h / 2;
	y1 = y0 + h;

	glBindTexture(GL_TEXTURE_2D, tex[TEX_BOMBE]);
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

static void display_menu_vectrex()
{
	glClearColor(1, 1, 1, 0);
	glClear(GL_COLOR_BUFFER_BIT);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0, WIDTH, HEIGHT, 0, -1, 1);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	GLfloat x0, y0, x1, y1;
	double aspect, w, h;

	aspect = tex_w[TEX_VECTREX] / (double)tex_h[TEX_VECTREX];
	h = HEIGHT - 10;
	w = aspect * h;

	x0 = WIDTH / 2 - w / 2;
	x1 = x0 + w;
	y0 = HEIGHT / 2 - h / 2;
	y1 = y0 + h;

	glBindTexture(GL_TEXTURE_2D, tex[TEX_VECTREX]);
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

static void display_menu_crt(Uint32 ticks)
{
	glClearColor(1, 1, 1, 0);
	glClear(GL_COLOR_BUFFER_BIT);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0, WIDTH, HEIGHT, 0, -1, 1);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	GLfloat x0, y0, x1, y1;
	double aspect, w, h;

	aspect = tex_w[TEX_CRT] / (double)tex_h[TEX_CRT];
	h = HEIGHT;
	w = aspect * h;

	x0 = WIDTH / 2 - w / 2;
	x1 = x0 + w;
	y0 = HEIGHT / 2 - h / 2;
	y1 = y0 + h;

	glBindTexture(GL_TEXTURE_2D, tex[TEX_CRT]);
	glEnable(GL_TEXTURE_2D);
	glColor3f(1, 1, 1);
	glBegin(GL_QUADS);
		glTexCoord2f(0, 0); glVertex2f(x0, y0);
		glTexCoord2f(1, 0); glVertex2f(x1, y0);
		glTexCoord2f(1, 1); glVertex2f(x1, y1);
		glTexCoord2f(0, 1); glVertex2f(x0, y1);
	glEnd();
	glDisable(GL_TEXTURE_2D);

	glLineWidth(4);

	glBegin(GL_LINES);
	for (unsigned i = 0; i < CRT_LINES; ++i) {
		glColor3f(1, 0, 0);
		glVertex2f(200, 110 + 40 * i); glVertex2f(600, 110 + 40 * i);
		if (i < CRT_LINES - 1) {
			glColor3f(1, 0, 1);
			glVertex2f(200, 110 + 40 * (i + 1)); glVertex2f(600, 110 + 40 * i);
		}
	}
	glColor3f(0, 0, 1);
	glVertex2f(200, 110); glVertex2f(600, 110 + 40 * (CRT_LINES - 1));
	glEnd();

	// Compute position of raster beam
	glPointSize(12);

	glColor3f(0, 0, 0);
	glBegin(GL_POINTS);

	if (raster_trace >= 1.0) {
		raster_trace = 1.0;
		if (raster_line == CRT_LINES - 1) {
			raster_vert_trace += 0.0005 * ticks;

			if (raster_vert_trace >= 1.0) {
				raster_trace = raster_hor_trace = raster_vert_trace = 0;
				raster_line = 0;
			} else
				glVertex2f(200 + (600 - 200) * (1 - raster_vert_trace), 110 + 40 * (CRT_LINES - 1) * (1 - raster_vert_trace));
		} else {
			raster_hor_trace += 0.01 * ticks;

			if (raster_hor_trace >= 1.0) {
				raster_hor_trace = 0;
				raster_trace = 0;
				raster_line = (raster_line + 1) % CRT_LINES;
			} else
				glVertex2f(600 - (600 - 200) * raster_hor_trace, 110 + 40 * (raster_line + raster_hor_trace));
		}
	} else {
		glColor3f(0, 1, 1);
		raster_trace += 0.002 * ticks;
		glVertex2f(200 + (600 - 200) * raster_trace, 110 + 40 * raster_line);
	}

	glEnd();

	glLineWidth(1);
	glPointSize(1);
}

static void display_menu(Uint32 ticks)
{
	switch (menu_select) {
	case MODE_MENU_MACHINES: display_menu_bombe(ticks); break;
	case MODE_MENU_VECTREX : display_menu_vectrex(); break;
	case MODE_MENU_CRT     : display_menu_crt(ticks); break;
	}
}

static void display(Uint32 ticks)
{
	switch (view_mode) {
	case MODE_MENU: display_menu(ticks); break;
	case MODE_MACHINES: display_machines(); break;
	}
}

static int kbd_machines(unsigned key)
{
	switch (key) {
	case 'q':
		view_mode = MODE_MENU;
		break;
	case SDLK_RIGHT:
		machine_index = (machine_index + 1) % MACHINES;
		break;
	case SDLK_LEFT:
		machine_index = (machine_index + MACHINES - 1) % MACHINES;
		break;
	case ' ': {
		char buf[80];
		snprintf(buf, sizeof buf, "bash ./%s", machine_scripts[machine_index]);
		system(buf);
		break;
	}
	}
	return 1;
}

static int kbd_menu(unsigned key)
{
	switch (key) {
	case 'q':
		return 0;
	case SDLK_RIGHT:
		menu_select = (menu_select + 1) % MENU_MODES;
		break;
	case SDLK_LEFT:
		menu_select = (menu_select + MENU_MODES - 1) % MENU_MODES;
		break;
	case ' ':
		switch (menu_select) {
		case MODE_MENU_MACHINES:
			machine_index = 0;
			view_mode = MODE_MACHINES;
			break;
		case MODE_MENU_VECTREX:
			system("bash ./vectrex");
			break;
		}
		break;
	case 'w':
	case 'h':
		system("helm");
		break;
	case 's':
		system("bash ./samples");
		break;
	case 'i':
		system("bash ./intermezzo");
		break;
	case 'p':
		system("bash ./pwm");
		break;
	case 'r':
		system("bash ./ringmod");
		break;
	case 'x':
		system("bash ./squaker");
		break;
	case 'z':
		system("bash ./zelda");
		break;
	}
	return 1;
}

static int kbd(unsigned key)
{
	switch (view_mode) {
	case MODE_MENU: return kbd_menu(key); break;
	case MODE_MACHINES: return kbd_machines(key); break;
	default: return 0;
	}
}

static int mainloop(void)
{
	glViewport(0, 0, WIDTH, HEIGHT);
	glClearColor(0, 0, 0, 0);

	timer = SDL_GetTicks();

	while (1) {
		SDL_Event ev;

		while (SDL_PollEvent(&ev)) {
			switch (ev.type) {
			case SDL_QUIT:
				return 0;
			case SDL_KEYDOWN:
				if (kbd(ev.key.keysym.sym) == 0)
					return 0;
				break;
			}
		}

		Uint32 next = SDL_GetTicks();
		display(next - timer);
		timer = next;

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
	gfx_load(4, "../images/nes.jpg");
	gfx_load(5, "../images/bombe.jpg");
	gfx_load(6, "../images/vectrex.jpg");
	gfx_load(7, "../images/crt.jpg");
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
