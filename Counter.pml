#define R 3
#define B 2

// for verification only
int helper = 0;
bit changed[R] = 0;

// variables used in the algorithm
int c = 0;
bit isEdited[R] = 0;

int reader_id = 0;  // not part of the algorithm

active proctype writer() {
  printf("i am writer %d\n", _pid);
  do
  :: true -> // just loop infinitely
      if 
      :: c[index] == 255 -> 
          index--;
          c[index] = 0;
          carry = 1;
      :: else ->
          if
          :: carry == 1 -> 
              printf("carried 1");
              carry = 0;
          :: else -> skip;
          fi;
          c[index]++;
          printf("Incremented: %d\n", c[index])
      fi;
     
     int i = 0;
     do
     :: i < R -> 
        isEdited[i] = 1;
        i++;
     :: else -> break;
     od 
  od
}

active [R] proctype reader() {
  byte local_copy[B] = 0;
  byte local_copy_decoy[B] = 0;  
  int my_id;

  d_step {
      my_id = reader_id;
      reader_id++;
  }

  printf("i am reader %d\n", _pid);
  do
  :: true ->
     do
     :: isEdited[my_id] == 1 ->   // make sure the v here  
        atomic {
           isEdited[my_id] = 0;
           helper = c;
        }
        local_copy_decoy = c;

        if 
        :: isEdited[my_id] == 0 ->
            for(i : 0 .. B) {
               local_copy[i] = local_copy_decoy[i];
            }
            printf("Reader %d updated\n", my_id);
        :: else ->
            printf("Number %d decoy is attacked!!\n", my_id);
        fi 
     //   printf("Reader %d: %d\n", my_id, local_copy);
     //:: else ->
     //   printf("Reader %d: %d\n", my_id, local_copy);
     :: else -> break;
     od 
     // is the same as local_copy here
     assert (local_copy == helper);
cp:  printf("Reader %d: %d\n", my_id, local_copy);
  :: else -> break;
  od
}
