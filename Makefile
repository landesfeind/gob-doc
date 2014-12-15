CFLAGS += -std=c99

.PHONY: all clean

all: gob-doc

clean:
	rm -f gob-doc *.o *.c

install: gob-doc
	install gob-doc /usr/bin/gob-doc

gob-doc: scan.o
	$(CC) -o $@  $(LDFLAGS) $^

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ -c $^

%.c: %.l
	$(LEX) $(LFLAGS) -o $@ $^
