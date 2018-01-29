CC = gcc
AR = ar
SIZE = size

TESTS := $(patsubst tests/%.sh,%,$(wildcard tests/test_*))
SRC += $(filter-out test_%.c,$(wildcard *.c emubd/*.c))
OBJ := $(SRC:.c=.o)
DEP := $(SRC:.c=.d) $(addsuffix .d,$(TESTS))
ASM := $(SRC:.c=.s)

SHELL = /bin/bash -o pipefail

ifdef DEBUG
override CFLAGS += -O0 -g3
else
override CFLAGS += -Os
endif
ifdef WORD
override CFLAGS += -m$(WORD)
endif
override CFLAGS += -I.
override CFLAGS += -std=c99 -Wall -pedantic

all: $(OBJ)

asm: $(ASM)

size: $(OBJ)
	$(SIZE) -t $^

.SUFFIXES:
test: $(TESTS)
$(TESTS): $(OBJ)
test_%: tests/test_%.sh FORCE
ifdef QUIET
	./$< | sed -n '/^[-=]/p'
else
	./$<
endif

-include $(DEP)

ifneq ($(filter $(TESTS),$(MAKECMDGOALS)),)
$(TESTS): test_%: test_%.o
$(TESTS):
	$(CC) $(CFLAGS) $^ $(LFLAGS) -o $@
else
%: %.o $(OBJ)
	$(CC) $(CFLAGS) $^ $(LFLAGS) -o $@
endif

%.a: $(OBJ)
	$(AR) rcs $@ $^

%.o: %.c
	$(CC) -c -MMD $(CFLAGS) $< -o $@

%.s: %.c
	$(CC) -S $(CFLAGS) $< -o $@

clean: FORCE
	rm -f $(TESTS) $(addsuffix .c,$(TESTS))
	rm -f $(OBJ) $(addsuffix .o,$(TESTS))
	rm -f $(DEP) $(addsuffix .d,$(TESTS))
	rm -f $(ASM) $(addsuffix .s,$(TESTS))

FORCE:

