#define R 3
#define B 2

// for verification only
byte helper[B] = 0;
bit changed[R] = 0;

// variables used in the algorithm
byte c[B] = 0;
bit isEdited[R] = 0;

int reader_id = 0;  // not part of the algorithm

active proctype writer() {
  printf("i am writer %d\n", _pid);
  int index = B-1;
  int carry = 0;
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
     :: carry == 1 && i < R -> 
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
     :: isEdited[my_id] == 1 ->   // repeat until a complete value of counter is obtained
war:        isEdited[my_id] = 0;      
        atomic {                  // make sure the v here  
          isEdited[my_id] = 0;
          int i = 0;
          for(i : 0 .. B-1) {
              helper[i] = c[i];
          }
        }
        int i = 0;
        for(i : 0 .. B-1) {
            local_copy_decoy[i] = c[i];
        }

        if 
        :: isEdited[my_id] == 0 ->    // if no writing occured during the above 3 lines, we good
            for(i : 0 .. B-1) {
               local_copy[i] = local_copy_decoy[i];
            }
csr:            printf("Reader %d updated\n", my_id);
        :: else ->
            printf("Number %d decoy is attacked!!\n", my_id);
        fi 
     //   printf("Reader %d: %d\n", my_id, local_copy);
     //:: else ->
     //   printf("Reader %d: %d\n", my_id, local_copy);
     :: else -> break;
     od 
     // is the same as local_copy here
     atomic {
       for (i : 0 .. B-1) { 
          assert(local_copy[i] == helper[i])
       }
     }
     // assert (local_copy == helper);
// cp:  printf("Reader %d: %d\n", my_id, local_copy);
  :: else -> break;
  od
}

 // require that, under weak fairness, reads complete eventually even if writes subside.
ltl eventual_entry { []((reader[1]@war) implies eventually (reader[1]@csr))}
