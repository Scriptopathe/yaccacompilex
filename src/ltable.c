#include "ltable.h"

ltable_t* ltable_new() {
    ltable_t* l = (ltable_t*)malloc(sizeof(ltable_t));
    l->index = 0;
    return l;
}

void ltable_add(ltable_t* this, int address) {
    this->labels[this->index] = address;
    this->index++;
}

void ltable_print(ltable_t* this) {
  printf("--------------  Labels Table  --------------\n");
	printf("| ID                 |  Address            |\n");
  for (int i = 0; i < this->index; i++) {
    printf("|%20d|%21d|\n", i, this->labels[i]);
  }
  printf("--------------------------------------------\n");
}

int get_value_at_index(ltable_t* this, int index){
  return this->labels[index];
}
