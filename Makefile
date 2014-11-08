CFLAGS += -std=c99

.PHONY: all clean

all: gob-doc

clean:
	rm -f gob-doc *.o *.c

gob-doc: scan.o
	$(CC) -o $@  $(LDFLAGS) $^

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ -c $^

%.c: %.l
	$(LEX) $(LFLAGS) -o $@ $^
