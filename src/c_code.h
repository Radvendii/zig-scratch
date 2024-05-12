#include <stdbool.h>

typedef struct {
  bool val;
} MyStruct;

#define constant_struct (MyStruct) { .val = true }

extern MyStruct foo;

extern bool b;
