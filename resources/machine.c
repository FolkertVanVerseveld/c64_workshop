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

#define TEXTURES 9

#define TEX_BOMBE 5
#define TEX_VECTREX 6
#define TEX_CRT 7
#define TEX_AAAH 8

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
#define MODE_MENU_POUET 3

#define MENU_MODES 4

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

	x0 = WIDTH / 2 - w / 2;
	x1 = x0 + w;
	y0 = HEIGHT / 2 - h / 2 + 30 * sin(bombe_wobble);
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

#define VECTREX_SEGMENTS 40
#define VECTREX_PHASE_DIFF 0.2
#define VECTREX_SPEED 0.005
#define VECTREX_WIDTH 64

static float vectrex_offset = 0;

static void display_menu_vectrex(Uint32 ticks)
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

	vectrex_offset = fmodf(vectrex_offset + VECTREX_SPEED * ticks, 2 * M_PI);

	glBindTexture(GL_TEXTURE_2D, tex[TEX_VECTREX]);
	glEnable(GL_TEXTURE_2D);
	glColor3f(1, 1, 1);
	glBegin(GL_QUADS);
	for (unsigned i = 0; i < VECTREX_SEGMENTS; ++i) {
		GLfloat s0, s1, t0, t1, sx0, sy0, sx1, sy1, sx2, sx3;

		s0 = 0;
		s1 = 1;

		t0 = (1.0f / VECTREX_SEGMENTS) * i;
		t1 = (1.0f / VECTREX_SEGMENTS) * (i + 1);

		sx0 = x0 + VECTREX_WIDTH * sin(vectrex_offset + i * VECTREX_PHASE_DIFF);
		sx1 = x1 + VECTREX_WIDTH * sin(vectrex_offset + i * VECTREX_PHASE_DIFF);
		sx2 = x0 + VECTREX_WIDTH * sin(vectrex_offset + (i + 1) * VECTREX_PHASE_DIFF);
		sx3 = x1 + VECTREX_WIDTH * sin(vectrex_offset + (i + 1) * VECTREX_PHASE_DIFF);

		sy0 = y0 + ((double)i / VECTREX_SEGMENTS) * h;
		sy1 = y0 + ((double)(i + 1) / VECTREX_SEGMENTS) * h;

		glTexCoord2f(s0, t0); glVertex2f(sx0, sy0);
		glTexCoord2f(s1, t0); glVertex2f(sx1, sy0);
		glTexCoord2f(s1, t1); glVertex2f(sx3, sy1);
		glTexCoord2f(s0, t1); glVertex2f(sx2, sy1);
	}
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

unsigned roto_angle;
float roto_x, roto_y, roto_length;
float roto_xs = 1.0f, roto_ys = 1.0f;
float roto_xd = 0.0f, roto_yd = 0.0f;
unsigned roto_xp = 0, roto_yp = 0;

#define X_P 0.3
#define Y_P 0.6
#define ZOOMPERIOD 21
#define XPERIOD 6
#define YPERIOD 5

static void display_menu_pouet(Uint32 ticks)
{
	double ang, dx, dy;

	roto_angle = (roto_angle + ticks) % (360 * ZOOMPERIOD);
	roto_xp = (roto_xp + ticks) % (360 * XPERIOD);
	roto_yp = (roto_yp + ticks) % (360 * YPERIOD);

	ang = (double)roto_angle / ZOOMPERIOD;
	dx = (double)roto_xp / XPERIOD;
	dy = (double)roto_yp / YPERIOD;

	roto_xs = roto_ys = 1.3f + 0.8f * sin(ang / 180.0 * M_PI);
	roto_xd = tex_w[TEX_AAAH]  * (X_P + sin(dx / 180.0 * M_PI));
	roto_yd = tex_h[TEX_AAAH] * (Y_P + cos(dy / 180.0 * M_PI));

	glClearColor(0, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT);

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(-WIDTH / 2, WIDTH / 2, -HEIGHT / 2, HEIGHT / 2, -1, 1);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glBindTexture(GL_TEXTURE_2D, tex[TEX_AAAH]);
	glEnable(GL_TEXTURE_2D);
	glColor3f(1, 1, 1);
	glTranslatef(-roto_xd, -roto_yd, 0);
	glScalef(roto_xs, roto_ys, 1.0f);
	glRotatef(((double)roto_angle / ZOOMPERIOD), 0, 0, 1);

	GLfloat tx0, tx1, ty0, ty1;

	tx0 = roto_x - 20 * tex_w[TEX_AAAH] / 2;
	tx1 = roto_x + 20 * tex_w[TEX_AAAH] / 2;
	ty0 = roto_y - 20 * tex_h[TEX_AAAH] / 2;
	ty1 = roto_y + 20 * tex_h[TEX_AAAH] / 2;

	glBegin(GL_QUADS);
		glTexCoord2f(-10, 10); glVertex2f(tx0, ty0);
		glTexCoord2f(10, 10); glVertex2f(tx1, ty0);
		glTexCoord2f(10, -10); glVertex2f(tx1, ty1);
		glTexCoord2f(-10, -10); glVertex2f(tx0, ty1);
	glEnd();
}

static void display_menu(Uint32 ticks)
{
	switch (menu_select) {
	case MODE_MENU_MACHINES: display_menu_bombe(ticks); break;
	case MODE_MENU_VECTREX : display_menu_vectrex(ticks); break;
	case MODE_MENU_CRT     : display_menu_crt(ticks); break;
	case MODE_MENU_POUET   : display_menu_pouet(ticks); break;
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
		case MODE_MENU_CRT:
			system("bash ./debug");
			break;
		case MODE_MENU_POUET:
			system("firefox https://pouet.net");
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
	case 'a':
		system("bash ./amiga");
		break;
	case 'l':
		system("bash ./lman");
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
	gfx_load(8, "../images/sbm_obey.png");
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
