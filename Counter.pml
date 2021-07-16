#define R 3
#define B 2

// for verification only
bit changed[R] = 0;

// variables used in the algorithm
byte c[B] = 0;
bit isEdited[R] = 0;

int reader_id = 0;  // not part of the algorithm

active proctype writer() {
  printf("i am writer %d\n", _pid);
  do
  :: true -> // just loop infinitely
      int index = B-1;
      int carry = 0;
      
      int i;
dow:  
      if 
      :: c[index] == 255 -> 
          i = 0;
          for (i : 0 .. R-1) {
            isEdited[i] = 1;
          }
          c[index] = 0;

          index--;
          carry = 1;
      :: else ->
          if
          :: carry == 1 -> 
              carry = 0;
          :: else -> skip;
          fi;

          i = 0;
          for (i : 0 .. R-1) {
            isEdited[i] = 1;
          }
          c[index]++;
      fi;

      printf("Incremented: %d\n", c[index])

      if 
       :: carry == 1 && index >= 0 -> 
          goto dow;
       :: else -> skip;
      fi;
  od
}

active [R] proctype reader() {
  byte local_copy[B] = 0;
  byte local_copy_decoy[B] = 0; 
  int my_id;

  // for verification only
  byte helper1[B] = 0;
  byte helper2[B] = 0;

  d_step {
      my_id = reader_id;
      reader_id++;
  }

  printf("i am reader %d\n", _pid);
  do
  :: true ->
     do
     :: isEdited[my_id] == 1 ->   // repeat until a complete value of counter is obtained
  sr:   isEdited[my_id] = 0;      // sr: short for "start read"
        int i;
        atomic {                  // make sure the v here  
          i = 0;
          for(i : 0 .. B-1) {
              helper1[i] = c[i];
          }
        }
        i = 0;
        for(i : 0 .. B-1) {
            local_copy_decoy[i] = c[i];
        }
        atomic {                  // make sure the v here  
          i = 0;
          for(i : 0 .. B-1) {
              helper2[i] = c[i];
          }
        }

        if 
        :: isEdited[my_id] == 0 ->    // if no writing occured during the above 10 lines, we good
            i = 0;
            for(i : 0 .. B-1) {
               local_copy[i] = local_copy_decoy[i];
            }
rc:         printf("Reader %d updated\n", my_id); // short for "read complete"
            goto finish;
        :: else ->
            printf("Number %d decoy is attacked!!\n", my_id);
        fi 
     :: else -> skip;
     od 
     
     // is the same as local_copy here
finish:     atomic {
       i = 0;
       for (i : 0 .. B-1) { 
          printf("reader= %d, byte= %d, local_copy[i]= %d, helper1[i]= %d or helper2[i]%d\n", my_id, i, local_copy[i], helper1[i], helper2[i]);
          assert(local_copy[i] == helper1[i] || local_copy[i] == helper2[i]);
       }
     }
     
     printf("Reader %d: finished reading\n", my_id);
  :: else -> break;
  od
}

 // require that, under weak fairness, reads complete eventually even if writes subside.
ltl eventual_entry { []((reader[1]@sr) implies eventually (reader[1]@rc))}
