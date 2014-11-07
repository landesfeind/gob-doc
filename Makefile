
CFLAGS += -std=c99 -g

gob-doc: scan.o
	$(CC) -o $@  $(LDFLAGS) $^

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ -c $^

%.c: %.l
	$(LEX) $(LFLAGS) -o $@ $^
