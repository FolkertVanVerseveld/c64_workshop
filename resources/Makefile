.PHONY: default clean

default: machine

machine: machine.c
	gcc -std=gnu99 -Wall -Wextra -pedantic $(shell pkg-config --cflags gl sdl2) -o machine machine.c $(shell pkg-config --libs gl sdl2) -lSDL2_image -lm

clean:
	rm -f machine
